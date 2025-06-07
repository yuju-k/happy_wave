import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final _firestore = FirebaseFirestore.instance;

  /// 두 사용자 UID로 일관된 채팅방 ID 생성
  /// UID를 정렬하여 항상 동일한 순서로 조합
  String _generateConsistentChatRoomId(String uid1, String uid2) {
    final sortedUids = [uid1, uid2]..sort();
    return '${sortedUids[0]}_${sortedUids[1]}';
  }

  /// 사용자 UID로 채팅방 ID를 조회합니다.
  Future<String?> fetchChatRoomIdForUser(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final chatroomId = userDoc.data()?['chatroomId'] as String?;

      if (chatroomId != null) {
        // 채팅방이 실제로 존재하는지 확인
        final chatroomDoc =
            await _firestore.collection('chatrooms').doc(chatroomId).get();
        if (chatroomDoc.exists) {
          return chatroomId;
        } else {
          // 채팅방이 존재하지 않으면 사용자 문서에서 chatroomId 제거
          await _firestore.collection('users').doc(uid).update({
            'chatroomId': FieldValue.delete(),
            'connect_status': false,
          });
          debugPrint('존재하지 않는 채팅방 ID 제거: $chatroomId');
          return null;
        }
      }

      // chatroomId가 없는 경우, shared_homes에서 사용자가 포함된 채팅방 찾기
      final sharedHomesQuery =
          await _firestore
              .collection('shared_homes')
              .where('users', arrayContains: uid)
              .limit(1)
              .get();

      if (sharedHomesQuery.docs.isNotEmpty) {
        final foundChatroomId = sharedHomesQuery.docs.first.id;

        // 사용자 문서에 chatroomId 업데이트
        await _firestore.collection('users').doc(uid).update({
          'chatroomId': foundChatroomId,
        });

        debugPrint('찾은 채팅방 ID를 사용자 문서에 업데이트: $foundChatroomId');
        return foundChatroomId;
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching chat room ID for UID $uid: $e');
      return null;
    }
  }

  /// 사용자 UID로 자신의 프로필을 조회합니다.
  Future<Map<String, String?>?> fetchMyProfile(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists || userDoc.data() == null) {
        debugPrint('User document does not exist or is empty for UID: $uid');
        return null;
      }

      final data = userDoc.data()!;
      return {
        'name': data['name'] as String?,
        'profileImageUrl': data['profileImageUrl'] as String?,
      };
    } catch (e) {
      debugPrint('Error fetching profile for UID $uid: $e');
      return null;
    }
  }

  /// 채팅방 ID와 내 UID를 사용해 상대방의 정보를 조회합니다.
  Future<Map<String, String?>?> fetchOtherUserInfo(
    String roomId,
    String myUid,
  ) async {
    try {
      // 채팅방에서 사용자 목록 가져오기
      final chatRoomDoc =
          await _firestore.collection('chatrooms').doc(roomId).get();
      if (!chatRoomDoc.exists) {
        debugPrint('Chatroom does not exist: $roomId');
        return null;
      }

      final users = chatRoomDoc.data()?['users'] as List<dynamic>?;
      if (users == null || users.isEmpty) {
        debugPrint('No users found in chatroom $roomId');
        return null;
      }

      // 상대방 UID 찾기
      final otherUserUid = users.firstWhere(
        (uid) => uid != myUid,
        orElse: () => null,
      );

      if (otherUserUid == null) {
        debugPrint('No other user found in chatroom $roomId');
        return null;
      }

      // 상대방 정보 가져오기
      final otherUserDoc =
          await _firestore.collection('users').doc(otherUserUid).get();
      final data = otherUserDoc.data();
      if (data == null) {
        debugPrint('No data found for other user $otherUserUid');
        return null;
      }

      return {
        'otherUserId': otherUserUid,
        'otherName': data['name'] as String?,
        'otherProfileImageUrl': data['profileImageUrl'] as String?,
        'otherStatusMessage': data['statusMessage'] as String?,
      };
    } catch (e) {
      debugPrint('Error fetching other user info for room $roomId: $e');
      return null;
    }
  }

  /// 두 사용자 간의 채팅방을 찾거나 생성합니다 (필요한 경우 사용)
  Future<String?> findOrCreateChatRoom(String uid1, String uid2) async {
    try {
      final chatroomId = _generateConsistentChatRoomId(uid1, uid2);
      final chatroomRef = _firestore.collection('chatrooms').doc(chatroomId);

      final chatroomDoc = await chatroomRef.get();

      if (!chatroomDoc.exists) {
        // 채팅방이 존재하지 않으면 생성
        await chatroomRef.set({
          'users': [uid1, uid2],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': null,
        });

        // 양쪽 사용자 문서에 chatroomId 업데이트
        await _firestore.collection('users').doc(uid1).update({
          'chatroomId': chatroomId,
        });
        await _firestore.collection('users').doc(uid2).update({
          'chatroomId': chatroomId,
        });

        debugPrint('새 채팅방 생성: $chatroomId');
      }

      return chatroomId;
    } catch (e) {
      debugPrint('Error finding or creating chatroom: $e');
      return null;
    }
  }
}
