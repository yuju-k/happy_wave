import 'package:flutter/material.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../services/message_send.dart';

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
  final TextEditingController _controller = TextEditingController();

  /// 메시지를 전송하고 감정 분석을 수행합니다.
  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      // 감정 분석 먼저 수행
      await _analyzeSentiment(text);

      // 메시지 전송
      await sendMessageToRoom(
        roomId: widget.chatRoomId,
        text: text,
        authorId: widget.myUserId,
        authorName: widget.myName,
      );

      if (mounted) {
        _controller.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('메시지 전송 중 오류: $e')));
      }
    }
  }

  /// 입력된 메시지의 감정을 분석합니다 (positive, negative, neutral).
  Future<void> _analyzeSentiment(String message) async {
    try {
      final model = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-2.0-flash',
      );

      final prompt = [
        Content.text('이 메시지의 감정을 분석해줘. positive, negative, neutral 중 하나로 출력해.'),
        Content.text(message),
      ];

      final response = await model.generateContent(prompt);
      final sentiment = response.text?.trim() ?? '분석 실패';

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('감정 분석 결과: $sentiment')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('감정 분석 중 오류: $e')));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: '메시지를 입력하세요',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send),
            onPressed: _handleSend,
          ),
        ),
        onSubmitted: (_) => _handleSend(),
      ),
    );
  }
}
