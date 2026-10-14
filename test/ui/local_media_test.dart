import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'fixtures/local_video_controller.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/local_media_preview.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('Outfit')
          ..addFont(rootBundle.load('assets/fonts/Outfit-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Outfit-SemiBold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  test(
    'video metadata keeps fractional duration and releases its player',
    () async {
      final file = File('synthetic-small-file.mp4');
      final controller = SyntheticVideoController(
        file,
        duration: const Duration(milliseconds: 10900),
      );
      final duration = await readLocalVideoDuration(
        file,
        createController: (_) => controller,
      );
      expect(duration, const Duration(milliseconds: 10900));
      expect(controller.released, isTrue);
    },
  );
  test(
    'unreadable video metadata is unavailable and releases its player',
    () async {
      final file = File('synthetic-unreadable.mp4');
      final controller = SyntheticVideoController(file, fail: true);
      expect(
        await readLocalVideoDuration(file, createController: (_) => controller),
        isNull,
      );
      expect(controller.released, isTrue);
    },
  );
  for (final dark in [false, true]) {
    testWidgets(
      'photo inspection and video retry at 320px / 2x / ${dark ? "dark" : "light"}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final temporary = (await tester.runAsync(
          () => Directory.systemTemp.createTemp('ecopin-local-viewer-'),
        ))!;
        addTearDown(() => temporary.delete(recursive: true));
        final first = File('${temporary.path}/first.png');
        final second = File('${temporary.path}/second.png');
        await tester.runAsync(() async {
          await first.writeAsBytes(
            image.encodePng(image.Image(width: 1, height: 1)),
          );
          await second.writeAsBytes(
            image.encodePng(image.Image(width: 1, height: 1)),
          );
        });
        const preview = Key('local-preview');
        Widget host(Widget child) => MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: RepaintBoundary(
            key: preview,
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: child,
            ),
          ),
        );
        await tester.pumpWidget(host(const SizedBox()));
        await tester.runAsync(() async {
          await precacheImage(
            FileImage(first),
            tester.element(find.byKey(preview)),
          );
          await precacheImage(
            FileImage(second),
            tester.element(find.byKey(preview)),
          );
        });
        await tester.pumpWidget(
          host(LocalPhotoPreview(photos: [first, second], initialIndex: 0)),
        );
        await tester.pumpAndSettle();
        expect(find.text('Photo 1 of 2'), findsOneWidget);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        expect(find.text('Photo 2 of 2'), findsOneWidget);
        await tester.tap(find.text('Previous'));
        await tester.pumpAndSettle();
        expect(find.text('Photo 1 of 2'), findsOneWidget);
        expect(tester.takeException(), isNull);
        var attempts = 0;
        await tester.pumpWidget(
          host(
            LocalVideoPreview(
              file: File('synthetic.mp4'),
              createController: (file) =>
                  SyntheticVideoController(file, fail: attempts++ == 0),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('video could not be opened'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        final output = Platform.environment['ECOPIN_SCREENSHOT_DIR'];
        if (output != null) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(preview),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '$output/mobile-local-video-error-${dark ? "dark" : "light"}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.tap(find.text('Retry video'));
        await tester.pumpAndSettle();
        expect(find.text('Play video'), findsOneWidget);
        await tester.tap(find.text('Play video'));
        await tester.pumpAndSettle();
        expect(find.text('Pause video'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
