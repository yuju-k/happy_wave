import 'package:flutter/material.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign In')),
      body: Center(
        child: Text('이 페이지는 로그인페이지입니다.', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
