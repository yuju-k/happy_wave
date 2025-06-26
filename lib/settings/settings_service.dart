import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsService {
  // Fetch user data stream
  Stream<DocumentSnapshot> getUserStream(String uid) {
    debugPrint('🔍 사용자 데이터 스트림 시작: $uid');
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  // Perform disconnection
  Future<void> disconnect(BuildContext context) async {
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
        if (!context.mounted) return;
        Navigator.pop(context);
        return;
      }

      final chatroomId = userData['chatroomId'] as String?;
      if (chatroomId == null) {
        debugPrint('❌ chatroomId가 없음 - 연결된 상태가 아님');
        if (!context.mounted) return;
        Navigator.pop(context);
        return;
      }

      final otherUserUid = await _findOtherUserUid(chatroomId, user.uid);
      await _updateConnectionStatus(user.uid, otherUserUid, chatroomId);
      await _cleanupInvites(user.uid, otherUserUid);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연결이 해제되었습니다. 대화 기록은 보존됩니다.')),
        );
      }
      debugPrint('🎉 연결 해제 완료');
    } catch (e, stackTrace) {
      _handleError(context, e, stackTrace);
    }
  }

  // Fetch user data
  Future<Map<String, dynamic>?> _fetchUserData(String uid) async {
    debugPrint('🔍 사용자 문서 조회: $uid');
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = userDoc.data();
    debugPrint('🔍 사용자 데이터: $userData');
    return userData;
  }

  // Find other user's UID in chatroom
  Future<String?> _findOtherUserUid(String chatroomId, String myUid) async {
    debugPrint('🔍 채팅방에서 상대방 UID 조회: $chatroomId');
    final chatroomDoc =
        await FirebaseFirestore.instance
            .collection('chatrooms')
            .doc(chatroomId)
            .get();

    debugPrint('🔍 채팅방 존재: ${chatroomDoc.exists}');
    debugPrint('🔍 채팅방 데이터: ${chatroomDoc.data()}');

    if (!chatroomDoc.exists) return null;

    final users = chatroomDoc.data()?['users'] as List<dynamic>?;
    debugPrint('🔍 채팅방 사용자 목록: $users');
    return users?.firstWhere((uid) => uid != myUid, orElse: () => null);
  }

  // Update connection status
  Future<void> _updateConnectionStatus(
    String myUid,
    String? otherUserUid,
    String chatroomId,
  ) async {
    debugPrint('🚀 Firestore 트랜잭션 시작');
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Update my user document
      debugPrint('📝 내 문서 업데이트: $myUid');
      transaction.update(
        FirebaseFirestore.instance.collection('users').doc(myUid),
        {'connect_status': false},
      );

      // Update other user's document
      if (otherUserUid != null) {
        debugPrint('📝 상대방 문서 업데이트: $otherUserUid');
        transaction.update(
          FirebaseFirestore.instance.collection('users').doc(otherUserUid),
          {'connect_status': false},
        );
      }

      // Update chatroom status
      debugPrint('📝 채팅방 문서 업데이트: $chatroomId');
      transaction.update(
        FirebaseFirestore.instance.collection('chatrooms').doc(chatroomId),
        {
          'status': 'disconnected',
          'disconnectedAt': FieldValue.serverTimestamp(),
        },
      );

      // Update shared home status
      debugPrint('📝 shared_home 문서 업데이트: $chatroomId');
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
      debugPrint('⚠️ otherUserUid가 null - 초대 정리 생략');
      return;
    }

    debugPrint('🗑️ 초대 문서 정리 시작');
    try {
      final batch = FirebaseFirestore.instance.batch();
      final myInviteRef = FirebaseFirestore.instance
          .collection('invites')
          .doc('${myUid}_$otherUserUid');
      final otherInviteRef = FirebaseFirestore.instance
          .collection('invites')
          .doc('${otherUserUid}_$myUid');

      debugPrint('🗑️ 삭제할 초대: ${myUid}_$otherUserUid, ${otherUserUid}_$myUid');
      batch.delete(myInviteRef);
      batch.delete(otherInviteRef);

      await batch.commit();
      debugPrint('✅ 초대 문서 정리 완료');
    } catch (e) {
      debugPrint('❌ 초대 문서 정리 오류: $e');
    }
  }

  // Handle errors
  void _handleError(BuildContext context, Object e, StackTrace stackTrace) {
    debugPrint('❌ 오류 발생: $e');
    debugPrint('📋 스택트레이스: $stackTrace');
    Navigator.pop(context); // Close loading dialog
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('연결 해제 중 오류가 발생했습니다: $e')));
    }
  }
}
