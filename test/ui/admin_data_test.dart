import 'package:ecopin_app/core/utils/password_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecopin_app/features/admin/data/admin_page.dart';
import 'package:ecopin_app/features/admin/data/audit_payload.dart';
import 'package:ecopin_app/features/admin/presentation/widgets/admin_widgets.dart';

void main() {
  test(
    'dates show a compact local offset and unavailable dates remain honest',
    () {
      expect(
        adminDate('2026-10-13T06:00:00Z'),
        matches(RegExp(r'UTC[+−]\d{2}:\d{2}$')),
      );
      expect(adminDate('not-a-date'), 'Unavailable');
      expect(adminDate(null), 'Unavailable');
    },
  );
  test('missing pagination preserves records without fabricating totals', () {
    final page = AdminPage.fromResponse(
      {
        'users': [
          {'id': 'actual-record'},
        ],
      },
      'users',
      2,
    );
    expect(page.records.single['id'], 'actual-record');
    expect(page.total, isNull);
    expect(page.totalPages, isNull);
    expect(page.page, 2);
    expect(
      () => AdminPage.fromResponse({'users': null}, 'users', 1),
      throwsFormatException,
    );
    expect(
      () => AdminPage.fromResponse(
        {
          'users': ['invalid-record'],
        },
        'users',
        1,
      ),
      throwsFormatException,
    );
  });
  test(
    'policy uses configured rules and never substitutes guessed defaults',
    () {
      expect(() => PasswordPolicy({}), throwsFormatException);
      final policy = PasswordPolicy({
        'password_min_length': 6,
        'password_require_uppercase': false,
        'password_require_lowercase': false,
        'password_require_numbers': false,
        'password_require_special_chars': false,
      });
      expect(policy.validate('abcdef'), isNull);
      expect(policy.validate('short'), isNotNull);
    },
  );
  test(
    'structured credential values are hidden recursively in encoded payloads',
    () {
      final value = auditPayloadText({
        'event_data':
            '{"note":"Keep this note","nested":[{"access_token":"SyntheticToken","PASSWORD":"SyntheticPassword"}],"email":"authorized@example.invalid"}',
      });
      expect(value, contains('Keep this note'));
      expect(value, contains('authorized@example.invalid'));
      expect(value, isNot(contains('SyntheticToken')));
      expect(value, isNot(contains('SyntheticPassword')));
      expect(value, contains('[hidden]'));
    },
  );
}
