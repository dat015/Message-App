import 'package:flutter/foundation.dart' show kIsWeb;

class Config {
  static const String serverIp = '192.168.1.11';
  static const String serverPort = '5053';
  static const String apiPrefix = 'api';

  static String get baseUrl {
    final String host = kIsWeb ? 'localhost' : serverIp;
    final String protocol = kIsWeb ? 'http' : 'http';

    return '$protocol://$host:$serverPort/';
  }

  static String get baseUrlWS {
    final String host = kIsWeb ? 'localhost' : serverIp;
    final String protocol = kIsWeb ? 'ws' : 'ws';

    return '$protocol://$host:$serverPort/ws';
  }
}