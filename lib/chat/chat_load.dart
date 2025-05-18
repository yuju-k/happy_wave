import 'package:cloud_firestore/cloud_firestore.dart';

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

/// 채팅방 ID와 내 UID를 사용해 상대방의 이름을 조회합니다.
Future<String?> fetchOtherUserName(String roomId, String myUid) async {
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

    return otherUserDoc.data()?['name'] as String?;
  } catch (e) {
    print('Error fetching other user name: $e');
    return null;
  }
}

/// 채팅방 ID와 내 UID를 사용해 상대방의 프로필 이미지 URL을 조회합니다.
Future<String?> fetchOtherUserProfileImage(String roomId, String myUid) async {
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

    return otherUserDoc.data()?['profileImageUrl'] as String?;
  } catch (e) {
    print('Error fetching other user profile image: $e');
    return null;
  }
}
