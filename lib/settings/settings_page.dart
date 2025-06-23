import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_service.dart';
import 'connection_status_widget.dart';
import 'confirmation_dialog.dart';

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
              ],
            ),
          );
        },
      ),
    );
  }
}
