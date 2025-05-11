import 'package:flutter/material.dart';
import 'invite_firebase.dart';

// 상수 및 스타일 정의
class _InviteUserConstants {
  static const double borderRadius = 12.0;
  static const double spacing = 24.0;
  static const Color cardBackground = Color(0xFFE0F7FA);
  static const Color buttonColor = Color(0xFF44C2D0);
}

class InviteUserPage extends StatefulWidget {
  const InviteUserPage({super.key});

  @override
  State<InviteUserPage> createState() => _InviteUserPageState();
}

class _InviteUserPageState extends State<InviteUserPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widgetWidth = screenWidth.clamp(300.0, 350.0);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                _buildInviteCard(context, widgetWidth),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  // 헤더 UI 빌드
  Widget _buildHeader(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '초대 하기',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: _InviteUserConstants.spacing / 2),
          Text(
            '상대방을 초대하여 연결해주세요.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 16, color: Colors.black),
          ),
        ],
      ),
    );
  }

  // 초대 카드 UI 빌드
  Widget _buildInviteCard(BuildContext context, double widgetWidth) {
    return Container(
      width: widgetWidth,
      padding: const EdgeInsets.symmetric(
        horizontal: _InviteUserConstants.spacing,
        vertical: _InviteUserConstants.spacing * 1.2,
      ),
      decoration: BoxDecoration(
        color: _InviteUserConstants.cardBackground,
        borderRadius: BorderRadius.circular(_InviteUserConstants.borderRadius),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '상대방의 이메일을 입력해주세요.',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: _InviteUserConstants.spacing),
          _buildEmailField(),
          const SizedBox(height: 20),
          _buildInviteButton(_emailController),
          const SizedBox(height: 16),
          const Text(
            '※ 초대는 상대방의 수락 시 연결됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // 이메일 입력 필드
  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: '이메일 주소',
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: const Icon(Icons.email_outlined),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  // 초대 보내기 버튼
  Widget _buildInviteButton(TextEditingController emailController) {
    return ElevatedButton.icon(
      onPressed: () async {
        final email = emailController.text.trim();
        if (email.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('이메일을 입력해주세요.')));
          return;
        }

        setState(() => _isLoading = true);

        final inviteService = InviteService();
        final result = await inviteService.sendInvite(email);

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (result == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('초대가 전송되었습니다!')));
          emailController.clear();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result)));
        }
      },
      icon: const Icon(Icons.send),
      label: const Text('초대 보내기'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _InviteUserConstants.buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
