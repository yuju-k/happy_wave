import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> sendMessageToRoom({
  required String roomId,
  required String text,
  required String authorId,
  required String authorName,
  required bool converted,
  required String originalMessage,
  String? sentimentResult,
  String? suggestionResult,
}) async {
  final firestore = FirebaseFirestore.instance;

  try {
    await firestore.runTransaction((transaction) async {
      final chatRoomRef = firestore.collection('chatrooms').doc(roomId);
      final messageRef = chatRoomRef.collection('messages').doc();

      // 메시지 데이터
      final message = {
        'text': text,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': FieldValue.serverTimestamp(),
        'originalMessage': originalMessage,
        'sentimentResult': sentimentResult,
        'suggestionResult': suggestionResult,
        'converted': converted, // 초기값은 false
      };

      // messages/{messageId}에 추가
      transaction.set(messageRef, message);

      // chatroom 문서가 없다면 생성, 있으면 병합
      transaction.set(chatRoomRef, {
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  } catch (e) {
    //print('Error sending message to room $roomId: $e');
    rethrow;
  }
}
