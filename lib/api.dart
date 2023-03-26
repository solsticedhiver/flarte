import 'dart:convert';
import 'package:flarte/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const List<Map<String, dynamic>> categories = [
  {
    'text': 'Home',
    'color': [124, 124, 124],
    'code': 'HOME'
  },
  {
    'text': 'Documentaires et reportages',
    'color': [225, 143, 71],
    'code': 'DOR'
  },
  {
    'text': 'Séries et fictions',
    'color': [0, 230, 227],
    'code': 'SER',
  },
  {
    'text': 'Cinéma',
    'color': [254, 0, 0],
    'code': 'CIN',
  },
  {
    'text': 'Magazines et émissions',
    'color': [109, 255, 115],
    'code': 'EMI',
  },
  {
    'text': 'Histoire',
    'color': [254, 184, 0],
    'code': 'HIS',
  },
  {
    'text': 'Voyages et découvertes',
    'color': [0, 199, 122],
    'code': 'DEC',
  },
  {
    'text': 'Sciences',
    'color': [239, 1, 89],
    'code': 'SCI',
  },
  {
    'text': 'Info et société',
    'color': [1, 121, 218],
    'code': 'ACT',
  },
  {
    'text': 'Culture et pop',
    'color': [208, 73, 244],
    'code': 'CPO',
  }
];

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

  Future<void> fetch(String key) async {
    if (data[key].isNotEmpty) {
      return;
    }
    debugPrint(
        '${DateTime.now().toIso8601String().substring(11, 19)}: in Cache.fetch($key)');
    final String url =
        "https://www.arte.tv/api/rproxy/emac/v4/fr/web/pages/$key/";
    final http.Response resp = await http
        .get(Uri.parse(url), headers: {'User-Agent': AppConfig.userAgent});
    if (resp.statusCode == 200) {
      final jr = json.decode(resp.body);
      data[key] = jr;
      notifyListeners();
    }
  }

  dynamic get(String key) async {
    if (data[key].isEmpty) {
      await fetch(key);
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
