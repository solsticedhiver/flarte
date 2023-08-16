import 'dart:async';
import 'dart:math';

import 'package:flarte/helpers.dart';
import 'package:flarte/config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'detail.dart';
import 'fulldetail.dart';
import 'settings.dart';
import 'search.dart';
import 'serie.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  AppConfig.textMode = prefs.getBool('textMode') ?? AppConfig.textMode;
  AppConfig.dlDirectory = prefs.getString('dlDirectory') ?? '';
  String? loc = prefs.getString('locale');
  Locale? locale;
  if (loc != null) {
    locale = Locale.fromSubtags(languageCode: loc);
  }
  String? tm = prefs.getString('theme');
  ThemeMode? themeMode;
  if (tm != null) {
    switch (tm) {
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'system':
        themeMode = ThemeMode.system;
        break;
    }
  }
  AppConfig.playerIndexQuality =
      prefs.getInt('quality') ?? AppConfig.playerIndexQuality;
  String? ptn = prefs.getString('player');
  if (ptn != null) {
    switch (ptn) {
      case 'embedded':
        AppConfig.player = PlayerTypeName.embedded;
        break;
      case 'custom':
        AppConfig.player = PlayerTypeName.custom;
        break;
      case 'vlc':
        AppConfig.player = PlayerTypeName.vlc;
        break;
    }
  }
  List<String>? adw = prefs.getStringList('watched');
  List<String>? adf = prefs.getStringList('favorites');

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<Cache>(create: (_) => Cache()),
      ChangeNotifierProvider<AppData>(create: (_) => AppData()),
      ChangeNotifierProvider<LocaleModel>(create: (_) => LocaleModel()),
      ChangeNotifierProvider<ThemeModeProvider>(
          create: (_) => ThemeModeProvider()),
    ],
    builder: (context, child) {
      if (locale != null) {
        Provider.of<LocaleModel>(context, listen: false)
            .changeLocale(locale, notify: false);
      }
      if (themeMode != null) {
        Provider.of<ThemeModeProvider>(context, listen: false).themeMode =
            themeMode;
      }
      if (adw != null) {
        Provider.of<AppData>(context, listen: false).watched = adw;
      }
      if (adf != null) {
        Provider.of<AppData>(context, listen: false).favorites = adf;
      }
      return const MyApp();
    },
  ));
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

    return Consumer2<LocaleModel, ThemeModeProvider>(
        builder: (context, localeModel, themeModeProvider, child) {
      return MaterialApp(
        title: 'Flarte',
        locale: localeModel.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeListResolutionCallback: (locales, supportedLocales) {
          const defaultLocale = Locale('en');
          if (locales == null) {
            return defaultLocale;
          } else {
            for (var l in locales) {
              // supportedLocales is expected to be only languageCode only (no contryCode)
              if (supportedLocales.contains(Locale(l.languageCode))) {
                return l;
              }
            }
          }
          return defaultLocale;
        },
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
        themeMode: themeModeProvider.themeMode,
        /* ThemeMode.system to follow system theme,
         ThemeMode.light for light theme,
         ThemeMode.dark for dark theme
      */
        home: const MyHomePage(title: 'arte.tv'),
      );
    });
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
    _tabController = TabController(
        initialIndex: 0, length: CategoriesList.codes.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    double leftSideWidth;
    CarouselListSize carSize = CarouselListSize.normal;
    CategoriesListSize catSize = CategoriesListSize.normal;
    leftSideWidth = 300;
    if (MediaQuery.sizeOf(context).width < 1600) {
      catSize = CategoriesListSize.small;
      leftSideWidth = 200;
    }
    if (MediaQuery.sizeOf(context).width < 1280) {
      carSize = CarouselListSize.small;
      catSize = CategoriesListSize.tiny;
      leftSideWidth = 64;
    }
    double padding = 10;
    if (MediaQuery.sizeOf(context).height < 720) {
      padding = 5;
      if (MediaQuery.sizeOf(context).height < 640) {
        padding = 0;
      }
    }

    return Scaffold(
        drawer: const Drawer(),
        body: Row(children: [
          SizedBox(
              width: leftSideWidth,
              child: Container(
                  color: Theme.of(context)
                      .canvasColor, // added a Container to fix the visual bug of hover highlight on first InkWell in Carousel
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                            flex: 1,
                            child: Consumer<LocaleModel>(
                                builder: (context, localeModel, child) {
                              String lang = localeModel
                                  .getCurrentLocale(context)
                                  .languageCode;
                              return CategoriesList(
                                  size: catSize,
                                  controller: _tabController,
                                  lang: lang);
                            })),
                        Material(
                            child: ListTile(
                          enabled: false,
                          selectedTileColor: Theme.of(context).highlightColor,
                          contentPadding: EdgeInsets.only(
                            left: 20,
                            top: padding,
                          ),
                          minLeadingWidth: 30,
                          leading: const Icon(Icons.cloud_download),
                          title: leftSideWidth != 64
                              ? Text(AppLocalizations.of(context)!.strDownloads,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500))
                              : null,
                          onTap: () {},
                        )),
                        Material(
                            child: ListTile(
                          selectedTileColor: Theme.of(context).highlightColor,
                          contentPadding: EdgeInsets.only(
                            left: 20,
                            top: padding,
                          ),
                          minLeadingWidth: 30,
                          leading: const Icon(Icons.search),
                          title: leftSideWidth != 64
                              ? Text(AppLocalizations.of(context)!.strSearch,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500))
                              : null,
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return const SearchScreen();
                            }));
                          },
                        )),
                        Material(
                            child: ListTile(
                          selectedTileColor: Theme.of(context).highlightColor,
                          contentPadding: EdgeInsets.only(
                            left: 20,
                            top: padding,
                            bottom: padding,
                          ),
                          minLeadingWidth: 30,
                          leading: const Icon(Icons.settings),
                          title: leftSideWidth != 64
                              ? Text(AppLocalizations.of(context)!.strSettings,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500))
                              : null,
                          onTap: () async {
                            final settings = await Navigator.push(context,
                                MaterialPageRoute<Map<String, dynamic>>(
                                    builder: (context) {
                              return const FlarteSettings();
                            }));
                            _saveSettings(settings);
                          },
                        )),
                      ]))),
          Expanded(
            flex: 1,
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _tabController,
              children: List.generate(
                  CategoriesList.codes.length,
                  (index) => Consumer2<Cache, LocaleModel>(
                          builder: (context, cache, localeModel, child) {
                        final lang =
                            localeModel.getCurrentLocale(context).languageCode;
                        final key = CategoriesList.codes[index];
                        return FutureBuilder(future: Future.microtask(() async {
                          List<dynamic>? data = await cache.fetch(key, lang);
                          return data;
                        }), builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            if (AppConfig.textMode) {
                              return ZoneList(
                                  // or ZoneList()
                                  data: snapshot.data!,
                                  size: carSize);
                            } else {
                              return CarouselList(
                                  // or ZoneList()
                                  data: snapshot.data!,
                                  size: carSize);
                            }
                          } else if (snapshot.hasData &&
                              snapshot.data == null) {
                            return Center(
                                child: Text(
                                    AppLocalizations.of(context)!.strError));
                          } else /*if (!snapshot.hasData) */ {
                            return Center(
                                child: Text(
                                    AppLocalizations.of(context)!.strFetching));
                          }
                        });
                      })),
            ),
          ),
        ]));
  }
}

