import 'dart:convert';

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
  final _model = FirebaseVertexAI.instance.generativeModel(
    model: 'gemini-2.0-flash',
  );
  String _originalMessage = '';
  String _sentimentResult = '';
  String _suggestionResult = '';
  late final ChatSession _chat;
  final List<Content> _history = []; // 대화 기록을 저장할 리스트

  @override
  void initState() {
    super.initState();
    _initializeChatSession(); //초기 대화 기록 로드
  }

  Future<void> _initializeChatSession() async {
    // 최근 10개 메시지 가져오기
    final pastMessages = await MessageService().getRecentMessages(
      roomId: widget.chatRoomId,
      limit: 10,
    );

    // 토큰 제한을 고려해 메시지 길이 제한
    var totalLength = 0;
    const maxLength = 2000; // 예: 2000자로 제한

    for (final msg in pastMessages) {
      if (totalLength + msg.text.length <= maxLength) {
        _history.add(Content('user', [TextPart(msg.text)]));
        totalLength += msg.text.length;
      } else {
        break;
      }
    }

    // 초기 대화 세션 시작
    _chat = _model.startChat(history: _history);
  }

  /// 메시지를 전송하고 감정 분석을 수행합니다.
  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      _originalMessage = text;
      // 감정 분석 먼저 수행
      await _analyzeSentiment(_originalMessage);

      // 메시지 전송
      await sendMessageToRoom(
        roomId: widget.chatRoomId,
        text: _originalMessage,
        authorId: widget.myUserId,
        authorName: widget.myName,
        sentimentResult: _sentimentResult,
        suggestionResult: _suggestionResult,
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
      // 새로운 메시지를 history에 추가
      _history.add(Content('user', [TextPart(message)]));

      const sentimentPrompt = '''
      다음 대화 맥락을 참고하여 마지막 사용자 메시지의 대화 태도를 분석해주세요.
      Positive, Negative, Neutral 중 하나로만 응답하세요.
      ''';

      final sentimentResponse = await _chat.sendMessage(
        Content.text(sentimentPrompt),
      );
      final sentiment =
          sentimentResponse.text?.toLowerCase().trim() ?? 'neutral';

      if (!['positive', 'negative', 'neutral'].contains(sentiment)) {
        _showSnackBar('유효하지 않은 감정 분석 결과. 기본값(neutral)으로 처리됩니다.');
        _sentimentResult = 'neutral';
        _suggestionResult = '';
        return;
      }

      print('감정: $_sentimentResult');
      _sentimentResult = sentiment;
      _suggestionResult = '';
      if (sentiment == 'negative') {
        // 제안 문장 생성 프롬프트
        const suggestionPrompt = '''
        다음 대화 맥락을 참고하여 마지막 사용자 메시지를 보다 긍정적이거나 중립적으로 변환해주세요.
        변환된 문장만 출력하세요.
        ''';

        final suggestionResponse = await _chat.sendMessage(
          Content.text(suggestionPrompt),
        );
        _suggestionResult = suggestionResponse.text?.trim() ?? '(제안 실패)';

        // AI 응답을 history에 추가
        _history.add(Content('assistant', [TextPart(_suggestionResult)]));

        if (mounted) {
          print('제안 메시지: $_suggestionResult');
        }
      }
    } catch (e) {
      print('감정 분석 중 오류 발생: $e');
      if (mounted) {
        _showSnackBar('감정 분석에 실패했습니다. 메시지를 전송합니다.');
        _sentimentResult = 'neutral';
        _suggestionResult = '';
      }
    }
  }

  void _showSnackBar(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), action: action));
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
