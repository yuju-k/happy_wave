import 'package:flutter/material.dart';
import 'package:happy_wave/auth/reset_password.dart';
import 'auth_firebase.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _textFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
    ).applyDefaults(Theme.of(context).inputDecorationTheme);
  }

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

  Widget _buildSignUpButton() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 350.0),
      child: ElevatedButton(
        onPressed: _handleSignUp,
        child: const Text('회원가입', style: TextStyle(fontSize: 16)),
      ),
    );
  }

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
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result)));
    }
  }

  Widget _buildTextButton(String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

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

  BoxDecoration _formContainerDecoration() {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
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
                  width: 350.0,
                  padding: const EdgeInsets.all(24.0),
                  decoration: _formContainerDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '회원가입',
                        style: Theme.of(context).textTheme.headlineSmall,
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
                        () =>
                            Navigator.pushReplacementNamed(context, '/sign-in'),
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
