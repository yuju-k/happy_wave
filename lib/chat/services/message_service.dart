import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class MessageService {
  /// 주어진 채팅방 ID에 대한 실시간 메시지 스트림을 제공합니다.
  Stream<types.Message> streamNewMessages(String roomId) {
    try {
      return FirebaseFirestore.instance
          .collection('chatrooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots()
          .expand((snapshot) => snapshot.docChanges)
          .where((change) => change.type == DocumentChangeType.added)
          .map((change) {
            final data = change.doc.data();
            if (data == null) {
              throw Exception('Message data is null');
            }

            return types.TextMessage(
              id: change.doc.id,
              author: types.User(id: data['authorId'] as String),
              createdAt:
                  data['createdAt'] is Timestamp
                      ? (data['createdAt'] as Timestamp).millisecondsSinceEpoch
                      : DateTime.now().millisecondsSinceEpoch,
              text: data['text'] as String,
            );
          });
    } catch (e) {
      print('Error streaming messages for room $roomId: $e');
      rethrow;
    }
  }
}
