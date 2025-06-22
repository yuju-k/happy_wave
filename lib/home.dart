import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkNameExists();
    _logUserLogin();
    InviteAlertListener.startListening(context);
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

        // 상태 업데이트
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _isConnected != connected) {
            setState(() {
              _isConnected = connected;
            });
          }
        });

        // 연결 상태에 따라 다른 화면 표시
        if (!_isConnected) {
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
