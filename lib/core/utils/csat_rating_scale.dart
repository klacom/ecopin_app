/// Single source of truth for the 1–5 citizen satisfaction scale.
class CsatRatingScale {
  const CsatRatingScale._();

  static const List<({int rating, String emoji, String label})> entries = [
    (rating: 1, emoji: '😢', label: 'Very Dissatisfied'),
    (rating: 2, emoji: '😕', label: 'Dissatisfied'),
    (rating: 3, emoji: '😐', label: 'Neutral'),
    (rating: 4, emoji: '😊', label: 'Satisfied'),
    (rating: 5, emoji: '😄', label: 'Very Satisfied'),
  ];

  static ({int rating, String emoji, String label}) of(int rating) =>
      entries[(rating.clamp(1, 5)) - 1];

  static String emoji(int rating) => of(rating).emoji;

  static String label(int rating) => of(rating).label;

  /// Rounds an average (num or numeric string) to the nearest scale entry.
  static ({int rating, String emoji, String label})? fromAverage(dynamic value) {
    if (value == null) return null;
    final parsed = num.tryParse(value.toString());
    if (parsed == null) return null;
    return of(parsed.round());
  }
}
