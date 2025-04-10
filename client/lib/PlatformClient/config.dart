import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class Config {
  // Địa chỉ IP của máy tính trong mạng LAN
  static const String localNetworkIP = '192.168.1.23'; // 👈 sửa IP ở đây nếu thay đổi

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5053/';
    } else if (Platform.isAndroid) {
      // Nếu là Android Emulator thì dùng 10.0.2.2
      // Nếu là thiết bị thật thì dùng IP LAN
      return _isPhysicalDevice()
          ? 'http://$localNetworkIP:5053/' // 👈 Điện thoại thật
          : 'http://10.0.2.2:5053/';       // 👈 Emulator
    } else if (Platform.isWindows) {
      return 'http://localhost:5053/';
    } else {
      return 'http://localhost:5053/';
    }
  }

  static String get redisConnectionString {
    if (kIsWeb) {
      return 'localhost:6379,abortConnect=false';
    } else if (Platform.isAndroid) {
      return _isPhysicalDevice()
          ? '$localNetworkIP:6379,abortConnect=false'
          : '10.0.2.2:6379,abortConnect=false';
    } else {
      return 'localhost:6379,abortConnect=false';
    }
  }
   

  static String get baseUrlWS {
    if (kIsWeb) {
      return 'ws://localhost:5053/ws/chat';
    } else if (Platform.isAndroid) {
      return _isPhysicalDevice()
          ? 'ws://$localNetworkIP:5053/ws/chat'
          : 'ws://10.0.2.2:5053/ws/chat';
    } else {
      return 'ws://localhost:5053/ws/chat';
    }
  }
    static String get baseUrlWSFriend {
    if (kIsWeb) {
      return 'ws://localhost:5053/ws/friend';
    } else if (Platform.isAndroid) {
      return _isPhysicalDevice()
          ? 'ws://$localNetworkIP:5053/ws/friend'
          : 'ws://10.0.2.2:5053/ws/friend'; 
    } else {
      return 'ws://localhost:5053/ws/friend';
    }
  }

  // Hàm tạm kiểm tra thiết bị thật (physical) hay emulator
  static bool _isPhysicalDevice() {
    // Hiện tại Flutter không có cách native 100% xác định Android Emulator trong dart:io
    // Bạn có thể tạm dùng biến môi trường hoặc `bool.fromEnvironment()` nếu muốn tùy biến
    // Hoặc cấu hình thông qua file .env nếu phức tạp hơn
    return const bool.fromEnvironment('IS_PHYSICAL_DEVICE', defaultValue: true);
  }
}
