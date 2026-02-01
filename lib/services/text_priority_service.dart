import '../utils/keyword_config.dart';

class TextPriorityResult {
  final int score;
  final String level;
  final List<String> matchedKeywords;

  TextPriorityResult({
    required this.score,
    required this.level,
    required this.matchedKeywords,
  });
}

class TextPriorityService {
  static TextPriorityResult evaluate(String text) {
    final normalizedText =
    text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final tokens = normalizedText.split(RegExp(r'\s+'));

    int score = 0;
    final List<String> matchedKeywords = [];

    void matchKeywords(Map<String, int> keywords) {
      for (final word in tokens) {
        if (keywords.containsKey(word)) {
          score += keywords[word]!;
          matchedKeywords.add(word);
        }
      }
    }

    // Bag-of-Words style matching
    matchKeywords(KeywordConfig.highPriorityKeywords);
    matchKeywords(KeywordConfig.mediumPriorityKeywords);
    matchKeywords(KeywordConfig.lowPriorityKeywords);

    String level;
    if (score >= 7) {
      level = 'High';
    } else if (score >= 3) {
      level = 'Medium';
    } else {
      level = 'Low';
    }

    return TextPriorityResult(
      score: score,
      level: level,
      matchedKeywords: matchedKeywords.toSet().toList(),
    );
  }
}
