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
  double playSpeed = 1.0;

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

    player.setRate(playSpeed);

    controller.waitUntilFirstFrameRendered.then((value) {
      setState(() {
        isVideoPlayalable = true;
      });
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    player.stop();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!player.state.playing) {
      player.open(
          Media(widget.videoStream,
              httpHeaders: {'User-Agent': AppConfig.userAgent}),
          play: false);
      debugPrint('Playing ${widget.video}');
      // work-around ffmpeg bug #10149 and #10169
      // mpv is plagged with the same problem/bug than ffmpeg, because it uses it somehow as back-end
      // we use the same work-around by specifying video, audio and subtitle stream separately too
      Future.microtask(() async {
        if (widget.subtitle.isNotEmpty) {
          debugPrint('Playing with subtitle from ${widget.subtitle}');
          final data = await File(widget.subtitle).readAsString();
          await player.setSubtitleTrack(SubtitleTrack.data(data));
        }
        if (widget.audioStream.isNotEmpty) {
          debugPrint('Playing audio from ${widget.audioStream}');
          await player.setAudioTrack(
            AudioTrack.uri(widget.audioStream),
          );
        }
      });
      player.setVolume(100);
      player.play();
    }

    final List<double> availableSpeed = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final themeData = Theme.of(context);
    final List<PopupMenuItem<double>> availableSpeedItems = availableSpeed
        .map((s) => PopupMenuItem<double>(
            onTap: () {
              setState(() {
                playSpeed = s;
              });
              player.setRate(playSpeed);
            },
            value: s,
            child: Text('x$s',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface))))
        .toList();
    final List<Widget> bottomButtonBar = [
      const MaterialDesktopPlayOrPauseButton(),
      const MaterialDesktopVolumeButton(),
      const MaterialDesktopPositionIndicator(),
      const Spacer(),
      Theme(
          data: ThemeData.from(colorScheme: themeData.colorScheme),
          child: PopupMenuButton<double>(
              enableFeedback: false,
              /*
              onSelected: (value) {
                debugPrint('rate play speed set to $value');
                player.setRate(value);
              },
              */
              color: Theme.of(context).colorScheme.surface,
              initialValue: playSpeed,
              // no tooltip because other buttons don't have one for now
              splashRadius: 20,
              tooltip: '',
              itemBuilder: (context) {
                return availableSpeedItems;
              },
              icon: Icon(
                Icons.speed,
                color: Theme.of(context).colorScheme.onBackground,
              ))),
      const MaterialDesktopFullscreenButton(),
    ];

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
                    normal: MaterialDesktopVideoControlsThemeData(
                        seekBarPositionColor: Colors.deepOrange,
                        seekBarThumbColor: Colors.deepOrange,
                        bottomButtonBar: bottomButtonBar),
                    fullscreen: MaterialDesktopVideoControlsThemeData(
                        seekBarPositionColor: Colors.deepOrange,
                        seekBarThumbColor: Colors.deepOrange,
                        bottomButtonBar: bottomButtonBar),
                    child: Center(
                        child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width * 9.0 / 16.0,
                      child: Video(
                        controller: controller,
                        subtitleViewConfiguration:
                            const SubtitleViewConfiguration(
                          style: TextStyle(
                            height: 1.4,
                            fontSize: 42.0,
                            letterSpacing: 0.0,
                            wordSpacing: 0.0,
                            color: Color(0xffffffff),
                            fontWeight: FontWeight.normal,
                            backgroundColor: Color(0xaa000000),
                          ),
                          textAlign: TextAlign.center,
                          padding: EdgeInsets.all(24.0),
                        ),
                      ),
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
