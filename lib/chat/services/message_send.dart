import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:happy_wave/utils/security_util.dart';
import '../../system_log.dart';

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

      var encryptedOriginalMessage = SecurityUtil.encryptChat(originalMessage);
      var encryptedSuggestionResult = SecurityUtil.encryptChat(suggestionResult ?? '');
      var encryptedText = SecurityUtil.encryptChat(text);
      // 메시지 데이터
      final message = {
        'text': encryptedText,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': FieldValue.serverTimestamp(),
        'originalMessage': encryptedOriginalMessage,
        'sentimentResult': sentimentResult,
        'suggestionResult': encryptedSuggestionResult,
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

    // 메시지 카운트 시스템로그
    final SystemLogService systemLogService = SystemLogService();
    systemLogService.logMessageSent(authorId);
  } catch (e) {
    //print('Error sending message to room $roomId: $e');
    print("e : ${e.toString()}");
    rethrow;
  }
}
