import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_wave/auth/controller/providers.dart';
import 'settings_service.dart';

class DisplaySettingPage extends ConsumerWidget {
  const DisplaySettingPage({super.key});

  void updateChatOriginalViewEnabled(bool newValue, WidgetRef ref) async {
    await SettingsService().updateChatOriginalViewEnabled(newValue);
    ref.read(memberControllerProvider.notifier).refreshMember();
  }

  void updateChatOriginalToggleEnabled(bool newValue, WidgetRef ref) async {
    await SettingsService().updateChatOriginalToggleEnabled(newValue);
    ref.read(memberControllerProvider.notifier).refreshMember();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: Padding(
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
                    Text('채팅 표시 설정', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('원본 메시지 항상 표시'),
                      subtitle: const Text('AI 변환된 메시지 아래에 원본 메시지를 항상 표시합니다.'),
                      value: ref.watch(memberControllerProvider).member?.chatOriginalViewEnabled ?? false,
                      onChanged: (bool value) => updateChatOriginalViewEnabled(value, ref),
                    ),
                    SwitchListTile(
                      title: const Text('원본 메시지 토글 버튼 표시'),
                      subtitle: const Text('AI 변환된 메시지 옆에 원본/변환 메시지를 토글하는 버튼을 표시합니다.'),
                      value: ref.watch(memberControllerProvider).member?.chatOriginalToggleEnabled ?? false,
                      onChanged: (bool value) => updateChatOriginalToggleEnabled(value, ref),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
