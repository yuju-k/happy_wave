import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../../services/message_service.dart';

class SentimentAnalyzer {
  // ===========================================
  // 콜백 함수들
  // ===========================================
  final Function(String sentiment, String suggestion) onSentimentAnalyzed;
  final Function(String suggestion) onSuggestionGenerated;
  final Function(String error) onError;

  // ===========================================
  // AI 관련 변수들
  // ===========================================
  final _model = FirebaseVertexAI.instance.generativeModel(
    model: 'gemini-2.0-flash',
  );
  late final ChatSession _chat;
  final List<Content> _history = [];

  // ===========================================
  // 생성자
  // ===========================================
  SentimentAnalyzer({
    required this.onSentimentAnalyzed,
    required this.onSuggestionGenerated,
    required this.onError,
  });

  // ===========================================
  // 초기화 및 해제
  // ===========================================
  Future<void> initialize(String chatRoomId) async {
    try {
      final pastMessages = await MessageService().getRecentMessages(
        roomId: chatRoomId,
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
      print('감정 분석기 초기화 완료: ${_history.length}개의 메시지 로드됨');
    } catch (e) {
      throw Exception('감정 분석기 초기화 실패: $e');
    }
  }

  void dispose() {
    // 필요한 경우 리소스 정리
  }

  // ===========================================
  // 감정 분석 메인 메서드
  // ===========================================
  Future<void> analyzeSentiment(String message) async {
    try {
      _history.add(Content('user', [TextPart(message)]));

      final sentiment = await _performSentimentAnalysis();
      print('감정 분석 결과: $sentiment');

      String suggestion = '';
      if (sentiment == 'negative') {
        suggestion = await _generateSuggestion(message);
        print('제안 메시지: $suggestion');
      }

      onSentimentAnalyzed(sentiment, suggestion);
    } catch (e) {
      onError('감정 분석 중 오류 발생: $e');
    }
  }

  // ===========================================
  // 감정 분석 구현
  // ===========================================
  Future<String> _performSentimentAnalysis() async {
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
    print('AI 감정 분석 응답: $rawResponse');

    return _extractSentimentFromResponse(rawResponse);
  }

  String _extractSentimentFromResponse(String response) {
    final lowerResponse = response.toLowerCase();

    if (lowerResponse.contains('positive')) return 'positive';
    if (lowerResponse.contains('negative')) return 'negative';
    if (lowerResponse.contains('neutral')) return 'neutral';
    if (lowerResponse.contains('긍정')) return 'positive';
    if (lowerResponse.contains('부정')) return 'negative';
    if (lowerResponse.contains('중립')) return 'neutral';

    print('⚠️ 알 수 없는 감정 응답, 기본값 사용: $response');
    return 'neutral';
  }

  // ===========================================
  // 제안 메시지 생성
  // ===========================================
  Future<String> _generateSuggestion(String message) async {
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
      print('AI 제안 생성 응답: $rawSuggestion');

      return rawSuggestion.isEmpty ? '제안 생성에 실패했습니다.' : rawSuggestion;
    } catch (e) {
      print('제안 생성 중 오류 발생: $e');
      return '제안 생성 중 오류가 발생했습니다.';
    }
  }
}
