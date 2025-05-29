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
  final List<Content> _history = [];

  bool _isLoading = false; // 메시지 전송 로딩 상태
  bool _showSuggestions = false; // 제안 메시지 표시 여부

  @override
  void initState() {
    super.initState();
    _initializeChatSession();
  }

  Future<void> _initializeChatSession() async {
    try {
      final pastMessages = await MessageService().getRecentMessages(
        roomId: widget.chatRoomId,
        limit: 10,
      );

      var totalLength = 0;
      const maxLength = 2000;

      for (final msg in pastMessages) {
        if (totalLength + msg.text.length <= maxLength) {
          _history.add(Content('user', [TextPart(msg.text)]));
          totalLength += msg.text.length;
        } else {
          break;
        }
      }

      _chat = _model.startChat(history: _history);
      print('대화 세션 초기화 완료: ${_history.length}개의 메시지 로드됨');
    } catch (e) {
      print('대화 세션 초기화 중 오류 발생: $e');
      _showSnackBar('대화 세션 초기화에 실패했습니다.');
      _chat = _model.startChat();
    }
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _showSuggestions = false; // 제안 숨기기
    });

    try {
      _originalMessage = text;
      print('전송할 메시지: $_originalMessage');

      await _analyzeSentiment(_originalMessage);

      // 부정적인 감정이고 제안이 있는 경우 제안 표시
      if (_sentimentResult == 'negative' && _suggestionResult.isNotEmpty) {
        setState(() {
          _showSuggestions = true;
          _isLoading = false;
        });
        print('제안 메시지 표시: $_suggestionResult');
        return; // 메시지 전송하지 않고 제안만 표시
      }

      // 긍정적이거나 중립적인 경우 바로 전송
      await _sendMessage(_originalMessage);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('메시지 전송 중 오류: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage(String message) async {
    try {
      await sendMessageToRoom(
        roomId: widget.chatRoomId,
        text: message,
        authorId: widget.myUserId,
        authorName: widget.myName,
        sentimentResult: _sentimentResult,
        suggestionResult: _suggestionResult,
      );

      if (mounted) {
        _controller.clear();
        setState(() {
          _showSuggestions = false;
          _originalMessage = '';
          _suggestionResult = '';
          _sentimentResult = '';
        });
        print('메시지 전송 완료');
      }
    } catch (e) {
      print('메시지 전송 실패: $e');
      rethrow;
    }
  }

  Future<void> _analyzeSentiment(String message) async {
    try {
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

      String extractedSentiment = _extractSentimentFromResponse(rawResponse);
      _sentimentResult = extractedSentiment;
      print('감정 분석 결과: $_sentimentResult');

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
      마지막 메시지를 긍정적이거나 중립적인 표현으로 바꿔주세요.
      마지막 메시지: "$message"
      응답 형식: 변경된 메시지
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

  void _selectOriginalMessage() {
    setState(() {
      _controller.text = _originalMessage;
    });
  }

  void _selectSuggestion() {
    setState(() {
      _controller.text = _suggestionResult;
    });
  }

  void _closeSuggestions() {
    setState(() {
      _showSuggestions = false;
      _controller.text = _originalMessage; // 원본 메시지 복원
    });
  }

  Future<void> _sendSelectedMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 선택된 메시지를 바로 전송 (감정 분석 재수행 안함)
      await _sendMessage(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('메시지 전송 중 오류: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
    return Column(
      children: [
        if (_showSuggestions) _suggestionWidget(),
        Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            child: TextField(
              controller: _controller,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: _showSuggestions ? '원본 또는 제안을 선택하세요' : '메시지를 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _buildSendButton(),
              ),
              onSubmitted:
                  (_) =>
                      _showSuggestions ? _sendSelectedMessage() : _handleSend(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _suggestionWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(color: Color(0xFF71D9D4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '💡 더 좋은 표현을 제안드려요!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: _closeSuggestions,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMessageButton(
                  label: '원본',
                  message: _originalMessage,
                  onPressed: _selectOriginalMessage,
                  isOriginal: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildMessageButton(
                  label: '제안',
                  message: _suggestionResult,
                  onPressed: _selectSuggestion,
                  isOriginal: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageButton({
    required String label,
    required String message,
    required VoidCallback onPressed,
    required bool isOriginal,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFEDFFFE),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOriginal ? Colors.orange.shade200 : Colors.green.shade200,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOriginal ? Icons.edit : Icons.lightbulb,
                  size: 16,
                  color: isOriginal ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOriginal ? Colors.orange : Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
      onPressed:
          _isLoading
              ? null
              : (_showSuggestions ? _sendSelectedMessage : _handleSend),
    );
  }
}
