import 'dart:convert';
import 'dart:math';

import 'package:flarte/helpers.dart';
import 'package:flarte/main.dart';
import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
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
      final url = widget.url;
      final resp = await cache.get(url, isJson: false);
      RegExp exp = RegExp(r'({\\\"page\\\":{\\\"code\\\":.*?}})],\\\"\$L');
      RegExpMatch? match = exp.firstMatch(resp['body']);
      final Map<String, dynamic> jd = json.decode(match![1]!
          .replaceAll('\\\\\\"', 'zzzzz')
          .replaceAll('\\"', '"')
          .replaceAll('zzzzz', '\\"'));
      data = jd['page'];
      final zones = data['zones'];
      //debugPrint(zones);
      for (var z in zones) {
        if (z['code'].startsWith('collection_videos') &&
            z['content']['data'] != null) {
          teasers.clear();
          teasers.addAll(z['content']['data']);
          break;
        }
        //debugPrint(teasers);
      }
      if (teasers.isEmpty) {
        // use the collection_subcollection_ instead
        Map<String, dynamic> jdNext;
        for (var z in zones) {
          if (z['code'].startsWith('collection_subcollection_')) {
            if (z['content']['data'] == null) {
              // get data for other seasons
              final url = "https://api.arte.tv${z['content']['esiInclude']}";
              final jd = await cache.get(url, isJson: true);
              z['content'] = jd;
              teasers.addAll(z['content']['data']);
            }
            jdNext = z['content'];
            // get any missing data if multiple page
            while (jdNext['pagination'] != null &&
                jdNext['pagination']['page'] < jdNext['pagination']['pages']) {
              jdNext = await cache.get(jdNext['pagination']['links']['next'],
                  isJson: true);
              z['content']['data'].addAll(jdNext['data']);
            }
            teasers.addAll(z['content']['data']);
          }
        }
        data['zones'] = zones;
      }
      setState(() {
        data;
        teasers;
      });
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
      for (var z in data['zones']) {
        if (z['content']['data'] != null && z['content']['data'].length > 1) {
          zoneCount++;
        }
      }
      final description = Text(widget.description,
          style: Theme.of(context).textTheme.titleMedium);
      if (zoneCount > 1) {
        body = Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          Container(
              margin: const EdgeInsets.only(
                  left: 20, top: 10, bottom: 10, right: 10),
              child: description),
          Expanded(
              flex: 2,
              child: Container(
                  margin: const EdgeInsets.all(10),
                  child: CarouselList(
                    data: Cache.parseJson(data),
                    size: CarouselListSize.normal,
                  )))
        ]);
      } else if (zoneCount > 0) {
        List<VideoData> videos =
            teasers.map((t) => VideoData.fromJson(t)).toList();
        body = Center(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ignore: sized_box_for_whitespace
          Container(
              margin: const EdgeInsets.all(10),
              width: width,
              child: description),
          // ignore: sized_box_for_whitespace
          Expanded(
              flex: 2,
              child: SizedBox(
                  width: width,
                  child: GridView.count(
                    childAspectRatio: 1.0,
                    crossAxisCount: count,
                    children: videos.map((v) {
                      return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          focusColor: Colors.deepOrange,
                          highlightColor: Colors.deepOrange,
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

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
        ),
        body: body);
  }
}
