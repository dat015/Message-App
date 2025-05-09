import 'package:first_app/data/dto/login_response.dart';
import 'package:first_app/data/dto/message_response.dart';
import 'package:first_app/data/repositories/Chat/websocket_service.dart';
import 'package:first_app/features/auth/presentation/screens/login.dart';
import 'package:first_app/features/auth/presentation/screens/register.dart';
import 'package:first_app/features/home/presentation/chat_box/chat.dart';
import 'package:first_app/features/home/presentation/screens/home_screen/home_screen.dart';
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
            builder:
                (_) => const Scaffold(
                  body: Center(child: Text('Lỗi: Không có dữ liệu đăng nhập')),
                ),
          );
        }

      // Route cho trang chat
      case chat:
        final args = settings.arguments as Map<String, dynamic>?;

        // Kiểm tra các tham số bắt buộc
        if (args == null ||
            args['conversationId'] == null ||
            args['user_id'] == null ||
            args['websocketService'] == null) {
          print("Error: Missing required arguments for ChatScreen");
          return MaterialPageRoute(
            builder:
                (_) => const Scaffold(
                  body: Center(
                    child: Text(
                      'Lỗi: Thiếu tham số cuộc trò chuyện hoặc người dùng',
                    ),
                  ),
                ),
          );
        }

        // Kiểm tra kiểu dữ liệu
        if (args['conversationId'] is! int ||
            args['user_id'] is! int ||
            args['websocketService'] is! WebSocketService) {
          print("Error: Invalid argument types for ChatScreen");
          return MaterialPageRoute(
            builder:
                (_) => const Scaffold(
                  body: Center(
                    child: Text('Lỗi: Tham số không đúng kiểu dữ liệu'),
                  ),
                ),
          );
        }

        // Lấy participantId nếu có
        final participantId = args['participantId'] as int?;

        // Lấy updateChatListCallback nếu có
        final updateChatListCallback =
            args['updateChatListCallback'] is Function
                ? args['updateChatListCallback']
                    as Function(MessageWithAttachment)?
                : null;
        final onConversationRemoved = 
            args['onConversationRemoved'] is Function
                ? args['onConversationRemoved']
                    as Function(int)?
                : null;

        // Trả về màn hình ChatScreen
        return MaterialPageRoute(
          builder:
              (_) => ChatScreen(
                conversationId: args['conversationId'] as int,
                userId: args['user_id'] as int,
                participantId: participantId,
                websocketService: args['websocketService'] as WebSocketService,
                updateChatListCallback: updateChatListCallback,
                onConversationRemoved: onConversationRemoved,
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
