// lib/chat/widgets/chat_input/chat_input_controller.dart
import 'package:flutter/material.dart';
import '../../services/message_send.dart';
import 'sentiment_analyzer.dart';
import '../../../system_log.dart';

class ChatInputController {
  // ===========================================
  // 의존성 및 콜백들
  // ===========================================
  final String chatRoomId;
  final String myUserId;
  final String myName;
  final VoidCallback onStateChanged;
  final Function(String, {SnackBarAction? action}) onShowSnackBar;

  // ===========================================
  // 상태 변수들
  // ===========================================
  final TextEditingController textController = TextEditingController();
  late final SentimentAnalyzer _sentimentAnalyzer;
  final SystemLogService _systemLogService = SystemLogService();

  String originalMessage = '';
  String sentimentResult = '';
  String suggestionResult = '';
  bool convertedResult = false;
  bool isLoading = false;
  bool showSuggestions = false;

  // ===========================================
  // 생성자
  // ===========================================
  ChatInputController({
    required this.chatRoomId,
    required this.myUserId,
    required this.myName,
    required this.onStateChanged,
    required this.onShowSnackBar,
  }) {
    _sentimentAnalyzer = SentimentAnalyzer(
      onSentimentAnalyzed: _handleSentimentResult,
      onSuggestionGenerated: _handleSuggestionResult,
      onError: _handleAnalysisError,
    );
  }

  // ===========================================
  // 초기화 및 해제
  // ===========================================
  Future<void> initialize() async {
    try {
      await _sentimentAnalyzer.initialize(chatRoomId);
      debugPrint('ChatInputController 초기화 완료');
    } catch (e) {
      debugPrint('ChatInputController 초기화 실패: $e');
      onShowSnackBar('대화 세션 초기화에 실패했습니다.');
    }
  }

  void dispose() {
    textController.dispose();
    _sentimentAnalyzer.dispose();
  }

  // ===========================================
  // 메시지 전송 관련 메서드들
  // ===========================================
  Future<void> handleSend() async {
    final text = textController.text.trim();
    if (text.isEmpty || isLoading) return;

    _setLoadingState(true);
    _hideSuggestions();

    try {
      originalMessage = text;
      debugPrint('전송할 메시지: $originalMessage');

      await _sentimentAnalyzer.analyzeSentiment(originalMessage);
      // 감정 분석 결과는 콜백으로 처리됨
    } catch (e) {
      _handleError('메시지 전송 중 오류: $e');
      _setLoadingState(false);
    }
  }

  Future<void> sendMessage(String message, {bool isFromSuggestionPanel = false}) async {
    // isFromSuggestionPanel 매개변수 추가
    try {
      await sendMessageToRoom(
        roomId: chatRoomId,
        text: message,
        authorId: myUserId,
        authorName: myName,
        originalMessage: originalMessage,
        sentimentResult: sentimentResult,
        suggestionResult: suggestionResult,
        converted: convertedResult,
      );

      // 제안창이 나타나고 선택 후 전송된 경우에만 기록
      if (isFromSuggestionPanel) {
        _systemLogService.logMessageSelectedAndSent(myUserId, convertedResult);
      }

      _clearAfterSend();
      debugPrint('메시지 전송 완료');
    } catch (e) {
      debugPrint('메시지 전송 실패: $e');
      rethrow;
    }
  }

  Future<void> sendSelectedMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    _setLoadingState(true);

    try {
      // 제안 패널에서 선택된 메시지임을 나타내는 플래그를 전달
      await sendMessage(text, isFromSuggestionPanel: true);
    } catch (e) {
      _handleError('메시지 전송 중 오류: $e');
    } finally {
      _setLoadingState(false);
    }
  }

  // ===========================================
  // 감정 분석 결과 처리 콜백들
  // ===========================================
  void _handleSentimentResult(String sentiment, String suggestion) {
    sentimentResult = sentiment;
    suggestionResult = suggestion;

    // 감정 분석 결과를 Firebase에 기록합니다. (uid를 함께 전달)
    _systemLogService.logSentiment(myUserId, sentimentResult);

    if (_isNegativeWithSuggestion()) {
      _showSuggestionsPanel();
    } else {
      // 긍정적이거나 중립적인 경우 바로 전송
      sendMessage(originalMessage) // isFromSuggestionPanel 기본값 false
          .then((_) {
            _setLoadingState(false);
          })
          .catchError((e) {
            _handleError('메시지 전송 중 오류: $e');
            _setLoadingState(false);
          });
    }
  }

  void _handleSuggestionResult(String suggestion) {
    suggestionResult = suggestion;
  }

  void _handleAnalysisError(String error) {
    debugPrint('감정 분석 오류: $error');
    onShowSnackBar('감정 분석에 실패했습니다. 메시지를 전송합니다.');
    sentimentResult = 'neutral';
    suggestionResult = '';

    // 실패 시에도 메시지는 전송
    sendMessage(originalMessage) // isFromSuggestionPanel 기본값 false
        .then((_) {
          _setLoadingState(false);
        })
        .catchError((e) {
          _handleError('메시지 전송 중 오류: $e');
          _setLoadingState(false);
        });
  }

  // ===========================================
  // 사용자 액션 처리
  // ===========================================
  void selectOriginalMessage() {
    textController.text = originalMessage;
    convertedResult = false;
    onStateChanged();
  }

  void selectSuggestion() {
    textController.text = suggestionResult;
    convertedResult = true;
    onStateChanged();
  }

  void closeSuggestions() {
    showSuggestions = false;
    convertedResult = false;
    textController.text = originalMessage;
    onStateChanged();
  }

  // ===========================================
  // 상태 관리 헬퍼 메서드들
  // ===========================================
  void _setLoadingState(bool loading) {
    isLoading = loading;
    onStateChanged();
  }

  void _hideSuggestions() {
    showSuggestions = false;
    onStateChanged();
  }

  void _showSuggestionsPanel() {
    showSuggestions = true;
    isLoading = false;
    onStateChanged();
    debugPrint('제안 메시지 표시: $suggestionResult');
  }

  void _clearAfterSend() {
    textController.clear();
    showSuggestions = false;
    originalMessage = '';
    suggestionResult = '';
    sentimentResult = '';
    convertedResult = false;
    onStateChanged();
  }

  // ===========================================
  // 조건 체크 및 유틸리티 메서드들
  // ===========================================
  bool _isNegativeWithSuggestion() {
    return sentimentResult == 'negative' && suggestionResult.isNotEmpty;
  }

  void _handleError(String message) {
    onShowSnackBar(message);
  }

  // ===========================================
  // UI 헬퍼 메서드들
  // ===========================================
  String getHintText() {
    return showSuggestions ? '원본 또는 제안을 선택하세요' : '메시지 입력';
  }

  void handleTextSubmission() {
    showSuggestions ? sendSelectedMessage() : handleSend();
  }

  void handleSendButtonPress() {
    showSuggestions ? sendSelectedMessage() : handleSend();
  }
}
