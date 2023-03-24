import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flarte/api.dart';
import 'package:flarte/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:process/process.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:xdg_directories/xdg_directories.dart';
import 'package:path/path.dart' as path;

import 'player.dart';

void main() {
  runApp(ChangeNotifierProvider<Cache>(
      create: (_) => Cache(), child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const pageTransitionsTheme = PageTransitionsTheme(
      builders: {
        // TODO: change transition to ZoomPageTransitionsBuilder() when media_kit fixes their issue#64
        TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: OpenUpwardsPageTransitionsBuilder(),
      },
    );
    return MaterialApp(
      title: 'Flarte',
      //theme: ThemeData(
      //  primarySwatch: Colors.deepOrange,
      //),
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        brightness: Brightness.light,
        pageTransitionsTheme: pageTransitionsTheme,
        /* light theme settings */
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.deepOrange,
        brightness: Brightness.dark,
        pageTransitionsTheme: pageTransitionsTheme,
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
    if (MediaQuery.of(context).size.width < 1600) {
      size = CategoriesListSize.small;
      leftSideWidth = 200;
    }
    if (MediaQuery.of(context).size.width < 1280) {
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
                    color: Theme.of(context).colorScheme.primary,
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
                    color: Theme.of(context).colorScheme.primary,
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
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
              elevation: 8.0,
              child: SizedBox(
                  width: min(MediaQuery.of(context).size.width - 100, 600),
                  child: ShowDetail(video: v)));
        });
  }

  Future<Map<String, dynamic>> _getProgramDetail(String programId) async {
    final url =
        'https://www.arte.tv/api/rproxy/emac/v4/fr/web/programs/$programId';
    final resp = await http
        .get(Uri.parse(url), headers: {'User-Agent': AppConfig.userAgent});
    final Map<String, dynamic> jr = json.decode(resp.body);
    return jr;
  }

  void _showBigDialogProgram(
      BuildContext context, Map<String, dynamic> v) async {
    final programId = v['programId'];
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
              child: SizedBox(
            width: min(MediaQuery.of(context).size.width - 50, 900),
            child: FutureBuilder(
              future: _getProgramDetail(programId),
              builder: (context, snapshot) {
                Widget trailer = const Text('');
                if (snapshot.hasData) {
                  if (snapshot.data != null) {
                    final content = snapshot.data?['value']['zones'][0]
                        ['content']['data'][0];
                    String? description = content['fullDescription'];
                    description ??= content['shortDescription'];
                    description = description
                        ?.replaceAll('<p>', '')
                        .replaceAll('</p>', '\n')
                        .replaceAll('<br>', '\n')
                        .replaceAll('<br />', '\n')
                        .replaceAll(RegExp('\n{2,}'), '\n\n')
                        .replaceFirst(RegExp(r'\n$'), '');
                    trailer = Text(description!,
                        style: Theme.of(context).textTheme.bodyMedium);
                  }
                }
                return Container(
                    padding: const EdgeInsets.all(15),
                    child: Stack(children: [
                      ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.8),
                            BlendMode.darken,
                          ),
                          child: Image(
                              image: CachedNetworkImageProvider(v['mainImage']
                                      ['url']
                                  .replaceFirst('__SIZE__', '1280x720')
                                  .replaceFirst('?type=TEXT', '')))),
                      Container(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(v['title'],
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                if (v['subtile'] != null)
                                  const SizedBox(height: 10),
                                if (v['subtile'] != null)
                                  Text(v['subtitle'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                const SizedBox(height: 10),
                                trailer,
                              ])),
                    ]));
              },
            ),
          ));
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
      final programId = videos.where((v) => v['programId'] != null).toList();
      if (videos.isEmpty ||
          z['displayOptions']['template'].startsWith('event') ||
          z['displayOptions']['template'].startsWith('single') ||
          programId.isEmpty ||
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
  final CategoriesListSize size;

  ZoneList(
      {super.key, required this.data, this.size = CategoriesListSize.normal}) {
    final List<dynamic> dvz;
    List<Map<String, dynamic>> tmp = [];
    if (data.isEmpty) {
      dvz = [];
    } else {
      dvz = data['value']['zones'];
    }
    for (var z in dvz) {
      final shows = z['content']['data'];
      final programId = shows.where((v) => v['programId'] != null).toList();
      if (shows.isEmpty ||
          z['displayOptions']['template'].startsWith('event') ||
          z['displayOptions']['template'].startsWith('single') ||
          programId.isEmpty ||
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
          width: widget.size == CategoriesListSize.small ? 300 : 350,
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

class ShowDetail extends StatefulWidget {
  final Map<String, dynamic> video;

  @override
  State<ShowDetail> createState() => _ShowDetailState();

  const ShowDetail({super.key, required this.video});
}

class _ShowDetailState extends State<ShowDetail> {
  late Version selectedVersion;
  late Format selectedFormat;
  List<Version> versions = [];
  List<DropdownMenuItem<Version>> versionItems = [];
  List<DropdownMenuItem<Format>> formatItems = [];
  List<Format> formats = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final programId = widget.video['programId'];

      debugPrint(programId);
      final resp = await http.get(
          Uri.parse('https://api.arte.tv/api/player/v2/config/fr/$programId'));
      Map<String, dynamic> jr = json.decode(resp.body);
      if (jr['data'] == null) {
        return;
      }
      final streams = jr['data']['attributes']['streams'];
      //debugPrint(json.encode(streams).toString());
      List<Version> cv = [];
      for (var s in streams) {
        final v = s['versions'][0];
        //debugPrint(v['shortLabel']);
        cv.add(Version(
            shortLabel: v['shortLabel'], label: v['label'], url: s['url']));
      }
      debugPrint(cv.toString());
      if (cv.isNotEmpty) {
        setState(() {
          versions.clear();
          versions.addAll(cv);
          selectedVersion = versions.first;
          versionItems = versions
              .map((e) =>
                  DropdownMenuItem<Version>(value: e, child: Text(e.label)))
              .toList();
        });
        _getFormats();
      }
    });
  }

  void _getFormats() async {
    // directly parse the .m3u8 to get the bandwidth value to pass to libmpv backend
    final resp = await http.get(Uri.parse(selectedVersion.url),
        headers: {'User-Agent': AppConfig.userAgent});
    final lines = resp.body.split('\n');
    List<Format> tf = [];
    // #EXT-X-STREAM-INF:BANDWIDTH=xxx,AVERAGE-BANDWIDTH=yyyy,VIDEO-RANGE=SDR,CODECS="avc1.4d401e,mp4a.40.2",RESOLUTION=zzzxzzz,FRAME-RATE=25.000,AUDIO="program_audio_0",SUBTITLES="subs"
    for (var line in lines) {
      if (line.startsWith('#EXT-X-STREAM-INF')) {
        final info = line.split(':').last;
        String resolution = '', bandwidth = '';
        for (var i in info.split(',')) {
          if (i.startsWith('RESOLUTION')) {
            resolution = i.split('=').last;
          } else if (i.startsWith('BANDWIDTH')) {
            bandwidth = i.split('=').last;
          }
        }
        tf.add(Format(resolution: resolution, bandwidth: bandwidth));
        tf.sort((a, b) {
          int aa = int.parse(a.bandwidth.replaceFirst('p', ''));
          int bb = int.parse(b.bandwidth.replaceFirst('p', ''));
          return aa.compareTo(bb);
        });
      }
    }
    debugPrint(tf.toString());
    if (tf.isNotEmpty) {
      setState(() {
        formats.clear();
        formats.addAll(tf);
        selectedFormat = formats[2];
        formatItems = formats
            .map((e) => DropdownMenuItem<Format>(
                value: e, child: Text('${e.resolution.split('x').last}p')))
            .toList();
      });
    }
  }

  void _ytdlp() async {
    ProcessManager mgr = const LocalProcessManager();
    // look for the format id that matches our resolution
    String binary = '';
    if (Platform.isLinux) {
      binary = 'yt-dlp';
    } else if (Platform.isWindows) {
      binary = 'yt-dlp.exe';
    } else {
      return;
    }
    List<String> cmd = [
      binary,
      '--user-agent',
      AppConfig.userAgent,
      '-J',
      selectedVersion.url
    ];
    String formatId = '';
    ProcessResult result = await mgr.run(cmd);
    if (result.exitCode != 0) {
      debugPrint(result.stderr);
      return;
    }
    final jr = json.decode(result.stdout);
    for (var f in jr['formats']) {
      if (f['resolution'] == selectedFormat.resolution) {
        formatId = f['format_id'];
        break;
      }
    }
    debugPrint('found format_id: $formatId');
    String workingDirectory = '';
    if (Platform.isLinux) {
      // download with yt-dlp in $XDG_DOWNLOAD_DIR if defined, else $HOME
      Directory? downloadDir = getUserDirectory('DOWNLOAD');
      if (downloadDir == null) {
        workingDirectory = const String.fromEnvironment('HOME');
      } else {
        workingDirectory = downloadDir.path;
      }
    } else if (Platform.isWindows) {
      // download to %USERPORFILE%\Downloads
      workingDirectory =
          path.join(Platform.environment['USERPROFILE']!, 'Downloads');
    }
    if (formatId.isNotEmpty) {
      cmd = [
        binary,
        '--user-agent',
        AppConfig.userAgent,
        '-f',
        formatId,
        selectedVersion.url
      ];
      debugPrint('workingDirectory: $workingDirectory');
      result = await mgr.run(cmd, workingDirectory: workingDirectory);
    }
    if (result.exitCode != 0) {
      debugPrint(result.stderr);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    //debugPrint(json.encode(widget.video));

    final imageUrl = (widget.video['mainImage']['url'])
        .replaceFirst('__SIZE__', '400x225')
        .replaceFirst('?type=TEXT', '');
    return Container(
        padding: const EdgeInsets.all(15),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.video['title'],
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              widget.video['subtitle'] != null
                  ? Text(
                      widget.video['subtitle'],
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
                          widget.video['shortDescription'] != null
                              ? Text(widget.video['shortDescription'],
                                  maxLines: 16,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium)
                              : const SizedBox.shrink(),
                          const SizedBox(height: 10),
                          Row(children: [
                            Chip(
                              backgroundColor:
                                  Theme.of(context).primaryColorDark,
                              label: Text(widget.video['kind']['label']),
                            ),
                            const SizedBox(width: 10),
                            if (!widget.video['kind']['isCollection'] &&
                                widget.video['durationLabel'] != null)
                              Chip(
                                backgroundColor:
                                    Theme.of(context).primaryColorDark,
                                label: Text(widget.video['durationLabel']),
                              ),
                          ]),
                          const SizedBox(height: 10),
                          widget.video['kind']['isCollection']
                              ? const SizedBox.shrink()
                              : Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.play_arrow),
                                      onPressed: versions.isNotEmpty
                                          ? () {
                                              String title = '';
                                              String? subtitle =
                                                  widget.video['subtitle'];
                                              if (subtitle != null &&
                                                  subtitle.isNotEmpty) {
                                                title =
                                                    '${widget.video['title']} / $subtitle';
                                              } else {
                                                title = widget.video['title'];
                                              }

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        MyScreen(
                                                            title: title,
                                                            url: selectedVersion
                                                                .url,
                                                            bitrate:
                                                                selectedFormat
                                                                    .bandwidth)),
                                              );
                                            }
                                          : null,
                                    ),
                                    const SizedBox(width: 24),
                                    IconButton(
                                      icon: const Icon(Icons.download),
                                      onPressed:
                                          versions.isNotEmpty ? _ytdlp : null,
                                    ),
                                    const SizedBox(width: 24),
                                    IconButton(
                                      icon: const Icon(Icons.copy),
                                      onPressed: versions.isNotEmpty
                                          ? () {
                                              _copyToClipboard(
                                                  context, selectedVersion.url);
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 10),
                          widget.video['kind']['isCollection']
                              ? const SizedBox.shrink()
                              : Row(children: [
                                  versionItems.isNotEmpty
                                      ? DropdownButton<Version>(
                                          underline: const SizedBox.shrink(),
                                          hint: const Text('Version'),
                                          selectedItemBuilder:
                                              (BuildContext context) {
                                            return versions.map<Widget>((v) {
                                              return Container(
                                                padding: const EdgeInsets.only(
                                                    left: 10),
                                                alignment: Alignment.centerLeft,
                                                constraints:
                                                    const BoxConstraints(
                                                        minWidth: 100),
                                                child: Text(
                                                  v.shortLabel,
                                                  style: const TextStyle(
                                                      color: Colors.deepOrange,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              );
                                            }).toList();
                                          },
                                          value: selectedVersion,
                                          items: versionItems,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedVersion = value!;
                                              _getFormats();
                                            });
                                          })
                                      : const SizedBox(height: 24),
                                  const SizedBox(width: 10),
                                  formatItems.isNotEmpty
                                      ? DropdownButton<Format>(
                                          underline: const SizedBox.shrink(),
                                          hint: const Text('Format'),
                                          value: selectedFormat,
                                          selectedItemBuilder:
                                              (BuildContext context) {
                                            return formats.map<Widget>((f) {
                                              return Container(
                                                padding: const EdgeInsets.only(
                                                    left: 10),
                                                alignment: Alignment.centerLeft,
                                                constraints:
                                                    const BoxConstraints(
                                                        minWidth: 100),
                                                child: Text(
                                                  '${f.resolution.split('x').last}p',
                                                ),
                                              );
                                            }).toList();
                                          },
                                          items: formatItems,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedFormat = value!;
                                            });
                                          })
                                      : const SizedBox(height: 24),
                                ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            const Expanded(
                                flex: 1, child: SizedBox(height: 10)),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Fermer'),
                            )
                          ]),
                        ]),
                  )
                ],
              ),
            ]));
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content:
          Text('Copied to clipboard', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.black87,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

enum CategoriesListSize { tiny, small, normal }

class Version {
  String shortLabel;
  String label;
  String url;
  Version({required this.shortLabel, required this.label, required this.url});

  @override
  String toString() {
    return 'Version($shortLabel, $label)';
  }
}

class Format {
  String resolution;
  String bandwidth;
  Format({required this.resolution, required this.bandwidth});

  @override
  String toString() {
    return 'Format($resolution, $bandwidth)';
  }
}