void _saveSettings(Map<String, dynamic>? settings) async {
  if (settings == null) {
    return;
  }
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('locale', settings['locale'].languageCode);
  prefs.setString('theme', settings['theme'].toString().split('.').last);
  prefs.setInt('quality', settings['quality']);
  prefs.setString('player', settings['player'].toString().split('.').last);
  prefs.setBool('textMode', AppConfig.textMode);
  prefs.setString('dlDirectory', AppConfig.dlDirectory);
}

class Carousel extends StatefulWidget {
  final List<Widget> children;
  final CarouselListSize size;
  late final double _width, _height;
  @override
  State<Carousel> createState() => _CarouselState();

  Carousel(
      {super.key,
      required this.children,
      this.size = CarouselListSize.normal}) {
    switch (size) {
      case CarouselListSize.normal:
        _width = 285;
        _height = 265;
        break;
      case CarouselListSize.small:
        _width = 220;
        _height = 112 + 100;
        break;
      case CarouselListSize.tiny:
        _width = 180;
        _height = 90 + 100;
        break;
    }
  }
}

class _CarouselState extends State<Carousel> {
  final _controller = ScrollController();

  bool isChevronRightEnabled = true;
  bool isChevronLeftEnabled = false;

  @override
  Widget build(BuildContext context) {
    bool isChevronRightVisible = true;
    bool isChevronLeftVisible = true;

    return LayoutBuilder(builder: (context, constraints) {
      if (285 * widget.children.length < constraints.maxWidth) {
        isChevronLeftVisible = false;
        isChevronRightVisible = false;
      }
      const double chevronSize = 16.0;
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
                          double scrollWidth = widget._width;
                          while (scrollWidth + widget._width < box.size.width) {
                            scrollWidth += widget._width;
                          }
                          _controller.animateTo(
                              _controller.offset - scrollWidth,
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
                    padding: const EdgeInsets.all(chevronSize),
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
                          double scrollWidth = widget._width;
                          while (scrollWidth + widget._width < box.size.width) {
                            scrollWidth += widget._width;
                          }
                          _controller.animateTo(
                              _controller.offset + scrollWidth,
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
                    padding: const EdgeInsets.all(chevronSize),
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
  final List<dynamic> data;
  final CarouselListSize size;

  const CarouselList(
      {super.key, required this.data, this.size = CarouselListSize.normal});

  void _showDialogProgram(
      BuildContext context, List<VideoData> videos, int index) {
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
              elevation: 8.0,
              child: SizedBox(
                  width: min(MediaQuery.sizeOf(context).width, 650),
                  child: ShowDetail(videos: videos, index: index)));
        });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> thumbnails = [];

    //debugPrint('in CarouselList.build()');
    final List<dynamic> zones;
    if (data.isEmpty) {
      zones = [];
    } else {
      zones = data;
    }
    for (var z in zones) {
      List<VideoData> videos = z['videos'];
      thumbnails
          .add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text('${z['title']} (${videos.length})',
                style: Theme.of(context).textTheme.titleLarge)),
        Carousel(
            size: size,
            children: videos.map((v) {
              return InkWell(
                onLongPress: () {
                  _showDialogProgram(context, videos, videos.indexOf(v));
                },
                onDoubleTap: () {
                  _showDialogProgram(context, videos, videos.indexOf(v));
                },
                onTap: () {
                  StatefulWidget screen;
                  if (v.isCollection) {
                    screen = SerieScreen(
                        title: v.title,
                        url: v.url,
                        description: v.shortDescription != null
                            ? v.shortDescription!
                            : v.subtitle!);
                  } else {
                    screen = FullDetailScreen(
                        videos: videos,
                        index: videos.indexOf(v),
                        title: z['title']);
                  }
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => screen));
                },
                child: VideoCard(video: v, size: size, withDurationLabel: true),
              );
            }).toList())
      ]));
    }
    return SingleChildScrollView(
        // subtract NavigationRail width
        child: Container(
            width: MediaQuery.sizeOf(context).width,
            height: MediaQuery.sizeOf(context).height,
            padding: const EdgeInsets.all(10),
            child: thumbnails.isNotEmpty
                ? ListView.builder(
                    itemCount: thumbnails.length,
                    itemBuilder: (context, index) {
                      return thumbnails[index];
                    },
                  )
                : Center(
                    child: Text(
                        AppLocalizations.of(context)!.strNothingDisplay))));
  }
}

