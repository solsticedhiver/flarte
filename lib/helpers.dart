import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flarte/config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Cache extends ChangeNotifier {
  final Map<String, dynamic> data = {};
  //int index = 0;

  static List<dynamic> parseJson(Map<String, dynamic> data) {
    List<dynamic> result = [];
    final List<dynamic> zones = data['value']['zones'];
    for (var z in zones) {
      List<dynamic> videos = z['content']['data'];
      videos.retainWhere((v) => v['programId'] != null);
      if (videos.length <= 1 ||
          z['displayOptions']['template'].startsWith('event') ||
          z['displayOptions']['template'].startsWith('single')) {
        continue;
      }

      result.add({
        'title': z['title'],
        'videos': videos.map((v) => VideoData.fromJson(v)).toList()
      });
    }
    return result;
  }

  Future<Map<String, dynamic>> get(String key, {isJson = true}) async {
    if (!data.containsKey(key) || data[key].isEmpty) {
      final resp = await http
          .get(Uri.parse(key), headers: {'User-Agent': AppConfig.userAgent});
      Map<String, dynamic> jr = {};
      if (resp.statusCode != 200) {
        return jr;
      }
      if (isJson) {
        try {
          jr = json.decode(resp.body);
          set(key, jr);
        } on FormatException {
          return jr;
        }
      } else {
        jr = {'body': resp.body};
        set(key, jr);
      }
      return jr;
    }
    return data[key];
  }

  void set(String key, dynamic dyn, {notify = false}) {
    data[key] = dyn;
    if (notify) {
      notifyListeners();
    }
    //debugPrint('data cache length:  ${data.toString().length / 1024}ko');
  }

  Future<List<dynamic>?> fetch(String key, String lang) async {
    final cacheKey = '$key-$lang';
    if (!data.containsKey(cacheKey) || data[cacheKey] == null) {
      final String url =
          "https://www.arte.tv/api/rproxy/emac/v4/$lang/web/pages/$key/";
      final resp = await http
          .get(Uri.parse(url), headers: {'User-Agent': AppConfig.userAgent});
      if (resp.statusCode == 200) {
        final jr = json.decode(resp.body);
        set(cacheKey, parseJson(jr), notify: true);
        return data[cacheKey];
      } else {
        return null;
      }
    } else {
      return data[cacheKey];
    }
  }
}

enum CategoriesListSize { tiny, small, normal }

enum CarouselListSize { tiny, small, normal }

enum PlayerTypeName { embedded, vlc, custom }

class Version {
  String shortLabel;
  String label;
  Uri url;
  String audioLanguage;
  String? subtitleLanguage;

  Version(
      {required this.shortLabel,
      required this.label,
      required this.url,
      required this.audioLanguage,
      this.subtitleLanguage});

  @override
  String toString() {
    return 'Version($shortLabel/$audioLanguage, $label)';
  }
}

class Format {
  String resolution;
  String bandwidth; // used with media_kit/libmpv player
  Uri url;

  Format(
      {required this.resolution, required this.bandwidth, required this.url});

  @override
  String toString() {
    return 'Format($resolution, $bandwidth)';
  }

  @override
  int get hashCode {
    return resolution.hashCode + bandwidth.hashCode;
  }

  @override
  bool operator ==(other) {
    return other is Format &&
        other.resolution == resolution &&
        other.bandwidth == bandwidth;
  }
}

class Subtitle {
  String name;
  Uri? url;
  String audioLanguage;

  Subtitle(
      {required this.name, required this.url, required this.audioLanguage});
}

class LocaleModel with ChangeNotifier {
  Locale? _locale;
  Locale? get locale => _locale;

  void changeLocale(Locale? l, {notify = true}) {
    if (AppLocalizations.supportedLocales.contains(l)) {
      _locale = l;
      if (notify) {
        notifyListeners();
      }
    }
  }

  Locale getCurrentLocale(BuildContext context) {
    if (_locale != null) {
      return _locale!;
    } else {
      return Localizations.localeOf(context);
    }
  }
}

class ThemeModeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark;

  void switchTheme() {
    if (themeMode == ThemeMode.dark) {
      themeMode = ThemeMode.light;
    } else if (themeMode == ThemeMode.light) {
      themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }

  void changeTheme(ThemeMode tm) {
    themeMode = tm;
    notifyListeners();
  }
}

class VideoData {
  String programId;
  String title;
  String? subtitle;
  String? imageUrl;
  String? shortDescription;
  bool isCollection;
  String? label;
  String? durationLabel;
  String url;
  String? srcJson;
  //bool hasBeenPlayed;
  //bool isFavorite;
  List<Version>? versions;
  String? teaserText;
  int ageRating;

  VideoData({
    required this.programId,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.shortDescription,
    required this.isCollection,
    required this.label,
    required this.durationLabel,
    required this.url,
    required this.ageRating,
    this.srcJson,
    this.versions,
    this.teaserText,
  });

