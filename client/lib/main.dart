import 'package:first_app/features/auth/presentation/screens/login.dart';
import 'package:first_app/features/auth/presentation/screens/welcomScreen.dart';
import 'package:first_app/features/home/presentation/screens/home_screen.dart';
import 'package:first_app/features/home/presentation/chat_box/chat.dart';
import 'package:first_app/theme/theme.dart';
import 'package:flutter/material.dart';

import 'features/routes/routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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