import 'package:flutter/material.dart';
import 'auth/auth_firebase.dart';
import 'auth/sign_in.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut(); // 로그아웃 실행
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SignInPage()),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('이 페이지는 home입니다.', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
