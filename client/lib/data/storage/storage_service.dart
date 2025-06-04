import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;

class StorageService {
  static Future<void> saveUserData(String key, Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);

    if (kIsWeb) {
      // Lưu vào localStorage của trình duyệt
      html.window.localStorage[key] = jsonString;
    } else {
      // Lưu vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonString);
    }
  }

  static Future<Map<String, dynamic>?> getUserData(String key) async {
    String? jsonString;

    if (kIsWeb) {
      jsonString = html.window.localStorage[key];
    } else {
      final prefs = await SharedPreferences.getInstance();
      jsonString = prefs.getString(key);
    }

    if (jsonString == null) return null;
    return jsonDecode(jsonString);
  }

  static Future<String?> getToken() async {
    final userData = await getUserData("user_data");
    return userData?["token"];
  }

  static Future<void> clearUserData(String key) async {
    if (kIsWeb) {
      html.window.localStorage.remove(key);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    }
  }
}