import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
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
  final bool doPop;
  const VideoButtons(
      {super.key,
      required this.videos,
      required this.index,
      required this.oneLine,
      required this.withFullDetailButton,
      this.doPop = false});

  @override
  State<VideoButtons> createState() => _VideoButtonsState();
}

class _VideoButtonsState extends State<VideoButtons> {
  late Version selectedVersion;
  late Format selectedFormat;
  late Subtitle? selectedSubtitle;
  List<Version> versions = [];
  List<Format> formats = [];
  List<Subtitle> subtitles = [];
  List<DropdownMenuItem<Version>> versionItems = [];
  List<DropdownMenuItem<Format>> formatItems = [];
  List<DropdownMenuItem<Subtitle>> subtitleItems = [];
  late VideoData video = widget.videos[widget.index];
  late String _stream;

  @override
  void initState() {
    super.initState();

    if (versions.isNotEmpty) return;

    Future.microtask(() async {
      final programId = video.programId;
      final lang = Provider.of<LocaleModel>(context, listen: false)
          .getCurrentLocale(context)
          .languageCode;

      debugPrint('programId: $programId');
      try {
        final (cv, tf, ss) = await _getDetails(lang, programId);
        debugPrint('Versions: $cv');
        debugPrint('Formats: $tf');
        debugPrint('Subtitles: $ss');
        if (cv.isNotEmpty && mounted) {
          setState(() {
            versions = cv;
            selectedVersion = versions.first;
            versionItems = versions
                .map((e) =>
                    DropdownMenuItem<Version>(value: e, child: Text(e.label)))
                .toList();
          });
          video.versions = versions;
        }
        if (tf.isNotEmpty && mounted) {
          setState(() {
            formats = tf;
            if (formats.length - 1 >= AppConfig.playerIndexQuality) {
              selectedFormat = formats[AppConfig.playerIndexQuality];
            } else {
              selectedFormat = formats.last;
            }
            formatItems = formats
                .map((e) => DropdownMenuItem<Format>(
                    value: e, child: Text('${e.resolution.split('x').last}p')))
                .toList();
          });
        }
        if (ss.isNotEmpty && mounted) {
          ss.insert(
              0,
              Subtitle(
                  name: AppLocalizations.of(context)!.strNone,
                  url: null,
                  audioLanguage: 'None'));
          setState(() {
            subtitles = ss;
            selectedSubtitle = subtitles.first;
            subtitleItems = subtitles
                .map((e) =>
                    DropdownMenuItem<Subtitle>(value: e, child: Text(e.name)))
                .toList();
          });
        } else {
          selectedSubtitle = null;
        }
      } catch (e) {
        if (e is Map<String, dynamic>) {
          final messengerState = ScaffoldMessenger.of(context);
          final themeData = Theme.of(context);
          _showMessage(
              messengerState, themeData, '${e['title']} / ${e['message']}');
        } else {
          debugPrint('Error: ${e.toString()}');
        }
      }
    });
  }

  Future<(List<Version>, List<Format>, List<Subtitle>)> _getDetails(
      String lang, String programId) async {
    final cache = Provider.of<Cache>(context, listen: false);

    final url = 'https://api.arte.tv/api/player/v2/config/$lang/$programId';
    debugPrint(url);
    Map<String, dynamic>? jr;
    List<Version> cv = [];
    List<Format> tf = [];
    List<Subtitle> ss = [];

    jr = await cache.get(url);
    if (jr['data'] == null ||
        jr['data']['attributes'] == null ||
        jr['data']['attributes']['streams'] == null) {
      return (<Version>[], <Format>[], <Subtitle>[]);
    }
    //debugPrint(json.encode(jr).toString());
    final streams = jr['data']['attributes']['streams'];
    //debugPrint(json.encode(streams).toString());
    // pick-up first url stream
    _stream = streams[0]['url'];
    debugPrint('First stream found: $_stream');

    final stream = await MediaStream.getMediaPlaylist(_stream);
    for (var v in stream.audio.keys) {
      final url = stream.audio[v]!;
      final urlPart = url.toString().split('_');
      final shortLabel = urlPart[urlPart.length - 2].split('-')[0];
      cv.add(Version(
          url: url, label: v, shortLabel: shortLabel, audioLanguage: v));
    }
    for (var f in stream.resolution.keys) {
      final rb = f.split('@');
      tf.add(Format(
          bandwidth: rb[1], resolution: rb[0], url: stream.resolution[f]!));
    }
    tf.sort((a, b) {
      int aa = int.parse(a.bandwidth);
      int bb = int.parse(b.bandwidth);
      return aa.compareTo(bb);
    });
    for (var s in stream.subtitle.keys) {
      ss.add(Subtitle(
          name: s, url: stream.subtitle[s]!, audioLanguage: 'unknown'));
    }
    return (cv, tf, ss);
  }

