import 'package:first_app/features/auth/presentation/screens/login.dart';
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
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.generateRoute,
      title: 'Flutter Demo',
      theme: lightMode,
      home: const SignInScreen(),
    );
  }
}