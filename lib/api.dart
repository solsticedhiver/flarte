import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String urlHOME =
    "https://www.arte.tv/api/rproxy/emac/v4/fr/web/pages/HOME/";

Future<Map<String, dynamic>> fetchUrl(String url) async {
  debugPrint(
      '${DateTime.now().toIso8601String().substring(11, 19)}: in fetchUrl()');
  final http.Response resp = await http.get(Uri.parse(url));
  if (resp.statusCode != 200) {
    return {};
  }
  final jr = json.decode(resp.body);
  return jr;
}

const List<Map<String, dynamic>> categories = [
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
    'HOM': {},
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

  void set(String key, Map<dynamic, dynamic> dict) {
    data[key] = dict;
    //index = data.keys.toList().indexOf(key);
    notifyListeners();
  }
}
