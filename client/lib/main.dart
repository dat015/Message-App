import 'package:first_app/features/auth/presentation/screens/login.dart';
import 'package:first_app/features/auth/presentation/screens/welcomScreen.dart';
import 'package:first_app/features/home/presentation/screens/home_screen.dart';
import 'package:first_app/features/home/presentation/chat_box/chat.dart';
import 'package:first_app/features/auth/presentation/screens/change_password.dart';
import 'package:first_app/features/auth/presentation/screens/forget_password.dart';
import 'package:first_app/features/auth/presentation/screens/login.dart'; // SignInScreen
import 'package:first_app/features/auth/presentation/screens/otps_form.dart'; // Otp
import 'package:first_app/features/auth/presentation/screens/register.dart';
import 'package:first_app/theme/theme.dart';
import 'package:flutter/material.dart';

import 'features/routes/routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login, // Route mặc định là HomeScreen
      onGenerateRoute: AppRoutes.generateRoute, // Định nghĩa route động
      title: 'Flutter Demo',
      theme: lightMode,
      home: const SignInScreen(),
    );
  }
}