  String _outputFilename() {
    return "${video.programId}_${selectedVersion.shortLabel.replaceAll(' ', '_')}_${selectedFormat.resolution}.mp4";
  }

  Future<String> _webvtt(Uri url) async {
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
    return webvtt.toString();
  }

  void _ffmpeg() async {
    final cwd = AppConfig.dlDirectory;
    debugPrint(cwd);
    final outputFilename =
        '${video.programId}_${selectedVersion.shortLabel.replaceAll(' ', '_')}_${selectedFormat.resolution}.mp4';
    debugPrint(outputFilename);
    final messengerState = ScaffoldMessenger.of(context);
    final themeData = Theme.of(context);

    if (File(path.join(cwd, outputFilename)).existsSync()) {
      _showMessage(
          messengerState, themeData, 'File $outputFilename already exists');
      return;
    }
    // work-around ffmpeg bug #10149 and #10169
    // because ffmpeg can't handle vtt subtitle correctly or choke on some time_id3/sidx stream
    // we download subtitle to modify it and then stream video, audio and subtitle separatly
    final (videoStream, audioStream, subtitleUrl) =
        await MediaStream.getMediaStream(
            selectedFormat.url, selectedVersion.url, selectedSubtitle?.url);
    debugPrint('Playing $video');
    debugPrint(videoStream.toString());
    ProcessManager mgr = const LocalProcessManager();
    String ffmpeg = 'ffmpeg';
    if (Platform.isWindows) {
      ffmpeg = 'ffmpeg.exe';
    } else if (!Platform.isLinux) {
      _showMessage(messengerState, themeData, 'not implemented');
      return;
    }
    if (!mgr.canRun(ffmpeg, workingDirectory: cwd)) {
      _showMessage(messengerState, themeData, 'ffmpeg has not been found');
      return;
    }
    _showMessage(
        messengerState, themeData, 'Downloading video ${video.programId}',
        isError: false);

    String videoFilename =
        videoStream.toString().split('/').last.replaceFirst('m3u8', 'mp4');
    String audioFilename = '';
    String subFilename = '';
    debugPrint(videoFilename);
    final dlVideo = mgr.run([
      ffmpeg,
      '-headers',
      'User-Agent: ${AppConfig.userAgent}',
      '-i',
      videoStream.toString(),
      '-c',
      'copy',
      videoFilename
    ], workingDirectory: cwd);
    List<Future> tasks = [dlVideo];
    if (audioStream != null) {
      audioFilename = audioStream.toString().split('/').last;
      debugPrint(audioFilename);
      final dlAudio = mgr.run([
        ffmpeg,
        '-headers',
        'User-Agent: ${AppConfig.userAgent}',
        '-i',
        audioStream.toString(),
        '-c',
        'copy',
        audioFilename
      ], workingDirectory: cwd);
      tasks.add(dlAudio);
    }
    String message;
    bool isError;
    String programId = video.programId;
    try {
      List responses = await Future.wait(tasks, eagerError: true);
      if (responses[0].exitCode != 0) {
        debugPrint(responses[0].stderr);
        throw (Exception('Error downloading video $programId'));
      }
      if (audioStream != null &&
          responses[1] is ProcessResult &&
          responses[1].exitCode != 0) {
        debugPrint(responses[0].stderr);
        throw (Exception('Error downloading audio $programId'));
      }
      // combine video/audio/subtitle together
      final String cmd;
      if (audioStream == null && subtitleUrl == null) {
        await File(path.join(cwd, videoFilename))
            .rename(path.join(cwd, outputFilename));
        cmd = '';
      } else if (subtitleUrl == null) {
        cmd =
            '$ffmpeg -i $videoFilename -i $audioFilename -map 0:v -map 1:a -c copy $outputFilename';
      } else {
        // WORKAROUND: because of ffmpeg bug #10169, remove all STYLE blocks in webvtt
        subFilename = subtitleUrl.toString().split('/').last;
        final subn = path.join(cwd, subFilename);
        final subtitle = await _webvtt(subtitleUrl);
        await File(subn).writeAsString(subtitle, flush: true);
        debugPrint(subn);
        cmd =
            '$ffmpeg -i $videoFilename -i $audioFilename -i $subFilename -map 0:v -map 1:a -map 2:s -c:v copy -c:a copy -c:s mov_text $outputFilename';
      }
      message = 'Finished downloading video ${video.programId}';
      isError = false;
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
      if (audioStream != null && audioFilename.isNotEmpty) {
        await File(path.join(cwd, audioFilename)).delete();
      }
      if (subtitleUrl != null && subFilename.isNotEmpty) {
        await File(path.join(cwd, subFilename)).delete();
      }
      if (File(path.join(cwd, videoFilename)).existsSync()) {
        await File(path.join(cwd, videoFilename)).delete();
      }
    } catch (e) {
      debugPrint(e.toString());
      message = 'Error downloading video ${video.programId} with ffmpeg';
      isError = true;
    }
    _showMessage(messengerState, themeData, message, isError: isError);
  }

