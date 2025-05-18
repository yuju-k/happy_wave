import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

class ChatWidget extends StatelessWidget {
  final String chatRoomId;
  final List<types.Message> messages;
  final String currentUserId;

  const ChatWidget({
    super.key,
    required this.chatRoomId,
    required this.messages,
    required this.currentUserId,
  });

  /// 메시지를 Firestore에 전송합니다.
  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: types.User(id: currentUserId),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      text: message.text,
    );

    FirebaseFirestore.instance
        .collection('chatrooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
          'authorId': currentUserId,
          'createdAt': Timestamp.now(),
          'text': message.text,
        });
  }

  @override
  Widget build(BuildContext context) {
    return Text('구현해야됨');
  }
}
