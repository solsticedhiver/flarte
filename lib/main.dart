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
      home: const MyHomePage(title: 'Flarte'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Future<Map<String, dynamic>> _home = fetchHome();

  void _showDialogProgram(
      BuildContext bcontext, Map<String, dynamic> v, String imageUrl) {
    showDialog(
        context: bcontext,
        builder: (bcontext) {
          return Dialog(
              child: Container(
                  padding: const EdgeInsets.all(15),
                  width: 600,
                  height: 420,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                        style: Theme.of(bcontext)
                                            .textTheme
                                            .bodyMedium)
                                    : const SizedBox.shrink()),
                          ],
                        )
                      ])));
        });
  }

  List<Widget> _buildCarouselList(Map<String, dynamic> data) {
    List<Widget> thumbnails = [];
    final zones = data['value']['zones'];
    List<dynamic> videos = [];

    for (var z in zones) {
      videos = z['content']['data'];
      if (videos.isEmpty ||
          z['title'].contains('event') ||
          z['code'] == 'highlights_HOME' ||
          z['code'] == 'cbde5425-226c-4638-b9f6-6847e509db7f') {
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
        return SizedBox(
            height: 230,
            width: 295,
            child: InkWell(
                onTap: () {
                  _showDialogProgram(context, v, imageUrl);
                },
                child: Card(
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Image(
                                image: CachedNetworkImageProvider(imageUrl),
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
                            ]))))));
      }).toList()));
    }
    return thumbnails;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Row(children: [
        NavigationRail(
            labelType: NavigationRailLabelType.all,
            destinations: [
              const NavigationRailDestination(
                  icon: const Icon(Icons.home), label: const Text('Home')),
              const NavigationRailDestination(
                  icon: const Icon(Icons.category),
                  label: const Text(
                    'Catégories',
                  )),
            ],
            selectedIndex: 0),
        Center(
            child: FutureBuilder(
                future: _home,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final thumbnails = _buildCarouselList(snapshot.data!);
                    return SingleChildScrollView(
                        child: Container(
                            color: Colors.grey[100],
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: thumbnails,
                            )));
                  } else {
                    return const SizedBox(width: 5555);
                  }
                }))
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
  bool isChevronLeftVisible = false;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      SizedBox(
          height: 230,
          width: MediaQuery.of(context).size.width - 120,
          child: ListView(
            controller: _controller,
            prototypeItem: const SizedBox(width: 285, height: 230),
            scrollDirection: Axis.horizontal,
            children: widget.children,
          )),
      Positioned(
          left: 5,
          top: 65,
          child: ElevatedButton(
            onPressed: !isChevronLeftVisible
                ? null
                : () {
                    final box = context.findRenderObject() as RenderBox;
                    _controller.animateTo(_controller.offset - box.size.width,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut);
                    setState(() {
                      if (_controller.offset <
                          _controller.position.viewportDimension) {
                        isChevronLeftVisible = false;
                      }
                      isChevronRightVisible = true;
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
          )),
      Positioned(
          right: 5,
          top: 65,
          child: ElevatedButton(
            onPressed: !isChevronRightVisible
                ? null
                : () {
                    final box = context.findRenderObject() as RenderBox;
                    _controller.animateTo(_controller.offset + box.size.width,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut);
                    setState(() {
                      if (_controller.offset >=
                          _controller.position.maxScrollExtent -
                              _controller.position.viewportDimension) {
                        isChevronRightVisible = false;
                      }
                      isChevronLeftVisible = true;
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
          )),
    ]);
  }
}
