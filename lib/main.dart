//import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flarte/api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(ChangeNotifierProvider<Cache>(
      create: (_) => Cache(), child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flarte',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: const MyHomePage(title: 'arte.tv'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(initialIndex: 0, length: 10, vsync: this);
    final cache = Provider.of<Cache>(context, listen: false);
    Future.delayed(Duration.zero, () async {
      cache.set('HOM', await fetchUrl(urlHOME));
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isLeftSideSmall = (MediaQuery.of(context).size.width < 1300);
    return Scaffold(
        drawer: const Drawer(),
        body: Row(children: [
          CategoriesList(small: isLeftSideSmall, controller: _tabController),
          Expanded(
            flex: 1,
            child: TabBarView(controller: _tabController, children: [
              Consumer<Cache>(builder: (context, cache, child) {
                return CarouselList(data: cache.data['HOM'], shrink: 100);
              }),
              Consumer<Cache>(builder: (context, cache, child) {
                return CarouselList(data: cache.data['DOR'], shrink: 100);
              }),
              Consumer<Cache>(builder: (context, cache, child) {
                return CarouselList(data: cache.data['SER'], shrink: 100);
              }),
              Consumer<Cache>(builder: (context, cache, child) {
                return CarouselList(data: cache.data['CIN'], shrink: 100);
              }),
              Consumer<Cache>(builder: (context, cache, child) {
                return CarouselList(data: cache.data['EMI'], shrink: 100);
              }),
              Consumer<Cache>(builder: (context, cache, child) {
                return CarouselList(data: cache.data['HIS'], shrink: 100);
              }),
              Consumer<Cache>(builder: (context, cache, child) {
                return CarouselList(data: cache.data['DEC'], shrink: 100);
              }),
              Consumer<Cache>(builder: (context, cache, child) {
                return CarouselList(data: cache.data['SCI'], shrink: 100);
              }),
              Consumer<Cache>(builder: (context, cache, child) {
                return CarouselList(data: cache.data['ACT'], shrink: 100);
              }),
              Consumer<Cache>(builder: (context, cache, child) {
                return CarouselList(data: cache.data['CPO'], shrink: 100);
              }),
            ]),
          )
        ]));
  }
}

class Carousel extends StatefulWidget {
  final List<Widget> children;
  @override
  State<Carousel> createState() => _CarouselState();

  const Carousel({super.key, required this.children});
}

class _CarouselState extends State<Carousel> {
  final _controller = ScrollController();

