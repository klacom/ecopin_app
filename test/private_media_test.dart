import 'package:flutter_test/flutter_test.dart';
import 'package:ecopin_app/core/utils/private_media.dart';

void main() {
  test(
    'stable and expired signed references resolve to the same authenticated endpoint',
    () {
      final stable = privateMediaTarget(
        'storage://Cleanup%20Task%20Photos/task/before/photo.jpg',
        'https://project.test',
        'http://localhost:3000',
      );
      final old = privateMediaTarget(
        'https://project.test/storage/v1/object/sign/Cleanup%20Task%20Photos/task/before/photo.jpg?token=expired',
        'https://project.test',
        'http://localhost:3000',
      );
      expect(old, stable);
      expect(stable?.queryParameters['bucket'], 'Cleanup Task Photos');
      expect(stable.toString(), isNot(contains('expired')));
    },
  );
  test(
    'foreign hosts, traversal and missing backend configuration fail closed',
    () {
      for (final source in [
        'https://foreign.test/storage/v1/object/public/Report%20Cleanup/task/before/photo.jpg',
        'storage://Report%20Cleanup/task/before/%2e%2e',
        'storage://avatars/user/avatar.jpg',
      ]) {
        expect(
          privateMediaTarget(
            source,
            'https://project.test',
            'http://localhost:3000',
          ),
          isNull,
        );
      }
      expect(
        privateMediaTarget(
          'storage://Report%20Cleanup/task/before/photo.jpg',
          'https://project.test',
          '',
        ),
        isNull,
      );
    },
  );
  test('public external assets are not classified as private', () {
    expect(
      isPrivateMedia('https://external.test/image.jpg', 'https://project.test'),
      isFalse,
    );
    expect(
      isPrivateMedia(
        'storage://Cleanup%20Task%20Photos/task/before/photo.jpg',
        'https://project.test',
      ),
      isTrue,
    );
  });
}
