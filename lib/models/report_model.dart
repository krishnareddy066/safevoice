class Report {
  final String reportId;
  final String anonId;
  final String description;
  final DateTime timestamp;
  final String location;
  final String status;

  // Text prioritization
  final int priorityScore;
  final String priorityLevel;
  final List<String> extractedKeywords;

  // Media
  final String? imageUrl;
  final String? audioUrl;
  final String? audioTranscript;

  Report({
    required this.reportId,
    required this.anonId,
    required this.description,
    required this.timestamp,
    required this.location,
    required this.status,
    required this.priorityScore,
    required this.priorityLevel,
    required this.extractedKeywords,
    this.imageUrl,
    this.audioUrl,
    this.audioTranscript,
  });

  Map<String, dynamic> toMap() {
    return {
      'report_id': reportId,
      'anon_id': anonId,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'status': status,
      'priority_score': priorityScore,
      'priority_level': priorityLevel,
      'extracted_keywords': extractedKeywords,
      'image_url': imageUrl,
      'audio_url': audioUrl,
      'audio_transcript': audioTranscript,
    };
  }
}
