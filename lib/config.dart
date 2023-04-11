import 'package:flarte/api.dart';

class AppConfig {
  static const String name = 'Flarte';
  static const String version = '0.1.1';
  static const String url = 'https://github.com/solsticedhiver/flarte';
  static PlayerTypeName player = PlayerTypeName.embedded;
  // index of resolution, usually 0=>216p, 1=>360p, 2=>432p, 3=> 720p, 4=> 1080p
  static int playerIndexQuality = 2;
  static String userAgent = '${name.replaceAll(' ', '')}/$version +$url';
}
