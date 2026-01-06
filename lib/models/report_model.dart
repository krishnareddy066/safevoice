class Report {
  final String reportId;
  final String anonId;
  final String description;
  final DateTime timestamp;
  final String location;
  final String status;

  Report({
    required this.reportId,
    required this.anonId,
    required this.description,
    required this.timestamp,
    required this.location,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'report_id': reportId,
      'anon_id': anonId,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'status': status,
    };
  }
}
