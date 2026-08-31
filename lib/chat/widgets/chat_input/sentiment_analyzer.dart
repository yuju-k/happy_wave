import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/message_service.dart';
import 'sentiment_response_parser.dart';

/// Fast Flash-Lite for on-send classification. Avoids Gemini 3.7 thinking latency.
const geminiFlashModel = 'gemini-3.5-flash-lite';

const _maxHistoryMessages = 6;

const _analysisSystemPrompt = '''
가까운 사이 채팅의 "지금 보낼 메시지"만 분류하세요. 맥락은 참고만 하세요.
생각하는 과정, 설명, 마크다운 없이 JSON만 출력하세요.

sentiment:
- negative: 비난, 비꼬기, 무시, 압박, 단정, 차가운 거절처럼 갈등을 키울 태도
- positive: 공감, 배려, 협력처럼 관계를 부드럽게 하는 태도
- neutral: 사실 전달, 일정 확인처럼 갈등도 친밀도 강화도 뚜렷하지 않음

suggestion:
- negative일 때만 같은 뜻의 더 부드러운 한국어 한 문장. 원문과 비슷한 길이.
- positive/neutral이면 빈 문자열.
''';

class _HistoryTurn {
  const _HistoryTurn({required this.isMine, required this.text});

  final bool isMine;
  final String text;
}

class SentimentAnalyzer {
  SentimentAnalyzer({
    required this.onSentimentAnalyzed,
    required this.onSuggestionGenerated,
    required this.onError,
    required this.myUserId,
  }) : _model = _firebaseAI.generativeModel(
         model: geminiFlashModel,
         systemInstruction: Content.system(_analysisSystemPrompt),
         generationConfig: GenerationConfig(
           maxOutputTokens: 128,
           responseMimeType: 'application/json',
           responseSchema: Schema.object(
             properties: {
               'sentiment': Schema.enumString(
                 enumValues: const ['positive', 'negative', 'neutral'],
                 description: '지금 보낼 메시지의 대화 태도',
               ),
               'suggestion': Schema.string(
                 description: 'negative일 때만 부드러운 다시 쓰기, 아니면 빈 문자열',
               ),
             },
           ),
         ),
       );

  /// Agent Platform Gemini API (formerly Vertex AI), billed via Google Cloud/Blaze.
  /// Gemini Developer API prepaid credits on this project are depleted.
  static FirebaseAI get _firebaseAI => FirebaseAI.vertexAI(
    auth: FirebaseAuth.instance,
    appCheck: FirebaseAppCheck.instance,
    location: 'global',
  );

  final Function(String sentiment, String suggestion) onSentimentAnalyzed;
  final Function(String suggestion) onSuggestionGenerated;
  final Function(String error) onError;
  final String myUserId;

  final GenerativeModel _model;
  final List<_HistoryTurn> _history = [];

  Future<void> initialize(String chatRoomId) async {
    try {
      final pastMessages = await MessageService().getRecentMessages(
        roomId: chatRoomId,
        limit: _maxHistoryMessages,
      );

      _history
        ..clear()
        ..addAll(
          pastMessages.map(
            (msg) =>
                _HistoryTurn(isMine: msg.author.id == myUserId, text: msg.text),
          ),
        );

      debugPrint('감정 분석기 초기화 완료: ${_history.length}개의 메시지 로드됨');
    } catch (e) {
      throw Exception('감정 분석기 초기화 실패: $e');
    }
  }

  void dispose() {
    _history.clear();
  }

  Future<void> analyzeSentiment(String message) async {
    try {
      final result = await _analyze(message);
      debugPrint('감정 분석 결과: ${result.sentiment}');
      debugPrint('제안 메시지: ${result.suggestion}');

      if (result.sentiment == 'negative' && result.suggestion.isNotEmpty) {
        onSuggestionGenerated(result.suggestion);
      }

      _appendHistory(isMine: true, text: message);
      onSentimentAnalyzed(result.sentiment, result.suggestion);
    } catch (e) {
      onError('감정 분석 중 오류 발생: $e');
    }
  }

  Future<SentimentParseResult> _analyze(String currentMessage) async {
    final prompt = '''
대화 맥락:
${_formatTranscript()}

지금 보낼 메시지:
$currentMessage
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final rawResponse = response.text?.trim() ?? '';
    debugPrint('AI 감정 분석 응답: $rawResponse');
    return parseAnalysisResponse(rawResponse);
  }

  void _appendHistory({required bool isMine, required String text}) {
    _history.add(_HistoryTurn(isMine: isMine, text: text));
    if (_history.length > _maxHistoryMessages) {
      _history.removeRange(0, _history.length - _maxHistoryMessages);
    }
  }

  String _formatTranscript() {
    if (_history.isEmpty) return '(이전 대화 없음)';
    return _history
        .map((turn) => '${turn.isMine ? '나' : '상대'}: ${turn.text}')
        .join('\n');
  }
}
