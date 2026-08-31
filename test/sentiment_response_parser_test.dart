import 'package:flutter_test/flutter_test.dart';
import 'package:happy_wave/chat/widgets/chat_input/sentiment_response_parser.dart';

void main() {
  group('parseSentimentResponse', () {
    test('reads JSON sentiment field', () {
      expect(parseSentimentResponse('{"sentiment":"negative"}'), 'negative');
      expect(parseSentimentResponse('{"sentiment": "Positive"}'), 'positive');
    });

    test('reads JSON even when wrapped in extra text', () {
      expect(
        parseSentimentResponse('분류 결과:\n{"sentiment":"neutral"}\n끝'),
        'neutral',
      );
    });

    test('uses the last English label when the model rambles', () {
      expect(
        parseSentimentResponse('It is not positive. Final: negative'),
        'negative',
      );
    });

    test('does not treat "not negative" as negative via contains()', () {
      expect(parseSentimentResponse('not negative, so positive'), 'positive');
    });

    test('falls back to Korean keywords', () {
      expect(parseSentimentResponse('부정적입니다'), 'negative');
      expect(parseSentimentResponse('긍정'), 'positive');
      expect(parseSentimentResponse('중립적'), 'neutral');
    });

    test('unknown output defaults to neutral', () {
      expect(parseSentimentResponse(''), 'neutral');
      expect(parseSentimentResponse('잘 모르겠어요'), 'neutral');
    });
  });

  group('parseAnalysisResponse', () {
    test('reads sentiment and suggestion together', () {
      final result = parseAnalysisResponse(
        '{"sentiment":"negative","suggestion":"답장이 늦어서 걱정돼. 지금 괜찮아?"}',
      );
      expect(result.sentiment, 'negative');
      expect(result.suggestion, '답장이 늦어서 걱정돼. 지금 괜찮아?');
    });

    test('drops suggestion unless sentiment is negative', () {
      final result = parseAnalysisResponse(
        '{"sentiment":"neutral","suggestion":"주말에 시간 돼?"}',
      );
      expect(result.sentiment, 'neutral');
      expect(result.suggestion, '');
    });
  });

  group('sanitizeSuggestion', () {
    test('strips markdown fences and quotes', () {
      expect(
        sanitizeSuggestion('```\n미안해, 주말은 어려울 것 같아\n```'),
        '미안해, 주말은 어려울 것 같아',
      );
      expect(sanitizeSuggestion('"미안해, 주말은 어려울 것 같아"'), '미안해, 주말은 어려울 것 같아');
    });

    test('strips common prefixes', () {
      expect(sanitizeSuggestion('변경된 메시지: 주말에 시간 맞춰볼까?'), '주말에 시간 맞춰볼까?');
      expect(sanitizeSuggestion('제안: 조금 있다가 이야기하자'), '조금 있다가 이야기하자');
    });

    test('returns empty string for blank input', () {
      expect(sanitizeSuggestion('   '), '');
    });
  });
}
