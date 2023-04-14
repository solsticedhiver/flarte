import 'dart:convert';
import 'package:flarte/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:html/parser.dart' as parser;

class Cache extends ChangeNotifier {
  final Map<String, dynamic> data = {};
  //int index = 0;

  Future<List<dynamic>> _test_france_tv() async {
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
        debugPrint(imageUrl);
        videos.add({
          'title': title.trim(),
          'subtitle': subtitle.trim(),
          'imageUrl': imageUrl,
          'shortDescription': '',
          'isCollection': false,
          'label': '',
          'durationLabel': '',
          'url': ''
        });
      }
      result.add({'title': zoneTitle, 'videos': videos});
    }
    return result;
  }

  static Map<String, dynamic> buildVideo(Map<String, dynamic> video) {
    return {
      'programId': video['programId'],
      'title': video['title'],
      'subtitle': video['subtitle'],
      'imageUrl': (video['mainImage']['url'])
          .replaceFirst('__SIZE__', '400x225')
          .replaceFirst('?type=TEXT', ''),
      'shortDescription': video['shortDescription'],
      'isCollection': video['kind']['isCollection'],
      'label': video['kind']['label'],
      'durationLabel': video['durationLabel'],
      'url': video['url'],
    };
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
        'videos': videos.map((v) => buildVideo(v)).toList()
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
