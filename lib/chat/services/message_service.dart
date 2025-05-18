import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class MessageService {
  /// 주어진 채팅방 ID에 대한 실시간 메시지 스트림을 제공합니다.
  Stream<List<types.Message>> getMessagesStream(String roomId) {
    return FirebaseFirestore.instance
        .collection('chatrooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                return types.TextMessage(
                  id: doc.id,
                  author: types.User(id: data['authorId'] as String),
                  createdAt:
                      (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
                  text: data['text'] as String,
                );
              }).toList(),
        );
  }
}
