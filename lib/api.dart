import 'dart:convert';
import 'package:flarte/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Cache extends ChangeNotifier {
  final Map<String, dynamic> data = {};
  //int index = 0;

  Future<void> fetch(String key, String lang) async {
    final cacheKey = '$key-$lang';
    if (data.keys.contains(cacheKey) && data[cacheKey].isNotEmpty) {
      return;
    }
    debugPrint(
        '${DateTime.now().toIso8601String().substring(11, 19)}: in Cache.fetch($key)');

    final String url =
        "https://www.arte.tv/api/rproxy/emac/v4/$lang/web/pages/$key/";
    final http.Response resp = await http
        .get(Uri.parse(url), headers: {'User-Agent': AppConfig.userAgent});
    if (resp.statusCode == 200) {
      final jr = json.decode(resp.body);
      data[cacheKey] = jr;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> get(String key, String lang) async {
    final cacheKey = '$key-$lang';
    debugPrint(cacheKey);
    if (!data.keys.contains(cacheKey) || !data[cacheKey].isEmpty) {
      await fetch(key, lang);
    }
    return data[cacheKey];
  }

  void set(String key, String lang, Map<dynamic, dynamic> dict) {
    final cacheKey = '$key-$lang';
    data[cacheKey] = dict;
    //index = data.keys.toList().indexOf(key);
    notifyListeners();
  }
}

enum CategoriesListSize { tiny, small, normal }

enum CarouselListSize { tiny, small, normal }

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

  void changeLocale(Locale? l) {
    if (AppLocalizations.supportedLocales.contains(l)) {
      _locale = l;
      notifyListeners();
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
