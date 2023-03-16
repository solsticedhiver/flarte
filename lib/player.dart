import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'config.dart';

class MyScreen extends StatefulWidget {
  final String programId;
  const MyScreen({super.key, required this.programId});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  // Create a [Player] instance from `package:media_kit`.
  final Player player = Player();
  // Reference to the [VideoController] instance from `package:media_kit_video`.
  VideoController? controller;
  String? url;
  String title = '';
  bool isBuffering = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // Create a [VideoController] instance from `package:media_kit_video`.
      // Pass the [handle] of the [Player] from `package:media_kit` to the [VideoController] constructor.
      controller = await VideoController.create(
        player.handle,
        //enableHardwareAcceleration: false,
      );
      // Must be created before opening any media. Otherwise, a separate window will be created.
      final resp = await http.get(Uri.parse(
          'https://api.arte.tv/api/player/v2/config/fr/${widget.programId}'));
      final Map<String, dynamic> jr = json.decode(resp.body);
      setState(() {
        url = jr['data']['attributes']['streams'][0]['url'];
        String? subtitle = jr['data']['attributes']['metadata']['subtitle'];
        if (subtitle != null && subtitle.isNotEmpty) {
          title =
              '${jr['data']['attributes']['metadata']['title']} / $subtitle}';
        } else {
          title = jr['data']['attributes']['metadata']['title'];
        }
      });
      debugPrint('Playing $url');
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
    player.open(Playlist([if (url != null && url!.isNotEmpty) Media(url!)]));
    return Scaffold(
        appBar: AppBar(title: Text(title)),
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
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 10.0),
        Text(position.toString().substring(2, 7)),
        Expanded(
          child: Slider(
            min: 0.0,
            max: duration.inMilliseconds.toDouble(),
            value: position.inMilliseconds.toDouble().clamp(
                  0,
                  duration.inMilliseconds.toDouble(),
                ),
            onChanged:
                null, // disabled because seeking fails on most streamed video with mpv
            /*
            onChanged: (e) {
              widget.player.seek(Duration(milliseconds: e ~/ 1));
            },
            onChangeEnd: (e) {
              widget.player.seek(Duration(milliseconds: e ~/ 1));
            },*/
          ),
        ),
        Text(duration.toString().substring(2, 7)),
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
              color: Theme.of(context).colorScheme.secondary,
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
              color: Theme.of(context).colorScheme.secondary,
            )),
        const SizedBox(width: 24.0),
      ],
    );
  }
}
