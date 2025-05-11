import 'package:flutter/material.dart';

class InviteUserPage extends StatefulWidget {
  const InviteUserPage({super.key});

  @override
  State<InviteUserPage> createState() => _InviteUserPageState();
}

class _InviteUserPageState extends State<InviteUserPage> {
  static const double _borderRadius = 12.0;
  static const double _spacing = 24.0;

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    final screenWidth = MediaQuery.of(context).size.width;
    final widgetWidth = screenWidth.clamp(300.0, 350.0);

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            Container(
              width: widgetWidth,
              padding: const EdgeInsets.symmetric(
                horizontal: _spacing,
                vertical: _spacing * 1.2,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F7FA), // 밝은 민트색
                borderRadius: BorderRadius.circular(_borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                  const SizedBox(height: 24),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: '이메일 주소',
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // 초대 기능 연결 예정
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('초대 보내기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF44C2D0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '※ 초대는 상대방의 수락 시 연결됩니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 헤더 UI
  Widget _buildHeader() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: _spacing),
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
            const SizedBox(height: _spacing / 2),
            Text(
              '상대방을 초대하여 연결해주세요.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: _spacing),
          ],
        ),
      ),
    );
  }
}
