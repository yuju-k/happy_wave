// lib/main.dart - 개선된 버전
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

// 백그라운드 메시지 핸들러 (개선됨)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint("백그라운드 메시지 수신: ${message.messageId}");
  debugPrint("제목: ${message.notification?.title}");
  debugPrint("내용: ${message.notification?.body}");
  debugPrint("데이터: ${message.data}");

  // 백그라운드에서 로컬 알림 표시
  try {
    await NotificationService.showBackgroundNotification(message);
    debugPrint("백그라운드 알림 표시 완료");
  } catch (e) {
    debugPrint("백그라운드 알림 표시 실패: $e");
  }
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

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppStateService().dispose();
    super.dispose();
  }

  // 서비스들 초기화
  Future<void> _initializeServices() async {
    try {
      // 앱 상태 서비스 초기화
      AppStateService().initialize();

      // 알림 서비스 초기화
      await NotificationService().initialize(navigatorKey: navigatorKey);

      // 포그라운드 메시지 리스너
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('포그라운드 메시지 수신: ${message.messageId}');
        // NotificationService에서 처리
        NotificationService().handleForegroundNotification(message);
      });

      // 앱 종료 상태에서 알림 탭 처리 설정
      await NotificationService().setupInteractedMessage();

      debugPrint('모든 서비스 초기화 완료');
    } catch (e) {
      debugPrint('서비스 초기화 실패: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('앱 생명주기 상태 변경: $state');

    // 앱이 포그라운드로 돌아왔을 때 알림 탭 확인
    if (state == AppLifecycleState.resumed) {
      _checkForPendingNotifications();
    }
  }

  // 대기 중인 알림 확인
  Future<void> _checkForPendingNotifications() async {
    try {
      await NotificationService().setupInteractedMessage();
    } catch (e) {
      debugPrint('대기 중인 알림 확인 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Navigator Key 설정
      initialRoute: '/',
      routes: {
        '/': (context) => const MainPage(),
        '/home': (context) => const HomePage(),
        '/sign-in': (context) => const SignInPage(),
        '/sign-up': (context) => const SignUpPage(),
        '/profile': (context) => const ProfilePage(),
        '/settings': (context) => const SettingsPage(),
        '/chat': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final chatRoomId = args?['chatRoomId'] as String?;
          if (chatRoomId == null) {
            return const HomePage();
          }
          return ChatPage(chatRoomId: chatRoomId);
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
              // 로그인된 사용자의 경우 알림 서비스 다시 초기화 (토큰 갱신 등)
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
