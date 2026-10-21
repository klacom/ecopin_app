import 'package:ecopin_app/shared/reports/data/models/video_submission_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final maximum in [5, 8, 10]) {
    test(
      '$maximum second recording allows tiny stop-time overhead but rejects a longer clip',
      () {
        final policy = VideoSubmissionPolicy.fromJson({
          'min_seconds': 5,
          'max_seconds': maximum,
        });
        expect(
          policy.accepts(Duration(milliseconds: maximum * 1000 + 26)),
          isTrue,
        );
        expect(
          policy.accepts(Duration(milliseconds: maximum * 1000 + 100)),
          isTrue,
        );
        expect(
          policy.accepts(Duration(milliseconds: maximum * 1000 + 101)),
          isFalse,
        );
        expect(policy.accepts(const Duration(milliseconds: 4999)), isFalse);
      },
    );
  }
}
