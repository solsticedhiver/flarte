import 'dart:convert';
import 'dart:math';

import 'package:flarte/helpers.dart';
import 'package:flarte/main.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as parser;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'detail.dart';
import 'fulldetail.dart';

class SerieScreen extends StatefulWidget {
  final String title;
  final String url;
  final String description;
  const SerieScreen(
      {super.key,
      required this.title,
      required this.url,
      required this.description});

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
      final cache = Provider.of<Cache>(context, listen: false);
      final url = 'https://www.arte.tv${widget.url}';
      final resp = await cache.get(url, isJson: false);
      final document = parser.parse(resp['body']);
      final script = document.querySelector('script#__NEXT_DATA__');
      if (script != null) {
        final Map<String, dynamic> jd = json.decode(script.text);
        setState(() {
          data = jd['props']['pageProps']['props']['page'];
        });
        final zones = data['value']['zones'];
        //debugPrint(zones);
        for (var z in zones) {
          if (z['code'].startsWith('collection_videos')) {
            setState(() {
              teasers.clear();
              teasers.addAll(z['content']['data']);
            });
            break;
          }
          //debugPrint(teasers);
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

  void _showDialogProgram(
      BuildContext context, List<VideoData> videos, int index) {
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
              elevation: 8.0,
              child: SizedBox(
                  width: min(MediaQuery.sizeOf(context).width - 100, 600),
                  child: ShowDetail(videos: videos, index: index)));
        });
  }

  @override
  Widget build(BuildContext context) {
    int count = MediaQuery.sizeOf(context).width ~/ 285;
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
      final description = Text(widget.description,
          style: Theme.of(context).textTheme.titleMedium);
      if (zoneCount > 1) {
        body = Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          Container(margin: const EdgeInsets.all(10), child: description),
          Expanded(
              flex: 2,
              child: CarouselList(
                data: Cache.parseJson(data),
                size: CarouselListSize.normal,
              ))
        ]);
      } else if (zoneCount > 0) {
        List<VideoData> videos =
            teasers.map((t) => VideoData.fromJson(t)).toList();
        body = Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
              // ignore: sized_box_for_whitespace
              Container(
                  width: width,
                  margin: const EdgeInsets.all(10),
                  child: description),
              // ignore: sized_box_for_whitespace
              Expanded(
                  flex: 2,
                  child: SizedBox(
                      width: width,
                      height: MediaQuery.sizeOf(context).height -
                          (50 + 10 * 2 + 56),
                      child: GridView.count(
                        childAspectRatio: 1.0,
                        crossAxisCount: count,
                        children: videos.map((v) {
                          return InkWell(
                              onLongPress: () {
                                _showDialogProgram(
                                    context, videos, videos.indexOf(v));
                              },
                              onDoubleTap: () {
                                _showDialogProgram(
                                    context, videos, videos.indexOf(v));
                              },
                              onTap: () {
                                //_showDialogProgram(context, Video.fromJson(t));
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => FullDetailScreen(
                                              videos: videos,
                                              index: videos.indexOf(v),
                                              title: widget.title,
                                            )));
                              },
                              child: VideoCard(
                                  video: v,
                                  size: CarouselListSize.normal,
                                  useSubtitle: useSubtitle,
                                  withShortDescription: true));
                        }).toList(),
                      )))
            ]));
      } else {
        body = Center(child: Text(AppLocalizations.of(context)!.strNoResults));
      }
    } else {
      body = Center(child: Text(AppLocalizations.of(context)!.strFetching));
    }

    return Scaffold(appBar: AppBar(title: Text(widget.title)), body: body);
  }
}
