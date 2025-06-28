import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_service.dart';
import 'connection_status_widget.dart';
import 'confirmation_dialog.dart';
import 'display_setting.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _navigateToProfile(BuildContext context) {
    Navigator.pushNamed(context, '/profile');
  }

  Future<void> _handleDisconnect(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: '연결 해제',
      content: '정말로 상대방과의 연결을 해제하시겠습니까?\n대화 기록은 보존되며, 재연결 시 다시 볼 수 있습니다.',
      confirmText: '해제',
      confirmColor: Colors.red,
    );

    if (!context.mounted) return;
    if (confirmed == true) {
      await SettingsService().disconnect(context);
    }
  }

  void _handleLogout(BuildContext context) {
    FirebaseAuth.instance
        .signOut()
        .then((_) {
          if (!context.mounted) return;
          Navigator.pushReplacementNamed(context, '/');
        })
        .catchError((error) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('로그아웃 실패')));
        });
  }

  // 비밀번호 입력 다이얼로그를 표시하는 함수 추가
  Future<void> _showPasswordInputDialog(BuildContext context) async {
    final TextEditingController passwordController = TextEditingController();
    bool isPasswordCorrect = false;

    await showDialog(
      context: context,
      barrierDismissible: false, // 다이얼로그 바깥을 탭해도 닫히지 않도록 설정
      builder: (dialogContext) {
        // 새로운 BuildContext 사용
        return AlertDialog(
          title: const Text('비밀번호 입력'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '비밀번호를 입력하세요'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // dialogContext 사용하여 팝
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                if (passwordController.text == '601216') {
                  // 비밀번호 확인
                  isPasswordCorrect = true;
                  Navigator.pop(dialogContext); // dialogContext 사용하여 팝
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    // dialogContext 사용하여 스낵바 표시
                    const SnackBar(content: Text('비밀번호가 틀렸습니다.')),
                  );
                }
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );

    // 비밀번호가 맞다면 DisplaySettingPage로 이동
    if (isPasswordCorrect && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DisplaySettingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: StreamBuilder(
        stream: SettingsService().getUserStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('사용자 정보를 불러올 수 없습니다.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final isConnected = userData['connect_status'] == true;
          final hasPendingInvites =
              userData['pendingInvites'] != null &&
              (userData['pendingInvites'] as List).isNotEmpty;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile settings button
                ElevatedButton.icon(
                  icon: const Icon(Icons.person),
                  label: const Text('프로필 설정'),
                  onPressed: () => _navigateToProfile(context),
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  icon: const Icon(Icons.no_encryption),
                  label: const Text('채팅 표시 설정'),
                  onPressed: () => _showPasswordInputDialog(context),
                ),
                const SizedBox(height: 16),

                // Disconnect button
                if (isConnected && !hasPendingInvites)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.link_off),
                    label: const Text('상대방과 연결 해제'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _handleDisconnect(context),
                  ),
                if (isConnected && !hasPendingInvites)
                  const SizedBox(height: 16),

                // Connection status
                ConnectionStatusWidget(
                  isConnected: isConnected,
                  hasPendingInvites: hasPendingInvites,
                ),
                const SizedBox(height: 16),

                // Logout button
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('로그아웃'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _handleLogout(context),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
