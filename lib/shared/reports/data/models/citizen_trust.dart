class CitizenTrust {
  const CitizenTrust({
    required this.score,
    required this.threshold,
    required this.urgentAllowed,
    required this.recoveryReportsRemaining,
    this.lockedUntil,
  });
  final int score;
  final int threshold;
  final bool urgentAllowed;
  final int recoveryReportsRemaining;
  final DateTime? lockedUntil;

  factory CitizenTrust.fromJson(Map<String, dynamic> json) {
    if (json['score'] is! int ||
        json['score_threshold'] is! int ||
        json['urgent_allowed'] is! bool ||
        json['recovery_reports_remaining'] is! int) {
      throw const FormatException('Trust status is unavailable.');
    }
    return CitizenTrust(
      score: json['score'],
      threshold: json['score_threshold'],
      urgentAllowed: json['urgent_allowed'],
      recoveryReportsRemaining: json['recovery_reports_remaining'],
      lockedUntil: DateTime.tryParse(json['locked_until']?.toString() ?? ''),
    );
  }
}
