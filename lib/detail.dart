import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flarte/controls.dart';
import 'package:flarte/fulldetail.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:process/process.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';

import 'helpers.dart';
import 'config.dart';
import 'serie.dart';
import 'player.dart';

class ShowDetail extends StatefulWidget {
  final VideoData video;
  final bool imageTop;

  @override
  State<ShowDetail> createState() => _ShowDetailState();

  const ShowDetail({super.key, required this.video, this.imageTop = false});
}

class _ShowDetailState extends State<ShowDetail> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //debugPrint(widget.video.srcJson);

    final imageUrl = widget.video.imageUrl ?? '';
    return Container(
        padding: const EdgeInsets.all(15),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.video.title,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              widget.video.subtitle != null
                  ? Text(
                      widget.video.subtitle!,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    )
                  : const SizedBox.shrink(),
              if (widget.imageTop) ...[
                const SizedBox(height: 15),
                Image(
                  width: 400,
                  height: 225,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(width: 400, height: 225),
                  image: CachedNetworkImageProvider(imageUrl,
                      headers: {'User-Agent': AppConfig.userAgent}),
                )
              ],
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!widget.imageTop) ...[
                    Image(
                      width: 200,
                      height: 300,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(width: 200, height: 300),
                      image: CachedNetworkImageProvider(
                          '${imageUrl.replaceFirst('400x225', '300x450')}?type=TEXT',
                          headers: {'User-Agent': AppConfig.userAgent}),
                    )
                  ],
                  const SizedBox(width: 15),
                  Flexible(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          widget.video.shortDescription != null
                              ? Text(
                                  widget.video.shortDescription!.replaceAll(
                                      RegExp('\u{00a0}+'), '\u{00a0}'),
                                  maxLines: 16,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium)
                              : const SizedBox.shrink(),
                          const SizedBox(height: 10),
                          Row(children: [
                            if (widget.video.label != null) ...[
                              Chip(
                                backgroundColor: Theme.of(context).primaryColor,
                                label: Text(widget.video.label!),
                              )
                            ],
                            const SizedBox(width: 10),
                            if (!widget.video.isCollection &&
                                widget.video.durationLabel != null)
                              Chip(
                                backgroundColor: Theme.of(context).primaryColor,
                                label: Text(widget.video.durationLabel!),
                              ),
                          ]),
                          const SizedBox(height: 10),
                          widget.video.isCollection
                              ? const SizedBox.shrink()
                              : VideoButtons(
                                  video: widget.video,
                                  oneLine: false,
                                  withFullDetailButton: true),
                          widget.video.isCollection
                              ? TextButton(
                                  onPressed: () {
                                    if (!widget.imageTop) {
                                      Navigator.pop(context);
                                    }
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => SerieScreen(
                                                title: widget.video.title,
                                                url: widget.video.url)));
                                  },
                                  child: Text(AppLocalizations.of(context)!
                                      .strEpisodes),
                                )
                              : const SizedBox.shrink(),
                          if (!widget.imageTop) ...[
                            const SizedBox(height: 10),
                            Row(children: [
                              const Expanded(
                                  flex: 1, child: SizedBox(height: 10)),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                    AppLocalizations.of(context)!.strClose),
                              )
                            ])
                          ],
                        ]),
                  )
                ],
              ),
            ]));
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context)!.strCopiedClipboard,
          style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.black87,
      behavior: SnackBarBehavior.floating,
    ));
  }
}
