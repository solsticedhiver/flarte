import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
  final String subtitleData;
  final VideoData video;
  const MyScreen(
      {super.key,
      required this.title,
      required this.videoStream,
      required this.audioStream,
      required this.subtitleData,
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
  // A [GlobalKey<VideoState>] is required to access the programmatic fullscreen interface.
  late final GlobalKey<VideoState> key = GlobalKey<VideoState>();

  @override
  void initState() {
    super.initState();

    subscription = player.stream.position.listen((event) {
      if (player.state.duration != Duration.zero &&
          event > player.state.duration * 0.9) {
        final ad = Provider.of<AppData>(context, listen: false);
        if (!ad.watched.contains(widget.video.programId)) {
          ad.addWatched(widget.video.programId);
          subscription.cancel();
        }
      }
    });
    player.setRate(playSpeed);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (kIsWeb || Platform.isAndroid) {
        key.currentState?.enterFullscreen();
      }
    });

    Future.microtask(() async {
      if (!player.state.playing) {
        await player.open(
            Media(widget.videoStream,
                httpHeaders:
                    kIsWeb ? null : {'User-Agent': AppConfig.userAgent}),
            play: false);
        // work-around ffmpeg bug #10149 and #10169
        // mpv is plagged with the same problem/bug than ffmpeg, because it uses it somehow as back-end
        // we use the same work-around by specifying video, audio and subtitle stream separately too
        if (widget.subtitleData.isNotEmpty) {
          await player
              .setSubtitleTrack(SubtitleTrack.data(widget.subtitleData));
        } else if (!kIsWeb) {
          await player.setSubtitleTrack(SubtitleTrack.no());
        }
        if (widget.audioStream.isNotEmpty) {
          await player.setAudioTrack(
            AudioTrack.uri(widget.audioStream),
          );
        }
        await player.setVolume(100);
        await player.play();
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
    player.stop();
    player.dispose();
    super.dispose();
  }

  List<Widget> topBar(BuildContext context) {
    return [
      MaterialDesktopCustomButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (key.currentState?.isFullscreen() ?? false) {
            key.currentState?.exitFullscreen();
          }
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
      const Spacer(),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
    Widget themeVideo = SizedBox.shrink(); // to make the compiler happy
    const subtitleViewConfigutation = SubtitleViewConfiguration(
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
    );

    int method = 1;
    if (kIsWeb) {
      method = 2;
      // TODO: fix it to customize the toolbar
    } else if (Platform.isAndroid) {
      method = 2;
    } else if (Platform.isLinux || Platform.isWindows) {
      method = 1;
    }
    /*
      themeVideo = Center(
          child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.width * 9.0 / 16.0,
        child: Video(
          controller: controller,
          subtitleViewConfiguration: subtitleViewConfigutation,
        ),
      ));
      */
    if (method == 2) {
      final List<Widget> bottomButtonBar = [
        const MaterialPositionIndicator(),
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
      ];

      themeVideo = MaterialVideoControlsTheme(
          normal: MaterialVideoControlsThemeData(
              seekBarPositionColor: Colors.deepOrange,
              seekBarThumbColor: Colors.deepOrange,
              bottomButtonBar: bottomButtonBar,
              topButtonBar: topBar(context)),
          fullscreen: MaterialVideoControlsThemeData(
              seekBarPositionColor: Colors.deepOrange,
              seekBarThumbColor: Colors.deepOrange,
              bottomButtonBar: bottomButtonBar,
              topButtonBar: topBar(context)),
          child: Center(
              child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.width * 9.0 / 16.0,
            child: Video(
              controller: controller,
              subtitleViewConfiguration: subtitleViewConfigutation,
              onEnterFullscreen: () async {
                await defaultEnterNativeFullscreen();
              },
              onExitFullscreen: () async {
                await defaultExitNativeFullscreen();
                if (Platform.isAndroid) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          )));
    } else if (method == 1) {
      final List<Widget> bottomDesktopButtonBar = [
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

      themeVideo = MaterialDesktopVideoControlsTheme(
          normal: MaterialDesktopVideoControlsThemeData(
              seekBarPositionColor: Colors.deepOrange,
              seekBarThumbColor: Colors.deepOrange,
              bottomButtonBar: bottomDesktopButtonBar),
          fullscreen: MaterialDesktopVideoControlsThemeData(
              seekBarPositionColor: Colors.deepOrange,
              seekBarThumbColor: Colors.deepOrange,
              bottomButtonBar: bottomDesktopButtonBar),
          child: Center(
              child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.width * 9.0 / 16.0,
            child: Video(
              controller: controller,
              subtitleViewConfiguration: subtitleViewConfigutation,
            ),
          )));
    }

    Widget mainWidget = Stack(children: [
      SizedBox.expand(
          child:
              Center(child: Text(AppLocalizations.of(context)!.strInitStream))),
      Visibility(visible: isVideoPlayalable, child: themeVideo)
    ]);
    Widget scaffold;
    if (method == 2) {
      scaffold = Scaffold(body: mainWidget);
    } else {
      scaffold = Scaffold(
          appBar: AppBar(
              title: Text(widget.title),
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white),
          body: Card(
            elevation: 8.0,
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.all(10),
            child: mainWidget,
          ));
    }
    return scaffold;
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
