import 'package:first_app/data/dto/login_response.dart';
import 'package:first_app/features/auth/presentation/screens/login.dart';
import 'package:first_app/features/auth/presentation/screens/register.dart';
import 'package:first_app/features/home/presentation/chat_box/chat.dart';
import 'package:first_app/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'navigation_helper.dart'; // Import NavigationHelper

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String chat = '/chat';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        debugPrint("Received arguments for home: ${settings.arguments}");
        if (settings.arguments is LoginResponse) {
          final user = settings.arguments as LoginResponse;
          return MaterialPageRoute(builder: (_) => HomeScreen(user: user));
        }
        debugPrint("Error: HomeScreen did not receive LoginResponse");
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Lỗi: Không có dữ liệu đăng nhập')),
          ),
        );

      case chat:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null || args['conversationId'] == null || args['user_id'] == null) {
          debugPrint("Error: Missing required arguments for ChatScreen");
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Lỗi: Thiếu tham số cuộc trò chuyện hoặc người dùng'),
              ),
            ),
          );
        }
        if (args['conversationId'] is! int || args['user_id'] is! int) {
          debugPrint("Error: Invalid argument types for ChatScreen");
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Lỗi: Tham số không đúng kiểu dữ liệu'),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: args['conversationId'] as int,
            userId: args['user_id'] as int,
          ),
        );

      case login:
        return MaterialPageRoute(builder: (_) => SignInScreen());

      case register:
        return MaterialPageRoute(builder: (_) => SignUpScreen());

      default:
        debugPrint("Unknown route: ${settings.name}");
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Không tìm thấy trang: ${settings.name}'),
            ),
          ),
        );
    }
  }
}