import 'dart:io';

import 'package:flarte/helpers.dart';
import 'package:xdg_directories/xdg_directories.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class AppConfig {
  static const String name = 'Flarte';
  static const String version = '0.3.1';
  static const String commit = 'ffe83c8';
  static const String url = 'https://github.com/solsticedhiver/flarte';
  static PlayerTypeName player = PlayerTypeName.embedded;
  // index of resolution, usually 0=>216p, 1=>360p, 2=>432p, 3=> 720p, 4=> 1080p
  static int playerIndexQuality = 2;
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
