import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;

class StorageService {
  static Future<void> saveUserData(String key, Map<String, dynamic> value) async {
    String jsonString = jsonEncode(value);

    if (kIsWeb) {
      // 🌐 Web: Lưu vào localStorage
      html.window.localStorage[key] = jsonString;
    } else {
      // 📱 Mobile: Lưu vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonString);
    }
  }

  static Future<Map<String, dynamic>?> getUserData(String key) async {
    String? jsonString;

    if (kIsWeb) {
      // 🌐 Web: Lấy dữ liệu từ localStorage
      jsonString = html.window.localStorage[key];
    } else {
      // 📱 Mobile: Lấy dữ liệu từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      jsonString = prefs.getString(key);
    }

    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return null;
  }

  static Future<void> clearUserData(String key) async {
    if (kIsWeb) {
      // 🌐 Web: Xóa localStorage
      html.window.localStorage.remove(key);
    } else {
      // 📱 Mobile: Xóa SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    }
  }
}
