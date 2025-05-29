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

  bool _isLoading = false; // 로딩 상태 관리

  @override
  void initState() {
    super.initState();
    _initializeChatSession(); //초기 대화 기록 로드
  }

  Future<void> _initializeChatSession() async {
    try {
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
      print('대화 세션 초기화 완료: ${_history.length}개의 메시지 로드됨');
    } catch (e) {
      print('대화 세션 초기화 중 오류 발생: $e');
      _showSnackBar('대화 세션 초기화에 실패했습니다.');
      _chat = _model.startChat(); // 초기화 실패 시 빈 세션 시작
    }
  }

  /// 메시지를 전송하고 감정 분석을 수행합니다.
  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true; // 로딩 시작
    });

    try {
      _originalMessage = text;
      print('전송할 메시지: $_originalMessage');

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
        print('메시지 전송 완료');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('메시지 전송 중 오류: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false; // 로딩 종료
      });
    }
  }

  Future<void> _analyzeSentiment(String message) async {
    try {
      // 새로운 메시지를 history에 추가
      _history.add(Content('user', [TextPart(message)]));

      const sentimentPrompt = '''
      다음 대화 맥락을 참고하여 마지막 사용자 메시지의 대화 태도를 분석해주세요.
      다음 중 하나로만 응답하세요:
      - positive (긍정적)
      - negative (부정적)
      - neutral (중립적)

      응답 형식: 단어 하나만 영어로 답하세요.
      ''';

      final sentimentResponse = await _chat.sendMessage(
        Content.text(sentimentPrompt),
      );

      final rawResponse = sentimentResponse.text?.trim() ?? '';
      print('AI 응답: $rawResponse');

      // 응답에서 감정 키워드 추출
      String extractedSentiment = _extractSentimentFromResponse(rawResponse);

      _sentimentResult = extractedSentiment;
      print('감정 분석 결과: $_sentimentResult');

      // 부정적인 경우 제안 메시지 생성
      if (_sentimentResult == 'negative') {
        await _generateSuggestion(message);
      } else {
        _suggestionResult = '';
        print('제안없음 (감정: $_sentimentResult)');
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

  String _extractSentimentFromResponse(String response) {
    final lowerResponse = response.toLowerCase();

    if (lowerResponse.contains('positive')) {
      return 'positive';
    } else if (lowerResponse.contains('negative')) {
      return 'negative';
    } else if (lowerResponse.contains('neutral')) {
      return 'neutral';
    }

    // 한국어 응답도 처리
    if (lowerResponse.contains('긍정')) {
      return 'positive';
    } else if (lowerResponse.contains('부정')) {
      return 'negative';
    } else if (lowerResponse.contains('중립')) {
      return 'neutral';
    }

    print('⚠️ 알 수 없는 감정 응답, 기본값 사용: $response');
    return 'neutral';
  }

  Future<void> _generateSuggestion(String message) async {
    try {
      final suggestionPrompt = '''
      대화 맥락을 참고하여 마지막 메시지를 긍정적이거나 중립적으로 변환해주세요.
      마지막 메시지: "$message"
      응답 형식: 변환 메시지
      ''';

      final suggestionResponse = await _chat.sendMessage(
        Content.text(suggestionPrompt),
      );

      final rawSuggestion = suggestionResponse.text?.trim() ?? '';
      print('AI 제안: $rawSuggestion');

      _suggestionResult = rawSuggestion;
    } catch (e) {
      print('제안 생성 중 오류 발생: $e');
      if (mounted) {
        _showSnackBar('제안 생성에 실패했습니다.');
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
        enabled: !_isLoading, // 로딩 중에는 입력 비활성화
        decoration: InputDecoration(
          //hintText: '메시지를 입력하세요',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: _buildSendButton(),
        ),
        onSubmitted: (_) => _handleSend(),
      ),
    );
  }

  Widget _buildSendButton() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.send),
      onPressed: _isLoading ? null : _handleSend,
    );
  }
}
