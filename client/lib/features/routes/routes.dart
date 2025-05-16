import 'package:first_app/data/dto/friend_dto.dart';
import 'package:first_app/data/dto/login_response.dart';
import 'package:first_app/data/dto/message_response.dart';
import 'package:first_app/data/repositories/Chat/websocket_service.dart';
import 'package:first_app/data/repositories/Conversations_repo/conversations_repository.dart';
import 'package:first_app/features/auth/presentation/screens/login.dart';
import 'package:first_app/features/auth/presentation/screens/register.dart';
import 'package:first_app/features/home/presentation/chat_box/chat.dart';
import 'package:first_app/features/home/presentation/screens/home_screen/CreateGroupScreen.dart';
import 'package:first_app/features/home/presentation/screens/home_screen/home_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String chat = '/chat';
  static const String createGroup = '/create_group'; // Route mới

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        debugPrint("Received arguments for home: ${settings.arguments}");
        if (settings.arguments is LoginResponse) {
          final user = settings.arguments as LoginResponse;
          return MaterialPageRoute(builder: (_) => HomeScreen(user: user));
        } else {
          debugPrint("Error: HomeScreen did not receive LoginResponse");
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Lỗi: Không có dữ liệu đăng nhập')),
            ),
          );
        }

      case chat:
        final args = settings.arguments as Map<String, dynamic>?;

        if (args == null ||
            args['conversationId'] == null ||
            args['user_id'] == null ||
            args['websocketService'] == null) {
          debugPrint("Error: Missing required arguments for ChatScreen");
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text(
                  'Lỗi: Thiếu tham số cuộc trò chuyện hoặc người dùng',
                ),
              ),
            ),
          );
        }

        if (args['conversationId'] is! int ||
            args['user_id'] is! int ||
            args['websocketService'] is! WebSocketService) {
          debugPrint("Error: Invalid argument types for ChatScreen");
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Lỗi: Tham số không đúng kiểu dữ liệu'),
              ),
            ),
          );
        }

        final participantId = args['participantId'] as int?;
        final updateChatListCallback = args['updateChatListCallback'] is Function
            ? args['updateChatListCallback'] as Function(MessageWithAttachment)?
            : null;
        final onConversationRemoved = args['onConversationRemoved'] is Function
            ? args['onConversationRemoved'] as Function(int)
            : (int _) {};

        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: args['conversationId'] as int,
            userId: args['user_id'] as int,
            participantId: participantId,
            websocketService: args['websocketService'] as WebSocketService,
            updateChatListCallback: updateChatListCallback,
            onConversationRemoved: onConversationRemoved,
          ),
        );

      case createGroup:
        final args = settings.arguments as Map<String, dynamic>?;

        if (args == null ||
            args['userId'] == null ||
            args['friends'] == null ||
            args['conversationRepo'] == null ||
            args['webSocketService'] == null) {
          debugPrint("Error: Missing required arguments for CreateGroupScreen");
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Lỗi: Thiếu tham số cần thiết cho tạo nhóm'),
              ),
            ),
          );
        }

        if (args['userId'] is! int ||
            args['friends'] is! List<FriendDTO> ||
            args['conversationRepo'] is! ConversationRepo ||
            args['webSocketService'] is! WebSocketService) {
          debugPrint("Error: Invalid argument types for CreateGroupScreen");
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Lỗi: Tham số không đúng kiểu dữ liệu'),
              ),
            ),
          );
        }
         List<FriendDTO>? selectedFriends = args['selectedFriends'] as List<FriendDTO>?
            ?? []; // Khởi tạo selectedFriends nếu không có trong args

        return MaterialPageRoute(
          builder: (_) => CreateGroupScreen(
            userId: args['userId'] as int,
            friends: args['friends'] as List<FriendDTO>,
            conversationRepo: args['conversationRepo'] as ConversationRepo,
            webSocketService: args['webSocketService'] as WebSocketService,
            selectedFriends: selectedFriends,
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