import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flarte/config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:html/parser.dart' as parser;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Cache extends ChangeNotifier {
  final Map<String, dynamic> data = {};
  //int index = 0;

  Future<List<dynamic>> _testFranceTv() async {
    List<dynamic> result = [];
    final resp = await http.get(Uri.parse('https://www.france.tv'));
    if (resp.statusCode != 200) {
      return result;
    }
    final document = parser.parse(resp.body);
    final sliders = document.getElementsByClassName('c-section-slider');
    for (var s in sliders) {
      final zoneTitle =
          s.getElementsByClassName('c-headlines--title-2')[0].innerHtml;
      List<dynamic> videos = [];
      for (var i in s.getElementsByClassName('c-slider__item')) {
        final t = i.getElementsByClassName('c-card-poster__cached-title');
        String title = '';
        if (t.isNotEmpty) title = t[0].innerHtml;
        final desc =
            i.getElementsByClassName('c-card-poster__cached-description');
        String subtitle = '';
        if (desc.isNotEmpty) subtitle = desc[0].innerHtml;
        String? imageUrl = '';
        final image = i.querySelector('span.c-card-poster__image-wrapper img');
        if (image != null) imageUrl = image.attributes['data-src'];
        videos.add(VideoData(
            programId: 'unknown',
            title: title.trim(),
            subtitle: subtitle.trim(),
            imageUrl: imageUrl,
            shortDescription: '',
            isCollection: false,
            label: '',
            durationLabel: '',
            url: ''));
      }
      result.add({'title': zoneTitle, 'videos': videos});
    }
    return result;
  }

  static List<dynamic> parseJson(Map<String, dynamic> data) {
    List<dynamic> result = [];
    final List<dynamic> zones = data['value']['zones'];
    for (var z in zones) {
      List<dynamic> videos = z['content']['data'];
      final programId = videos.where((v) => v['programId'] != null).toList();
      if (videos.isEmpty ||
          z['displayOptions']['template'].startsWith('event') ||
          z['displayOptions']['template'].startsWith('single') ||
          programId.isEmpty ||
          videos.length == 1) {
        continue;
      }
      result.add({
        'title': z['title'],
        'videos': videos.map((v) => VideoData.fromJson(v)).toList()
      });
    }
    return result;
  }

  Future<void> fetch(String key, String lang) async {
    final cacheKey = '$key-$lang';
    if (data.keys.contains(cacheKey) && data[cacheKey].isNotEmpty) {
      return;
    }
    /*
    if (key == 'HOME') {
      data[cacheKey] = await _test_france_tv();
      notifyListeners();
      return;
    }
    */
    debugPrint(
        '${DateTime.now().toIso8601String().substring(11, 19)}: in Cache.fetch($key, $lang)');

    final String url =
        "https://www.arte.tv/api/rproxy/emac/v4/$lang/web/pages/$key/";
    final http.Response resp = await http
        .get(Uri.parse(url), headers: {'User-Agent': AppConfig.userAgent});
    if (resp.statusCode == 200) {
      final jr = json.decode(resp.body);
      data[cacheKey] = parseJson(jr);
      notifyListeners();
    }
  }

  Future<List<dynamic>> get(String key, String lang) async {
    final cacheKey = '$key-$lang';
    if (!data.keys.contains(cacheKey) || !data[cacheKey].isEmpty) {
      await fetch(key, lang);
    }
    return data[cacheKey];
  }

  void set(String key, String lang, Map<dynamic, dynamic> dict) {
    final cacheKey = '$key-$lang';
    data[cacheKey] = dict;
    notifyListeners();
  }
}

enum CategoriesListSize { tiny, small, normal }

enum CarouselListSize { tiny, small, normal }

enum PlayerTypeName { embedded, vlc, custom }

class Version {
  String shortLabel;
  String label;
  String url;
  Version({required this.shortLabel, required this.label, required this.url});

  @override
  String toString() {
    return 'Version($shortLabel, $label)';
  }
}

class Format {
  String resolution;
  String bandwidth; // used with media_kit/libmpv player
  Format({required this.resolution, required this.bandwidth});

  @override
  String toString() {
    return 'Format($resolution, $bandwidth)';
  }
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
    this.srcJson,
    this.versions,
    this.teaserText,
  });

  factory VideoData.fromJson(Map<String, dynamic> video) {
    return VideoData(
      programId: video['programId'],
      title: video['title'],
      subtitle: video['subtitle'],
      imageUrl: (video['mainImage']['url'])
          .replaceFirst('__SIZE__', '400x225')
          .replaceFirst('?type=TEXT', ''),
      shortDescription: video['shortDescription'],
      isCollection: video['kind']['isCollection'],
      label: video['kind']['label'],
      durationLabel: video['durationLabel'],
      url: video['url'],
      teaserText: video['teaserText'],
      srcJson: !kReleaseMode ? json.encode(video) : null,
    );
  }
}

class VideoCard extends StatefulWidget {
  final VideoData video;
  final CarouselListSize size;
  final bool withShortDescription;
  final bool useSubtitle;

  const VideoCard({
    super.key,
    required this.video,
    required this.size,
    this.withShortDescription = false,
    this.useSubtitle = false,
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
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: padding / 3),
            Text(
              widget.video.teaserText.toString().trim(),
              maxLines: 3,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: color),
            ),
            const SizedBox(height: padding),
            if (widget.video.durationLabel != null)
              Chip(
                backgroundColor: Theme.of(context).primaryColor,
                label: Text(widget.video.durationLabel!),
              ),
          ]);
    } else {
      bottomText = ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          widget.video.title,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
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
