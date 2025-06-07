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
      if (user == null) return;

      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final userDoc = await userDocRef.get();
      final userData = userDoc.data();

      if (userData == null) {
        Navigator.of(context).pop(); // 로딩 닫기
        return;
      }

      final homeId = userData['homeId'] as String?;
      final chatroomId = userData['chatroomId'] as String?;

      if (homeId != null) {
        // shared_home에서 상대방 UID 찾기
        final sharedHomeDoc =
            await FirebaseFirestore.instance
                .collection('shared_homes')
                .doc(homeId)
                .get();

        String? otherUserUid;
        if (sharedHomeDoc.exists) {
          final users = sharedHomeDoc.data()?['users'] as List<dynamic>?;
          if (users != null) {
            otherUserUid = users.firstWhere(
              (uid) => uid != user.uid,
              orElse: () => null,
            );
          }
        }

        // Firestore 트랜잭션으로 연결 상태만 변경 (데이터는 보존)
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          // 내 문서에서 연결 상태만 false로 변경 (homeId, chatroomId는 보존)
          transaction.update(userDocRef, {'connect_status': false});

          // 상대방 문서에서도 연결 상태만 false로 변경
          if (otherUserUid != null) {
            final otherUserRef = FirebaseFirestore.instance
                .collection('users')
                .doc(otherUserUid);
            transaction.update(otherUserRef, {'connect_status': false});
          }

          // shared_home 문서의 상태를 'disconnected'로 변경 (삭제하지 않음)
          final sharedHomeRef = FirebaseFirestore.instance
              .collection('shared_homes')
              .doc(homeId);
          transaction.update(sharedHomeRef, {
            'status': 'disconnected',
            'disconnectedAt': FieldValue.serverTimestamp(),
          });

          // 채팅방 문서도 보존하되 상태만 변경
          if (chatroomId != null) {
            final chatroomRef = FirebaseFirestore.instance
                .collection('chatrooms')
                .doc(chatroomId);
            transaction.update(chatroomRef, {
              'status': 'disconnected',
              'disconnectedAt': FieldValue.serverTimestamp(),
            });
          }
        });

        // invites 문서는 정리 (재연결을 위해 새로운 초대 필요)
        await _cleanupInvites(user.uid, otherUserUid);
      }

      Navigator.of(context).pop(); // 로딩 닫기

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연결이 해제되었습니다. 대화 기록은 보존됩니다.')),
        );
      }
    } catch (e) {
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
      if (otherUserUid == null) return;

      final batch = FirebaseFirestore.instance.batch();

      // 내가 보낸 초대
      final myInviteRef = FirebaseFirestore.instance
          .collection('invites')
          .doc('${myUid}_$otherUserUid');

      // 상대방이 보낸 초대
      final otherInviteRef = FirebaseFirestore.instance
          .collection('invites')
          .doc('${otherUserUid}_$myUid');

      batch.delete(myInviteRef);
      batch.delete(otherInviteRef);

      await batch.commit();
    } catch (e) {
      debugPrint('초대 문서 정리 중 오류: $e');
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
