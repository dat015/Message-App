import 'package:first_app/features/auth/presentation/screens/change_password.dart';
import 'package:first_app/features/auth/presentation/screens/forget_password.dart';
import 'package:first_app/features/auth/presentation/screens/login.dart'; // SignInScreen
import 'package:first_app/features/auth/presentation/screens/otps_form.dart'; // Otp
import 'package:first_app/features/auth/presentation/screens/register.dart';
import 'package:first_app/theme/theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: lightMode,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const SignInScreen(),
        '/register': (context) => const SignUpScreen(),
        '/forget-password': (context) => const ForgetPassword(),
        '/otp': (context) => Otp(email: ModalRoute.of(context)!.settings.arguments as String),
        '/change-password': (context) => ChangePassword(email: ModalRoute.of(context)!.settings.arguments as String), 
      },
    );
  }
}