class CategoriesList extends StatefulWidget {
  final CategoriesListSize size;
  final TabController controller;
  final String lang;

  const CategoriesList(
      {super.key,
      required this.size,
      required this.controller,
      required this.lang});

  // WARNING: this should match the order of categories in _CategoriesListState
  static List<String> codes = [
    'HOME',
    'DOR',
    'SER',
    'CIN',
    'EMI',
    'HIS',
    'DEC',
    'SCI',
    'ACT',
    'CPO'
  ];

  @override
  State<CategoriesList> createState() => _CategoriesListState();
}

class _CategoriesListState extends State<CategoriesList> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    double padding = 8;
    if (MediaQuery.sizeOf(context).height < 720) {
      padding = 4;
      if (MediaQuery.sizeOf(context).height < 640) {
        padding = 0;
      }
    }

    List<Map<String, dynamic>> categories = [
      {
        'text': AppLocalizations.of(context)!.strHOME,
        'color': [124, 124, 124],
        'code': 'HOME'
      },
      {
        'text': AppLocalizations.of(context)!.strDOR,
        'color': [225, 143, 71],
        'code': 'DOR'
      },
      {
        'text': AppLocalizations.of(context)!.strSER,
        'color': [0, 230, 227],
        'code': 'SER',
      },
      {
        'text': AppLocalizations.of(context)!.strCIN,
        'color': [254, 0, 0],
        'code': 'CIN',
      },
      {
        'text': AppLocalizations.of(context)!.strEMI,
        'color': [109, 255, 115],
        'code': 'EMI',
      },
      {
        'text': AppLocalizations.of(context)!.strHIS,
        'color': [254, 184, 0],
        'code': 'HIS',
      },
      {
        'text': AppLocalizations.of(context)!.strDEC,
        'color': [0, 199, 122],
        'code': 'DEC',
      },
      {
        'text': AppLocalizations.of(context)!.strSCI,
        'color': [239, 1, 89],
        'code': 'SCI',
      },
      {
        'text': AppLocalizations.of(context)!.strACT,
        'color': [1, 121, 218],
        'code': 'ACT',
      },
      {
        'text': AppLocalizations.of(context)!.strCPO,
        'color': [208, 73, 244],
        'code': 'CPO',
      }
    ];

    return ListView.builder(
      //padding: const EdgeInsets.symmetric(vertical: 10),
      shrinkWrap: true,
      semanticChildCount: categories.length,
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final c = categories[index];
        String text = c['text'];
        Widget avatar = SizedBox(
            child: Container(
                width: 32,
                padding: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        width: widget.size == CategoriesListSize.tiny ? 4 : 2,
                        strokeAlign: BorderSide.strokeAlignOutside,
                        color: index == selectedIndex
                            ? Colors.deepOrange
                            : Theme.of(context).canvasColor)),
                child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Color.fromARGB(
                        255, c['color'][0], c['color'][1], c['color'][2]),
                    child: Text(text.substring(0, 1),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .inversePrimary)))));
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
        return Material(
            child: ListTile(
          selected: index == selectedIndex,
          leading: leading,
          onTap: () async {
            setState(() {
              selectedIndex = index;
              widget.controller.animateTo(index);
            });
            final cache = Provider.of<Cache>(context, listen: false);
            cache.fetch(c['code'], widget.lang);
          },
          minLeadingWidth: 30,
          contentPadding:
              EdgeInsets.only(left: 20, top: padding, bottom: padding),
          title: title,
        ));
      },
    );
  }
}

