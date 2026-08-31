import 'dart:convert';

const sentimentLabels = {'positive', 'negative', 'neutral'};

final _jsonObjectPattern = RegExp(r'\{[\s\S]*\}');
final _englishLabelPattern = RegExp(r'\b(positive|negative|neutral)\b');
final _markdownFencePattern = RegExp(r'^```(?:\w+)?\s*([\s\S]*?)\s*```$');
final _suggestionPrefixPattern = RegExp(
  r'^(?:변경된\s*메시지|제안(?:\s*메시지)?|rewritten(?:\s*message)?|here(?:'
  r"'s| is) (?:the |a )?rewrite)\s*[:：\-]\s*",
  caseSensitive: false,
);

class SentimentParseResult {
  const SentimentParseResult({required this.sentiment, this.suggestion = ''});

  final String sentiment;
  final String suggestion;
}

/// Parses a combined analysis JSON payload.
SentimentParseResult parseAnalysisResponse(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return const SentimentParseResult(sentiment: 'neutral');
  }

  final jsonText = _jsonObjectPattern.firstMatch(trimmed)?.group(0);
  if (jsonText != null) {
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is Map) {
        final sentiment = _normalizeSentiment(decoded['sentiment']);
        final suggestion = sanitizeSuggestion(
          decoded['suggestion'] is String ? decoded['suggestion'] as String : '',
        );
        if (sentiment != null) {
          return SentimentParseResult(
            sentiment: sentiment,
            suggestion: sentiment == 'negative' ? suggestion : '',
          );
        }
      }
    } catch (_) {}
  }

  return SentimentParseResult(sentiment: parseSentimentResponse(raw));
}

String? _normalizeSentiment(dynamic value) {
  if (value is! String) return null;
  final normalized = value.trim().toLowerCase();
  return sentimentLabels.contains(normalized) ? normalized : null;
}

/// Parses a model reply into `positive` / `negative` / `neutral`.
///
/// Prefers JSON `{"sentiment": "..."}`. Falls back to a single English label,
/// then Korean keywords. Unknown output becomes `neutral`.
String parseSentimentResponse(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 'neutral';

  final fromJson = _sentimentFromJson(trimmed);
  if (fromJson != null) return fromJson;

  final englishMatches =
      _englishLabelPattern
          .allMatches(trimmed.toLowerCase())
          .map((match) => match.group(1)!)
          .toList();
  if (englishMatches.isNotEmpty) {
    return englishMatches.last;
  }

  return _sentimentFromKorean(trimmed) ?? 'neutral';
}

String? _sentimentFromJson(String raw) {
  final jsonText = _jsonObjectPattern.firstMatch(raw)?.group(0);
  if (jsonText == null) return null;

  try {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map) return null;
    final normalized = _normalizeSentiment(decoded['sentiment']);
    if (normalized != null) return normalized;
  } catch (_) {
    return null;
  }
  return null;
}

String? _sentimentFromKorean(String raw) {
  if (raw.contains('부정적') || raw.contains('부정')) return 'negative';
  if (raw.contains('긍정적') || raw.contains('긍정')) return 'positive';
  if (raw.contains('중립적') || raw.contains('중립')) return 'neutral';
  return null;
}

/// Strips fences, quotes, and boilerplate so the UI can show the rewrite only.
String sanitizeSuggestion(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return '';

  final fenced = _markdownFencePattern.firstMatch(text);
  if (fenced != null) {
    text = (fenced.group(1) ?? '').trim();
  }

  text = text.replaceFirst(_suggestionPrefixPattern, '').trim();
  text = _stripWrappingQuotes(text);
  return text.trim();
}

String _stripWrappingQuotes(String text) {
  if (text.length < 2) return text;
  const pairs = <String, String>{'"': '"', "'": "'", '“': '”', '‘': '’'};
  final closer = pairs[text[0]];
  if (closer != null && text.endsWith(closer)) {
    return text.substring(1, text.length - 1).trim();
  }
  return text;
}
