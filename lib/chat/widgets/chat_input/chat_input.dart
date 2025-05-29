import 'package:flutter/material.dart';
import 'chat_input_controller.dart';
import 'chat_input_ui.dart';

class ChatInput extends StatefulWidget {
  final String chatRoomId;
  final String myUserId;
  final String myName;

  const ChatInput({
    super.key,
    required this.chatRoomId,
    required this.myUserId,
    required this.myName,
  });

  @override
  ChatInputState createState() => ChatInputState();
}

class ChatInputState extends State<ChatInput> {
  late final ChatInputController _controller;
  late final ChatInputUI _ui;

  @override
  void initState() {
    super.initState();
    _controller = ChatInputController(
      chatRoomId: widget.chatRoomId,
      myUserId: widget.myUserId,
      myName: widget.myName,
      onStateChanged: () => setState(() {}),
      onShowSnackBar: _showSnackBar,
    );
    _ui = ChatInputUI(controller: _controller);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), action: action));
  }

  @override
  Widget build(BuildContext context) {
    return _ui.build(context);
  }
}