  bool isChevronRightVisible = true;
  bool isChevronLeftVisible = true;
  bool isChevronRightEnabled = true;
  bool isChevronLeftEnabled = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (285 * widget.children.length < constraints.maxWidth) {
        isChevronLeftVisible = false;
        isChevronRightVisible = false;
      }
      return Stack(children: [
        SizedBox(
            height: 250,
            child: ListView(
              controller: _controller,
              prototypeItem: const SizedBox(width: 285, height: 250),
              scrollDirection: Axis.horizontal,
              children: widget.children,
            )),
        Visibility(
            visible: isChevronLeftVisible,
            child: Positioned(
                left: 5,
                top: 65,
                child: ElevatedButton(
                  onPressed: !isChevronLeftEnabled
                      ? null
                      : () {
                          final box = context.findRenderObject() as RenderBox;
                          _controller.animateTo(
                              _controller.offset - box.size.width,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut);
                          setState(() {
                            if (_controller.offset <
                                _controller.position.viewportDimension) {
                              isChevronLeftEnabled = false;
                            }
                            isChevronRightEnabled = true;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onSecondary,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                  ),
                  child: Icon(
                    Icons.chevron_left,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ))),
        Visibility(
            visible: isChevronRightVisible,
            child: Positioned(
                right: 5,
                top: 65,
                child: ElevatedButton(
                  onPressed: !isChevronRightEnabled
                      ? null
                      : () {
                          final box = context.findRenderObject() as RenderBox;
                          _controller.animateTo(
                              _controller.offset + box.size.width,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut);
                          setState(() {
                            if (_controller.offset >=
                                _controller.position.maxScrollExtent -
                                    _controller.position.viewportDimension) {
                              isChevronRightEnabled = false;
                            }
                            isChevronLeftEnabled = true;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onSecondary,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ))),
      ]);
    });
  }
}

class CarouselList extends StatelessWidget {
  final Map<dynamic, dynamic> data;
  final int shrink;

  const CarouselList({super.key, required this.data, required this.shrink});

  void _showDialogProgram(
      BuildContext bcontext, Map<String, dynamic> v, String imageUrl) {
    //JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    //String prettyprint = encoder.convert(v);
    //debugPrint(prettyprint);
    showDialog(
        context: bcontext,
        builder: (bcontext) {
          return Dialog(
              child: Container(
                  padding: const EdgeInsets.all(15),
                  width: 600,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          v['title'],
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(bcontext).textTheme.titleLarge,
                        ),
                        v['subtitle'] != null
                            ? Text(
                                v['subtitle'],
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(bcontext).textTheme.titleMedium,
                              )
                            : const SizedBox.shrink(),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image(
                              width: 200,
                              height: 300,
                              image: CachedNetworkImageProvider(
                                  '${imageUrl.replaceFirst('400x225', '300x450')}?type=TEXT'),
                            ),
                            const SizedBox(width: 15),
                            Flexible(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    v['shortDescription'] != null
                                        ? Text(v['shortDescription'],
                                            maxLines: 16,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(bcontext)
                                                .textTheme
                                                .bodyMedium)
                                        : const SizedBox.shrink(),
                                    if (v['durationLabel'] != null)
                                      Chip(
                                        label: Text(v['durationLabel']),
                                      )
                                  ]),
                            )
                          ],
                        )
                      ])));
        });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> thumbnails = [];
    List<dynamic> videos = [];

    debugPrint('in CarouselList.build()');
    final List<dynamic> zones;
    if (data.isEmpty) {
      zones = [];
    } else {
      zones = data['value']['zones'];
    }
    for (var z in zones) {
      videos = z['content']['data'];
      if (videos.isEmpty ||
          z['title'].contains('event') ||
          z['code'] == 'highlights_HOME' ||
          z['title'] == "Parcourir toute l'offre" ||
          z['title'] == 'Les documentaires par thème' ||
          videos.length == 1) {
        //debugPrint('skipped ${z['title']}/${z['code']} (${videos.length})');
        continue;
      }
      thumbnails.add(Container(
          padding: const EdgeInsets.all(15),
          child: Text('${z['title']} (${videos.length})',
              style: Theme.of(context).textTheme.headlineSmall)));
      thumbnails.add(Carousel(
          children: videos.map((v) {
        final imageUrl = (v['mainImage']['url'])
            .replaceFirst('__SIZE__', '400x225')
            .replaceFirst('?type=TEXT', '');
        return InkWell(
            onTap: () {
              _showDialogProgram(context, v, imageUrl);
            },
            child: Card(
                child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image(
                            image: CachedNetworkImageProvider(imageUrl),
                            // image size divided by 1.5
                            height: 148,
                            width: 265,
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              v['title'],
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              v['subtitle'] ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]))));
      }).toList()));
    }
    return SingleChildScrollView(
        // subtract NavigationRail width
        child: Container(
            width: MediaQuery.of(context).size.width - shrink,
            color: Colors.grey[100],
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: thumbnails,
            )));
  }
}

class CategoriesList extends StatefulWidget {
  final bool small;
  final TabController controller;
  late final double _leftSideWidth;

  CategoriesList({super.key, required this.small, required this.controller}) {
    if (small) {
      _leftSideWidth = 200;
    } else {
      _leftSideWidth = 300;
    }
  }

  @override
  State<CategoriesList> createState() => _CategoriesListState();
}

class _CategoriesListState extends State<CategoriesList> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: widget._leftSideWidth,
        child: ListView.builder(
          //padding: const EdgeInsets.symmetric(vertical: 10),
          semanticChildCount: categories.length,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final c = categories[index];
            String text = c['text'];
            if (widget.small) {
              text = c['text'].split(' ').first;
            }
            return ListTile(
              selectedTileColor: Theme.of(context).highlightColor,
              selected: index == selectedIndex,
              leading: CircleAvatar(
                  backgroundColor: Color.fromARGB(
                      255, c['color'][0], c['color'][1], c['color'][2]),
                  child: Text(text.substring(0, 1),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.inversePrimary))),
              onTap: () async {
                String url =
                    "https://www.arte.tv/api/rproxy/emac/v4/fr/web/pages/${c['code']}/";
                final cache = Provider.of<Cache>(context, listen: false);
                //debugPrint('${c['code']}');
                if (cache.data[c['code']].isEmpty) {
                  final resp = await fetchUrl(url);
                  cache.set(c['code'], resp);
                }
                setState(() {
                  selectedIndex = index;
                  widget.controller.animateTo(index);
                });
              },
              contentPadding:
                  const EdgeInsets.only(left: 15, top: 10, bottom: 10),
              title: Text(text,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            );
          },
        ));
  }
}
