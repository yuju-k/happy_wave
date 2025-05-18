import 'package:flutter/material.dart';
import '../services/message_send.dart'; // sendMessageToRoom 함수 import

class ChatWidget extends StatefulWidget {
  final String? chatRoomId;
  final String? myUserId;
  final String? myName;

  const ChatWidget({super.key, this.chatRoomId, this.myUserId, this.myName});

  @override
  ChatWidgetState createState() => ChatWidgetState();
}

class ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _controller = TextEditingController();

  void _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.chatRoomId == null || widget.myUserId == null)
      return;

    await sendMessageToRoom(
      roomId: widget.chatRoomId!,
      text: text,
      authorId: widget.myUserId!,
      authorName: widget.myName!,
    );

    _controller.clear(); // 입력창 초기화
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: '메시지를 입력하세요',
          suffixIcon: IconButton(
            icon: const Icon(Icons.send),
            onPressed: _handleSend,
          ),
        ),
      ),
    );
  }
}
