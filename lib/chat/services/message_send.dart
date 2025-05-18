import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> sendMessageToRoom({
  required String roomId,
  required String text,
  required String authorId,
  required String authorName,
}) async {
  final firestore = FirebaseFirestore.instance;
  try {
    await firestore.runTransaction((transaction) async {
      final messageRef =
          firestore
              .collection('chatrooms')
              .doc(roomId)
              .collection('messages')
              .doc();

      final message = {
        'text': text,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      transaction.set(messageRef, message);
      transaction.update(firestore.collection('chatrooms').doc(roomId), {
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    });
  } catch (e) {
    print('Error sending message to room $roomId: $e');
    rethrow;
  }
}
