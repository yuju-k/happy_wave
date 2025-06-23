import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'home.dart';
import 'auth/sign_up.dart';
import 'auth/sign_in.dart';
import 'profile/profile.dart';
import 'settings.dart';
import 'services/notification_service.dart';
import 'services/app_state_service.dart';
import 'chat/chat_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Firebase 초기화 후 NotificationService 초기화
  await NotificationService().initialize();
  // 백그라운드에서 로컬 알림을 표시하도록 NotificationService의 정적 메서드 호출
  await NotificationService.showBackgroundNotification(message);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    // 앱 상태 서비스 초기화
    AppStateService().initialize();

    // NotificationService에 navigatorKey 전달
    NotificationService().initialize(navigatorKey: navigatorKey); // 초기화 시 키 전달
    NotificationService().setupInteractedMessage();

    // 포그라운드 메시지 리스너 (NotificationService에서 처리하므로 여기서는 단순 로깅만)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');
      // NotificationService에서 포그라운드 알림 처리
      NotificationService().handleForegroundNotification(message);
    });
  }

  @override
  void dispose() {
    // 앱 상태 서비스 정리
    AppStateService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const MainPage(),
        '/home': (context) => const HomePage(),
        '/sign-in': (context) => const SignInPage(),
        '/sign-up': (context) => const SignUpPage(),
        '/profile': (context) => const ProfilePage(),
        '/settings': (context) => const SettingsPage(),
        '/chat': (context) {
          // ChatPage 라우트 추가 및 인자 전달 로직
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final chatRoomId = args?['chatRoomId'] as String?;
          if (chatRoomId == null) {
            // chatRoomId가 없으면 홈으로 리다이렉트 또는 에러 처리
            return const HomePage();
          }
          return ChatPage(chatRoomId: chatRoomId); // chatRoomId 전달
        },
      },
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFEDFFFE),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF44C2D0),
          primary: Color(0xFF44C2D0),
          secondary: Colors.blueAccent,
          surface: Color(0xFFD8F3F1),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF05638A),
          ),
          bodyMedium: TextStyle(fontSize: 16, color: Color(0xFF05638A)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF44C2D0),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF44C2D0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF44C2D0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF44C2D0), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF44C2D0),
          foregroundColor: Color(0xFF05638A),
          titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      themeMode: ThemeMode.system,
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _checkUserLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (snapshot.hasData) {
              // 로그인된 사용자의 경우 알림 서비스 초기화
              await NotificationService().initialize();
              Navigator.pushReplacementNamed(context, '/home');
            } else {
              Navigator.pushReplacementNamed(context, '/sign-up');
            }
          });
          return const SizedBox.shrink();
        }
      },
    );
  }

  Future<User?> _checkUserLoginStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return null;
      }

      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && refreshedUser.uid.isNotEmpty) {
        try {
          await refreshedUser.getIdToken(true);
          return refreshedUser;
        } catch (tokenError) {
          debugPrint('토큰 발급 실패: $tokenError');
          await FirebaseAuth.instance.signOut();
          return null;
        }
      } else {
        await FirebaseAuth.instance.signOut();
        return null;
      }
    } catch (e) {
      debugPrint('사용자 정보 갱신 실패: $e');
      await FirebaseAuth.instance.signOut();
      return null;
    }
  }
}