  void _vlc() async {
    ProcessManager mgr = const LocalProcessManager();
    String binary = '';
    final messengerState = ScaffoldMessenger.of(context);
    final themeData = Theme.of(context);
    if (Platform.isLinux) {
      binary = 'cvlc';
    } else if (Platform.isWindows) {
      String? programFiles = Platform.environment['ProgramFiles'];
      if (programFiles == null || programFiles.isEmpty) {
        _showMessage(messengerState, themeData, '%ProgramFiles% is empty');
        return;
      }
      binary = path.join(programFiles, 'VideoLAN', 'VLC', 'vlc.exe');
      if (!File(binary).existsSync()) {
        _showMessage(messengerState, themeData, '$binary not found');
        // try in Program Files (x86)
        programFiles = Platform.environment['ProgramFiles(x86)'];
        if (programFiles == null || programFiles.isEmpty) {
          _showMessage(
              messengerState, themeData, '%ProgramFiles(x86)% is empty');
          return;
        }
        binary = path.join(programFiles, 'VideoLAN', 'VLC', 'vlc.exe');
        if (!File(binary).existsSync()) {
          _showMessage(messengerState, themeData, '$binary not found');
          return;
        }
      }
    } else {
      _showMessage(
          messengerState, themeData, AppLocalizations.of(context)!.strNotImpl);
      return;
    }
    if (!mgr.canRun(binary)) {
      if (!context.mounted) return;
      _showMessage(messengerState, themeData, '[c]vlc has not been found');
      return;
    }
    List<String> cmd;
    if (Platform.isWindows) {
      cmd = [
        binary,
        '--play-and-exit',
        '--quiet',
        '--http-user-agent="${AppConfig.userAgent}"',
        '--adaptive-maxheight=${selectedFormat.resolution.split('x').last}',
        _stream
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
        _stream
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
      _showMessage(messengerState, themeData,
          'Launching external [c]vlc instance to read video ${video.programId}',
          isError: false);
      ProcessResult result = await mgr.run(cmd);
      if (result.exitCode != 0) {
        //debugPrint(result.stderr);
        _showMessage(messengerState, themeData, 'Error: ${result.stderr}');
        return;
      }
    } on ProcessException catch (e) {
      //debugPrint('ProcessException: ${e.message}');
      _showMessage(messengerState, themeData, 'Error: ${e.message}');
    }
  }

  void _libmpv() async {
    String title = '';
    if (video.subtitle != null && video.subtitle!.isNotEmpty) {
      title = '${video.title} / ${video.subtitle}';
    } else {
      title = video.title;
    }

    final (videoStream, audioStream, subtitleUrl) =
        await MediaStream.getMediaStream(
            selectedFormat.url, selectedVersion.url, selectedSubtitle?.url);
    debugPrint('Playing $video');

    String subtitleData = '';
    if (subtitleUrl != null) {
      subtitleData = await _webvtt(subtitleUrl);
      debugPrint('Playing with subtitle from $subtitleUrl');
    }
    debugPrint(videoStream.toString());
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      if (kIsWeb ||
          Platform.isLinux ||
          Platform.isWindows ||
          Platform.isAndroid) {
        String videoStreamString, audioStreamString = '';
        if (kIsWeb) {
          videoStreamString = _stream;
        } else {
          videoStreamString = videoStream.toString();
          if (audioStream != null) {
            audioStreamString = audioStream.toString();
            debugPrint('Playing audio from $audioStream');
          }
        }
        return MyScreen(
            title:
                '$title [${selectedVersion.shortLabel}, ${selectedFormat.resolution}]',
            videoStream: videoStreamString,
            audioStream: audioStreamString,
            subtitleData: subtitleData,
            video: video);
      } else {
        return Center(child: Text(AppLocalizations.of(context)!.strNotImpl));
      }
    }));
  }

  Future<bool?> _displayAgeWarning(BuildContext context, int ageRating) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.strWarning),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.black87,
              child: Text('-${video.ageRating}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context)!.strYouAreAboutToWatch),
          ]),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: Text(AppLocalizations.of(context)!.strCancel),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: Text(AppLocalizations.of(context)!.strContinue),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> top = [
      IconButton(
        icon: const Icon(Icons.play_arrow),
        tooltip: AppLocalizations.of(context)!.strPlay,
        onPressed: versions.isNotEmpty && formats.isNotEmpty
            ? () {
                Future.microtask(() async {
                  bool? showVideo;
                  if (video.ageRating != 0) {
                    showVideo =
                        await _displayAgeWarning(context, video.ageRating);
                  } else {
                    showVideo = true;
                  }
                  if (showVideo != null && showVideo) {
                    if (AppConfig.player == PlayerTypeName.embedded) {
                      _libmpv();
                    } else if (AppConfig.player == PlayerTypeName.vlc) {
                      _vlc();
                    }
                  }
                });
              }
            : null,
      ),
      const SizedBox(width: 24),
      IconButton(
        icon: const Icon(Icons.download),
        tooltip: AppLocalizations.of(context)!.strDownload,
        onPressed: versions.isNotEmpty &&
                formats.isNotEmpty &&
                !kIsWeb &&
                (Platform.isWindows || Platform.isLinux)
            ? _ffmpeg
            : null,
      ),
      const SizedBox(width: 24),
      IconButton(
        icon: const Icon(Icons.copy),
        tooltip: AppLocalizations.of(context)!.strURL,
        onPressed: versions.isNotEmpty
            ? () {
                _copyToClipboard(context, _stream);
              }
            : null,
      ),
      if (widget.withFullDetailButton) ...[
        const SizedBox(width: 24),
        IconButton(
            icon: const Icon(Icons.read_more),
            tooltip: AppLocalizations.of(context)!.strMore,
            onPressed: () {
              if (widget.doPop) {
                // this will mean in dialog else in text mode
                Navigator.pop(context);
              }
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
                    //constraints: const BoxConstraints(minWidth: 100),
                    child: Text(
                      //v.shortLabel,
                      v.label,
                      style: const TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList();
              },
              value: selectedVersion,
              items: versionItems,
              onChanged: (value) async {
                setState(() {
                  selectedVersion = value!;
                  debugPrint(selectedVersion.url.toString());
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
                    //constraints: const BoxConstraints(minWidth: 100),
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
      const SizedBox(width: 10),
      subtitleItems.isNotEmpty
          ? DropdownButton<Subtitle>(
              underline: const SizedBox.shrink(),
              hint: const Text('Subtitle'),
              value: selectedSubtitle,
              selectedItemBuilder: (BuildContext context) {
                return subtitles.map<Widget>((s) {
                  return Container(
                    padding: const EdgeInsets.only(left: 10),
                    alignment: Alignment.centerLeft,
                    //constraints: const BoxConstraints(minWidth: 100),
                    child: Text(
                      s.name,
                    ),
                  );
                }).toList();
              },
              items: subtitleItems,
              onChanged: (value) {
                setState(() {
                  selectedSubtitle = value!;
                });
              })
          : const SizedBox(height: 24),
    ];

    return Column(children: [Row(children: top), Row(children: bottom)]);
  }

  void _showMessage(ScaffoldMessengerState messengerState, ThemeData themeData,
      String message,
      {bool isError = true}) {
    messengerState.showSnackBar(SnackBar(
      content: Text(message,
          style: TextStyle(
              color: isError
                  ? themeData.colorScheme.onError
                  : themeData.colorScheme.onInverseSurface)),
      backgroundColor: isError
          ? themeData.colorScheme.error
          : themeData.colorScheme.inverseSurface,
      behavior: SnackBarBehavior.floating,
      duration:
          isError ? const Duration(seconds: 20) : const Duration(seconds: 5),
      showCloseIcon: isError,
      closeIconColor: themeData.colorScheme.onError,
    ));
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context)!.strCopiedClipboard,
          style:
              TextStyle(color: Theme.of(context).colorScheme.onInverseSurface)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Theme.of(context).colorScheme.inverseSurface,
    ));
  }
}