  factory VideoData.fromJson(Map<String, dynamic> video) {
    return VideoData(
      programId: video['programId'],
      title: video['title'],
      subtitle: video['subtitle']?.trim(),
      imageUrl: (video['mainImage']['url'])
          .replaceFirst('__SIZE__', '400x225')
          .replaceFirst('?type=TEXT', ''),
      shortDescription: video['shortDescription']?.trim(),
      isCollection: video['kind']['isCollection'],
      label: video['kind']['label']?.trim(),
      durationLabel: video['durationLabel']?.trim(),
      url: video['url'],
      teaserText: video['teaserText']?.trim(),
      ageRating: video['ageRating'] ?? 0,
      srcJson: !kReleaseMode ? json.encode(video) : null,
    );
  }

  @override
  String toString() {
    return 'VideoData($programId, $title)';
  }
}

class VideoCard extends StatefulWidget {
  final VideoData video;
  final CarouselListSize size;
  final bool withShortDescription;
  final bool useSubtitle;
  final bool withDurationLabel;

  const VideoCard({
    super.key,
    required this.video,
    required this.size,
    this.withShortDescription = false,
    this.useSubtitle = false,
    this.withDurationLabel = false,
  });

  @override
  State<VideoCard> createState() => VideoCardState();
}

class VideoCardState extends State<VideoCard> {
  late bool hasBeenPlayed;
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double imageHeight, imageWidth;
    switch (widget.size) {
      case CarouselListSize.normal:
        // image size divided by 1.5
        imageHeight = 148;
        imageWidth = 265;
        break;
      case CarouselListSize.small:
        // image size divided by 2
        imageHeight = 112;
        imageWidth = 200;
        break;
      case CarouselListSize.tiny:
        // image size divided by 2.5
        imageHeight = 90;
        imageWidth = 160;
        break;
    }

    Widget bottomText;
    const double padding = 8.0;
    if (widget.withShortDescription) {
      Color? color;
      if (Theme.of(context).brightness == Brightness.dark) {
        color = Colors.grey[400];
      } else {
        color = null;
      }
      bottomText = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: padding),
            Text(
                widget.useSubtitle && widget.video.subtitle != null
                    ? widget.video.subtitle!
                    : widget.video.title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: padding / 3),
            Text(
              widget.video.teaserText != null
                  ? widget.video.teaserText!.trim()
                  : '',
              maxLines: 3,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: color),
            ),
          ]);
    } else {
      bottomText = ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          widget.video.title,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: (widget.size == CarouselListSize.normal)
            ? Text(
                widget.video.subtitle ?? '',
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              )
            : null,
        isThreeLine: widget.size == CarouselListSize.normal,
      );
    }
    return Card(
        child: Container(
            padding: const EdgeInsets.all(padding),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(children: [
                    Image(
                      errorBuilder: (context, error, stackTrace) =>
                          SizedBox(width: imageWidth, height: imageHeight),
                      image: CachedNetworkImageProvider(
                          widget.video.imageUrl ?? '',
                          headers: {'User-Agent': AppConfig.userAgent}),
                      height: imageHeight,
                      width: imageWidth,
                    ),
                    if ((widget.withDurationLabel ||
                            widget.withShortDescription) &&
                        widget.video.durationLabel != null &&
                        !widget.video.isCollection)
                      Positioned(
                          bottom: 5,
                          left: 5,
                          child: Chip(
                            labelPadding: const EdgeInsets.only(
                                left: 0, right: 0, top: 0, bottom: 0),
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            label: Text(widget.video.durationLabel!,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface)),
                          )),
                    Consumer<AppData>(builder: (context, appData, child) {
                      isFavorite =
                          appData.favorites.contains(widget.video.programId);
                      return Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                              hoverColor: Theme.of(context).cardColor,
                              highlightColor: Theme.of(context).cardColor,
                              splashColor: Theme.of(context).cardColor,
                              onPressed: () {
                                setState(() {
                                  isFavorite = !isFavorite;
                                  //widget.video.isFavorite = isFavorite;
                                });

                                if (isFavorite) {
                                  appData.addFavorite(widget.video.programId);
                                } else {
                                  appData
                                      .removeFavorite(widget.video.programId);
                                }
                              },
                              icon: Icon(Icons.favorite,
                                  color: isFavorite
                                      ? Colors.deepOrange
                                      : Theme.of(context).disabledColor)));
                    }),
                    if (!widget.video.isCollection)
                      Consumer<AppData>(builder: (context, appData, child) {
                        hasBeenPlayed =
                            appData.watched.contains(widget.video.programId);
                        return Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                                hoverColor: Theme.of(context).cardColor,
                                highlightColor: Theme.of(context).cardColor,
                                splashColor: Theme.of(context).cardColor,
                                onPressed: () {
                                  setState(() {
                                    hasBeenPlayed = !hasBeenPlayed;
                                  });
                                  if (hasBeenPlayed) {
                                    appData.addWatched(widget.video.programId);
                                  } else {
                                    appData
                                        .removeWatched(widget.video.programId);
                                  }
                                },
                                icon: Icon(Icons.check_circle_outline,
                                    color: hasBeenPlayed
                                        ? Colors.deepOrange
                                        : Theme.of(context).disabledColor)));
                      }),
                  ]),
                  bottomText,
                ])));
  }
}

