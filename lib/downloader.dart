import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'package:http/http.dart' as http;

class Stream {
  Uri? video;
  Uri? audio;
  Uri? subtitle;
  int videoSize = 0;
  int audioSize = 0;
  Stream(
      {required this.video,
      required this.audio,
      required this.subtitle,
      this.videoSize = 0,
      this.audioSize = 0});

  static Future<Stream> getMediaPlaylist(String url, String resolution) async {
    // get m3u8 playlist for each video, audio and subtitle stream
    Uri playlistUri = Uri.parse(url);
    final resp = await http.get(playlistUri);
    String contentString = resp.body;
    int height = int.parse(resolution.split('x')[1]);

    try {
      final playlist = await HlsPlaylistParser.create()
          .parseString(playlistUri, contentString);
      if (playlist is HlsMasterPlaylist) {
        Uri? video, audio, subtitle;
        for (var v in playlist.variants) {
          if (v.format.height == height) {
            video = v.url;
            break;
          }
        }
        if (playlist.audios.isNotEmpty) {
          audio = playlist.audios[0].url;
          debugPrint(playlist.audios[0].format.language);
          debugPrint(playlist.audios[0].format.label);
        } else {
          audio = null;
        }
        if (playlist.subtitles.isNotEmpty) {
          subtitle = playlist.subtitles[0].url;
          debugPrint(playlist.subtitles[0].format.language);
          debugPrint(playlist.subtitles[0].format.label);
        } else {
          subtitle = null;
        }
        return Stream(video: video, audio: audio, subtitle: subtitle);
      } else {
        // we expect a master paylist m3u8
        return Future.error(Exception('Expecting a master m3u8 playlist'));
      }
    } on ParserException catch (e) {
      return Future.error(e);
    }
  }

  static Future<Stream> getMediaStream(String url, String resolution) async {
    // get real stream for video, audio, subtitle
    Stream playlists = await Stream.getMediaPlaylist(url, resolution);

    Uri? video, audio, subtitle;
    int videoSize = 0;
    if (playlists.video != null) {
      final resp = await http.get(playlists.video!);
      String contentString = resp.body;

      try {
        final playlist = await HlsPlaylistParser.create()
            .parseString(playlists.video!, contentString);
        if (playlist is HlsMediaPlaylist) {
          final _ = playlist.baseUri!.split('/');
          _.removeLast();
          final baseUri = _.join('/');
          video = Uri.parse('$baseUri/${playlist.segments[0].url!}');
          final count = playlist.segments
              .where((s) => s.url == playlist.segments[0].url)
              .length;
          if (count != playlist.segments.length) {
            debugPrint('Warning: different urls for video stream segments');
          }
          for (var s in playlist.segments) {
            if (s.byterangeLength != null) {
              videoSize = videoSize + s.byterangeLength!;
            }
          }
        }
      } on ParserException catch (e) {
        return Future.error(e);
      }
    } else {
      return Future.error(Exception('Stream video Uri is null'));
    }
    int audioSize = 0;
    if (playlists.audio != null) {
      final resp = await http.get(playlists.audio!);
      String contentString = resp.body;

      try {
        final playlist = await HlsPlaylistParser.create()
            .parseString(playlists.audio!, contentString);
        if (playlist is HlsMediaPlaylist) {
          final _ = playlist.baseUri!.split('/');
          _.removeLast();
          final baseUri = _.join('/');
          audio = Uri.parse('$baseUri/${playlist.segments[0].url!}');
          final count = playlist.segments
              .where((s) => s.url == playlist.segments[0].url)
              .length;
          if (count != playlist.segments.length) {
            debugPrint('Warning: different urls for audio stream segments');
          }
          for (var s in playlist.segments) {
            if (s.byterangeLength != null) {
              audioSize = audioSize + s.byterangeLength!;
            }
          }
        }
      } on ParserException catch (e) {
        return Future.error(e);
      }
    } else {
      return Future.error(Exception('Stream audio Uri is null'));
    }
    if (playlists.subtitle != null) {
      final resp = await http.get(playlists.subtitle!);
      String contentString = resp.body;

      try {
        final playlist = await HlsPlaylistParser.create()
            .parseString(playlists.subtitle!, contentString);
        if (playlist is HlsMediaPlaylist) {
          final _ = playlist.baseUri!.split('/');
          _.removeLast();
          final baseUri = _.join('/');
          subtitle = Uri.parse('$baseUri/${playlist.segments[0].url!}');
        }
      } on ParserException catch (e) {
        return Future.error(e);
      }
    }
    return Stream(
        video: video,
        audio: audio,
        subtitle: subtitle,
        videoSize: videoSize!,
        audioSize: audioSize!);
  }

  @override
  String toString() {
    return 'Stream(video: $video, audio: $audio, subtitle: $subtitle)';
  }
}
