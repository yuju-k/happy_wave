import 'package:flutter/material.dart';
import 'sign_up.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  // 텍스트 필드 위젯 생성
  Widget _buildTextField(String label, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        obscureText: isPassword,
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
          MaterialPageRoute(builder: (context) => const SignUpPage()),
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
        padding: const EdgeInsets.only(top: 15.0),
        child: Image.asset(
          'assets/Happywave_logo(2).png',
          width: 360,
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
                        color: Colors.grey.withAlpha(50),
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
                        '로그인',
                        style: TextStyle(
                          color: Color(0xFF05638A),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField('이메일'),
                      _buildTextField('비밀번호', isPassword: true),
                      const SizedBox(height: 16),
                      _buildButton('로그인'),
                      const SizedBox(height: 8),
                      _buildTextButton(context, '계정이 없으신가요? 회원가입하기'),
                      _buildTextButton(context, '비밀번호를 잊으셨나요?'),
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
