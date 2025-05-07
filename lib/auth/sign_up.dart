import 'package:flutter/material.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  Widget _textField(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _button(String label) {
    return ElevatedButton(onPressed: () {}, child: Text(label));
  }

  Widget _logo() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: Image.asset(
          'assets/Happywave_logo.png',
          width: 250,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Stack(
        children: [
          _logo(),
          Padding(
            padding: const EdgeInsets.only(top: 130.0),
            child: Center(
              child: Container(
                width: 350,
                height: 400,
                decoration: BoxDecoration(
                  color: Color(0xFFD8F3F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '회원가입',
                      style: TextStyle(
                        color: Color(0xFF05638A),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _textField('이메일'),
                    _textField('비밀번호'),
                    _textField('비밀번호 확인'),
                    _button('회원가입'),
                    _button('로그인'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
