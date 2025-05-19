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
      //print('Error streaming messages for room $roomId: $e');
      rethrow;
    }
  }

  // 최근 메시지를 불러옴
  /// 최근 메시지들을 불러옵니다 (최신순 정렬, 기본 10개).
  Future<List<types.TextMessage>> getRecentMessages({
    required String roomId,
    int limit = 10,
  }) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('chatrooms')
              .doc(roomId)
              .collection('messages')
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      final messages =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return types.TextMessage(
              id: doc.id,
              author: types.User(id: data['authorId'] as String),
              createdAt:
                  data['createdAt'] is Timestamp
                      ? (data['createdAt'] as Timestamp).millisecondsSinceEpoch
                      : DateTime.now().millisecondsSinceEpoch,
              text: data['text'] as String,
            );
          }).toList();

      return messages.reversed.toList(); // 오래된 순서로 변경 (context 순서 유지)
    } catch (e) {
      print('getRecentMessages 오류: $e');
      rethrow;
    }
  }
}
