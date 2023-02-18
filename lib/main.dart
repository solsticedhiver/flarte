import 'package:cached_network_image/cached_network_image.dart';
import 'package:flarte/api.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flarte',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
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

class _MyHomePageState extends State<MyHomePage> {
  final Future<Map<String, dynamic>> _home = fetchUrl(urlHOME);
  int _selectedIndex = 0;

  Widget _buildScreen(int screen) {
    switch (screen) {
      case 0:
        return FutureBuilder(
            future: _home,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return CarouselList(data: snapshot.data!);
              } else {
                return const SizedBox(width: 555);
              }
            });
      case 1:
        return SingleChildScrollView(
            child: SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width - 100,
                child: Row(children: [
                  SizedBox(
                      width: 350,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        semanticChildCount: 9,
                        children: categories.map((c) {
                          return ListTile(
                            leading: CircleAvatar(
                                backgroundColor: Color.fromARGB(
                                    255,
                                    c['color'][0],
                                    c['color'][1],
                                    c['color'][2]),
                                child: Text(c['text'].substring(0, 1),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .inversePrimary))),
                            onTap: () async {
                              String url =
                                  "https://www.arte.tv/api/rproxy/emac/v4/fr/web/pages/${c['code']}/";
                              final resp = await fetchUrl(url);
                            },
                            contentPadding: const EdgeInsets.only(
                                left: 15, top: 10, bottom: 10),
                            title: Text(c['text']),
                          );
                        }).toList(),
                      ))
                ])));
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: const Drawer(),
      body: Row(children: [
        NavigationRail(
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                  icon: Icon(Icons.category_outlined),
                  selectedIcon: Icon(Icons.category),
                  label: Text(
                    'Catégories',
                  )),
            ],
            selectedIndex: _selectedIndex),
        Center(child: _buildScreen(_selectedIndex))
      ]),
    );
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
            height: 240,
            child: ListView(
              controller: _controller,
              prototypeItem: const SizedBox(width: 285, height: 230),
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
  final Map<String, dynamic> data;

  const CarouselList({super.key, required this.data});

  void _showDialogProgram(
      BuildContext bcontext, Map<String, dynamic> v, String imageUrl) {
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
                                child: v['shortDescription'] != null
                                    ? Text(v['shortDescription'],
                                        maxLines: 16,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(bcontext)
                                            .textTheme
                                            .bodyMedium)
                                    : const SizedBox.shrink()),
                          ],
                        )
                      ])));
        });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> thumbnails = [];
    List<dynamic> videos = [];

    //debugPrint('in CarouselList.build()');
    final zones = data['value']['zones'];
    for (var z in zones) {
      videos = z['content']['data'];
      if (videos.isEmpty ||
          z['title'].contains('event') ||
          z['code'] == 'highlights_HOME' ||
          z['title'] == "Parcourir toute l'offre" ||
          z['title'].startsWith('ARTE ')) {
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
            width: MediaQuery.of(context).size.width - 100,
            color: Colors.grey[100],
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: thumbnails,
            )));
  }
}
