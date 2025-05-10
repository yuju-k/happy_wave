import 'package:flutter/material.dart';
import 'sign_up.dart';
import 'reset_password.dart';
import 'auth_firebase.dart';
import '../home.dart';

// 상수 정의
const Color primaryColor = Color(0xFF44C2D0);
const Color textColor = Color(0xFF05638A);
const Color backgroundColor = Color(0xFFD8F3F1);
const double containerWidth = 350.0;
const double borderRadius = 20.0;

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  // 컨트롤러 및 서비스 초기화
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  // 텍스트 필드 스타일 정의
  InputDecoration _textFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: primaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: primaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: primaryColor, width: 2.0),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  // 텍스트 필드 위젯 생성
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: _textFieldDecoration(label),
      ),
    );
  }

  // 로그인 버튼 위젯 생성
  Widget _buildSignInButton() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: containerWidth),
      child: ElevatedButton(
        onPressed: _handleSignIn,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: const Text('로그인', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  // 로그인 처리 로직
  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final result = await _authService.signIn(email, password);

    if (!mounted) return;

    if (result == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result)));
    }
  }

  // 텍스트 버튼 위젯 생성
  Widget _buildTextButton(String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(color: textColor, fontSize: 14),
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
          'assets/Happywave_logo_2.png',
          width: 360,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // 로그인 폼 컨테이너 스타일
  BoxDecoration _formContainerDecoration() {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withAlpha(50),
          spreadRadius: 2,
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
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
                  width: containerWidth,
                  padding: const EdgeInsets.all(24.0),
                  decoration: _formContainerDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '로그인',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField('이메일', _emailController),
                      _buildTextField(
                        '비밀번호',
                        _passwordController,
                        isPassword: true,
                      ),
                      const SizedBox(height: 16),
                      _buildSignInButton(),
                      const SizedBox(height: 8),
                      _buildTextButton(
                        '계정이 없으신가요? 회원가입하기',
                        () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpPage(),
                          ),
                        ),
                      ),
                      _buildTextButton(
                        '비밀번호를 잊으셨나요?',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ResetPasswordPage(),
                          ),
                        ),
                      ),
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
