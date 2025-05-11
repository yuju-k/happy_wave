import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'home.dart';
import 'auth/sign_up.dart';
import 'auth/sign_in.dart';
import 'profile/profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 바인딩 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

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
      },

      theme: ThemeData(
        primaryColor: Color(0xFF44C2D0), // 앱바, 버튼 등의 기본 색상
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF44C2D0), // 테마의 기본 색상 시드
          primary: Color(0xFF44C2D0), // 주요 UI 요소 색상
          secondary: Colors.blueAccent, // 보조 색상 (예: 플로팅 버튼)
          //배경 색깔 EDFFFE
          surface: Colors.white, // 배경 색상
        ),
        scaffoldBackgroundColor: Color(0xFFEDFFFE), // Scaffold 배경 색상
        // 텍스트 스타일 설정
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
        ),
        // ElevatedButton 스타일 설정
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF44C2D0), // 버튼 배경 색상
            foregroundColor: Colors.white, // 버튼 텍스트/아이콘 색상
          ),
        ),
        // AppBar 스타일 설정
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF44C2D0),
          foregroundColor: Colors.white, // AppBar 텍스트/아이콘 색상
        ),
      ),
      // 다크 모드 테마 (선택)
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.grey[900],
      ),
      themeMode: ThemeMode.system, // 시스템 설정에 따라 테마 전환
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (snapshot.hasData) {
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
    return FirebaseAuth.instance.currentUser;
  }
}
