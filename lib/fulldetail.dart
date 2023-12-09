import 'package:cached_network_image/cached_network_image.dart';
import 'package:flarte/controls.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'helpers.dart';
import 'config.dart';
import 'serie.dart';

class FullDetailScreen extends StatefulWidget {
  final List<VideoData> videos;
  final String title;
  final int index;
  const FullDetailScreen({
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

    //debugPrint('in _FullDetailScreeState.initState()');

    Future.microtask(() async {
      final lang = Provider.of<LocaleModel>(context, listen: false)
          .getCurrentLocale(context)
          .languageCode;
      final cache = Provider.of<Cache>(context, listen: false);
      Map<String, dynamic> jr;
      final url =
          'https://www.arte.tv/api/rproxy/emac/v4/$lang/web/programs/${video.programId}';
      jr = await cache.get(url);
      if (mounted && jr.isNotEmpty) {
        setState(() {
          final imageUrl = data['mainImage']['url'];
          final title = data['title'];
          final subtitle = data['subtitle'];
          data = jr['value']['zones'][0]['content']['data'][0];
          // keep the old url to avoid redownloading the same image at a new url
          data['mainImage']['url'] = imageUrl;
          data['title'] = title;
          data['subtitle'] = subtitle;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //debugPrint(video.srcJson!.replaceAll("'", "\\'"));
    //debugPrint(data.toString());
    if (data.isEmpty) {
      data = {
        'programId': video.programId,
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
    // make sure that <br> breakline become carriage return \n
    description = description.replaceAllMapped(
        RegExp(r'<br ?/?>([^\n])'), (match) => '\n${match.group(1)}');
    description = Bidi.stripHtmlIfNeeded(description.trim());
    // remove leading space on each line
    description = description
        .replaceAll(RegExp('^[ \u{00a0}]+', multiLine: true, unicode: true), '')
        .replaceAll(RegExp('[ \u{00a0}]+'), ' ')
        .replaceAll(RegExp('\n{2,}', multiLine: true), '\n\n');
    shortDescription = Bidi.stripHtmlIfNeeded(shortDescription).trim();

    final imageUrl =
        '${data['mainImage']['url'].replaceFirst('__SIZE__', '300x450')}?type=TEXT';
    bool showImage = MediaQuery.sizeOf(context).width > 1280;
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
    for (var c in data['credits'] ?? []) {
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
    String appBarTitle;
    if (widget.title.isNotEmpty) {
      appBarTitle =
          '${widget.title} (${widget.index + 1}/${widget.videos.length})';
    } else {
      appBarTitle = AppLocalizations.of(context)!.strDetails;
    }

    String viewable = '';
    switch (data['ageRating']) {
      case 16:
        viewable = '22h - 6h';
        break;
      case 18:
        viewable = '23h - 6h';
        break;
    }

    return Scaffold(
        appBar: AppBar(
            title: Text(appBarTitle),
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white),
        body: Stack(children: [
          Container(
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
                                headers: {'User-Agent': AppConfig.userAgent}),
                            fit: BoxFit.fitWidth,
                          )))),
                    Expanded(
                        flex: 2,
                        child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(data['title'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge),
                                  if (data['subtitle'] != null &&
                                      data['subtitle'].isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    Text(data['subtitle'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall),
                                  ],
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    Chip(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .inverseSurface,
                                      label: Text(data['kind']['label'],
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onInverseSurface)),
                                    ),
                                    const SizedBox(width: 10),
                                    if (!data['kind']['isCollection'] &&
                                        data['durationLabel'] != null)
                                      Chip(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .inverseSurface,
                                        label: Text(data['durationLabel'],
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onInverseSurface)),
                                      ),
                                    Consumer<AppData>(
                                        builder: (context, appData, child) {
                                      if (appData.favorites
                                          .contains(video.programId)) {
                                        return Container(
                                            padding:
                                                const EdgeInsets.only(left: 10),
                                            child: const Icon(Icons.favorite));
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    }),
                                    Consumer<AppData>(
                                        builder: (context, appData, child) {
                                      if (appData.watched
                                          .contains(video.programId)) {
                                        return Container(
                                            padding:
                                                const EdgeInsets.only(left: 10),
                                            child: const Icon(
                                                Icons.check_circle_outline));
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
                                                    builder: (context) => SerieScreen(
                                                        title: video.title,
                                                        url: video.url,
                                                        description: video
                                                                .shortDescription ??
                                                            video.subtitle ??
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .strEpisodes)));
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
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall!
                                              .copyWith(
                                                  fontSize: 17.5,
                                                  letterSpacing: 0.5))
                                    ],
                                    const SizedBox(height: 10),
                                    Text(description,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                                height: 1.35,
                                                letterSpacing: 0.5))
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
                                  flex: 1, child: Text('${data['programId']}'))
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
                                    child: Text(AppLocalizations.of(context)!
                                        .strFirstBroadcastDate)),
                                Expanded(
                                    flex: 1, child: Text(firstBroadcastDate))
                              ])
                            ],
                            if (availabilityStart.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(children: [
                                Expanded(
                                    flex: 1,
                                    child: Text(AppLocalizations.of(context)!
                                        .strAvailability)),
                                Expanded(
                                    flex: 1,
                                    child: Text(
                                        '${AppLocalizations.of(context)!.strFrom} $availabilityStart\n${AppLocalizations.of(context)!.strTo} $availabilityEnd'))
                              ])
                            ],
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(
                                  flex: 1,
                                  child: Text(AppLocalizations.of(context)!
                                      .strAgeRating)),
                              Expanded(
                                  flex: 1,
                                  child: Text(data['ageRating'] == 0
                                      ? '⸺'
                                      : '${data['ageRating']}'))
                            ]),
                            if (data['ageRating'] != 0) ...[
                              const SizedBox(height: 10),
                              Row(children: [
                                Expanded(
                                    flex: 1,
                                    child: Text(AppLocalizations.of(context)!
                                        .strViewable)),
                                Expanded(flex: 1, child: Text(viewable))
                              ]),
                            ],
                            const SizedBox(height: 10),
                            if (data['genre'] != null)
                              Row(children: [
                                Expanded(
                                    flex: 1,
                                    child: Text(AppLocalizations.of(context)!
                                        .strGenre)),
                                Expanded(
                                    flex: 1,
                                    child: Text('${data['genre']['label']}'))
                              ]),
                            if (data['geoblocking'] != null) ...[
                              const SizedBox(height: 10),
                              Row(children: [
                                const Expanded(
                                    flex: 1, child: Text('GeoBlocking')),
                                Expanded(
                                    flex: 1,
                                    child:
                                        Text('${data['geoblocking']['code']}'))
                              ])
                            ],
                            const SizedBox(height: 10),
                            ...credits,
                          ],
                        )))),
                  ]))),
          Builder(builder: (context) {
            return Positioned(
                left: 10,
                top: (MediaQuery.sizeOf(context).height -
                        Scaffold.of(context).appBarMaxHeight!) /
                    2,
                child: ElevatedButton(
                  onPressed: widget.index == 0
                      ? null
                      : () {
                          final wi = widget.index - 1;
                          if (wi >= 0) {
                            Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (context) => FullDetailScreen(
                                        videos: widget.videos,
                                        index: wi,
                                        title: widget.title)));
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(0, 0, 0, 0),
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
                top: (MediaQuery.sizeOf(context).height -
                        Scaffold.of(context).appBarMaxHeight!) /
                    2,
                child: ElevatedButton(
                  onPressed: widget.index == widget.videos.length - 1
                      ? null
                      : () {
                          final wi = widget.index + 1;
                          if (wi < widget.videos.length) {
                            Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (context) => FullDetailScreen(
                                        videos: widget.videos,
                                        index: wi,
                                        title: widget.title)));
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(0, 0, 0, 0),
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
