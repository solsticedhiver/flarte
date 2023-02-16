import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchHome() async {
  const String url =
      "https://www.arte.tv/api/rproxy/emac/v4/fr/web/pages/HOME/";

  debugPrint(
      '${DateTime.now().toIso8601String().substring(11, 19)}: in fetchHome()');
  final http.Response resp = await http.get(Uri.parse(url));
  if (resp.statusCode != 200) {
    return {};
  }
  final jr = json.decode(resp.body);
  return jr;
}
