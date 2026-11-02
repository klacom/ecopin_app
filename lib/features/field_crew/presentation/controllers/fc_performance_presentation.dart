import 'package:ecopin_app/core/utils/csat_rating_scale.dart';

/// One set of results: a crew member's own, or their squad's.
class CrewResultSet {
  const CrewResultSet({this.completed, this.rating, this.ratingCount = 0});

  /// Null means the server did not send it. It is never shown as a zero.
  final int? completed;
  final num? rating;
  final int ratingCount;
}

/// What the Your results screen shows, read from the server's answer.
class CrewResults {
  const CrewResults({required this.you, this.squadName, this.squad});
  final CrewResultSet you;
  final String? squadName;
  final CrewResultSet? squad;
}

num? _num(Object? value) =>
    value == null ? null : num.tryParse(value.toString());

String? _text(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

CrewResultSet _set(Object? raw) {
  final map = raw is Map ? raw : const {};
  return CrewResultSet(
    completed: _num(map['total_completed'])?.toInt(),
    rating: _num(map['avg_satisfaction_rating']),
    ratingCount: _num(map['total_ratings_received'])?.toInt() ?? 0,
  );
}

/// Reads the server's answer. An empty answer means the results could not be
/// loaded (the provider returns an empty map when offline), so it is null:
/// the screen then says so instead of showing zeros the crew did not earn.
CrewResults? crewResultsFrom(Map<String, dynamic>? data) {
  if (data == null || data['performance'] is! Map) return null;
  final team = data['crew_team'];
  final teamMap = team is Map ? team : null;
  return CrewResults(
    you: _set(data['performance']),
    squadName: _text(teamMap?['name']),
    squad: teamMap?['performance'] is Map
        ? _set(teamMap!['performance'])
        : null,
  );
}

String _trim(num value) {
  final text = value.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

/// “4.5 out of 5”.
String crewRatingText(num rating) => '${_trim(rating)} out of 5';

/// “Very satisfied”, in sentence case, or null when there is no rating.
String? crewRatingWord(num? rating) {
  final label = CsatRatingScale.fromAverage(rating)?.label;
  if (label == null) return null;
  return '${label[0]}${label.substring(1).toLowerCase()}';
}

/// “from 8 ratings”.
String crewRatingCount(int count) =>
    'from $count ${count == 1 ? 'rating' : 'ratings'}';
