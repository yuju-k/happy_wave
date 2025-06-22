import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../services/app_state_service.dart';

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

    // 메시지 전송 후 상대방에게 알림 보내기
    await _sendNotificationToOtherUser(
      roomId: roomId,
      senderName: authorName,
      messageText: text,
      senderId: authorId,
    );
  } catch (e) {
    //print('Error sending message to room $roomId: $e');
    rethrow;
  }
}

// 상대방에게 알림 전송 (백그라운드/종료 상태에서만)
Future<void> _sendNotificationToOtherUser({
  required String roomId,
  required String senderName,
  required String messageText,
  required String senderId,
}) async {
  try {
    final firestore = FirebaseFirestore.instance;

    // 채팅방의 모든 사용자 가져오기
    final chatRoomDoc =
        await firestore.collection('chatrooms').doc(roomId).get();
    final users = List<String>.from(chatRoomDoc.data()?['users'] ?? []);

    // 상대방 UID 찾기 (자신 제외)
    final receiverUid = users.firstWhere(
      (uid) => uid != senderId,
      orElse: () => '',
    );

    if (receiverUid.isNotEmpty) {
      // 상대방이 앱을 사용 중인지 확인
      final isReceiverAppActive = await AppStateService().isUserAppActive(
        receiverUid,
      );

      if (!isReceiverAppActive) {
        // 상대방이 앱을 사용하지 않는 경우에만 알림 전송
        await NotificationService().sendMessageNotification(
          receiverUid: receiverUid,
          senderName: senderName,
          messageText: messageText,
          chatRoomId: roomId,
        );
        debugPrint('상대방이 앱을 사용하지 않으므로 알림을 전송했습니다.');
      } else {
        debugPrint('상대방이 앱을 사용 중이므로 알림을 전송하지 않습니다.');
      }
    }
  } catch (e) {
    print('알림 전송 중 오류: $e');
    // 알림 전송 실패해도 메시지 전송은 성공으로 처리
  }
}
