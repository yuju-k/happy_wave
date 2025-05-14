import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'home.dart';
import 'auth/sign_up.dart';
import 'auth/sign_in.dart';
import 'profile/profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
