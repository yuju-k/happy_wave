import 'package:flutter/material.dart';
//import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../../services/message_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final GenerativeModel _model; // 이제 ChatSession 대신 GenerativeModel을 직접 사용
  final List<Content> _externalHistory = []; // 실제 사용자 메시지 기록 (컨텍스트 전달용)
  // ===========================================
  // 생성자
  // ===========================================
  SentimentAnalyzer({
    required this.onSentimentAnalyzed,
    required this.onSuggestionGenerated,
    required this.onError,
  }) : _model = FirebaseAI.vertexAI(
         // 모델을 생성자에서 초기화, 상태 비저장 호출에 사용
         auth: FirebaseAuth.instance,
       ).generativeModel(model: 'gemini-2.0-flash');

  // ===========================================
  // 초기화 및 해제
  // ===========================================
  Future<void> initialize(String chatRoomId) async {
    try {
      final pastMessages = await MessageService().getRecentMessages(
        roomId: chatRoomId,
        limit: 20,
      );

      var totalLength = 0;
      const maxLength = 2000;

      for (final msg in pastMessages) {
        if (totalLength + msg.text.length <= maxLength) {
          _externalHistory.add(
            Content('user', [TextPart(msg.text)]),
          ); // 실제 사용자 메시지만 추가
          totalLength += msg.text.length;
          debugPrint('메시지추가:${msg.text}');
        } else {
          break;
        }
      }
      debugPrint('감정 분석기 초기화 완료: ${_externalHistory.length}개의 메시지 로드됨');
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
      _externalHistory.add(Content('user', [TextPart(message)]));

      final sentiment = await _performSentimentAnalysis(message);
      debugPrint('감정 분석 결과: $sentiment');

      String suggestion = '';
      if (sentiment == 'negative') {
        suggestion = await _generateSuggestion(message);
        debugPrint('제안 메시지: $suggestion');
      }

      onSentimentAnalyzed(sentiment, suggestion);
    } catch (e) {
      onError('감정 분석 중 오류 발생: $e');
    }
  }

  // ===========================================
  // 감정 분석 구현
  // ===========================================
  Future<String> _performSentimentAnalysis(String currentMessage) async {
    const sentimentPrompt = '''
    다음 대화 맥락을 참고하여 마지막 사용자 메시지의 대화 태도를 분석해주세요.
    [대화 태도] 대화 중 갈등을 유발할 수 있는 메시지임
    다음 중 하나로만 응답하세요:
    - positive (긍정적)
    - negative (부정적)
    - neutral (중립적)

    응답 형식: 단어 하나만 영어로 답하세요.
    ''';

    // 상태 비저장 호출을 위해 필요한 컨텍스트와 프롬프트 조합
    final List<Content> requestContent = [
      // _externalHistory에서 최근 메시지들을 컨텍스트로 포함 (최대 10개)
      ..._externalHistory.sublist(
        (_externalHistory.length - 10).clamp(0, _externalHistory.length),
      ),
      Content.text(sentimentPrompt), // 감정 분석 지시 프롬프트
      Content('user', [TextPart(currentMessage)]), // 현재 사용자 메시지
    ];

    final sentimentResponse = await _model.generateContent(requestContent);

    final rawResponse = sentimentResponse.text?.trim() ?? '';
    debugPrint('AI 감정 분석 응답: $rawResponse');

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
    if (lowerResponse.contains('긍정적')) return 'positive';
    if (lowerResponse.contains('부정적')) return 'negative';
    if (lowerResponse.contains('중립적')) return 'neutral';

    debugPrint('⚠️ 알 수 없는 감정 응답, 기본값 사용: $response');
    return 'neutral';
  }

  // ===========================================
  // 제안 메시지 생성
  // ===========================================
  Future<String> _generateSuggestion(String currentMessage) async {
    try {
      final suggestionPrompt = '''
      마지막 메시지를 긍정적이거나 중립적 대화태도로 변경해주세요.
      마지막 메시지: "$currentMessage"
      응답 형식: 변경된 메시지
      마지막 메시지의 메시지 길이와 비슷한 길이의 메시지로 변경하세요.
      변경된 메시지만 출력하세요.
      ''';

      // 상태 비저장 호출을 위해 필요한 컨텍스트와 프롬프트 조합
      final List<Content> requestContent = [
        // _externalHistory에서 최근 메시지들을 컨텍스트로 포함 (최대 10개)
        ..._externalHistory.sublist(
          (_externalHistory.length - 10).clamp(0, _externalHistory.length),
        ),
        Content.text(suggestionPrompt), // 제안 지시 프롬프트
        Content('user', [TextPart(currentMessage)]), // 현재 사용자 메시지
      ];

      final suggestionResponse = await _model.generateContent(requestContent);

      final rawSuggestion = suggestionResponse.text?.trim() ?? '';
      debugPrint('AI 제안 생성 응답: $rawSuggestion');

      return rawSuggestion.isEmpty ? '제안 생성에 실패했습니다.' : rawSuggestion;
    } catch (e) {
      debugPrint('제안 생성 중 오류 발생: $e');
      return '제안 생성 중 오류가 발생했습니다.';
    }
  }
}
