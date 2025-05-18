import 'package:flutter/material.dart';

class ChatOutput extends StatefulWidget {
  final String? chatRoomId;
  final String? myName;
  final String? myUserId;
  final String? otherUserName;
  final String? otherUserId;

  const ChatOutput({
    super.key,
    this.chatRoomId,
    this.myName,
    this.otherUserName,
    this.otherUserId,
    this.myUserId,
  });

  @override
  State<ChatOutput> createState() => _ChatOutputState();
}

class _ChatOutputState extends State<ChatOutput> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
