import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:process/process.dart';
import 'package:xdg_directories/xdg_directories.dart';
import 'package:path/path.dart' as path;

import 'api.dart';
import 'config.dart';
import 'serie.dart';
import 'player.dart';

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

      debugPrint(programId);
      final resp = await http.get(
          Uri.parse('https://api.arte.tv/api/player/v2/config/fr/$programId'));
      Map<String, dynamic> jr = json.decode(resp.body);
      if (jr['data'] == null) {
        return;
      }
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
      if (cv.isNotEmpty) {
        setState(() {
          versions.clear();
          versions.addAll(cv);
          selectedVersion = versions.first;
          versionItems = versions
              .map((e) =>
                  DropdownMenuItem<Version>(value: e, child: Text(e.label)))
              .toList();
        });
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
    if (tf.isNotEmpty) {
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
          selectedFormat = formats[2];
        }
        formatItems = formats
            .map((e) => DropdownMenuItem<Format>(
                value: e, child: Text('${e.resolution.split('x').last}p')))
            .toList();
      });
    }
  }

  String _dlDirectory() {
    String workingDirectory = '';

    if (Platform.isLinux) {
      // download with yt-dlp in $XDG_DOWNLOAD_DIR if defined, else $HOME
      Directory? downloadDir = getUserDirectory('DOWNLOAD');
      if (downloadDir == null) {
        workingDirectory = const String.fromEnvironment('HOME');
      } else {
        workingDirectory = downloadDir.path;
      }
    } else if (Platform.isWindows) {
      // download to %USERPORFILE%\Downloads
      workingDirectory =
          path.join(Platform.environment['USERPROFILE']!, 'Downloads');
    }
    debugPrint('workingDirectory: $workingDirectory');
    return workingDirectory;
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
      result = await mgr.run(cmd, workingDirectory: _dlDirectory());
    }
    if (result.exitCode != 0) {
      debugPrint(result.stderr);
      return;
    }
  }

  void _ffmpeg() async {
    ProcessManager mgr = const LocalProcessManager();
    // look for the format id that matches our resolution
    String ffmpeg = 'ffmpeg';
    String ffprobe = 'ffprobe';
    if (Platform.isWindows) {
      ffmpeg = 'ffmpeg.exe';
      ffprobe = 'ffprobe.exe';
    } else if (!Platform.isLinux) {
      return;
    }
    List<String> cmd = [
      ffprobe,
      '-headers',
      'User-Agent: ${AppConfig.userAgent}',
      '-v',
      'quiet',
      '-print_format',
      'json',
      '-show_programs',
      '-i',
      selectedVersion.url
    ];
    ProcessResult result = await mgr.run(cmd);
    if (result.exitCode != 0) {
      debugPrint(result.stderr);
      return;
    }
    Map<String, dynamic> jr = json.decode(result.stdout);
    final res = selectedFormat.resolution.split('x');
    final width = int.parse(res[0]);
    final height = int.parse(res[1]);
    int program = -1;
    for (var p in jr['programs']) {
      if (p['streams'][0]['height'] == height) {
        program = p['program_id'];
        break;
      }
    }
    if (program == -1) {
      return;
    }
    cmd = [
      ffmpeg,
      '-headers',
      'User-Agent: ${AppConfig.userAgent}',
      '-i',
      selectedVersion.url,
      '-map',
      '0:p:$program',
      '-c',
      'copy',
      _outputFilename()
    ];
    result = await mgr.run(cmd, workingDirectory: _dlDirectory());
    if (result.exitCode != 0) {
      debugPrint(result.stderr);
      return;
    } else {
      debugPrint('Done downloading ${selectedVersion.url}');
    }
  }

  void _cvlc() async {
    ProcessManager mgr = const LocalProcessManager();
    // look for the format id that matches our resolution
    String binary_vlc = '';
    if (Platform.isLinux) {
      binary_vlc = 'cvlc';
    } else if (Platform.isWindows) {
      binary_vlc = 'cvlc.exe';
    } else {
      return;
    }
    List<String> cmd = [
      binary_vlc,
      '--play-and-exit',
      '--http-user-agent',
      'User-Agent: ${AppConfig.userAgent}',
      '--quiet',
      '--adaptive-maxheight',
      selectedFormat.resolution.split('x').last,
      selectedVersion.url
    ];
    ProcessResult result = await mgr.run(cmd);
    if (result.exitCode != 0) {
      debugPrint(result.stderr);
      return;
    }
  }

  void _libmpv() {
    String title = '';
    String? subtitle = widget.video['subtitle'];
    if (subtitle != null && subtitle.isNotEmpty) {
      title = '${widget.video['title']} / $subtitle';
    } else {
      title = widget.video['title'];
    }

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MyScreen(
              title: title,
              url: selectedVersion.url,
              bitrate: selectedFormat.bandwidth)),
    );
  }

  @override
  Widget build(BuildContext context) {
    //debugPrint(json.encode(widget.video));

    final imageUrl = (widget.video['mainImage']['url'])
        .replaceFirst('__SIZE__', '400x225')
        .replaceFirst('?type=TEXT', '');
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
                    image: CachedNetworkImageProvider(
                        '${imageUrl.replaceFirst('400x225', '300x450')}?type=TEXT'),
                  ),
                  const SizedBox(width: 15),
                  Flexible(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          widget.video['shortDescription'] != null
                              ? Text(widget.video['shortDescription'],
                                  maxLines: 16,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium)
                              : const SizedBox.shrink(),
                          const SizedBox(height: 10),
                          Row(children: [
                            Chip(
                              backgroundColor:
                                  Theme.of(context).primaryColorDark,
                              label: Text(widget.video['kind']['label']),
                            ),
                            const SizedBox(width: 10),
                            if (!widget.video['kind']['isCollection'] &&
                                widget.video['durationLabel'] != null)
                              Chip(
                                backgroundColor:
                                    Theme.of(context).primaryColorDark,
                                label: Text(widget.video['durationLabel']),
                              ),
                          ]),
                          const SizedBox(height: 10),
                          widget.video['kind']['isCollection']
                              ? const SizedBox.shrink()
                              : Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.play_arrow),
                                      onPressed:
                                          versions.isNotEmpty ? _libmpv : null,
                                    ),
                                    const SizedBox(width: 24),
                                    IconButton(
                                      icon: const Icon(Icons.download),
                                      onPressed:
                                          versions.isNotEmpty ? _ffmpeg : null,
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
                                  ],
                                ),
                          const SizedBox(height: 10),
                          widget.video['kind']['isCollection']
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
                          widget.video['kind']['isCollection']
                              ? TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => SerieScreen(
                                                title: widget.video['title'],
                                                url: widget.video['url'])));
                                  },
                                  child: const Text('Épisodes'),
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
                              child: const Text('Fermer'),
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content:
          Text('Copied to clipboard', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.black87,
      behavior: SnackBarBehavior.floating,
    ));
  }
}
