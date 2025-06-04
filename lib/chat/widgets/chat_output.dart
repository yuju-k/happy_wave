import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:intl/intl.dart';
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

  // 각 메시지별로 원본 컨테이너 표시 상태를 관리하는 맵
  final Map<String, bool> _showOriginalMap = {};

  @override
  void initState() {
    super.initState();
    _subscribeToMessages();
  }

  /// 실시간 메시지 스트림을 구독하여 새 메시지를 수신합니다.
  void _subscribeToMessages() {
    try {
      _messageService
          .streamNewMessages(widget.chatRoomId)
          .listen(
            (newMessage) {
              if (!mounted) return;

              setState(() {
                _messages.add(newMessage);
                // 새 메시지의 원본 컨테이너는 기본적으로 숨김
                _showOriginalMap[newMessage.id] = false;
              });

              // 다음 프레임에서 스크롤을 리스트 끝으로 이동
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToEnd();
              });
            },
            onError: (error) {
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('메시지 스트림 오류: $error')));
              }
            },
          );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('메시지 구독 초기화 오류: $error')));
      }
    }
  }

  /// 스크롤을 리스트의 끝으로 부드럽게 이동합니다.
  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// 원본 컨테이너 표시 상태를 토글합니다.
  void _toggleOriginalContainer(String messageId) {
    setState(() {
      _showOriginalMap[messageId] = !(_showOriginalMap[messageId] ?? false);
    });
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
        final message = _messages[index];
        if (message is! types.TextMessage) return const SizedBox.shrink();

        final isMyMessage = message.author.id == widget.myUserId;
        final createdTime = DateTime.fromMillisecondsSinceEpoch(
          message.createdAt!,
        );
        final formattedTime = DateFormat('HH:mm').format(createdTime);

        return _buildMessageBubble(
          context,
          message: message,
          isMyMessage: isMyMessage,
          formattedTime: formattedTime,
        );
      },
    );
  }

  /// 메시지 버블 UI를 생성합니다.
  Widget _buildMessageBubble(
    BuildContext context, {
    required types.TextMessage message,
    required bool isMyMessage,
    required String formattedTime,
  }) {
    final showOriginal = _showOriginalMap[message.id] ?? false;
    final isConverted = message.metadata?['converted'] as bool? ?? false;
    final textOriginalMessage =
        message.metadata?['originalMessage'] as String? ?? '';

    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isMyMessage
                  ? const Color.fromARGB(255, 212, 250, 253)
                  : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 메시지 텍스트와 시간/아이콘을 함께 배치
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 메시지 텍스트
                  Expanded(
                    child: Text(
                      message.text,
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      softWrap: true,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 시간과 아이콘
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (isConverted) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _toggleOriginalContainer(message.id),
                              child: Icon(
                                Icons.auto_fix_high,
                                size: 18,
                                color:
                                    showOriginal
                                        ? Colors.grey
                                        : const Color(0xFF389EA9),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // 원본 컨테이너를 조건부로 표시
              if (showOriginal) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Color(0xFF389EA9), width: 3.0),
                    ),
                    color: Color(0xFFF5F5F5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '원본 메시지',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF389EA9),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        textOriginalMessage,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
