import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

import 'downloader.dart';

class MyMobileScreen extends StatefulWidget {
  final String url;
  final String title;
  final String bitrate;
  const MyMobileScreen(
      {super.key,
      required this.url,
      required this.title,
      required this.bitrate});

  @override
  State<MyMobileScreen> createState() => _MyMobileScreenState();
}

class _MyMobileScreenState extends State<MyMobileScreen> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {
          controller.play();
        });
      });
    controller.setClosedCaptionFile(Future.microtask(() async {
      String resolution =
          '768x432'; // hard-coded for now as this is not used at all
      MediaStream stream;
      try {
        stream = await MediaStream.getMediaStream(widget.url, resolution);
      } catch (e) {
        // this is a TS stream with no separate audio stream, causing the timed_id3 error
        stream = await MediaStream.getMediaPlaylist(widget.url, resolution);
      }
      debugPrint(stream.toString());
      String fileContents = '';
      if (stream.subtitle != null) {
        final resp = await http.get(stream.subtitle!);
        fileContents = utf8.decode(resp.bodyBytes);
      }
      ClosedCaptionFile closedCaptionFile = WebVTTCaptionFile(fileContents);
      return closedCaptionFile;
    }));
    controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Playing ${widget.url} at ${widget.bitrate} bps');

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
                child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: controller.value.isInitialized
                        ? Stack(children: [
                            VideoPlayer(controller),
                            ClosedCaption(text: controller.value.caption.text),
                          ])
                        : const SizedBox.expand()),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 24.0),
                ElevatedButton(
                  onPressed: () {
                    debugPrint(controller.value.caption.toString());
                    setState(() {
                      controller.value.isPlaying
                          ? controller.pause()
                          : controller.play();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onSecondary,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(24),
                  ),
                  child: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10.0),
                Text(
                    '0${controller.value.position.toString().substring(0, 7)}'),
                Expanded(
                  child: Slider(
                    min: 0.0,
                    max: controller.value.duration.inMilliseconds.toDouble(),
                    value: controller.value.position.inMilliseconds
                        .toDouble()
                        .clamp(
                          0,
                          controller.value.duration.inMilliseconds.toDouble(),
                        ),
                    /*onChanged:
                null, // disabled because seeking fails on most streamed video with mpv
            */
                    onChanged: (e) {
                      controller.seekTo(Duration(milliseconds: e ~/ 1));
                    },
                    /*
            onChangeEnd: (e) {
              widget.player.seek(Duration(milliseconds: e ~/ 1));
            },*/
                  ),
                ),
                Text(
                    '0${controller.value.duration.toString().substring(0, 7)}'),
                const SizedBox(width: 10.0),
                ElevatedButton(
                    onPressed: () {
                      controller.setVolume(controller.value.volume - 0.05);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.onSecondary,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(24),
                    ),
                    child: Icon(
                      Icons.volume_down,
                      color: Theme.of(context).colorScheme.primary,
                    )),
                ElevatedButton(
                    onPressed: () {
                      debugPrint(controller.value.volume.toString());
                      controller.setVolume(controller.value.volume + 0.05 <= 1.0
                          ? controller.value.volume + 0.05
                          : controller.value.volume);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.onSecondary,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(24),
                    ),
                    child: Icon(
                      Icons.volume_up,
                      color: Theme.of(context).colorScheme.primary,
                    )),
                const SizedBox(width: 24.0),
              ],
            ),
            const SizedBox(height: 16.0),
          ],
        ));
  }
}
