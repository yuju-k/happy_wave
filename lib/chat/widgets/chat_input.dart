import 'package:flutter/material.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../services/message_send.dart';
import '../services/message_service.dart';

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

  Future<void> _analyzeSentiment(String message) async {
    try {
      final model = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-2.0-flash',
      );

      final model2 = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-2.0-flash',
      );

      // ① 최근 메시지 불러오기
      final pastMessages = await MessageService().getRecentMessages(
        roomId: widget.chatRoomId,
      );

      // ② 감정 분석용 히스토리 구성
      final sentimentHistory = <Content>[
        Content.text(
          '다음 대화 맥락을 참고하여 마지막 사용자 메시지의 대화 태도를 분석해주세요. '
          'Positive, Negative, Neutral 중 하나로만 응답하세요.',
        ),
      ];

      for (final msg in pastMessages) {
        sentimentHistory.add(Content('user', [TextPart(msg.text)]));
      }

      sentimentHistory.add(Content('user', [TextPart(message)]));

      final chat = model.startChat(history: sentimentHistory);

      // ③ 감정 분석 요청 (빈 메시지 보내지 않음!)
      final response = await chat.sendMessage(
        Content.text("Analyze the sentiment"),
      );

      final sentiment = response.text?.toLowerCase().trim() ?? 'unknown';
      print('감정 분석 결과: $sentiment');

      // ④ Negative일 경우, 대체 메시지 생성
      if (sentiment.contains('negative')) {
        final suggestionHistory = <Content>[
          Content.text(
            '다음 대화 맥락을 참고하여 마지막 사용자 메시지를 보다 긍정적이거나 중립적으로 변환해주세요. '
            '변환된 문장만 출력하세요.',
          ),
        ];

        for (final msg in pastMessages) {
          suggestionHistory.add(Content('user', [TextPart(msg.text)]));
        }

        suggestionHistory.add(Content('user', [TextPart(message)]));

        final chat2 = model2.startChat(history: suggestionHistory);
        final suggestionResponse = await chat2.sendMessage(
          Content.text("Suggest alternative"),
        );

        final suggestion = suggestionResponse.text?.trim() ?? '(제안 실패)';
        print('메시지 제안: $suggestion');

        // 원하신다면 여기에 UI로 메시지 제안을 전달하는 로직 삽입 가능
      }
    } catch (e) {
      print('감정 분석 중 오류 발생: $e');
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
