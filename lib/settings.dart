import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/app_state_service.dart';
import 'services/notification_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Navigation to profile settings
  void _navigateToProfile(BuildContext context) {
    Navigator.pushNamed(context, '/profile');
  }

  // Show confirmation dialog for disconnection
  Future<bool?> _showDisconnectDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('연결 해제'),
            content: const Text(
              '정말로 상대방과의 연결을 해제하시겠습니까?\n대화 기록은 보존되며, 재연결 시 다시 볼 수 있습니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('해제', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  // Handle disconnection process
  Future<void> _handleDisconnect(BuildContext context) async {
    final shouldDisconnect = await _showDisconnectDialog(context);
    if (shouldDisconnect == true) {
      await _performDisconnection(context);
    }
  }

  // Perform disconnection logic
  Future<void> _performDisconnection(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('❌ 사용자가 로그인되어 있지 않음');
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final userData = await _fetchUserData(user.uid);
      if (userData == null) {
        debugPrint('❌ 사용자 데이터가 없음');
        Navigator.pop(context);
        return;
      }

      final chatroomId = userData['chatroomId'] as String?;
      if (chatroomId == null) {
        debugPrint('❌ chatroomId가 없음 - 연결된 상태가 아님');
        Navigator.pop(context);
        return;
      }

      final otherUserUid = await _findOtherUserUid(chatroomId, user.uid);
      await _updateConnectionStatus(user.uid, otherUserUid, chatroomId);
      await _cleanupInvites(user.uid, otherUserUid);

      Navigator.pop(context); // Close loading dialog
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연결이 해제되었습니다. 대화 기록은 보존됩니다.')),
        );
      }
      debugPrint('🎉 연결 해제 완료');
    } catch (e, stackTrace) {
      _handleDisconnectionError(context, e, stackTrace);
    }
  }

  // Fetch user data from Firestore
  Future<Map<String, dynamic>?> _fetchUserData(String uid) async {
    debugPrint('🔍 사용자 문서 조회 시작...');
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = userDoc.data();
    debugPrint('🔍 사용자 데이터: $userData');
    return userData;
  }

  // Find the other user's UID in the chatroom
  Future<String?> _findOtherUserUid(String chatroomId, String myUid) async {
    debugPrint('🔍 채팅방 문서에서 상대방 UID 찾기...');
    final chatroomDoc =
        await FirebaseFirestore.instance
            .collection('chatrooms')
            .doc(chatroomId)
            .get();

    debugPrint('🔍 chatroom 문서 존재: ${chatroomDoc.exists}');
    debugPrint('🔍 chatroom 데이터: ${chatroomDoc.data()}');

    if (!chatroomDoc.exists) return null;

    final users = chatroomDoc.data()?['users'] as List<dynamic>?;
    debugPrint('🔍 채팅방 사용자 목록: $users');
    return users?.firstWhere((uid) => uid != myUid, orElse: () => null);
  }

  // Update connection status in Firestore
  Future<void> _updateConnectionStatus(
    String myUid,
    String? otherUserUid,
    String chatroomId,
  ) async {
    debugPrint('🚀 Firebase 트랜잭션 시작...');
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Update my user document
      debugPrint('📝 내 문서 업데이트 중...');
      transaction.update(
        FirebaseFirestore.instance.collection('users').doc(myUid),
        {'connect_status': false},
      );

      // Update other user's document
      if (otherUserUid != null) {
        debugPrint('📝 상대방 문서 업데이트 중...');
        transaction.update(
          FirebaseFirestore.instance.collection('users').doc(otherUserUid),
          {'connect_status': false},
        );
      }

      // Update chatroom status
      debugPrint('📝 채팅방 문서 업데이트 중...');
      transaction.update(
        FirebaseFirestore.instance.collection('chatrooms').doc(chatroomId),
        {
          'status': 'disconnected',
          'disconnectedAt': FieldValue.serverTimestamp(),
        },
      );

      // Update shared home status
      debugPrint('📝 shared_home 문서 업데이트 중...');
      transaction.update(
        FirebaseFirestore.instance.collection('shared_homes').doc(chatroomId),
        {
          'status': 'disconnected',
          'disconnectedAt': FieldValue.serverTimestamp(),
        },
      );
    });
    debugPrint('✅ 트랜잭션 완료');
  }

  // Clean up invite documents
  Future<void> _cleanupInvites(String myUid, String? otherUserUid) async {
    if (otherUserUid == null) {
      debugPrint('⚠️ otherUserUid가 null - invites 정리 건너뜀');
      return;
    }

    debugPrint('🗑️ invites 문서 정리 시작...');
    try {
      final batch = FirebaseFirestore.instance.batch();
      final myInviteRef = FirebaseFirestore.instance
          .collection('invites')
          .doc('${myUid}_$otherUserUid');
      final otherInviteRef = FirebaseFirestore.instance
          .collection('invites')
          .doc('${otherUserUid}_$myUid');

      debugPrint(
        '🗑️ 삭제할 invites: ${myUid}_$otherUserUid, ${otherUserUid}_$myUid',
      );
      batch.delete(myInviteRef);
      batch.delete(otherInviteRef);

      await batch.commit();
      debugPrint('✅ invites 문서 정리 완료');
    } catch (e) {
      debugPrint('❌ 초대 문서 정리 중 오류: $e');
    }
  }

  // Handle disconnection errors
  void _handleDisconnectionError(
    BuildContext context,
    Object e,
    StackTrace stackTrace,
  ) {
    debugPrint('❌ 연결 해제 중 오류: $e');
    debugPrint('📋 스택트레이스: $stackTrace');
    Navigator.pop(context); // Close loading dialog
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('연결 해제 중 오류가 발생했습니다: $e')));
    }
  }

  // Handle logout with app state and notification cleanup
  void _handleLogout(BuildContext context) async {
    try {
      // 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('로그아웃 중...'),
                ],
              ),
            ),
      );

      // 앱 상태 정리
      await AppStateService().clearAppState();
      debugPrint('✅ 앱 상태 정리 완료');

      // FCM 토큰 제거
      await NotificationService().removeFCMToken();
      debugPrint('✅ FCM 토큰 제거 완료');

      // Firebase Auth 로그아웃
      await FirebaseAuth.instance.signOut();
      debugPrint('✅ Firebase 로그아웃 완료');

      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.pop(context);
        // 로그아웃 후 홈 화면으로 이동
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (error) {
      debugPrint('❌ 로그아웃 실패: $error');

      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.pop(context);
        // 오류 처리
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('로그아웃 실패: $error')));
      }
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
      body: _buildUserDataStream(user.uid, context),
    );
  }

  // Build stream for user data
  Widget _buildUserDataStream(String uid, BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('사용자 정보를 불러올 수 없습니다.'));
        }

        return _buildSettingsContent(context, snapshot.data!);
      },
    );
  }

  // Build settings content
  Widget _buildSettingsContent(BuildContext context, DocumentSnapshot userDoc) {
    final userData = userDoc.data() as Map<String, dynamic>;
    final isConnected = userData['connect_status'] == true;
    final hasPendingInvites =
        userData['pendingInvites'] != null &&
        (userData['pendingInvites'] as List).isNotEmpty;

    debugPrint('🔍 현재 연결 상태: $isConnected');
    debugPrint('🔍 대기 중인 초대: $hasPendingInvites');
    debugPrint('🔍 사용자 데이터: $userData');

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

          // Disconnect button (shown when connected and no pending invites)
          if (isConnected && !hasPendingInvites) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.link_off),
              label: const Text('상대방과 연결 해제'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _handleDisconnect(context),
            ),
            const SizedBox(height: 16),
          ],

          // Connection status display
          _buildConnectionStatus(isConnected, hasPendingInvites),
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
  }

  // Build connection status widget
  Widget _buildConnectionStatus(bool isConnected, bool hasPendingInvites) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isConnected ? Icons.link : Icons.link_off,
                color: isConnected ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                isConnected ? '연결됨' : '연결되지 않음',
                style: TextStyle(
                  color: isConnected ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (hasPendingInvites) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '초대 대기 중',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
