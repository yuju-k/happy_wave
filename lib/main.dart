import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'home.dart';
import 'auth/sign_up.dart';
import 'auth/sign_in.dart';
import 'profile/profile.dart';
import 'settings.dart';

// 백그라운드 메시지 핸들러 (top-level 함수여야 함)
@pragma('vm:entry-point') // Android 에서는 @pragma('vm:entry-point') 필요
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
    _initializeFirebaseMessaging();
  }

  Future<void> _initializeFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;

    // iOS 포그라운드 알림 설정 (iOS 특화)
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 알림 권한 요청 (iOS 및 Android 13+)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // FCM 토큰 가져오기 (각 기기 고유 ID)
    String? token = await messaging.getToken();
    debugPrint('FCM Token: $token');

    // 토큰을 Firestore에 저장 (특정 사용자에게 알림을 보내려면 필요)
    if (FirebaseAuth.instance.currentUser != null && token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }

    // 포그라운드 메시지 수신 시 처리
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );
        // 여기에서 로컬 알림을 표시할 수 있습니다 (flutter_local_notifications 패키지 사용 권장)
        // 현재 앱의 SnackBar를 사용하여 임시로 알림을 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.notification!.title ?? '새 알림'),
            action: SnackBarAction(
              label: '보기',
              onPressed: () {
                // 알림 탭 시 특정 페이지로 이동하는 로직 (예시)
                if (message.data['roomId'] != null) {
                  Navigator.pushNamed(context, '/chat'); // 예시
                }
              },
            ),
          ),
        );
      }
    });

    // 사용자가 알림을 탭하여 앱을 열었을 때 처리 (백그라운드에서 포그라운드로)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message opened app from background: ${message.data}');
      // 알림을 탭했을 때 특정 페이지로 이동하는 등의 로직
      if (message.data['roomId'] != null) {
        Navigator.pushNamed(context, '/'); // 예시
      }
    });

    // 앱이 완전히 종료된 상태에서 알림을 탭하여 열었을 때 처리
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state: ${initialMessage.data}');
      // 예를 들어, 여기서도 특정 페이지로 이동
      if (initialMessage.data['roomId'] != null) {
        Navigator.pushNamed(context, '/');
      }
    }
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
