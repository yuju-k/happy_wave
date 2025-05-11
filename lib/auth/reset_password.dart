import 'package:flutter/material.dart';
import 'auth_firebase.dart';

// 상수 정의
const double containerWidth = 350.0;
const double borderRadius = 20.0;

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  // 컨트롤러 및 서비스 초기화
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // 텍스트 필드 위젯 생성
  Widget _buildTextField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: '이메일'),
      ),
    );
  }

  // 비밀번호 재설정 버튼 위젯 생성
  Widget _buildResetButton() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: containerWidth),
      child: ElevatedButton(
        onPressed: _handleResetPassword,
        child: const Text('비밀번호 재설정 메일 보내기', style: TextStyle(fontSize: 15)),
      ),
    );
  }

  // 비밀번호 재설정 처리 로직
  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이메일을 입력해주세요.')));
      }
      return;
    }

    final result = await _authService.resetPassword(email);

    if (mounted) {
      if (result == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('비밀번호 재설정 메일이 전송되었습니다.')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result)));
      }
    }
  }

  // 폼 컨테이너 스타일
  BoxDecoration _formContainerDecoration() {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 80.0,
              horizontal: 24.0,
            ),
            child: Container(
              width: containerWidth,
              padding: const EdgeInsets.all(24.0),
              decoration: _formContainerDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '비밀번호 재설정',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '가입한 이메일 주소를 입력하면\n비밀번호 재설정 메일을 보내드립니다.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(),
                  const SizedBox(height: 24),
                  _buildResetButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
