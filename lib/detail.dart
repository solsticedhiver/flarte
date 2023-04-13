import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flarte/fulldetail.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:process/process.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';

import 'api.dart';
import 'config.dart';
import 'serie.dart';
import 'player.dart';
import 'mobile_player.dart';
import 'downloader.dart';

class ShowDetail extends StatefulWidget {
  final Map<String, dynamic> video;

  @override
  State<ShowDetail> createState() => _ShowDetailState();

  const ShowDetail({super.key, required this.video});
}

class _ShowDetailState extends State<ShowDetail> {
  late Version selectedVersion;
  late Format selectedFormat;
  List<Version> versions = [];
  List<DropdownMenuItem<Version>> versionItems = [];
  List<DropdownMenuItem<Format>> formatItems = [];
  List<Format> formats = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final programId = widget.video['programId'];

      debugPrint('programId: $programId');
      final lang = Provider.of<LocaleModel>(context, listen: false)
          .getCurrentLocale(context)
          .languageCode;

      final resp = await http.get(Uri.parse(
          'https://api.arte.tv/api/player/v2/config/$lang/$programId'));
      Map<String, dynamic> jr = json.decode(resp.body);
      if (jr['data'] == null ||
          jr['data']['attributes'] == null ||
          jr['data']['attributes']['streams'] == null) {
        return;
      }
      //debugPrint(json.encode(jr).toString());
      final streams = jr['data']['attributes']['streams'];
      //debugPrint(json.encode(streams).toString());
      List<Version> cv = [];
      for (var s in streams) {
        final v = s['versions'][0];
        //debugPrint(v['shortLabel']);
        cv.add(Version(
            shortLabel: v['shortLabel'], label: v['label'], url: s['url']));
      }
      debugPrint(cv.toString());
      if (cv.isNotEmpty && mounted) {
        setState(() {
          versions.clear();
          versions.addAll(cv);
          selectedVersion = versions.first;
          debugPrint(selectedVersion.url);
          versionItems = versions
              .map((e) =>
                  DropdownMenuItem<Version>(value: e, child: Text(e.label)))
              .toList();
        });
        _getFormats();
      }
    });
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.black87,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _getFormats() async {
    // directly parse the .m3u8 to get the bandwidth value to pass to libmpv backend
    final resp = await http.get(Uri.parse(selectedVersion.url),
        headers: {'User-Agent': AppConfig.userAgent});
    final lines = resp.body.split('\n');
    List<Format> tf = [];
    // #EXT-X-STREAM-INF:BANDWIDTH=xxx,AVERAGE-BANDWIDTH=yyyy,VIDEO-RANGE=SDR,CODECS="avc1.4d401e,mp4a.40.2",RESOLUTION=zzzxzzz,FRAME-RATE=25.000,AUDIO="program_audio_0",SUBTITLES="subs"
    for (var line in lines) {
      if (line.startsWith('#EXT-X-STREAM-INF')) {
        final info = line.split(':').last;
        String resolution = '', bandwidth = '';
        for (var i in info.split(',')) {
          if (i.startsWith('RESOLUTION')) {
            resolution = i.split('=').last;
          } else if (i.startsWith('BANDWIDTH')) {
            bandwidth = i.split('=').last;
          }
        }
        tf.add(Format(resolution: resolution, bandwidth: bandwidth));
        tf.sort((a, b) {
          int aa = int.parse(a.bandwidth.replaceFirst('p', ''));
          int bb = int.parse(b.bandwidth.replaceFirst('p', ''));
          return aa.compareTo(bb);
        });
      }
    }
    debugPrint(tf.toString());
    if (tf.isNotEmpty && mounted) {
      setState(() {
        formats.clear();
        formats.addAll(tf);
        // try to keep the previously defined resolution, if initiliazed
        try {
          final _ = selectedFormat;
          for (var f in formats) {
            if (f.resolution == selectedFormat.resolution) {
              selectedFormat = f;
              break;
            }
          }
        } catch (e) {
          if (formats.length - 1 >= AppConfig.playerIndexQuality) {
            selectedFormat = formats[AppConfig.playerIndexQuality];
          } else {
            selectedFormat = formats.last;
          }
        }
        formatItems = formats
            .map((e) => DropdownMenuItem<Format>(
                value: e, child: Text('${e.resolution.split('x').last}p')))
            .toList();
      });
    }
  }

  String _outputFilename() {
    return "${widget.video['programId']}_${selectedVersion.shortLabel.replaceAll(' ', '_')}_${selectedFormat.resolution}.mp4";
  }

  void _ytdlp() async {
    ProcessManager mgr = const LocalProcessManager();
    // look for the format id that matches our resolution
    String binary = '';
    if (Platform.isLinux) {
      binary = 'yt-dlp';
    } else if (Platform.isWindows) {
      binary = 'yt-dlp.exe';
    } else {
      return;
    }
    List<String> cmd = [
      binary,
      '--user-agent',
      AppConfig.userAgent,
      '-J',
      selectedVersion.url
    ];
    String formatId = '';
    ProcessResult result = await mgr.run(cmd);
    if (result.exitCode != 0) {
      debugPrint(result.stderr);
      return;
    }
    final jr = json.decode(result.stdout);
    for (var f in jr['formats']) {
      if (f['resolution'] == selectedFormat.resolution) {
        formatId = f['format_id'];
        break;
      }
    }
    debugPrint('found format_id: $formatId');
    if (formatId.isNotEmpty) {
      cmd = [
        binary,
        '--user-agent',
        AppConfig.userAgent,
        '-f',
        formatId,
        '-o',
        _outputFilename(),
        selectedVersion.url
      ];
      result = await mgr.run(cmd, workingDirectory: AppConfig.dlDirectory);
    }
    if (result.exitCode != 0) {
      debugPrint(result.stderr);
      _showMessage(context,
          'Error downloading video ${widget.video['programId']} with yt-dlp');
      return;
    }
  }

  Future<void> _webvtt(Uri url, String subFilename) async {
    final req = await http.get(url);
    String resp = utf8.decode(req.bodyBytes);
    StringBuffer webvtt = StringBuffer('');
    bool addLine = true;
    for (var line in resp.split('\n')) {
      if (line.startsWith('STYLE')) {
        addLine = false;
      } else if (line.trim() == '' && !addLine) {
        addLine = true;
      }
      if (addLine) {
        webvtt.writeln(line.trim());
      }
    }
    await File(subFilename).writeAsString(webvtt.toString(), flush: true);
  }

  void _ffmpeg() async {
    // work-around ffmpeg bug #10149 and #10169
    // because ffmpeg can't handle vtt subtitle correctly or choke on some time_id3/sidx stream
    // we download subtitle to modify it and then stream video, audio and subtitle separatly
    debugPrint('looking at ${selectedVersion.url}');
    MediaStream stream;
    try {
      stream = await MediaStream.getMediaStream(
          selectedVersion.url, selectedFormat.resolution);
    } catch (e) {
      // this is a TS stream with no separate audio stream, causing the timed_id3 error
      stream = await MediaStream.getMediaPlaylist(
          selectedVersion.url, selectedFormat.resolution);
    }
    debugPrint(stream.toString());
    ProcessManager mgr = const LocalProcessManager();
    String ffmpeg = 'ffmpeg';
    if (Platform.isWindows) {
      ffmpeg = 'ffmpeg.exe';
    } else if (!Platform.isLinux) {
      return;
    }
    final cwd = AppConfig.dlDirectory;
    debugPrint(cwd);
    String videoFilename =
        stream.video.toString().split('/').last.replaceFirst('m3u8', 'mp4');
    String audioFilename = '';
    String subFilename = '';
    debugPrint(videoFilename);
    final dlVideo = mgr.run([
      ffmpeg,
      '-headers',
      'User-Agent: ${AppConfig.userAgent}',
      '-i',
      stream.video.toString(),
      '-c',
      'copy',
      videoFilename
    ], workingDirectory: cwd);
    List<Future> tasks = [dlVideo];
    if (stream.audio != null) {
      audioFilename = stream.audio.toString().split('/').last;
      debugPrint(audioFilename);
      final dlAudio = mgr.run([
        ffmpeg,
        '-headers',
        'User-Agent: ${AppConfig.userAgent}',
        '-i',
        stream.audio.toString(),
        '-c',
        'copy',
        audioFilename
      ], workingDirectory: cwd);
      tasks.add(dlAudio);
    }
    String message;
    String programId = widget.video['programId'];
    try {
      List responses = await Future.wait(tasks, eagerError: true);
      if (responses[0].exitCode != 0) {
        debugPrint(responses[0].stderr);
        throw (Exception('Error downloading video $programId'));
      }
      if (stream.audio != null &&
          responses[1] is ProcessResult &&
          responses[1].exitCode != 0) {
        debugPrint(responses[0].stderr);
        throw (Exception('Error downloading audio $programId'));
      }
      // combine video/audio/subtitle together
      final outputFilename =
          '${widget.video['programId']}_${selectedVersion.shortLabel.replaceAll(' ', '_')}_${selectedFormat.resolution}.mp4';
      debugPrint(outputFilename);
      final String cmd;
      if (stream.audio == null && stream.subtitle == null) {
        await File(path.join(cwd, videoFilename))
            .rename(path.join(cwd, outputFilename));
        cmd = '';
      } else if (stream.subtitle == null) {
        cmd =
            '$ffmpeg -i $videoFilename -i $audioFilename -map 0:v -map 1:a -c copy $outputFilename';
      } else {
        // WORKAROUND: because of ffmpeg bug #10169, remove all STYLE blocks in webvtt
        subFilename = stream.subtitle.toString().split('/').last;
        final subn = path.join(cwd, subFilename);
        await _webvtt(stream.subtitle!, subn);
        debugPrint(subn);
        cmd =
            '$ffmpeg -i $videoFilename -i $audioFilename -i $subFilename -map 0:v -map 1:a -map 2:s -c:v copy -c:a copy -c:s mov_text $outputFilename';
      }
      message = 'Download of video ${widget.video['programId']} finished';
      if (cmd.isNotEmpty) {
        final result = await mgr.run(cmd.split(' '), workingDirectory: cwd);
        if (result.exitCode != 0) {
          debugPrint(
              'Failed to combine video/audio/subtitle for ${widget.video['programId']}\n${result.stderr}');
          message = 'Error downloading video ${widget.video['programId']}';
        } else {
          debugPrint(
              'Finished combining video/audio/subtitle for ${widget.video['programId']}');
          message = 'Download of video ${widget.video['programId']} finished';
        }
      }
      if (stream.audio != null && audioFilename.isNotEmpty) {
        await File(path.join(cwd, audioFilename)).delete();
      }
      if (stream.subtitle != null && subFilename.isNotEmpty) {
        await File(path.join(cwd, subFilename)).delete();
      }
      if (File(path.join(cwd, videoFilename)).existsSync()) {
        await File(path.join(cwd, videoFilename)).delete();
      }
    } catch (e) {
      debugPrint(e.toString());
      message =
          'Error downloading video ${widget.video['programId']} with ffmpeg';
    }
    if (mounted) {
      _showMessage(context, message);
    }
  }

  void _vlc() async {
    ProcessManager mgr = const LocalProcessManager();
    String binary = '';
    if (Platform.isLinux) {
      binary = 'cvlc';
    } else if (Platform.isWindows) {
      String? programFiles = Platform.environment['ProgramFiles'];
      if (programFiles == null || programFiles.isEmpty) {
        _showMessage(context, '%ProgramFiles% is empty');
        return;
      }
      binary = path.join(programFiles, 'VideoLAN', 'VLC', 'vlc.exe');
      if (!File(binary).existsSync()) {
        _showMessage(context, '$binary not found');
        // try in Program Files (x86)
        programFiles = Platform.environment['ProgramFiles(x86)'];
        if (programFiles == null || programFiles.isEmpty) {
          _showMessage(context, '%ProgramFiles(x86)% is empty');
          return;
        }
        binary = path.join(programFiles, 'VideoLAN', 'VLC', 'vlc.exe');
        if (!File(binary).existsSync()) {
          _showMessage(context, '$binary not found');
          return;
        }
      }
    } else {
      return;
    }
    List<String> cmd;
    if (Platform.isWindows) {
      cmd = [
        binary,
        '--play-and-exit',
        '--quiet',
        '--http-user-agent="${AppConfig.userAgent}"',
        '--adaptive-maxheight="${selectedFormat.resolution.split('x').last}"',
        selectedVersion.url
      ];
    } else {
      cmd = [
        binary,
        '--play-and-exit',
        '--quiet',
        '--http-user-agent',
        AppConfig.userAgent,
        '--adaptive-maxheight',
        selectedFormat.resolution.split('x').last,
        selectedVersion.url
      ];
    }
    /*
    if (Platform.isWindows) {
      cmd.insertAll(1, [
        '-I',
        'dummy',
        '--dummy-quiet',
      ]);
    }
    */
    try {
      _showMessage(context,
          'Launching external [c]vlc instance to read video ${widget.video['programId']}');
      ProcessResult result = await mgr.run(cmd);
      if (result.exitCode != 0) {
        //debugPrint(result.stderr);
        _showMessage(context, 'Error: ${result.stderr}');
        return;
      }
    } on ProcessException catch (e) {
      //debugPrint('ProcessException: ${e.message}');
      _showMessage(context, 'Error: ${e.message}');
    }
  }

  void _libmpv() async {
    String title = '';
    String? subtitle = widget.video['subtitle'];
    if (subtitle != null && subtitle.isNotEmpty) {
      title = '${widget.video['title']} / $subtitle';
    } else {
      title = widget.video['title'];
    }

    MediaStream stream;
    try {
      stream = await MediaStream.getMediaStream(
          selectedVersion.url, selectedFormat.resolution);
    } catch (e) {
      // this is a TS stream with no separate audio stream, causing the timed_id3 error
      stream = await MediaStream.getMediaPlaylist(
          selectedVersion.url, selectedFormat.resolution);
    }
    String subFilename = '';
    if (stream.subtitle != null) {
      Directory tmpDir = await getTemporaryDirectory();
      debugPrint(tmpDir.toString());
      subFilename =
          path.join(tmpDir.path, stream.subtitle.toString().split('/').last);
      await _webvtt(stream.subtitle!, subFilename);
    }
    debugPrint(stream.toString());
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      if (Platform.isLinux || Platform.isWindows) {
        return MyScreen(
            title: title,
            video: stream.video!.toString(),
            audio: stream.audio != null ? stream.audio.toString() : '',
            subtitle: subFilename);
      } else {
        return MyMobileScreen(
            title: title,
            url: selectedVersion.url,
            bitrate: selectedFormat.bandwidth);
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    //debugPrint(json.encode(widget.video));

    final imageUrl = widget.video['imageUrl'];
    return Container(
        padding: const EdgeInsets.all(15),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.video['title'],
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              widget.video['subtitle'] != null
                  ? Text(
                      widget.video['subtitle'],
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    )
                  : const SizedBox.shrink(),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image(
                    width: 200,
                    height: 300,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(width: 200, height: 300),
                    image: CachedNetworkImageProvider(
                        '${imageUrl.replaceFirst('400x225', '300x450')}?type=TEXT',
                        headers: {'User-Agent': AppConfig.userAgent}),
                  ),
                  const SizedBox(width: 15),
                  Flexible(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          widget.video['shortDescription'] != null
                              ? Text(
                                  widget.video['shortDescription']
                                      .replaceAll(RegExp('\u{00a0}?'), ''),
                                  maxLines: 16,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium)
                              : const SizedBox.shrink(),
                          const SizedBox(height: 10),
                          Row(children: [
                            Chip(
                              backgroundColor: Theme.of(context).primaryColor,
                              label: Text(widget.video['label']),
                            ),
                            const SizedBox(width: 10),
                            if (!widget.video['isCollection'] &&
                                widget.video['durationLabel'] != null)
                              Chip(
                                backgroundColor: Theme.of(context).primaryColor,
                                label: Text(widget.video['durationLabel']),
                              ),
                          ]),
                          const SizedBox(height: 10),
                          widget.video['isCollection']
                              ? const SizedBox.shrink()
                              : Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.play_arrow),
                                      onPressed: versions.isNotEmpty &&
                                              formats.isNotEmpty
                                          ? () {
                                              if (AppConfig.player ==
                                                  PlayerTypeName.embedded) {
                                                _libmpv();
                                              } else if (AppConfig.player ==
                                                  PlayerTypeName.vlc) {
                                                _vlc();
                                              }
                                            }
                                          : null,
                                    ),
                                    const SizedBox(width: 24),
                                    IconButton(
                                      icon: const Icon(Icons.download),
                                      onPressed: versions.isNotEmpty &&
                                              formats.isNotEmpty
                                          ? _ffmpeg
                                          : null,
                                    ),
                                    const SizedBox(width: 24),
                                    IconButton(
                                      icon: const Icon(Icons.copy),
                                      onPressed: versions.isNotEmpty
                                          ? () {
                                              _copyToClipboard(
                                                  context, selectedVersion.url);
                                            }
                                          : null,
                                    ),
                                    const SizedBox(width: 24),
                                    IconButton(
                                        icon: const Icon(Icons.read_more),
                                        onPressed: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      FullDetailScreen(
                                                          programId: widget
                                                                  .video[
                                                              'programId'])));
                                        }),
                                  ],
                                ),
                          const SizedBox(height: 10),
                          widget.video['isCollection']
                              ? const SizedBox.shrink()
                              : Row(children: [
                                  versionItems.isNotEmpty
                                      ? DropdownButton<Version>(
                                          underline: const SizedBox.shrink(),
                                          hint: const Text('Version'),
                                          selectedItemBuilder:
                                              (BuildContext context) {
                                            return versions.map<Widget>((v) {
                                              return Container(
                                                padding: const EdgeInsets.only(
                                                    left: 10),
                                                alignment: Alignment.centerLeft,
                                                constraints:
                                                    const BoxConstraints(
                                                        minWidth: 100),
                                                child: Text(
                                                  v.shortLabel,
                                                  style: const TextStyle(
                                                      color: Colors.deepOrange,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              );
                                            }).toList();
                                          },
                                          value: selectedVersion,
                                          items: versionItems,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedVersion = value!;
                                              _getFormats();
                                            });
                                          })
                                      : const SizedBox(height: 24),
                                  const SizedBox(width: 10),
                                  formatItems.isNotEmpty
                                      ? DropdownButton<Format>(
                                          underline: const SizedBox.shrink(),
                                          hint: const Text('Format'),
                                          value: selectedFormat,
                                          selectedItemBuilder:
                                              (BuildContext context) {
                                            return formats.map<Widget>((f) {
                                              return Container(
                                                padding: const EdgeInsets.only(
                                                    left: 10),
                                                alignment: Alignment.centerLeft,
                                                constraints:
                                                    const BoxConstraints(
                                                        minWidth: 100),
                                                child: Text(
                                                  '${f.resolution.split('x').last}p',
                                                ),
                                              );
                                            }).toList();
                                          },
                                          items: formatItems,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedFormat = value!;
                                            });
                                          })
                                      : const SizedBox(height: 24),
                                ]),
                          widget.video['isCollection']
                              ? TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => SerieScreen(
                                                title: widget.video['title'],
                                                url: widget.video['url'])));
                                  },
                                  child: Text(AppLocalizations.of(context)!
                                      .strEpisodes),
                                )
                              : const SizedBox.shrink(),
                          const SizedBox(height: 10),
                          Row(children: [
                            const Expanded(
                                flex: 1, child: SizedBox(height: 10)),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child:
                                  Text(AppLocalizations.of(context)!.strClose),
                            )
                          ]),
                        ]),
                  )
                ],
              ),
            ]));
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context)!.strCopiedClipboard,
          style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.black87,
      behavior: SnackBarBehavior.floating,
    ));
  }
}
