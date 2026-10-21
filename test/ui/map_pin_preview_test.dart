import 'dart:io';
import 'dart:ui' as ui;

import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/my_marker_cluster_layer.dart';
import 'package:ecopin_app/shared/maps/presentation/widgets/report_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
  for (final dark in [false, true]) {
    testWidgets('pins and full cluster count remain usable at 2x / $dark', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: RepaintBoundary(
            key: const Key('pin-review'),
            child: Scaffold(
              body: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Wrap(
                    spacing: 32,
                    runSpacing: 32,
                    children: [
                      for (final status in [
                        'unresolved',
                        'in_progress',
                        'resolved',
                        'waiting_for_feedback',
                        'pending_owner_consent',
                        'closed',
                        'unknown',
                      ])
                        SizedBox(
                          width: 140,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ReportMarker(
                                status: status,
                                issueType: 'illegal_dumping',
                                title: status,
                                selected: status == 'resolved',
                                onTap: () {},
                              ),
                              const SizedBox(height: 12),
                              Text(
                                status.replaceAll('_', ' '),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ReportClusterBadge(count: 1200, onActivate: () {}),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('View 1200 nearby reports'), findsOneWidget);
      expect(find.text('999+'), findsOneWidget);
      expect(find.byTooltip('unknown, Unknown'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final output = Platform.environment['ECOPIN_SCREENSHOT_DIR'];
      if (output != null) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('pin-review')),
        );
        await tester.runAsync(() async {
          final capture = await boundary.toImage();
          final bytes = await capture.toByteData(
            format: ui.ImageByteFormat.png,
          );
          await File(
            '$output/pins-${dark ? 'dark' : 'light'}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          capture.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    });
  }
}
