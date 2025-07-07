// lib/connect/invite_user.dart 수정된 버전

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'invite_firebase.dart';

// 상수 및 스타일 정의
class _InviteUserConstants {
  static const double borderRadius = 12.0;
  static const double spacing = 24.0;
  static const Color cardBackground = Color(0xFFE0F7FA);
  static const Color buttonColor = Color(0xFF44C2D0);
  static const Color pendingColor = Color(0xFFFFA726);
}

class InviteUserPage extends StatefulWidget {
  const InviteUserPage({super.key});

  @override
  State<InviteUserPage> createState() => _InviteUserPageState();
}

class _InviteUserPageState extends State<InviteUserPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _pendingInviteEmail; // 대기 중인 초대의 이메일

  @override
  void initState() {
    super.initState();
    _checkPendingInvites();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // 현재 사용자가 보낸 pending 상태의 초대가 있는지 확인
  Future<void> _checkPendingInvites() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final query =
          await FirebaseFirestore.instance
              .collection('invites')
              .where('from', isEqualTo: currentUser.uid)
              .where('status', isEqualTo: 'pending')
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        final inviteData = query.docs.first.data();
        final toUid = inviteData['to'] as String;

        // 상대방의 이메일 가져오기
        final inviteService = InviteService();
        final email = await inviteService.getEmailByUid(toUid);

        if (mounted) {
          setState(() {
            _pendingInviteEmail = email;
          });
        }
      }
    } catch (e) {
      debugPrint('Pending 초대 확인 중 오류: $e');
    }
  }

  // pending 초대 취소
  Future<void> _cancelPendingInvite() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      // pending 상태의 초대 찾기
      final query =
          await FirebaseFirestore.instance
              .collection('invites')
              .where('from', isEqualTo: currentUser.uid)
              .where('status', isEqualTo: 'pending')
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        final inviteDoc = query.docs.first;
        final inviteData = inviteDoc.data();
        final toUid = inviteData['to'] as String;

        // 초대 상태를 cancelled로 변경
        await inviteDoc.reference.update({'status': 'cancelled'});

        // 상대방의 pendingInvites에서 제거
        await FirebaseFirestore.instance.collection('users').doc(toUid).update({
          'pendingInvites': FieldValue.arrayRemove([currentUser.uid]),
        });

        if (mounted) {
          setState(() {
            _pendingInviteEmail = null;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('초대가 취소되었습니다.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('초대 취소 중 오류가 발생했습니다: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widgetWidth = screenWidth.clamp(300.0, 350.0);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
                tooltip: '설정',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                // pending 상태에 따라 다른 UI 표시
                _pendingInviteEmail != null
                    ? _buildPendingCard(context, widgetWidth)
                    : _buildInviteCard(context, widgetWidth),
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
            _pendingInviteEmail != null ? '초대 대기 중' : '초대 하기',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: _InviteUserConstants.spacing / 2),
          Text(
            _pendingInviteEmail != null
                ? '상대방의 수락을 기다리고 있습니다.'
                : '상대방을 초대하여 연결해주세요.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 16, color: Colors.black),
          ),
        ],
      ),
    );
  }

  // pending 상태일 때의 카드 UI
  Widget _buildPendingCard(BuildContext context, double widgetWidth) {
    return Container(
      width: widgetWidth,
      padding: const EdgeInsets.symmetric(
        horizontal: _InviteUserConstants.spacing,
        vertical: _InviteUserConstants.spacing * 1.2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // 주황빛 배경
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
          // 대기 아이콘과 메시지
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule,
                color: _InviteUserConstants.pendingColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '초대 대기 중',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _InviteUserConstants.pendingColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 초대받은 사람 정보
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _InviteUserConstants.pendingColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$_pendingInviteEmail 님의',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  '수락을 대기하고 있습니다.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 취소 버튼
          OutlinedButton.icon(
            onPressed: _cancelPendingInvite,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('초대 취소'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            '※ 상대방이 수락하면 자동으로 연결됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // 일반 초대 카드 UI (기존과 동일)
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
          // 초대 전송 후 pending 상태 다시 확인
          _checkPendingInvites();
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
