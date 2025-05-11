import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConnectStatusPage extends StatefulWidget {
  const ConnectStatusPage({super.key});

  @override
  State<ConnectStatusPage> createState() => _ConnectStatusPageState();
}

class _ConnectStatusPageState extends State<ConnectStatusPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Center(child: Text('상대방과 연결 필요', style: TextStyle(fontSize: 18))),

        //임시 로그아웃 버튼
        ElevatedButton(
          onPressed: () {
            // 로그아웃 처리
            Navigator.pushReplacementNamed(context, '/sign-in');
            FirebaseAuth.instance.signOut();
            // Navigator.pushReplacementNamed(context, '/sign-in');
          },
          child: const Text('로그아웃'),
        ),
      ],
    );
  }
}
