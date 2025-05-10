import 'package:flutter/material.dart';
import 'sign_in.dart';
import 'auth_firebase.dart';
import '../home.dart';

// 상수 정의
const Color primaryColor = Color(0xFF44C2D0);
const Color textColor = Color(0xFF05638A);
const Color backgroundColor = Color(0xFFD8F3F1);
const double containerWidth = 350.0;
const double borderRadius = 20.0;

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // 컨트롤러 및 서비스 초기화
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
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

  // 회원가입 버튼 위젯 생성
  Widget _buildSignUpButton() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: containerWidth),
      child: ElevatedButton(
        onPressed: _handleSignUp,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: const Text('회원가입', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  // 회원가입 처리 로직
  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')));
      return;
    }

    final result = await _authService.signUp(email, password);

    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('회원가입 완료')));
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
        padding: const EdgeInsets.only(top: 50.0),
        child: Image.asset(
          'assets/Happywave_logo.png',
          width: 250,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // 회원가입 폼 컨테이너 스타일
  BoxDecoration _formContainerDecoration() {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withAlpha(51),
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
                        '회원가입',
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
                      _buildTextField(
                        '비밀번호 확인',
                        _confirmPasswordController,
                        isPassword: true,
                      ),
                      const SizedBox(height: 16),
                      _buildSignUpButton(),
                      const SizedBox(height: 8),
                      _buildTextButton(
                        '이미 계정이 있으신가요? 로그인하기',
                        () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignInPage(),
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
