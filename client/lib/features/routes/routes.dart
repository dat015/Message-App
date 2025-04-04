import 'package:first_app/data/dto/login_response.dart';
import 'package:first_app/features/auth/presentation/screens/login.dart';
import 'package:first_app/features/auth/presentation/screens/register.dart';
import 'package:first_app/features/home/presentation/chat_box/chat.dart';
import 'package:first_app/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';

// Quản lý các route trong ứng dụng
class AppRoutes {
  // Định nghĩa các route dưới dạng constant
  static const String home = '/'; // Trang chủ
  static const String login = '/login'; // Trang đăng nhập
  static const String register = '/register'; // Trang đăng ký
  static const String chat = '/chat'; // Trang chat

  // Hàm tạo route động dựa trên RouteSettings
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Route cho trang chủ
      case home:
        print("Received arguments for home: ${settings.arguments}");
        // Kiểm tra xem arguments có phải là LoginResponse không
        if (settings.arguments is LoginResponse) {
          final user = settings.arguments as LoginResponse;
          return MaterialPageRoute(builder: (_) => HomeScreen(user: user));
        } else {
          // Xử lý lỗi nếu không nhận được LoginResponse
          print("Error: HomeScreen did not receive LoginResponse");
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Lỗi: Không có dữ liệu đăng nhập')),
            ),
          );
        }

      // Route cho trang chat
      case chat:
        // Lấy arguments dưới dạng Map<String, dynamic>
        final args = settings.arguments as Map<String, dynamic>?;
        
        // Kiểm tra xem arguments có null hoặc thiếu dữ liệu không
        if (args == null || args['conversationId'] == null || args['user_id'] == null) {
          print("Error: Missing required arguments for ChatScreen");
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Lỗi: Thiếu tham số cuộc trò chuyện hoặc người dùng'),
              ),
            ),
          );
        }

        // Kiểm tra kiểu dữ liệu của conversationId và user_id
        if (args['conversationId'] is! int || args['user_id'] is! int) {
          print("Error: Invalid argument types for ChatScreen");
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Lỗi: Tham số không đúng kiểu dữ liệu'),
              ),
            ),
          );
        }

        // Tạo route cho ChatScreen với các tham số hợp lệ
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: args['conversationId'] as int,
            userId: args['user_id'] as int
          ),
        );

      // Route cho trang đăng nhập
      case login:
        return MaterialPageRoute(builder: (_) => SignInScreen());

      // Route cho trang đăng ký
      case register:
        return MaterialPageRoute(builder: (_) => SignUpScreen());

      // Route mặc định cho trường hợp không khớp
      default:
        print("Unknown route: ${settings.name}");
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