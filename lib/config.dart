import 'package:flarte/api.dart';

class AppConfig {
  static const String name = 'Flarte';
  static const String version = '0.1.0';
  static const String url = 'https://github.com/solsticedhiver/flarte';
  //static String lang = 'fr';
  static PlayerTypeName player = PlayerTypeName.embedded;
  static String userAgent = '${name.replaceAll(' ', '')}/$version +$url';
}