class ZoneList extends StatefulWidget {
  final List<dynamic> data;
  final CarouselListSize size;
  final List<dynamic> _zones = [];

  ZoneList(
      {super.key, required this.data, this.size = CarouselListSize.normal}) {
    _zones.addAll(data);
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
      return Center(child: Text(AppLocalizations.of(context)!.strFetching));
    }
    return Row(mainAxisSize: MainAxisSize.max, children: [
      Expanded(
          flex: 1,
          child: Container(
              height: MediaQuery.sizeOf(context).height,
              child: ListView.builder(
                //padding: const EdgeInsets.symmetric(vertical: 10),
                semanticChildCount: widget._zones.length,
                itemCount: widget._zones.length,
                itemBuilder: (context, index) {
                  if (widget._zones.isNotEmpty) {
                    return ListTile(
                        selectedTileColor:
                            Theme.of(context).listTileTheme.selectedTileColor,
                        selected: index == selectedZoneIndex,
                        onTap: () {
                          setState(() {
                            selectedZoneIndex = index;
                          });
                        },
                        title: Text(
                          '${widget._zones[index]['title']} (${widget._zones[index]['videos'].length})',
                          softWrap: true,
                        ));
                  } else {
                    return null;
                  }
                },
              ))),
      Expanded(
          flex: 2,
          child: ShowList(
              key: Key('$selectedZoneIndex'),
              videos: widget._zones.isNotEmpty
                  ? widget._zones[selectedZoneIndex]['videos']
                  : [])),
    ]);
  }
}

class ShowList extends StatefulWidget {
  final List<VideoData> videos;

  const ShowList({super.key, required this.videos});

  @override
  State<ShowList> createState() => _ShowListState();
}

class _ShowListState extends State<ShowList> {
  int selectedShowIndex = -1;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    selectedShowIndex = -1;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
          flex: 1,
          child: ListView.builder(
              itemCount: widget.videos.length,
              itemBuilder: (context, index) {
                return ListTile(
                  selectedTileColor:
                      Theme.of(context).listTileTheme.selectedTileColor,
                  selected: index == selectedShowIndex,
                  title: Text(widget.videos[index].title),
                  subtitle: (widget.videos[index].subtitle != null)
                      ? Text(widget.videos[index].subtitle!)
                      : null,
                  onTap: () {
                    setState(() {
                      selectedShowIndex = index;
                    });
                  },
                );
              })),
      Expanded(
          flex: 1,
          child: selectedShowIndex != -1
              ? SingleChildScrollView(
                  child: ShowDetail(
                      key: ValueKey(selectedShowIndex),
                      videos: widget.videos,
                      index: selectedShowIndex,
                      imageTop: true))
              : const SizedBox.shrink())
    ]);
  }
}
