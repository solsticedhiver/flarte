import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

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
  VideoController? controller;
  bool _isFullScreen = false;

  bool get isFullScreen => _isFullScreen;
  set isFullScreen(bool value) => setState(() => _isFullScreen = value);

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      controller = await VideoController.create(player);
      setState(() {});
    });
  }

  @override
  void dispose() {
    Future.microtask(() async {
      // Release allocated resources back to the system.
      await player.pause();
      await controller?.dispose();
      await player.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pp = player.platform as libmpvPlayer;
    pp.setProperty('user-agent', AppConfig.userAgent);
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
      player.open(Playlist([Media(widget.videoStream)]));
      debugPrint('Playing ${widget.video}');
    }

    double buttonSize = 16.0;
    double margin = 10.0;

    return RawKeyboardListener(
        autofocus: true,
        focusNode: FocusNode(),
        onKey: (event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey.keyLabel == "Escape" && isFullScreen) {
              windowManager.setFullScreen(!isFullScreen);
              isFullScreen = !isFullScreen;
            } else if (event.isKeyPressed(LogicalKeyboardKey.space)) {
              player.playOrPause();
            } else if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
              final position = player.state.position -
                  Duration(seconds: event.repeat ? 30 : 10);
              if (position > Duration.zero) {
                player.seek(position);
              }
            } else if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
              final position = player.state.position +
                  Duration(seconds: event.repeat ? 30 : 10);
              if (position < player.state.duration) {
                player.seek(position);
              }
            } else if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
              final position = player.state.position -
                  Duration(seconds: event.repeat ? 90 : 60);
              if (position > Duration.zero) {
                player.seek(position);
              }
            } else if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
              final position = player.state.position +
                  Duration(seconds: event.repeat ? 90 : 60);
              if (position < player.state.duration) {
                player.seek(position);
              }
            } else if (event.isKeyPressed(LogicalKeyboardKey.pageUp)) {
              final position =
                  player.state.position - const Duration(minutes: 5);
              if (position > Duration.zero) {
                player.seek(position);
              }
            } else if (event.isKeyPressed(LogicalKeyboardKey.pageDown)) {
              final position =
                  player.state.position + const Duration(minutes: 5);
              if (position < player.state.duration) {
                player.seek(position);
              }
            }
          }
        },
        child: Scaffold(
            appBar: !isFullScreen ? AppBar(title: Text(widget.title)) : null,
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: InkWell(
                      splashColor: Theme.of(context).canvasColor,
                      highlightColor: Theme.of(context).canvasColor,
                      focusColor: Theme.of(context).canvasColor,
                      hoverColor: Theme.of(context).canvasColor,
                      onDoubleTap: () {
                        windowManager.setFullScreen(!isFullScreen);
                        isFullScreen = !isFullScreen;
                      },
                      child: Card(
                        elevation: 8.0,
                        clipBehavior: Clip.antiAlias,
                        margin: EdgeInsets.all(!isFullScreen ? margin : 0.0),
                        child: Video(
                          controller: controller,
                        ),
                      )),
                ),
                if (!isFullScreen) ...[
                  SeekBar(
                      player: player,
                      buttonSize: buttonSize,
                      video: widget.video),
                  SizedBox(height: margin)
                ],
              ],
            )));
  }
}

class SeekBar extends StatefulWidget {
  final Player player;
  final double buttonSize;
  final VideoData video;
  const SeekBar({
    super.key,
    required this.player,
    required this.buttonSize,
    required this.video,
  });

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  bool playing = false;
  bool seeking = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();
    playing = widget.player.state.playing;
    position = widget.player.state.position;
    duration = widget.player.state.duration;
    subscriptions.addAll(
      [
        widget.player.streams.playing.listen((event) {
          setState(() {
            if (mounted) {
              playing = event;
            }
          });
        }),
        widget.player.streams.completed.listen((event) {
          setState(() {
            position = Duration.zero;
          });
        }),
        widget.player.streams.position.listen((event) {
          setState(() {
            if (mounted) {
              if (!seeking) position = event;
            }
            final ad = Provider.of<AppData>(context, listen: false);
            if (position > duration * 0.9 &&
                !ad.watched.contains(widget.video.programId)) {
              ad.addWatched(widget.video.programId);
            }
          });
        }),
        widget.player.streams.duration.listen((event) {
          setState(() {
            if (mounted) {
              duration = event;
            }
          });
        }),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (final s in subscriptions) {
      s.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: widget.buttonSize),
        ElevatedButton(
          onPressed: widget.player.playOrPause,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.onSecondary,
            shape: const CircleBorder(),
            padding: EdgeInsets.all(widget.buttonSize),
          ),
          child: Icon(
            playing ? Icons.pause : Icons.play_arrow,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10.0),
        Text('0${position.toString().substring(0, 7)}'),
        Expanded(
          child: Slider(
            min: 0.0,
            max: duration.inMilliseconds.toDouble(),
            value: position.inMilliseconds.toDouble().clamp(
                  0,
                  duration.inMilliseconds.toDouble(),
                ),
            onChanged: position.inMilliseconds > 0
                ? (e) {
                    setState(() {
                      position = Duration(milliseconds: e ~/ 1);
                    });
                  }
                : null,
            onChangeStart: (e) {
              seeking = true;
            },
            onChangeEnd: (e) {
              seeking = false;
              widget.player.seek(Duration(milliseconds: e ~/ 1));
            },
          ),
        ),
        Text('0${duration.toString().substring(0, 7)}'),
        const SizedBox(width: 10.0),
        ElevatedButton(
            onPressed: () {
              widget.player.setVolume(widget.player.state.volume - 5);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onSecondary,
              shape: const CircleBorder(),
              padding: EdgeInsets.all(widget.buttonSize),
            ),
            child: Icon(
              Icons.volume_down,
              color: Theme.of(context).colorScheme.primary,
            )),
        ElevatedButton(
            onPressed: () {
              widget.player.setVolume(widget.player.state.volume + 5 <= 100
                  ? widget.player.state.volume + 5
                  : widget.player.state.volume);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onSecondary,
              shape: const CircleBorder(),
              padding: EdgeInsets.all(widget.buttonSize),
            ),
            child: Icon(
              Icons.volume_up,
              color: Theme.of(context).colorScheme.primary,
            )),
        ElevatedButton(
            onPressed: () {
              bool ifs = MyScreen.of(context).isFullScreen;
              windowManager.setFullScreen(!ifs);
              MyScreen.of(context).isFullScreen = !ifs;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onSecondary,
              shape: const CircleBorder(),
              padding: EdgeInsets.all(widget.buttonSize),
            ),
            child: Icon(
              Icons.fullscreen,
              color: Theme.of(context).colorScheme.primary,
            )),
        SizedBox(width: widget.buttonSize),
      ],
    );
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
