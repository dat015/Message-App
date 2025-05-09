import 'package:first_app/PlatformClient/config.dart';
import 'package:first_app/data/providers/CallProvider.dart';
import 'package:first_app/data/providers/home_provider.dart';
import 'package:first_app/data/providers/providers.dart';
import 'package:first_app/data/repositories/Chat/websocket_service.dart';
import 'package:first_app/data/repositories/AI_Post_Repo/comment_suggestion_repo.dart';
import 'package:first_app/features/auth/presentation/screens/login.dart';
import 'package:first_app/features/home/presentation/ai_caption/bloc_comments/comment_suggestion_state.dart';
import 'package:first_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Thêm Firebase Core
import 'package:flutter/foundation.dart' show kIsWeb; // Để kiểm tra nền tảng
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:first_app/data/api/api_client.dart';

import 'features/routes/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Supabase
  await Supabase.initialize(
    url: 'https://hqpglsqigydjqafpvshl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhxcGdsc3FpZ3lkanFhZnB2c2hsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM1ODk3OTksImV4cCI6MjA1OTE2NTc5OX0.VypvOSQvRYyLkz3DcUZ6xjqPduOwQkCb07PH_BJzWPE',
  );

  // Khởi tạo Firebase
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDqjHLvkOkvSSJKe71Vo5YI2NQXtUnkX2s",
        authDomain: "messageapps-dbc91.firebaseapp.com",
        projectId: "messageapps-dbc91",
        storageBucket: "messageapps-dbc91.firebasestorage.app",
        messagingSenderId: "881588133937",
        appId: "1:881588133937:web:b26b2b67b1352ac4ae7510",
        measurementId: "G-MR2TSH231P",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        
        Provider<WebSocketService>(
          create:
              (_) => WebSocketService(
                url: Config.baseUrlWS,
                onMessageReceived: (message) {
                  print('Received chat message: ${message.message.content}');
                },
              ),
        ),
        ChangeNotifierProvider<CallProvider>(
          create:
              (context) => CallProvider(
                webSocketService: context.read<WebSocketService>(),
              ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Khởi tạo ApiClient và CommentSuggestionService
    final apiClient = ApiClient(); // Cấu hình base URL nếu cần
    final commentSuggestionService = CommentSuggestionService(apiClient);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => CommentSuggestionBloc(commentSuggestionService),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.login,
        onGenerateRoute: AppRoutes.generateRoute,
        title: 'Flutter Demo',
        theme: lightMode,
        home: const SignInScreen(),
      ),
    );
  }
}