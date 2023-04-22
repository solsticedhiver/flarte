import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flarte/controls.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'helpers.dart';
import 'config.dart';
import 'serie.dart';

class FullDetailScreen extends StatefulWidget {
  final List<VideoData> videos;
  final String title;
  int index;
  FullDetailScreen({
    super.key,
    required this.videos,
    required this.title,
    required this.index,
  });

  @override
  State<FullDetailScreen> createState() => _FullDetailScreenState();
}

class _FullDetailScreenState extends State<FullDetailScreen> {
  Map<String, dynamic> data = {};
  late VideoData video = widget.videos[widget.index];

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final lang = Provider.of<LocaleModel>(context, listen: false)
          .getCurrentLocale(context)
          .languageCode;
      final url =
          'https://www.arte.tv/api/rproxy/emac/v4/$lang/web/programs/${video.programId}';
      final Dio dio = Dio();
      dio.interceptors.add(
          DioCacheManager(CacheConfig(defaultMaxAge: const Duration(hours: 1)))
              .interceptor);
      final resp = await dio.get(url,
          options: Options(headers: {'User-Agent': AppConfig.userAgent}));
      final Map<String, dynamic> jr = resp.data;
      setState(() {
        data = jr['value']['zones'][0]['content']['data'][0];
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _removeTag(String? text) {
    if (text == null) {
      return '';
    }
    return text
        .replaceAll('<p>', '')
        .replaceAll('</p>', '\n')
        .replaceAll(RegExp('<br ?/?>'), '\n')
        .replaceAll(RegExp('\n{2,}'), '\n\n')
        .replaceFirst(RegExp(r'\n$'), '')
        .replaceAll(RegExp('</?strong>'), '')
        .replaceAll(RegExp('</?b>'), '')
        .replaceAll(RegExp('</?em>'), '');
  }

  @override
  Widget build(BuildContext context) {
    //debugPrint(json.encode(data).toString());
    if (data.isEmpty) {
      data = {
        'title': video.title,
        'subtitle': video.subtitle,
        'mainImage': {
          'url': video.imageUrl!.replaceFirst('400x225', '300x450')
        },
        'fullDescription': '',
        'shortDescription': video.shortDescription,
        'availability': null,
        'firstBroadcastDate': null,
        'credits': [],
        'durationLabel': video.durationLabel,
        'kind': {'isCollection': video.isCollection, 'label': video.label},
      };
    }
    String description = data['fullDescription'] ?? '';
    String shortDescription = data['shortDescription'] ?? '';
    if (description.isEmpty) {
      description = shortDescription;
      shortDescription = '';
    }
    description = description.trim();
    if (!description.startsWith('<p>')) {
      description = '<p>$description</p>';
    }
    shortDescription = _removeTag(shortDescription).trim();
    final imageUrl =
        '${data['mainImage']['url'].replaceFirst('__SIZE__', '300x450')}?type=TEXT';
    bool showImage = MediaQuery.of(context).size.width > 1280;
    Locale locale = Provider.of<LocaleModel>(context, listen: false)
        .getCurrentLocale(context);
    DateFormat dateFormat = DateFormat.yMd(locale.toString());
    String availabilityStart = '';
    String availabilityEnd = '';
    if (data['availability'] != null) {
      availabilityStart = dateFormat
          .format(DateTime.parse(data['availability']['start']).toLocal());
      availabilityEnd = dateFormat
          .format(DateTime.parse(data['availability']['end']).toLocal());
    }
    String firstBroadcastDate = '';
    if (data['firstBroadcastDate'] != null) {
      firstBroadcastDate = dateFormat
          .format(DateTime.parse(data['firstBroadcastDate']).toLocal());
    }
    List<Widget> credits = [];
    for (var c in data['credits']) {
      credits.addAll(
        [
          const SizedBox(height: 10),
          Row(children: [
            Expanded(flex: 1, child: Text(c['label'])),
            Expanded(flex: 1, child: Text('${(c['values']).join('\n')}'))
          ])
        ],
      );
    }
    //debugPrint(json.encode(data).toString());
    String? swipeDirection;
    String appBarTitle;
    if (widget.title.isNotEmpty) {
      appBarTitle =
          '${AppLocalizations.of(context)!.strDetails} / ${widget.title} (${widget.index + 1}/${widget.videos.length})';
    } else {
      appBarTitle = AppLocalizations.of(context)!.strDetails;
    }

    return Scaffold(
        appBar: AppBar(title: Text(appBarTitle)),
        body: Stack(children: [
          GestureDetector(
              supportedDevices: const {
                PointerDeviceKind.stylus,
                PointerDeviceKind.touch,
                PointerDeviceKind.trackpad
              },
              onPanUpdate: (details) {
                swipeDirection = details.delta.dx > 0 ? 'left' : 'right';
              },
              onPanEnd: (details) {
                int index = widget.index, wi;
                if (swipeDirection == null) {
                  return;
                } else if (swipeDirection == 'left') {
                  wi = widget.index - 1;
                  if (wi >= 0) {
                    index = wi;
                  }
                } else if (swipeDirection == 'right') {
                  wi = widget.index + 1;
                  if (wi < widget.videos.length) {
                    index = wi;
                  }
                }
                if (index != widget.index) {
                  widget.index = index;
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => FullDetailScreen(
                          videos: widget.videos,
                          index: widget.index,
                          title: widget.title)));
                }
              },
              child: Container(
                  padding: const EdgeInsets.all(15),
                  child: Center(
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                        if (showImage)
                          Expanded(
                              flex: 1,
                              child: Center(
                                  child: SizedBox.expand(
                                      child: Image(
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                                image: CachedNetworkImageProvider(imageUrl,
                                    headers: {
                                      'User-Agent': AppConfig.userAgent
                                    }),
                                fit: BoxFit.fitWidth,
                              )))),
                        Expanded(
                            flex: 2,
                            child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(data['title'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineLarge),
                                      const SizedBox(height: 10),
                                      Row(children: [
                                        Chip(
                                          backgroundColor:
                                              Theme.of(context).primaryColor,
                                          label: Text(data['kind']['label']),
                                        ),
                                        const SizedBox(width: 10),
                                        if (!data['kind']['isCollection'] &&
                                            data['durationLabel'] != null)
                                          Chip(
                                            backgroundColor:
                                                Theme.of(context).primaryColor,
                                            label: Text(data['durationLabel']),
                                          ),
                                        Consumer<AppData>(
                                            builder: (context, appData, child) {
                                          if (appData.favorites
                                              .contains(video.programId)) {
                                            return Container(
                                                padding: const EdgeInsets.only(
                                                    left: 10),
                                                child:
                                                    const Icon(Icons.favorite));
                                          } else {
                                            return const SizedBox.shrink();
                                          }
                                        }),
                                        Consumer<AppData>(
                                            builder: (context, appData, child) {
                                          if (appData.watched
                                              .contains(video.programId)) {
                                            return Container(
                                                padding: const EdgeInsets.only(
                                                    left: 10),
                                                child: const Icon(Icons
                                                    .check_circle_outline));
                                          } else {
                                            return const SizedBox.shrink();
                                          }
                                        }),
                                      ]),
                                      const SizedBox(height: 10),
                                      !video.isCollection
                                          ? VideoButtons(
                                              videos: widget.videos,
                                              index: widget.index,
                                              oneLine: true,
                                              withFullDetailButton: false)
                                          : TextButton(
                                              onPressed: () {
                                                //Navigator.pop(context);
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            SerieScreen(
                                                                title:
                                                                    video.title,
                                                                url: video
                                                                    .url)));
                                              },
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .strEpisodes),
                                            ),
                                      Flexible(
                                          child: SingleChildScrollView(
                                              child: Column(children: [
                                        if (data['subtile'] != null) ...[
                                          const SizedBox(height: 10),
                                          Text(data['subtitle'],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineMedium)
                                        ],
                                        if (shortDescription.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Text(shortDescription,
                                              textAlign: TextAlign.justify,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge)
                                        ],
                                        Html(
                                            data: description,
                                            tagsList: Html.tags,
                                            style: {
                                              'p': Style(
                                                  letterSpacing: 1.0,
                                                  fontWeight: FontWeight.w400,
                                                  textAlign: TextAlign.justify,
                                                  wordSpacing: 1.0,
                                                  fontSize: FontSize.medium),
                                              'strong': Style(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: FontSize.larger),
                                            })
                                      ]))),
                                    ]))),
                        Expanded(
                            flex: 1,
                            child: Center(
                                child: SingleChildScrollView(
                                    child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(children: [
                                  const Expanded(flex: 1, child: Text('ID')),
                                  Expanded(
                                      flex: 1,
                                      child: Text('${data['programId']}'))
                                ]),
                                const SizedBox(height: 10),
                                Row(children: [
                                  Expanded(
                                      flex: 1,
                                      child: Text(AppLocalizations.of(context)!
                                          .strDuration)),
                                  Expanded(
                                      flex: 1,
                                      child: Text('${data['durationLabel']}'))
                                ]),
                                if (firstBroadcastDate.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    Expanded(
                                        flex: 1,
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .strFirstBroadcastDate)),
                                    Expanded(
                                        flex: 1,
                                        child: Text(firstBroadcastDate))
                                  ])
                                ],
                                if (availabilityStart.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    Expanded(
                                        flex: 1,
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .strAvailability)),
                                    Expanded(
                                        flex: 1,
                                        child: Text(
                                            '${AppLocalizations.of(context)!.strFrom} $availabilityStart\n${AppLocalizations.of(context)!.strTo} $availabilityEnd'))
                                  ])
                                ],
                                const SizedBox(height: 10),
                                if (data['genre'] != null)
                                  Row(children: [
                                    Expanded(
                                        flex: 1,
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .strGenre)),
                                    Expanded(
                                        flex: 1,
                                        child:
                                            Text('${data['genre']['label']}'))
                                  ]),
                                if (data['geoblocking'] != null) ...[
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    const Expanded(
                                        flex: 1, child: Text('GeoBlocking')),
                                    Expanded(
                                        flex: 1,
                                        child: Text(
                                            '${data['geoblocking']['code']}'))
                                  ])
                                ],
                                const SizedBox(height: 10),
                                ...credits,
                              ],
                            )))),
                      ])))),
          Builder(builder: (context) {
            return Positioned(
                left: 10,
                top: (MediaQuery.of(context).size.height -
                        Scaffold.of(context).appBarMaxHeight!) /
                    2,
                child: ElevatedButton(
                  onPressed: widget.index == 0
                      ? null
                      : () {
                          final wi = widget.index - 1;
                          if (wi >= 0) {
                            widget.index = wi;
                          }

                          Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (context) => FullDetailScreen(
                                      videos: widget.videos,
                                      index: widget.index,
                                      title: widget.title)));
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onSecondary,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: Icon(
                    Icons.keyboard_double_arrow_left,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ));
          }),
          Builder(builder: (context) {
            return Positioned(
                right: 10,
                top: (MediaQuery.of(context).size.height -
                        Scaffold.of(context).appBarMaxHeight!) /
                    2,
                child: ElevatedButton(
                  onPressed: widget.index == widget.videos.length - 1
                      ? null
                      : () {
                          final wi = widget.index + 1;
                          if (wi < widget.videos.length) {
                            widget.index = wi;
                          }

                          Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (context) => FullDetailScreen(
                                      videos: widget.videos,
                                      index: widget.index,
                                      title: widget.title)));
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onSecondary,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: Icon(
                    Icons.keyboard_double_arrow_right,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ));
          }),
        ]));
  }
}
