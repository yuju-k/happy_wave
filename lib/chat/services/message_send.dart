//Firestore를 사용하여 메시지를 보내는 기능을 구현합니다.
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> sendMessageToRoom({
  required String roomId,
  required String text,
  required String authorId,
  required String authorName,
}) async {
  final message = {
    'text': text,
    'authorId': authorId,
    'authorName': authorName,
    'createdAt': FieldValue.serverTimestamp(),
    'isRead': false,
  };

  final messageRef =
      FirebaseFirestore.instance
          .collection('chatrooms')
          .doc(roomId)
          .collection('messages')
          .doc();

  await messageRef.set(message);

  // 마지막 메시지 업데이트 (optional)
  await FirebaseFirestore.instance.collection('chatrooms').doc(roomId).update({
    'lastMessage': text,
    'lastMessageAt': FieldValue.serverTimestamp(),
  });
}
