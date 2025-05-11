import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _onProfileSettings(BuildContext context) {
    // TODO: Navigate to profile settings page
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('프로필 설정 클릭됨')));
  }

  void _onLogout(BuildContext context) {
    // Firebase Auth 로그아웃
    FirebaseAuth.instance
        .signOut()
        .then((_) {
          // 로그아웃 후 홈 화면으로 이동
          Navigator.pushReplacementNamed(context, '/');
        })
        .catchError((error) {
          // 오류 처리
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('로그아웃 실패')));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: const Text('프로필 설정'),
              onPressed: () => _onProfileSettings(context),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('로그아웃'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _onLogout(context),
            ),
          ],
        ),
      ),
    );
  }
}
