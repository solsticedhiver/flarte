import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:process/process.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'fulldetail.dart';
import 'helpers.dart';
import 'player.dart';

class VideoButtons extends StatefulWidget {
  final List<VideoData> videos;
  final int index;
  final bool oneLine;
  final bool withFullDetailButton;
  const VideoButtons(
      {super.key,
      required this.videos,
      required this.index,
      required this.oneLine,
      required this.withFullDetailButton});

  @override
  State<VideoButtons> createState() => _VideoButtonsState();
}

class _VideoButtonsState extends State<VideoButtons> {
  late Version selectedVersion;
  late Format selectedFormat;
  List<Version> versions = [];
  List<DropdownMenuItem<Version>> versionItems = [];
  List<DropdownMenuItem<Format>> formatItems = [];
  List<Format> formats = [];
  late VideoData video = widget.videos[widget.index];

  @override
  void initState() {
    super.initState();

    if (versions.isNotEmpty) return;

    Future.microtask(() async {
      final programId = video.programId;

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
        video.versions = versions;
        _getFormats();
      }
    });
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
    return "${video.programId}_${selectedVersion.shortLabel.replaceAll(' ', '_')}_${selectedFormat.resolution}.mp4";
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
      if (!context.mounted) return;
      _showMessage(
          context, 'Error downloading video ${video.programId} with yt-dlp');
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
    final cwd = AppConfig.dlDirectory;
    debugPrint(cwd);
    final outputFilename =
        '${video.programId}_${selectedVersion.shortLabel.replaceAll(' ', '_')}_${selectedFormat.resolution}.mp4';
    debugPrint(outputFilename);
    if (File(path.join(cwd, outputFilename)).existsSync()) {
      _showMessage(context, 'File $outputFilename already exists');
      return;
    }
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
    String programId = video.programId;
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
      message = 'Download of video ${video.programId} finished';
      if (cmd.isNotEmpty) {
        final result = await mgr.run(cmd.split(' '), workingDirectory: cwd);
        if (result.exitCode != 0) {
          debugPrint(
              'Failed to combine video/audio/subtitle for ${video.programId}\n${result.stderr}');
          message = 'Error downloading video ${video.programId}';
        } else {
          debugPrint(
              'Finished combining video/audio/subtitle for ${video.programId}');
          message = 'Download of video ${video.programId} finished';
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
      message = 'Error downloading video ${video.programId} with ffmpeg';
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
          'Launching external [c]vlc instance to read video ${video.programId}');
      ProcessResult result = await mgr.run(cmd);
      if (result.exitCode != 0) {
        //debugPrint(result.stderr);
        if (!context.mounted) return;
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
    String? subtitle = video.subtitle;
    if (subtitle != null && subtitle.isNotEmpty) {
      title = '${video.title} / $subtitle';
    } else {
      title = video.title;
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
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      if (Platform.isLinux || Platform.isWindows || Platform.isAndroid) {
        return MyScreen(
            title: title,
            videoStream: stream.video!.toString(),
            audioStream: stream.audio != null ? stream.audio.toString() : '',
            subtitle: subFilename,
            video: video);
      } else {
        return Center(child: Text(AppLocalizations.of(context)!.strNotImpl));
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> top = [
      IconButton(
        icon: const Icon(Icons.play_arrow),
        onPressed: versions.isNotEmpty && formats.isNotEmpty
            ? () {
                if (AppConfig.player == PlayerTypeName.embedded) {
                  _libmpv();
                } else if (AppConfig.player == PlayerTypeName.vlc) {
                  _vlc();
                }
              }
            : null,
      ),
      const SizedBox(width: 24),
      IconButton(
        icon: const Icon(Icons.download),
        onPressed: versions.isNotEmpty && formats.isNotEmpty ? _ffmpeg : null,
      ),
      const SizedBox(width: 24),
      IconButton(
        icon: const Icon(Icons.copy),
        onPressed: versions.isNotEmpty
            ? () {
                _copyToClipboard(context, selectedVersion.url);
              }
            : null,
      ),
      if (widget.withFullDetailButton) ...[
        const SizedBox(width: 24),
        IconButton(
            icon: const Icon(Icons.read_more),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => FullDetailScreen(
                          videos: widget.videos,
                          index: widget.index,
                          title: '')));
            })
      ],
    ];
    List<Widget> bottom = [
      versionItems.isNotEmpty
          ? DropdownButton<Version>(
              underline: const SizedBox.shrink(),
              hint: const Text('Version'),
              selectedItemBuilder: (BuildContext context) {
                return versions.map<Widget>((v) {
                  return Container(
                    padding: const EdgeInsets.only(left: 10),
                    alignment: Alignment.centerLeft,
                    constraints: const BoxConstraints(minWidth: 100),
                    child: Text(
                      v.shortLabel,
                      style: const TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w600),
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
              selectedItemBuilder: (BuildContext context) {
                return formats.map<Widget>((f) {
                  return Container(
                    padding: const EdgeInsets.only(left: 10),
                    alignment: Alignment.centerLeft,
                    constraints: const BoxConstraints(minWidth: 100),
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
    ];

    if (widget.oneLine) {
      return Row(children: [...top, ...bottom]);
    } else {
      return Column(children: [Row(children: top), Row(children: bottom)]);
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.black87,
      behavior: SnackBarBehavior.floating,
    ));
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
