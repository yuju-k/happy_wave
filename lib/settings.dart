import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _onProfileSettings(BuildContext context) {
    Navigator.pushNamed(context, '/profile');
  }

  void _onDisconnect(BuildContext context) async {
    // 연결 해제 확인 다이얼로그 표시
    final shouldDisconnect = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('연결 해제'),
            content: const Text(
              '정말로 상대방과의 연결을 해제하시겠습니까?\n대화 기록은 보존되며, 재연결 시 다시 볼 수 있습니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('해제', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );

    if (shouldDisconnect == true) {
      await _performDisconnection(context);
    }
  }

  Future<void> _performDisconnection(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('🔍 현재 사용자: ${user?.uid}');

      if (user == null) {
        debugPrint('❌ 사용자가 로그인되어 있지 않음');
        return;
      }

      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      debugPrint('🔍 사용자 문서 조회 시작...');
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final userDoc = await userDocRef.get();
      final userData = userDoc.data();

      debugPrint('🔍 사용자 데이터: $userData');

      if (userData == null) {
        debugPrint('❌ 사용자 데이터가 없음');
        Navigator.of(context).pop(); // 로딩 닫기
        return;
      }

      final chatroomId = userData['chatroomId'] as String?;

      debugPrint('🔍 chatroomId: $chatroomId');

      if (chatroomId != null) {
        debugPrint('🔍 채팅방 문서에서 상대방 UID 찾기...');
        final chatroomDoc =
            await FirebaseFirestore.instance
                .collection('chatrooms')
                .doc(chatroomId)
                .get();

        debugPrint('🔍 chatroom 문서 존재: ${chatroomDoc.exists}');
        debugPrint('🔍 chatroom 데이터: ${chatroomDoc.data()}');

        String? otherUserUid;
        if (chatroomDoc.exists) {
          final users = chatroomDoc.data()?['users'] as List<dynamic>?;
          debugPrint('🔍 채팅방 사용자 목록: $users');

          if (users != null) {
            otherUserUid = users.firstWhere(
              (uid) => uid != user.uid,
              orElse: () => null,
            );
          }
        }

        debugPrint('🔍 상대방 UID: $otherUserUid');

        // 트랜잭션 시작 전 로그
        debugPrint('🚀 Firebase 트랜잭션 시작...');

        // Firestore 트랜잭션으로 연결 상태만 변경 (데이터는 보존)
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          debugPrint('📝 내 문서 업데이트 중...');
          // 내 문서에서 연결 상태만 false로 변경
          transaction.update(userDocRef, {'connect_status': false});

          // 상대방 문서에서도 연결 상태만 false로 변경
          if (otherUserUid != null) {
            debugPrint('📝 상대방 문서 업데이트 중...');
            final otherUserRef = FirebaseFirestore.instance
                .collection('users')
                .doc(otherUserUid);
            transaction.update(otherUserRef, {'connect_status': false});
          }

          // 채팅방 문서 상태 업데이트
          debugPrint('📝 채팅방 문서 업데이트 중...');
          final chatroomRef = FirebaseFirestore.instance
              .collection('chatrooms')
              .doc(chatroomId);
          transaction.update(chatroomRef, {
            'status': 'disconnected',
            'disconnectedAt': FieldValue.serverTimestamp(),
          });

          // shared_home이 존재한다면 상태 업데이트 (homeId와 chatroomId가 같다고 가정)
          debugPrint('📝 shared_home 문서 확인 및 업데이트...');
          final sharedHomeRef = FirebaseFirestore.instance
              .collection('shared_homes')
              .doc(chatroomId);

          // shared_home 문서가 존재하는지 확인하고 업데이트
          // 트랜잭션 내에서는 get()을 사용할 수 없으므로, 업데이트만 시도
          transaction.update(sharedHomeRef, {
            'status': 'disconnected',
            'disconnectedAt': FieldValue.serverTimestamp(),
          });
        });

        debugPrint('✅ 트랜잭션 완료');

        // invites 문서는 정리 (재연결을 위해 새로운 초대 필요)
        debugPrint('🗑️ invites 문서 정리 중...');
        await _cleanupInvites(user.uid, otherUserUid);
      } else {
        debugPrint('❌ chatroomId가 없음 - 연결된 상태가 아님');
      }

      Navigator.of(context).pop(); // 로딩 닫기

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연결이 해제되었습니다. 대화 기록은 보존됩니다.')),
        );
      }

      debugPrint('🎉 연결 해제 완료');
    } catch (e, stackTrace) {
      debugPrint('❌ 연결 해제 중 오류: $e');
      debugPrint('📋 스택트레이스: $stackTrace');

      Navigator.of(context).pop(); // 로딩 닫기
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('연결 해제 중 오류가 발생했습니다: $e')));
      }
    }
  }

  // invites 문서 정리
  Future<void> _cleanupInvites(String myUid, String? otherUserUid) async {
    try {
      if (otherUserUid == null) {
        debugPrint('⚠️ otherUserUid가 null - invites 정리 건너뜀');
        return;
      }

      debugPrint('🗑️ invites 문서 정리 시작...');
      final batch = FirebaseFirestore.instance.batch();

      // 내가 보낸 초대
      final myInviteRef = FirebaseFirestore.instance
          .collection('invites')
          .doc('${myUid}_$otherUserUid');

      // 상대방이 보낸 초대
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

  void _onLogout(BuildContext context) {
    FirebaseAuth.instance
        .signOut()
        .then((_) {
          Navigator.pushReplacementNamed(context, '/');
        })
        .catchError((error) {
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
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('사용자 정보를 불러올 수 없습니다.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final isConnected = userData?['connect_status'] == true;
          final hasPendingInvites =
              userData?['pendingInvites'] != null &&
              (userData!['pendingInvites'] as List).isNotEmpty;

          // 디버깅을 위한 로그
          debugPrint('🔍 현재 연결 상태: $isConnected');
          debugPrint('🔍 대기 중인 초대: $hasPendingInvites');
          debugPrint('🔍 사용자 데이터: $userData');

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 프로필 설정 버튼
                ElevatedButton.icon(
                  icon: const Icon(Icons.person),
                  label: const Text('프로필 설정'),
                  onPressed: () => _onProfileSettings(context),
                ),

                const SizedBox(height: 16),

                // 연결 해제 버튼 (연결된 상태일 때만 표시)
                if (isConnected && !hasPendingInvites) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.link_off),
                    label: const Text('상대방과 연결 해제'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _onDisconnect(context),
                  ),
                  const SizedBox(height: 16),
                ],

                // 상태 표시
                Container(
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
                ),

                const SizedBox(height: 16),

                // 로그아웃 버튼
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('로그아웃'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _onLogout(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
