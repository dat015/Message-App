import 'package:first_app/data/dto/login_response.dart';
import 'package:first_app/features/auth/presentation/screens/login.dart';
import 'package:first_app/features/auth/presentation/screens/register.dart';
import 'package:flutter/material.dart';

import '../home/presentation/chat_box/chat.dart';
import '../home/presentation/screens/home_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String chat = '/chat';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        print("Received arguments: ${settings.arguments}");
        if (settings.arguments is LoginResponse) {
          final user = settings.arguments as LoginResponse;
          return MaterialPageRoute(builder: (_) => HomeScreen(user: user));
        } else {
          print("Error: HomeScreen did not receive LoginResponse");
          return MaterialPageRoute(
            builder:
                (_) => Scaffold(
                  body: Center(child: Text('Lỗi: Không có dữ liệu đăng nhập')),
                ),
          );
        }

      case chat:
        final int conversationId =
            settings.arguments as int; // Lấy ID từ arguments
        final int user_id = 
            settings.arguments as int;
        return MaterialPageRoute(
          builder:
              (_) => ChatScreen(
                conversationId: conversationId,
                user_id : user_id
              ), // Truyền đúng tham số
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => SignInScreen(),
        ); 

      case register:
        return MaterialPageRoute(
          builder: (_) => SignUpScreen(),
        ); 

      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('Không tìm thấy trang: ${settings.name}'),
                ),
              ),
        );
    }
  }
}
