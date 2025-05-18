import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  /// 사용자 UID로 채팅방 ID를 조회합니다.
  Future<String?> fetchChatRoomIdForUser(String uid) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return userDoc.data()?['chatroomId'] as String?;
    } catch (e) {
      print('Error fetching chat room ID: $e');
      return null;
    }
  }

  /// 사용자 UID로 자신의 프로필을 조회합니다.
  Future<Map<String, String?>?> fetchMyProfile(String uid) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        print('User document does not exist for UID: $uid');
        return null;
      }

      final data = userDoc.data();
      if (data == null) {
        print('No data found in user document for UID: $uid');
        return null;
      }

      final name = data['name'] as String?;
      final profileImageUrl = data['profileImageUrl'] as String?;
      print(
        'Fetched profile for UID: $uid, name: $name, profileImageUrl: $profileImageUrl',
      );

      return {'name': name, 'profileImageUrl': profileImageUrl};
    } catch (e) {
      print('Error fetching my profile for UID: $uid: $e');
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
          await FirebaseFirestore.instance
              .collection('chatrooms')
              .doc(roomId)
              .get();

      final users = chatRoomDoc.data()?['users'] as List<dynamic>?;
      if (users == null || users.isEmpty) {
        return null;
      }

      final otherUserUid = users.firstWhere(
        (uid) => uid != myUid,
        orElse: () => null,
      );

      if (otherUserUid == null) {
        return null;
      }

      final otherUserDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(otherUserUid)
              .get();

      final data = otherUserDoc.data();
      return {
        'name': data?['name'] as String?,
        'profileImageUrl': data?['profileImageUrl'] as String?,
      };
    } catch (e) {
      print('Error fetching other user info: $e');
      return null;
    }
  }
}
