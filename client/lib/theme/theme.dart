import 'package:flutter/material.dart';

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF416FDF),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFF6EAEE7),
  onSecondary: Color(0xFFFFFFFF),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  background: Color(0xFFFCFDF6),
  onBackground: Color(0xFF1A1C18),
  shadow: Color(0xFF000000),
  outlineVariant: Color(0xFFC2C8BC),
  surface: Color(0xFFF9FAF3),
  onSurface: Color(0xFF1A1C18),
);

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF6B9EFF), // Làm sáng nhẹ màu chính để nổi bật hơn
  onPrimary: Color(0xFF1A2C5A), // Màu tối hơn (xanh đậm) cho chữ trên primary
  secondary: Color(0xFF8CC4FF), // Làm sáng nhẹ màu phụ
  onSecondary: Color(0xFF1A3C6E), // Màu tối hơn (xanh nhạt đậm) cho chữ trên secondary
  error: Color(0xFFFF6B6B), // Làm sáng nhẹ màu lỗi để nổi bật
  onError: Color(0xFF3D0000), // Màu đỏ đậm cho chữ trên nền lỗi
  background: Color(0xFF1A1C18), // Nền tối (đen xám đậm)
  onBackground: Color(0xFFE0E3DB), // Màu xám nhạt cho chữ trên nền
  shadow: Color(0xFF000000), // Giữ nguyên màu bóng đen
  outlineVariant: Color(0xFF44483F), // Xám đậm hơn cho viền phụ
  surface: Color(0xFF252722), // Bề mặt tối (xám xanh đậm nhạt)
  onSurface: Color(0xFFE0E3DB), // Màu xám nhạt cho chữ trên bề mặt
);

ThemeData lightMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: lightColorScheme,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(
        lightColorScheme.primary, // Slightly darker shade for the button
      ),
      foregroundColor:
          MaterialStateProperty.all<Color>(Colors.white), // text color
      elevation: MaterialStateProperty.all<double>(5.0), // shadow
      padding: MaterialStateProperty.all<EdgeInsets>(
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Adjust as needed
        ),
      ),
    ),
  ),
);

ThemeData darkMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: darkColorScheme,
);