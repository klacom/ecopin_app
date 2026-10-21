class VideoSubmissionPolicy {
  const VideoSubmissionPolicy(this.maxSeconds);
  final int maxSeconds;
  static const minSeconds = 5;
  // Recorder stop/container timing can exceed the requested maximum by a few ms.
  static const durationTolerance = Duration(milliseconds: 100);
  factory VideoSubmissionPolicy.fromJson(dynamic data) {
    if (data is! Map ||
        data['min_seconds'] != minSeconds ||
        data['max_seconds'] is! int ||
        data['max_seconds'] < minSeconds ||
        data['max_seconds'] > 10) {
      throw const FormatException('Invalid video limits');
    }
    return VideoSubmissionPolicy(data['max_seconds'] as int);
  }
  bool accepts(Duration duration) =>
      duration >= const Duration(seconds: minSeconds) &&
      duration <= Duration(seconds: maxSeconds) + durationTolerance;
}
