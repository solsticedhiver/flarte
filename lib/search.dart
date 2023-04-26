import 'dart:convert';
import 'dart:math';

import 'package:flarte/detail.dart';
import 'package:flarte/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<VideoData> data = [];
  String search = '';

  @override
  void initState() {
    super.initState();
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
                  width: min(MediaQuery.of(context).size.width - 100, 600),
                  child: ShowDetail(videos: videos, index: index)));
        });
  }

  Future<void> _searchTerm(String search) async {
    String lang = Provider.of<LocaleModel>(context, listen: false)
        .getCurrentLocale(context)
        .languageCode;
    final resp = await http.get(Uri.parse(
        'https://www.arte.tv/api/rproxy/emac/v4/$lang/web/pages/SEARCH/?page=1&query=${Uri.encodeComponent(search)}'));
    final Map<String, dynamic> jr = json.decode(resp.body);
    final List<dynamic> zones = jr['value']['zones'];
    for (var z in zones) {
      if (z['code'] == 'listing_SEARCH') {
        setState(() {
          data.clear();
          data.addAll((z['content']['data'] as List<dynamic>)
              .map((v) => VideoData.fromJson(v)));
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int count = MediaQuery.of(context).size.width ~/ 285;
    double width = 285.0 * count;
    final controller = TextEditingController();
    Widget results;

    if (data.isNotEmpty) {
      // ignore: sized_box_for_whitespace
      results = Container(
          width: width,
          child: GridView.count(
            childAspectRatio: 0.85,
            crossAxisCount: count,
            children: data.map((v) {
              return InkWell(
                  onTap: () {
                    _showDialogProgram(context, data, data.indexOf(v));
                  },
                  child: VideoCard(
                    video: v,
                    useSubtitle: false,
                    withShortDescription: true,
                    size: CarouselListSize.normal,
                  ));
            }).toList(),
          ));
    } else {
      String text;
      if (search.isEmpty) {
        text = AppLocalizations.of(context)!.strNothingDisplay;
      } else {
        text = AppLocalizations.of(context)!.strNoResults;
      }
      // ignore: sized_box_for_whitespace
      results = Container(width: width, child: Center(child: Text(text)));
    }

    if (search.isNotEmpty) {
      controller.text = search;
    }

    return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.strSearch)),
        body: Center(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Container(
                width: width - 10 * 2,
                margin: const EdgeInsets.only(
                    top: 16, bottom: 16, left: 10, right: 10),
                child: Row(children: [
                  Expanded(
                      flex: 5,
                      child: TextField(
                        controller: controller,
                        onSubmitted: (value) {
                          setState(() {
                            search = controller.text;
                          });
                          _searchTerm(search);
                        },
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText:
                              AppLocalizations.of(context)!.strSearchTerms,
                          suffixIcon: IconButton(
                              focusColor: Theme.of(context).canvasColor,
                              highlightColor: Theme.of(context).canvasColor,
                              splashColor: Theme.of(context).canvasColor,
                              hoverColor: Theme.of(context).canvasColor,
                              onPressed: () {
                                controller.clear();
                              },
                              icon: const Icon(Icons.backspace)),
                        ),
                      )),
                  const SizedBox(width: 24),
                  ElevatedButton(
                      onPressed: () {
                        setState(() {
                          search = controller.text;
                        });
                        _searchTerm(controller.text);
                      },
                      child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(AppLocalizations.of(context)!.strSubmit,
                              style: const TextStyle(fontSize: 20)))),
                ]),
              ),
              Container(
                  padding: const EdgeInsets.only(left: 16),
                  width: width,
                  child: Text(AppLocalizations.of(context)!.strResults,
                      style: Theme.of(context).textTheme.titleLarge)),
              const SizedBox(height: 16),
              Expanded(flex: 6, child: results),
            ])));
  }
}

// https://www.arte.tv/api/rproxy/emac/v4/fr/web/pages/SEARCH/?page=1&query=test