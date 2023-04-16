import 'dart:convert';
import 'dart:math';

import 'package:flarte/helpers.dart';
import 'package:flarte/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'detail.dart';

class SerieScreen extends StatefulWidget {
  final String title;
  final String url;
  const SerieScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<SerieScreen> createState() => _SerieScreenState();
}

class _SerieScreenState extends State<SerieScreen> {
  Map<String, dynamic> data = {};
  List<dynamic> teasers = [];

  // TODO: this is a mess, reorganize
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final resp =
          await http.get(Uri.parse('https://www.arte.tv${widget.url}'));
      final document = parser.parse(resp.body);
      final script = document.querySelector('script#__NEXT_DATA__');
      if (script != null) {
        final Map<String, dynamic> jd = json.decode(script.text);
        setState(() {
          data = jd['props']['pageProps']['props']['page'];
        });
        final zones = data['value']['zones'];
        //debugPrint(json.encode(zones));
        for (var z in zones) {
          if (z['code'].startsWith('collection_videos')) {
            setState(() {
              teasers.clear();
              teasers.addAll(z['content']['data']);
            });
            break;
          }
          //debugPrint(json.encode(teasers));
        }
        if (teasers.isEmpty) {
          // use the collection_subcollection instead
          for (var z in zones) {
            if (z['code'].startsWith('collection_subcollection_')) {
              setState(() {
                teasers.addAll(z['content']['data']);
              });
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showDialogProgram(BuildContext context, VideoData v) {
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
              elevation: 8.0,
              child: SizedBox(
                  width: min(MediaQuery.of(context).size.width - 100, 600),
                  child: ShowDetail(
                    video: v,
                  )));
        });
  }

  @override
  Widget build(BuildContext context) {
    int count = MediaQuery.of(context).size.width ~/ 285;
    double width = 285.0 * count;
    final titles = teasers.map((t) => t['title']).toList();
    // use the subtitle if all titles are the same
    bool useSubtitle =
        teasers.length == titles.where((t) => t == titles[0]).length;
    Widget body;
    if (data.isNotEmpty) {
      int zoneCount = 0;
      for (var z in data['value']['zones']) {
        if (z['content']['data'].length > 1) {
          zoneCount++;
        }
      }
      if (zoneCount > 1) {
        body = CarouselList(
          data: Cache.parseJson(data),
          size: CarouselListSize.normal,
        );
      } else {
        body = Center(
            child: Container(
                width: width,
                child: GridView.count(
                  childAspectRatio: 0.85,
                  crossAxisCount: count,
                  children: teasers.map((t) {
                    VideoData v = VideoData.fromJson(t);
                    return InkWell(
                        onTap: () {
                          _showDialogProgram(context, v);
                        },
                        child: VideoCard(
                            video: v,
                            size: CarouselListSize.normal,
                            useSubtitle: useSubtitle,
                            withShortDescription: true));
                  }).toList(),
                )));
      }
    } else {
      body = Center(child: Text(AppLocalizations.of(context)!.strFetching));
    }

    return Scaffold(appBar: AppBar(title: Text(widget.title)), body: body);
  }
}
