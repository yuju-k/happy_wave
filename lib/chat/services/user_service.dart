import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final _firestore = FirebaseFirestore.instance;

  /// 사용자 UID로 채팅방 ID를 조회합니다.
  Future<String?> fetchChatRoomIdForUser(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      return userDoc.data()?['chatroomId'] as String?;
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
      final chatRoomDoc =
          await _firestore.collection('chatrooms').doc(roomId).get();
      final users = chatRoomDoc.data()?['users'] as List<dynamic>?;
      if (users == null || users.isEmpty) {
        debugPrint('No users found in chatroom $roomId');
        return null;
      }

      final otherUserUid = users.firstWhere(
        (uid) => uid != myUid,
        orElse: () => null,
      );
      if (otherUserUid == null) {
        debugPrint('No other user found in chatroom $roomId');
        return null;
      }

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
}
