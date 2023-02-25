//import 'dart:convert';
import 'dart:async';
import 'dart:math';

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
      //theme: ThemeData(
      //  primarySwatch: Colors.deepOrange,
      //),
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        brightness: Brightness.light,
        /* light theme settings */
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.deepOrange,
        brightness: Brightness.dark,
        /* dark theme settings */
      ),
      themeMode: ThemeMode.dark,
      /* ThemeMode.system to follow system theme,
         ThemeMode.light for light theme,
         ThemeMode.dark for dark theme
      */
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
      await cache.fetch('HOME');
    });
  }

  @override
  Widget build(BuildContext context) {
    double leftSideWidth;
    CategoriesListSize size = CategoriesListSize.normal;
    leftSideWidth = 300;
    if (MediaQuery.of(context).size.width < 1500) {
      size = CategoriesListSize.small;
      leftSideWidth = 200;
    }
    if (MediaQuery.of(context).size.width < 1200) {
      size = CategoriesListSize.tiny;
      leftSideWidth = 64;
    }
    double padding = 10;
    if (MediaQuery.of(context).size.height < 720) {
      padding = 5;
    }
    return Scaffold(
        drawer: const Drawer(),
        body: Row(children: [
          SizedBox(
              width: leftSideWidth,
              child:
                  Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                Expanded(
                    flex: 1,
                    child:
                        CategoriesList(size: size, controller: _tabController)),
                ListTile(
                  selectedTileColor: Theme.of(context).highlightColor,
                  contentPadding: EdgeInsets.only(
                    left: 25,
                    top: padding,
                    bottom: padding,
                  ),
                  minLeadingWidth: 30,
                  leading: const Icon(Icons.settings),
                  title: leftSideWidth != 64 ? const Text('Settings') : null,
                  onTap: () {},
                ),
              ])),
          Expanded(
            flex: 1,
            child: TabBarView(controller: _tabController, children: [
              Consumer<Cache>(builder: (context, cache, child) {
                return CarouselList(data: cache.data['HOME'], size: size);
              }),
              Consumer<Cache>(builder: (context, cache, child) {
                return CarouselList(data: cache.data['DOR'], size: size);
              }),
              Consumer<Cache>(builder: (context, cache, child) {
                return CarouselList(data: cache.data['SER'], size: size);
              }),
              Consumer<Cache>(builder: (context, cache, child) {
                return CarouselList(data: cache.data['CIN'], size: size);
              }),
              Consumer<Cache>(builder: (context, cache, child) {
                return CarouselList(data: cache.data['EMI'], size: size);
              }),
              Consumer<Cache>(builder: (context, cache, child) {
                return CarouselList(data: cache.data['HIS'], size: size);
              }),
              Consumer<Cache>(builder: (context, cache, child) {
                return CarouselList(data: cache.data['DEC'], size: size);
              }),
              Consumer<Cache>(builder: (context, cache, child) {
                return CarouselList(data: cache.data['SCI'], size: size);
              }),
              Consumer<Cache>(builder: (context, cache, child) {
                return CarouselList(data: cache.data['ACT'], size: size);
              }),
              Consumer<Cache>(builder: (context, cache, child) {
                return CarouselList(data: cache.data['CPO'], size: size);
              }),
            ]),
          ),
        ]));
  }
}

class Carousel extends StatefulWidget {
  final List<Widget> children;
  final CategoriesListSize size;
  late final double _width, _height;
  @override
  State<Carousel> createState() => _CarouselState();

