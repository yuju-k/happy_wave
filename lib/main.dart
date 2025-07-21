import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_wave/auth/controller/providers.dart';
import 'package:happy_wave/core/notification/notification_service.dart';
import 'firebase_options.dart';
import 'home.dart';
import 'auth/sign_up.dart';
import 'auth/sign_in.dart';
import 'profile/profile.dart';
import 'settings/settings_page.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  NotificationService.instance.showNotification();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.instance.initialize();
  await NotificationService.instance.settingHandler();
  runApp(ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const MainPage(),
        '/home': (context) => const HomePage(),
        '/sign-in': (context) => const SignInPage(),
        '/sign-up': (context) => const SignUpPage(),
        '/profile': (context) => const ProfilePage(),
        '/settings': (context) => const SettingsPage(),
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
            color: Color(0xFF05638A), // headingTextStyle
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: Color(0xFF05638A), // bodyTextStyle
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF44C2D0),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // borderRadius
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
          //배경색 없음 . 투명
          backgroundColor: Color(0xFF44C2D0),
          foregroundColor: Color(0xFF05638A),
          titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),

      themeMode: ThemeMode.system, // 시스템 설정에 따라 테마 전환
    );
  }
}

class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<User?>(
      future: _checkUserLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (snapshot.hasData) {
              ref.read(memberControllerProvider.notifier).refreshMember();
              Navigator.pushReplacementNamed(context, '/home');
            } else {
              Navigator.pushReplacementNamed(context, '/sign-up');
            }
          });
          return const SizedBox.shrink(); // 전환 중 빈 화면 처리
        }
      },
    );
  }

  Future<User?> _checkUserLoginStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      // 사용자가 없으면 바로 null 반환
      if (user == null) {
        return null;
      }

      // 사용자가 있으면 토큰 유효성 검증
      await user.reload(); // 서버에서 최신 사용자 정보 가져오기

      // reload 후 다시 currentUser 확인 (서버에서 삭제된 경우 null이 됨)
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && refreshedUser.uid.isNotEmpty) {
        // 추가 검증: 토큰이 유효한지 확인
        try {
          await refreshedUser.getIdToken(true); // 강제로 새 토큰 발급
          return refreshedUser;
        } catch (tokenError) {
          // 토큰 발급 실패 시 로그아웃
          debugPrint('토큰 발급 실패: $tokenError');
          await FirebaseAuth.instance.signOut();
          return null;
        }
      } else {
        // reload 후 사용자가 null이면 로그아웃
        await FirebaseAuth.instance.signOut();
        return null;
      }
    } catch (e) {
      // reload 실패 시 (사용자가 서버에서 삭제된 경우)
      debugPrint('사용자 정보 갱신 실패: $e');
      await FirebaseAuth.instance.signOut();
      return null;
    }
  }
}
