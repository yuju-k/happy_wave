import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'auth/auth_firebase.dart';
import 'profile/profile.dart';
import 'system_log.dart';
import 'connect/invite_user.dart';
import 'connect/invite_alert.dart';
import 'chat/chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _checkNameExists();
    _logUserLogin();
    _saveDeviceToken();
    _initializeFCMListeners();
    InviteAlertListener.startListening(context);
  }

  // FCM 토큰을 얻어 Firestore에 저장하는 함수
  Future<void> _saveDeviceToken() async {
    final user = AuthService().currentUser;
    if (user == null) {
      debugPrint('FCM token save failed: User not logged in.');
      return;
    }

    try {
      // 1. 알림 권한 요청
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission');
      } else {
        debugPrint('User declined or has not accepted permission');
        return; // 권한이 없으면 토큰을 저장하지 않습니다.
      }

      // 2. FCM 토큰 가져오기
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('FCM Token saved to Firestore for UID: ${user.uid}');
        debugPrint('FCM Token: $token');
      } else {
        debugPrint('FCM token is null, cannot save.');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  // FCM 알림 수신 리스너 초기화
  void _initializeFCMListeners() {
    // 포그라운드 메시지 처리
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification?.title}, ${message.notification?.body}',
        );
        // 이 부분은 나중에 로컬 알림 UI를 구현할 때 추가할 수 있습니다.
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      debugPrint('Message data: ${message.data}');
    });

    // 앱이 완전히 종료된 상태에서 알림을 통해 실행되었을 때 메시지 처리
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        debugPrint('App launched from terminated state by notification!');
        debugPrint('Message data: ${message.data}');
      }
    });
  }

  Future<void> _logUserLogin() async {
    final user = AuthService().currentUser;
    if (user != null) {
      final logService = SystemLogService();
      await logService.logLogin(user.uid);
    }
  }

  Future<void> _checkNameExists() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (!doc.exists || !doc.data()!.containsKey('name')) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("로그인이 필요합니다.")));
    }

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: userDoc.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final connected = data?['connect_status'] == true;

        // 연결 상태에 따라 다른 화면 표시
        if (!connected) {
          // 연결되지 않은 상태: 초대 화면 표시
          return const InviteUserPage();
        } else {
          // 연결된 상태: 채팅 화면 표시
          return const ChatPage();
        }
      },
    );
  }
}
