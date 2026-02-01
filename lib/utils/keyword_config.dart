class KeywordConfig {

  // High priority keywords (Score: 4–5)
  static const Map<String, int> highPriorityKeywords = {
    'murder': 5,
    'weapon': 5,
    'gun': 5,
    'knife': 4,
    'bomb': 5,
    'fire': 4,
    'assault': 4,
  };

  // Medium priority keywords (Score: 2–3)
  static const Map<String, int> mediumPriorityKeywords = {
    'accident': 3,
    'theft': 3,
    'injury': 3,
    'robbery': 3,
    'fight': 2,
  };

  // Low priority keywords (Score: 1)
  static const Map<String, int> lowPriorityKeywords = {
    'noise': 1,
    'dispute': 1,
    'parking': 1,
    'nuisance': 1,
  };

  // ✅ AUTO PRIORITY FUNCTION (IMPORTANT)
  static String getPriority(String text) {
    final lowerText = text.toLowerCase();

    int score = 0;

    // Check High Priority
    highPriorityKeywords.forEach((key, value) {
      if (lowerText.contains(key)) {
        if (value > score) score = value;
      }
    });

    // Check Medium Priority
    mediumPriorityKeywords.forEach((key, value) {
      if (lowerText.contains(key)) {
        if (value > score) score = value;
      }
    });

    // Check Low Priority
    lowPriorityKeywords.forEach((key, value) {
      if (lowerText.contains(key)) {
        if (value > score) score = value;
      }
    });

    // Decide final priority
    if (score >= 4) {
      return "High";
    } else if (score >= 2) {
      return "Medium";
    } else {
      return "Normal";
    }
  }
}
