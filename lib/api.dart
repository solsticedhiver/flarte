import 'dart:convert';
import 'package:flarte/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Cache extends ChangeNotifier {
  final Map<String, dynamic> data = {
    'HOME': {},
    'DOR': {},
    'SER': {},
    'CIN': {},
    'EMI': {},
    'HIS': {},
    'DEC': {},
    'SCI': {},
    'ACT': {},
    'CPO': {}
  };
  //int index = 0;

  Future<void> fetch(String key, String lang) async {
    if (data[key].isNotEmpty) {
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
      data[key] = jr;
      notifyListeners();
    }
  }

  dynamic get(String key, String lang) async {
    if (data[key].isEmpty) {
      await fetch(key, lang);
    }
    return data[key];
  }

  void set(String key, Map<dynamic, dynamic> dict) {
    data[key] = dict;
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
