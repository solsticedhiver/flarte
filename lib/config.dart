import 'dart:io';

import 'package:flarte/helpers.dart';
import 'package:xdg_directories/xdg_directories.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

// index of resolution, usually 0=>216p, 1=>360p, 2=>432p, 3=> 720p, 4=> 1080p
enum PlayerQuality {
  r216p(name: '216p'),
  r360p(name: '360p'),
  r432p(name: '432p'),
  r720p(name: '720p'),
  r1080p(name: '1080p');

  const PlayerQuality({required this.name});

  final String name;
}

class AppConfig {
  static const String name = 'Flarte';
  static const String version = '0.3.5';
  static const String commit = 'HEAD/main';
  static const String url = 'https://github.com/solsticedhiver/flarte';
  static PlayerTypeName player = PlayerTypeName.embedded;
  static PlayerQuality playerQuality = PlayerQuality.r432p;
  static String userAgent = '${name.replaceAll(' ', '')}/$version +$url';
  static String _dlDirectory = '';
  static bool textMode = false;

  static set dlDirectory(String dl) {
    _dlDirectory = dl;
  }

  static String get dlDirectory {
    if (_dlDirectory.isNotEmpty) {
      return _dlDirectory;
    }
    String dlD = '';

    if (kIsWeb) return '';
    if (Platform.isLinux) {
      Directory? downloadDir = getUserDirectory('DOWNLOAD');
      if (downloadDir == null) {
        dlD = const String.fromEnvironment('HOME');
      } else {
        dlD = downloadDir.path;
      }
    } else if (Platform.isWindows) {
      // download to %USERPORFILE%\Downloads
      dlD = path.join(Platform.environment['USERPROFILE']!, 'Downloads');
    }
    debugPrint('workingDirectory: $dlD');
    return dlD;
  }
}
