import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_photo_repository.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_cannot_work_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class NoPhotos extends Fake implements FcLocalPhotoRepository {
  @override
  Future<FcLocalPhoto?> getActivePhoto(
    String id,
    String entity,
    String type,
  ) async => null;
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Outfit',
    )..addFont(rootBundle.load('assets/fonts/Outfit-Regular.ttf'))).load();
  });
  for (final dark in [false, true]) {
    for (final dismissal in ['Cancel', 'barrier', 'back']) {
      testWidgets(
        'cannot-work dialog safely dismisses using $dismissal with focused notes / dark=$dark',
        (tester) async {
          tester.view.physicalSize = Size(dark ? 360 : 600, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var queued = 0;
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                fcLocalPhotoRepositoryProvider.overrideWithValue(NoPhotos()),
                fcLocalRepositoryProvider.overrideWith(
                  (ref) =>
                      throw StateError('Cancel must not write to the queue'),
                ),
              ],
              child: MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                home: Scaffold(
                  body: Center(
                    child: FcCannotWorkButton(
                      task: CleanupTask.fromJson({
                        'id': 'task',
                        'title': 'Assigned cleanup',
                      }),
                      onFailureQueued: (_) => queued++,
                    ),
                  ),
                ),
              ),
            ),
          );
          for (var iteration = 0; iteration < 2; iteration++) {
            await tester.tap(find.text('Unable to Work This Site'));
            await tester.pumpAndSettle();
            expect(find.text('Cannot Work This Site'), findsOneWidget);
            expect(
              tester.widget<TextField>(find.byType(TextField)).controller!.text,
              isEmpty,
            );
            await tester.enterText(find.byType(TextField), 'Road blocked');
            await tester.pump();
            if (dismissal == 'Cancel') {
              await tester.tap(find.text('Cancel'));
            } else if (dismissal == 'barrier') {
              await tester.tapAt(const Offset(8, 8));
            } else {
              await tester.binding.handlePopRoute();
            }
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.byType(AlertDialog), findsNothing);
            expect(queued, 0);
          }
        },
      );
    }
  }
}
