import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'config.dart';

class MyScreen extends StatefulWidget {
  final String url;
  final String title;
  const MyScreen({super.key, required this.url, required this.title});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final Player player = Player();
  VideoController? controller;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      controller = await VideoController.create(player.handle);
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
    (player.platform as libmpvPlayer)
        .setProperty('user-agent', AppConfig.userAgent);
    player.volume = 100;
    debugPrint('Playing ${widget.url}');
    player.open(Playlist([Media(widget.url)]));

    return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Card(
                elevation: 8.0,
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.all(16.0),
                child: Video(
                  controller: controller,
                ),
              ),
            ),
            SeekBar(player: player),
            const SizedBox(height: 16.0),
          ],
        ));
  }
}

class SeekBar extends StatefulWidget {
  final Player player;
  const SeekBar({
    super.key,
    required this.player,
  });

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();
    isPlaying = widget.player.state.isPlaying;
    position = widget.player.state.position;
    duration = widget.player.state.duration;
    subscriptions.addAll(
      [
        widget.player.streams.isPlaying.listen((event) {
          setState(() {
            if (mounted) {
              isPlaying = event;
            }
          });
        }),
        widget.player.streams.position.listen((event) {
          setState(() {
            if (mounted) {
              position = event;
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
        const SizedBox(width: 24.0),
        ElevatedButton(
          onPressed: widget.player.playOrPause,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.onSecondary,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(24),
          ),
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
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
            /*onChanged:
                null, // disabled because seeking fails on most streamed video with mpv
            */
            onChanged: (e) {
              widget.player.seek(Duration(milliseconds: e ~/ 1));
            },
            /*
            onChangeEnd: (e) {
              widget.player.seek(Duration(milliseconds: e ~/ 1));
            },*/
          ),
        ),
        Text('0${duration.toString().substring(0, 7)}'),
        const SizedBox(width: 10.0),
        ElevatedButton(
            onPressed: () {
              widget.player.volume = widget.player.state.volume - 5;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onSecondary,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(24),
            ),
            child: Icon(
              Icons.volume_down,
              color: Theme.of(context).colorScheme.primary,
            )),
        ElevatedButton(
            onPressed: () {
              widget.player.volume = widget.player.state.volume + 5 <= 100
                  ? widget.player.state.volume + 5
                  : widget.player.state.volume;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onSecondary,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(24),
            ),
            child: Icon(
              Icons.volume_up,
              color: Theme.of(context).colorScheme.primary,
            )),
        const SizedBox(width: 24.0),
      ],
    );
  }
}
