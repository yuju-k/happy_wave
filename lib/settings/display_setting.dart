import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_service.dart';

class DisplaySettingPage extends StatelessWidget {
  const DisplaySettingPage({super.key});

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
          final chatOriginalViewEnabled =
              userData['chatOriginalViewEnabled'] as bool? ??
              true; // Default to true
          final chatOriginalToggleEnabled =
              userData['chatOriginalToggleEnabled'] as bool? ??
              true; // Default to true

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // New settings for chat message bubble
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '채팅 표시 설정',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('원본 메시지 항상 표시'),
                          subtitle: const Text(
                            'AI 변환된 메시지 아래에 원본 메시지를 항상 표시합니다.',
                          ),
                          value: chatOriginalViewEnabled,
                          onChanged: (bool value) {
                            SettingsService().updateChatOriginalViewEnabled(
                              value,
                            );
                          },
                        ),
                        SwitchListTile(
                          title: const Text('원본 메시지 토글 버튼 표시'),
                          subtitle: const Text(
                            'AI 변환된 메시지 옆에 원본/변환 메시지를 토글하는 버튼을 표시합니다.',
                          ),
                          value: chatOriginalToggleEnabled,
                          onChanged: (bool value) {
                            SettingsService().updateChatOriginalToggleEnabled(
                              value,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
