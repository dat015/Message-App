import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class Config {
  static  String get baseUrl {
    if (kIsWeb) {
      // Web
      return  'http://localhost:5053/';
    } else if (Platform.isAndroid) {
      // Android emulator
      return 'http://10.0.2.2:5053/';
    } else {
      // Các nền tảng khác (iOS, macOS, v.v.)
      return 'http://localhost:5053/';
    }
  }
   static String get redisConnectionString {
    if (kIsWeb) {
      // Web kết nối Redis qua Backend
      return 'localhost:6379,abortConnect=false';
    } else if (Platform.isAndroid) {
      // Android Emulator cần đổi `localhost` thành `10.0.2.2`
      return '10.0.2.2:6379,abortConnect=false';
    } else {
      // Các nền tảng khác (iOS, macOS, Windows,...)
      return 'localhost:6379,abortConnect=false';
    }
  }

  static String get baseUrlWS {
    if (kIsWeb) {
      // Web
      return 'ws://localhost:5053/ws';
    } else if (Platform.isAndroid) {
      // Android emulator
      return 'ws://10.0.2.2:5053/ws';
    } else {
      // Các nền tảng khác (iOS, macOS, v.v.)
      return 'ws://localhost:5053/ws';
    }

  }

}