  Carousel(
      {super.key,
      required this.children,
      this.size = CategoriesListSize.normal}) {
    switch (size) {
      case CategoriesListSize.normal:
        _width = 285;
        _height = 262;
        break;
      case CategoriesListSize.small:
        _width = 220;
        _height = 112 + 100;
        break;
      case CategoriesListSize.tiny:
        _width = 180;
        _height = 90 + 100;
        break;
    }
  }
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
            height: widget._height,
            child: ListView(
              controller: _controller,
              prototypeItem:
                  SizedBox(width: widget._width, height: widget._height),
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
  final CategoriesListSize size;
  late final double _imageHeight, _imageWidth;

  CarouselList(
      {super.key, required this.data, this.size = CategoriesListSize.normal}) {
    switch (size) {
      case CategoriesListSize.normal:
        // image size divided by 1.5
        _imageHeight = 148;
        _imageWidth = 265;
        break;
      case CategoriesListSize.small:
        // image size divided by 2
        _imageHeight = 112;
        _imageWidth = 200;
        break;
      case CategoriesListSize.tiny:
        // image size divided by 2.5
        _imageHeight = 90;
        _imageWidth = 160;
        break;
    }
  }

  void _showDialogProgram(BuildContext context, Map<String, dynamic> v) {
    //JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    //String prettyprint = encoder.convert(v);
    //debugPrint(prettyprint);
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
              child: SizedBox(
                  width: min(MediaQuery.of(context).size.width - 100, 500),
                  child: ShowDetail(video: v)));
        });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> thumbnails = [];
    List<dynamic> videos = [];

    //debugPrint('in CarouselList.build()');
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
      thumbnails
          .add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.all(15),
            child: Text('${z['title']} (${videos.length})',
                style: Theme.of(context).textTheme.headlineSmall)),
        Carousel(
            size: size,
            children: videos.map((v) {
              final imageUrl = (v['mainImage']['url'])
                  .replaceFirst('__SIZE__', '400x225')
                  .replaceFirst('?type=TEXT', '');
              return InkWell(
                  onTap: () {
                    _showDialogProgram(context, v);
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
                                  height: _imageHeight,
                                  width: _imageWidth,
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    v['title'],
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                  subtitle: (size == CategoriesListSize.normal)
                                      ? Text(
                                          v['subtitle'] ?? '',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        )
                                      : null,
                                  isThreeLine:
                                      size == CategoriesListSize.normal,
                                ),
                              ]))));
            }).toList())
      ]));
    }
    return SingleChildScrollView(
        // subtract NavigationRail width
        child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            padding: const EdgeInsets.all(10),
            child: thumbnails.isNotEmpty
                ? ListView.builder(
                    itemCount: thumbnails.length,
                    itemBuilder: (context, index) {
                      return thumbnails[index];
                    },
                  )
                : const Center(child: Text('Fetching data ...'))));
  }
}

class CategoriesList extends StatefulWidget {
  final CategoriesListSize size;
  final TabController controller;

  const CategoriesList(
      {super.key, required this.size, required this.controller});

  @override
  State<CategoriesList> createState() => _CategoriesListState();
}

class _CategoriesListState extends State<CategoriesList> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    double padding = 10;
    if (MediaQuery.of(context).size.height < 720) {
      padding = 5;
      if (MediaQuery.of(context).size.height < 640) {
        padding = 0;
      }
    }
    return ListView.builder(
      //padding: const EdgeInsets.symmetric(vertical: 10),
      shrinkWrap: true,
      semanticChildCount: categories.length,
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final c = categories[index];
        String text = c['text'];
        Widget avatar = CircleAvatar(
            backgroundColor: Color.fromARGB(
                255, c['color'][0], c['color'][1], c['color'][2]),
            child: Text(text.substring(0, 1),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.inversePrimary)));
        Widget leading;
        if (widget.size != CategoriesListSize.normal) {
          text = c['text'].split(' ').first;
        }
        Widget? title;
        if (widget.size == CategoriesListSize.tiny) {
          leading = Tooltip(message: text, child: avatar);
          title = null;
        } else {
          leading = avatar;
          title =
              Text(text, style: const TextStyle(fontWeight: FontWeight.w500));
        }
        return ListTile(
          selected: index == selectedIndex,
          leading: leading,
          onTap: () async {
            setState(() {
              selectedIndex = index;
              widget.controller.animateTo(index);
            });
            final cache = Provider.of<Cache>(context, listen: false);
            cache.fetch(c['code']);
          },
          contentPadding:
              EdgeInsets.only(left: 15, top: padding, bottom: padding),
          title: title,
        );
      },
    );
  }
}

class ZoneList extends StatefulWidget {
  final Map<dynamic, dynamic> data;
  final List<Map<String, dynamic>> _zones = [];
  final bool small;

