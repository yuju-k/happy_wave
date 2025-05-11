import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/auth_firebase.dart';
import 'profile/profile.dart';
import 'system_log.dart';
import 'connect/connect_other.dart';
import 'connect/invite_user.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkNameExists();
    _logUserLogin();
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(),
      const ProfilePage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_rounded),
            label: '대화',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final user = AuthService().currentUser;
    if (user == null) {
      return const Center(child: Text("로그인이 필요합니다."));
    }

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: userDoc.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final isConnected = data?['connect_status'] == true;

        if (!isConnected) {
          return InviteUserPage(); // 연결 안 된 상태
        }

        return _buildConnectedHome(); // 연결된 홈 콘텐츠 표시
      },
    );
  }

  Widget _buildConnectedHome() {
    return const Center(child: Text("공유된 HOME 화면입니다 😊"));
  }
}
