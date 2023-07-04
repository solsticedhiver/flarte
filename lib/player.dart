import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'config.dart';
import 'helpers.dart';

class MyScreen extends StatefulWidget {
  final String title;
  final String videoStream;
  final String audioStream;
  final String subtitle;
  final VideoData video;
  const MyScreen(
      {super.key,
      required this.title,
      required this.videoStream,
      required this.audioStream,
      required this.subtitle,
      required this.video});

  @override
  State<MyScreen> createState() => MyScreenState();

  static MyScreenState of(BuildContext context) =>
      context.findAncestorStateOfType<MyScreenState>()!;
}

class MyScreenState extends State<MyScreen> {
  final Player player =
      Player(configuration: const PlayerConfiguration(title: AppConfig.name));
  late final controller = VideoController(player);
  late StreamSubscription subscription;
  bool isVideoPlayalable = false;

  @override
  void initState() {
    super.initState();

    subscription = player.stream.position.listen((event) {
      if (event > player.state.duration * 0.9) {
        final ad = Provider.of<AppData>(context, listen: false);
        if (!ad.watched.contains(widget.video.programId)) {
          ad.addWatched(widget.video.programId);
          subscription.cancel();
        }
      }
    });

    controller.waitUntilFirstFrameRendered.then((value) {
      setState(() {
        isVideoPlayalable = true;
      });
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    player.pause();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (player.platform is libmpvPlayer) {
      final pp = player.platform as dynamic;
      // work-around ffmpeg bug #10149 and #10169
      // mpv is plagged with the same problem/bug than ffmpeg, because it uses it somehow as back-end
      // we use the same work-around by specifying video, audio and subtitle stream separately too
      if (player.state.playlist.medias.isEmpty) {
        if (widget.subtitle.isNotEmpty) {
          debugPrint('Playing with subtitle from ${widget.subtitle}');
          pp.setProperty('sub-files', widget.subtitle);
        }
        if (widget.audioStream.isNotEmpty) {
          debugPrint('Playing audio from ${widget.audioStream}');
          // escape character usedd as list seprator by mpv
          String audio = widget.audioStream;
          if (Platform.isLinux || Platform.isAndroid) {
            audio = audio.replaceAll(':', '\\:');
          } else if (Platform.isWindows) {
            audio = audio.replaceAll(';', '\\;');
          }
          pp.setProperty('audio-files', audio);
        }

        player.setVolume(100);
        player.open(Playlist([
          Media(widget.videoStream,
              httpHeaders: {'User-Agent': AppConfig.userAgent})
        ]));
        debugPrint('Playing ${widget.video}');
      }
    }

    return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Card(
          elevation: 8.0,
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.all(10),
          child: Stack(children: [
            Center(child: Text(AppLocalizations.of(context)!.strInitStream)),
            Visibility(
                visible: isVideoPlayalable,
                child: MaterialDesktopVideoControlsTheme(
                    normal: const MaterialDesktopVideoControlsThemeData(
                      seekBarPositionColor: Colors.deepOrange,
                      seekBarThumbColor: Colors.deepOrange,
                    ),
                    fullscreen: const MaterialDesktopVideoControlsThemeData(
                        seekBarPositionColor: Colors.deepOrange,
                        seekBarThumbColor: Colors.deepOrange),
                    child: Center(
                        child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width * 9.0 / 16.0,
                      child: Video(controller: controller),
                    ))))
          ]),
        ));
  }
}

// mpv --ytdl --script-opts=ytdl_hook-try_ytdl_first=yes --ytdl-format='bestvideo[width<=960][height<=540]+bestaudio/best'
/*
final player = Player();
// Check type. Only true for libmpv based platforms. Currently Windows & Linux.
if (player?.platform is libmpvPlayer) {
  await (player?.platform as libmpvPlayer?)?.setProperty("rtsp-transport", "udp");
}
*/