  ZoneList({super.key, required this.data, this.small = false}) {
    final List<dynamic> dvz;
    List<Map<String, dynamic>> tmp = [];
    if (data.isEmpty) {
      dvz = [];
    } else {
      dvz = data['value']['zones'];
    }
    for (var z in dvz) {
      final shows = z['content']['data'];
      if (shows.isEmpty ||
          z['title'].contains('event') ||
          z['code'] == 'highlights_HOME' ||
          z['title'] == "Parcourir toute l'offre" ||
          z['title'] == 'Les documentaires par thème' ||
          shows.length == 1) {
        //debugPrint('skipped ${z['title']}/${z['code']} (${videos.length})');
        continue;
      }
      tmp.add({'title': z['title'], 'shows': shows});
    }
    _zones.addAll(tmp);
  }

  @override
  State<ZoneList> createState() => _ZoneListState();
}

class _ZoneListState extends State<ZoneList> {
  int selectedZoneIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget._zones.isEmpty) {
      return const Center(child: Text('Fetching data...'));
    }
    return Row(mainAxisSize: MainAxisSize.max, children: [
      SizedBox(
          height: MediaQuery.of(context).size.height,
          width: widget.small ? 300 : 350,
          child: ListView.builder(
            //padding: const EdgeInsets.symmetric(vertical: 10),
            semanticChildCount: widget._zones.length,
            itemCount: widget._zones.length,
            itemBuilder: (context, index) {
              if (widget._zones.isNotEmpty) {
                return ListTile(
                    selectedTileColor: Theme.of(context).highlightColor,
                    selected: index == selectedZoneIndex,
                    onTap: () {
                      setState(() {
                        selectedZoneIndex = index;
                      });
                    },
                    title: Text(
                      '${widget._zones[index]['title']} (${widget._zones[index]['shows'].length})',
                      softWrap: true,
                    ));
              } else {
                return null;
              }
            },
          )),
      Expanded(
          flex: 1,
          child: ShowList(
              key: Key('$selectedZoneIndex'),
              videos: widget._zones.isNotEmpty
                  ? widget._zones[selectedZoneIndex]['shows']
                  : [])),
    ]);
  }
}

class ShowList extends StatefulWidget {
  final List<dynamic> videos;

  const ShowList({super.key, required this.videos});

  @override
  State<ShowList> createState() => _ShowListState();
}

class _ShowListState extends State<ShowList> {
  int selectedShowIndex = -1;

  @override
  void initState() {
    super.initState();
    selectedShowIndex = -1;
  }

  @override
  void dispose() {
    selectedShowIndex = -1;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
          width: 450,
          child: ListView.builder(
              itemCount: widget.videos.length,
              itemBuilder: (context, index) {
                return ListTile(
                  selectedTileColor: Theme.of(context).highlightColor,
                  selected: index == selectedShowIndex,
                  title: Text(widget.videos[index]['title']),
                  subtitle: (widget.videos[index]['subtitle'] != null)
                      ? Text(widget.videos[index]['subtitle'])
                      : null,
                  onTap: () {
                    setState(() {
                      selectedShowIndex = index;
                    });
                  },
                );
              })),
      Expanded(
          child: selectedShowIndex != -1
              ? ShowDetail(video: widget.videos[selectedShowIndex])
              : const SizedBox.shrink())
    ]);
  }
}

class ShowDetail extends StatelessWidget {
  final Map<String, dynamic> video;

  const ShowDetail({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (video['mainImage']['url'])
        .replaceFirst('__SIZE__', '400x225')
        .replaceFirst('?type=TEXT', '');
    return Container(
        padding: const EdgeInsets.all(15),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                video['title'],
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              video['subtitle'] != null
                  ? Text(
                      video['subtitle'],
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
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
                          video['shortDescription'] != null
                              ? Text(video['shortDescription'],
                                  maxLines: 16,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium)
                              : const SizedBox.shrink(),
                          const SizedBox(height: 10),
                          if (video['durationLabel'] != null)
                            Chip(
                              backgroundColor:
                                  Theme.of(context).primaryColorDark,
                              label: Text(video['durationLabel']),
                            )
                        ]),
                  )
                ],
              )
            ]));
  }
}

enum CategoriesListSize { tiny, small, normal }
