import 'package:flutter/material.dart';
import 'sign_in.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  // 텍스트 필드 위젯 생성
  Widget _buildTextField(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
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
            borderSide: const BorderSide(color: Color(0xFF44C2D0), width: 2.0),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  // 버튼 위젯 생성
  Widget _buildButton(String label) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 350),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  // 텍스트 버튼 위젯 생성
  Widget _buildTextButton(BuildContext context, String label) {
    return TextButton(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInPage()),
        );
      },
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF05638A), fontSize: 14),
      ),
    );
  }

  // 로고 위젯 생성
  Widget _buildLogo() {
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
      appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            _buildLogo(),
            Padding(
              padding: const EdgeInsets.only(top: 260.0),
              child: Center(
                child: Container(
                  width: 350,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8F3F1),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(51), // 20% opacity
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '회원가입',
                        style: TextStyle(
                          color: Color(0xFF05638A),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField('이메일'),
                      _buildTextField('비밀번호'),
                      _buildTextField('비밀번호 확인'),
                      const SizedBox(height: 16),
                      _buildButton('회원가입'),
                      const SizedBox(height: 8),
                      _buildTextButton(context, '이미 계정이 있으신가요? 로그인하기'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
