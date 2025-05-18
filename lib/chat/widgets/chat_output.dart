import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../services/message_service.dart';

class ChatOutput extends StatefulWidget {
  final String chatRoomId;
  final String myName;
  final String myUserId;
  final String? otherUserName;
  final String? otherUserId;

  const ChatOutput({
    super.key,
    required this.chatRoomId,
    required this.myName,
    required this.myUserId,
    this.otherUserName,
    this.otherUserId,
  });

  @override
  State<ChatOutput> createState() => _ChatOutputState();
}

class _ChatOutputState extends State<ChatOutput> {
  final MessageService _messageService = MessageService();
  final ScrollController _scrollController = ScrollController();
  final List<types.Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _subscribeToMessages();
  }

  /// 실시간 메시지 스트림을 구독합니다.
  void _subscribeToMessages() {
    try {
      _messageService
          .streamNewMessages(widget.chatRoomId)
          .listen(
            (newMsg) {
              if (!mounted) return;

              setState(() {
                _messages.add(newMsg);
              });

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
            },
            onError: (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('메시지 스트림 오류: $e')));
            },
          );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('메시지 구독 초기화 오류: $e')));
    }
  }

  /// 스크롤을 리스트 하단으로 이동합니다.
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        if (msg is! types.TextMessage) return const SizedBox.shrink();

        final isMine = msg.author.id == widget.myUserId;
        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMine ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(msg.text, style: const TextStyle(fontSize: 16)),
          ),
        );
      },
    );
  }
}