class AppData extends ChangeNotifier {
  List<String> watched = [];
  List<String> favorites = [];

  void addFavorite(String id) async {
    if (!favorites.contains(id)) {
      favorites.add(id);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorites', favorites);
      notifyListeners();
    }
  }

  void removeFavorite(String id) async {
    if (favorites.contains(id)) {
      favorites.remove(id);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorites', favorites);
      notifyListeners();
    }
  }

  void addWatched(String id) async {
    if (!watched.contains(id)) {
      watched.add(id);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('watched', watched);
      notifyListeners();
    }
  }

  void removeWatched(String id) async {
    if (watched.contains(id)) {
      watched.remove(id);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('watched', watched);
      notifyListeners();
    }
  }
}

class MediaStream {
  Map<String, Uri> audio;
  Map<String, Uri> subtitle;
  Map<String, Uri> resolution;
  int videoSize = 0;
  int audioSize = 0;
  MediaStream(
      {required this.audio,
      required this.subtitle,
      required this.resolution,
      this.videoSize = 0,
      this.audioSize = 0});

  static Future<MediaStream> getMediaPlaylist(String url) async {
    // get m3u8 playlist for each video, audio and subtitle stream
    Uri playlistUri = Uri.parse(url);
    final resp = await http.get(playlistUri);
    String contentString = utf8.decode(resp.bodyBytes);

    try {
      final playlist = await HlsPlaylistParser.create()
          .parseString(playlistUri, contentString);
      if (playlist is HlsMasterPlaylist) {
        Map<String, Uri> resolution = {};
        Map<String, Uri> audio = {};
        Map<String, Uri> subtitle = {};
        for (var v in playlist.variants) {
          resolution[
                  '${v.format.width}x${v.format.height}@${v.format.bitrate}'] =
              v.url;
        }
        if (playlist.audios.isNotEmpty) {
          for (var a in playlist.audios) {
            audio[a.name!.trim()] = a.url!;
          }
        }
        if (playlist.subtitles.isNotEmpty) {
          for (var s in playlist.subtitles) {
            subtitle[s.name!.trim()] = s.url!;
          }
        }
        return MediaStream(
            resolution: resolution, audio: audio, subtitle: subtitle);
      } else {
        // we expect a master paylist m3u8
        return Future.error(Exception('Expecting a master m3u8 playlist'));
      }
    } on ParserException catch (e) {
      return Future.error(e);
    }
  }

  static Future<(Uri?, Uri?, Uri?)> getMediaStream(
      Uri video, Uri? audio, Uri? subtitle) async {
    // get real stream for video, audio, subtitle

    Uri? videoStream, audioStream, subtitleUrl;
    int videoSize = 0, audioSize = 0;
    final resp = await http.get(video);
    String contentString = utf8.decode(resp.bodyBytes);

    try {
      final playlist =
          await HlsPlaylistParser.create().parseString(video, contentString);
      if (playlist is HlsMediaPlaylist) {
        final _ = playlist.baseUri!.split('/');
        _.removeLast();
        final baseUri = _.join('/');
        videoStream = Uri.parse('$baseUri/${playlist.segments[0].url!}');
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
    if (audio != null) {
      final resp = await http.get(audio);
      String contentString = utf8.decode(resp.bodyBytes);

      try {
        final playlist =
            await HlsPlaylistParser.create().parseString(audio, contentString);
        if (playlist is HlsMediaPlaylist) {
          final _ = playlist.baseUri!.split('/');
          _.removeLast();
          final baseUri = _.join('/');
          audioStream = Uri.parse('$baseUri/${playlist.segments[0].url!}');
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
      return Future.error(Exception('MediaStream audio Uri is null'));
    }
    if (subtitle != null) {
      final resp = await http.get(subtitle);
      String contentString = utf8.decode(resp.bodyBytes);

      try {
        final playlist = await HlsPlaylistParser.create()
            .parseString(subtitle, contentString);
        if (playlist is HlsMediaPlaylist) {
          final _ = playlist.baseUri!.split('/');
          _.removeLast();
          final baseUri = _.join('/');
          subtitleUrl = Uri.parse('$baseUri/${playlist.segments[0].url!}');
        }
      } on ParserException catch (e) {
        return Future.error(e);
      }
    }
    return (videoStream, audioStream, subtitleUrl);
  }
}
