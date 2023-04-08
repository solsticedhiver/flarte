import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'api.dart';
import 'config.dart';

class FullDetailScreen extends StatefulWidget {
  final String programId;
  const FullDetailScreen({
    super.key,
    required this.programId,
  });

  @override
  State<FullDetailScreen> createState() => _FullDetailScreenState();
}

class _FullDetailScreenState extends State<FullDetailScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<Map<String, dynamic>> _getProgramDetail(
      String programId, BuildContext context) async {
    final lang = Provider.of<LocaleModel>(context, listen: false)
        .getCurrentLocale(context)
        .languageCode;
    final url =
        'https://www.arte.tv/api/rproxy/emac/v4/$lang/web/programs/$programId';
    final resp = await http
        .get(Uri.parse(url), headers: {'User-Agent': AppConfig.userAgent});
    final Map<String, dynamic> jr = json.decode(resp.body);
    return jr;
  }

  String _removeTag(String? text) {
    if (text == null) {
      return '';
    }
    return text
        .replaceAll('<p>', '')
        .replaceAll('</p>', '\n')
        .replaceAll('<br>', '\n')
        .replaceAll('<br />', '\n')
        .replaceAll(RegExp('\n{2,}'), '\n\n')
        .replaceFirst(RegExp(r'\n$'), '')
        .replaceAll('<strong>', '')
        .replaceAll('</strong>', '')
        .replaceAll('<em>', '')
        .replaceAll('</em>', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.strDetails)),
      body: FutureBuilder(
        future: _getProgramDetail(widget.programId, context),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            final content =
                snapshot.data?['value']['zones'][0]['content']['data'][0];
            //debugPrint(json.encode(content).toString());
            String description = content['fullDescription'] ?? '';
            String shortDescription = content['shortDescription'] ?? '';
            if (description.isEmpty) {
              description = shortDescription.trim();
              shortDescription = '';
            }
            description = description.trim();
            if (!description.startsWith('<p>')) {
              description = '<p>$description</p>';
            }
            shortDescription = _removeTag(shortDescription);
            final imageUrl =
                '${content['mainImage']['url'].replaceFirst('__SIZE__', '300x450')}?type=TEXT';
            bool showImage = MediaQuery.of(context).size.width > 1280;
            final availabilityStart = DateFormat.yMd(
                    Provider.of<LocaleModel>(context, listen: false)
                        .getCurrentLocale(context)
                        .toString())
                .format(
                    DateTime.parse(content['availability']['start']).toLocal());
            final availabilityEnd = DateFormat.yMd(
                    Provider.of<LocaleModel>(context, listen: false)
                        .getCurrentLocale(context)
                        .toString())
                .format(
                    DateTime.parse(content['availability']['end']).toLocal());
            List<Widget> credits = [];
            for (var c in content['credits']) {
              credits.addAll(
                [
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(flex: 1, child: Text(c['label'])),
                    Expanded(
                        flex: 1, child: Text('${(c['values']).join('\n')}'))
                  ])
                ],
              );
            }
            //debugPrint(json.encode(content).toString());
            return Container(
                padding: const EdgeInsets.all(15),
                child: Center(
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                      if (showImage)
                        Expanded(
                            flex: 1,
                            child: Image(
                              image: CachedNetworkImageProvider(imageUrl),
                              fit: BoxFit.fill,
                            )),
                      Expanded(
                          flex: 2,
                          child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(content['title'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge),
                                    if (content['subtile'] != null)
                                      const SizedBox(height: 10),
                                    if (content['subtile'] != null)
                                      Text(content['subtitle'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium),
                                    if (shortDescription.isNotEmpty)
                                      const SizedBox(height: 10),
                                    if (shortDescription.isNotEmpty)
                                      Text(shortDescription,
                                          textAlign: TextAlign.justify,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge),
                                    const SizedBox(height: 10),
                                    Flexible(
                                        child: SingleChildScrollView(
                                            child: Html(
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
                                        }))),
                                  ]))),
                      Expanded(
                          flex: 1,
                          child: SingleChildScrollView(
                              child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(children: [
                                const Expanded(flex: 1, child: Text('ID')),
                                Expanded(
                                    flex: 1,
                                    child: Text('${content['programId']}'))
                              ]),
                              const SizedBox(height: 10),
                              Row(children: [
                                Expanded(
                                    flex: 1,
                                    child: Text(AppLocalizations.of(context)!
                                        .strDuration)),
                                Expanded(
                                    flex: 1,
                                    child: Text('${content['durationLabel']}'))
                              ]),
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
                              ]),
                              const SizedBox(height: 10),
                              Row(children: [
                                Expanded(
                                    flex: 1,
                                    child: Text(AppLocalizations.of(context)!
                                        .strGenre)),
                                Expanded(
                                    flex: 1,
                                    child: Text('${content['genre']['label']}'))
                              ]),
                              const SizedBox(height: 10),
                              ...credits,
                            ],
                          ))),
                    ])));
          } else {
            return Center(
                child: Text(AppLocalizations.of(context)!.strFetching));
          }
        },
      ),
    );
  }
}
