import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_wave/auth/controller/providers.dart';
import 'package:happy_wave/core/notification/notification_service.dart';
import 'auth/auth_firebase.dart';
import 'profile/profile.dart';
import 'system_log.dart';
import 'connect/invite_user.dart';
import 'connect/invite_alert.dart';
import 'chat/chat_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    _checkNameExists();
    _logUserLogin();
    _saveDeviceToken();
    _initializeMemberController();
    InviteAlertListener.startListening(context);
  }

  Future<void> _initializeMemberController() async {
    var user = AuthService().currentUser;
    if (user == null) return;
    await ref.read(memberControllerProvider.notifier).refreshMember();
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
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
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
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
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

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists || !doc.data()!.containsKey('name')) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("로그인이 필요합니다.")));
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: userDoc.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
