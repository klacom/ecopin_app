import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_photo_repository.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_repository.dart';
import 'package:ecopin_app/features/field_crew/presentation/screens/field_crew_task_detail_screen.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_photo_upload_section.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_photo_gallery_card.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/widgets/private_media_image.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_task_detail_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fixtures/local_video_controller.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_details_widgets/fullscreen_image_view.dart';

class EvidenceTask extends FcTaskDetailNotifier {
  EvidenceTask(this.task, {this.initial}) : super(task.id);
  final FcTaskDetailState? initial;
  final CleanupTask task;
  @override
  FcTaskDetailState build() => initial ?? FcTaskDetailState(task: task);
}

class EmptyPhotos implements FcLocalPhotoRepository {
  @override
  Future<List<FcLocalPhoto>> getPendingUploads() async => [];
  @override
  Future<List<FcLocalPhoto>> getPendingDeletes() async => [];
  @override
  Future<FcLocalPhoto?> getActivePhoto(
    String entityId,
    String entityType,
    String photoType,
  ) async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class EmptyOutbox implements FcLocalRepository {
  @override
  Stream<List<String>> watchPendingWrites() => Stream.value([]);
  @override
  Future<List<FcOutboxItem>> getPendingOutboxItems() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Outfit',
    )..addFont(rootBundle.load('assets/fonts/Outfit-Regular.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    dotenv.loadFromString(envString: 'API_BASE_URL=https://synthetic.invalid');
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://synthetic.supabase.co',
      publishableKey: 'synthetic',
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
    );
    String part(Map<String, dynamic> data) =>
        base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
    final token =
        '${part({'alg': 'HS256', 'typ': 'JWT'})}.'
        '${part({'sub': 'crew', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.synthetic';
    await Supabase.instance.client.auth.setInitialSession(
      jsonEncode({
        'access_token': token,
        'refresh_token': 'synthetic',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': 'crew',
          'aud': 'authenticated',
          'role': 'authenticated',
          'app_metadata': {},
          'user_metadata': {},
          'created_at': '2026-01-01T00:00:00Z',
        },
      }),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  for (final kind in ['standalone', 'report', 'cluster']) {
    testWidgets(
      '$kind task shows report-owned evidence without task photo or failure controls',
      (tester) async {
        tester.view.physicalSize = const Size(500, 1500);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final task = CleanupTask.fromJson({
          'id': 'task',
          'title': 'Assigned task',
          'assigned_crew_ids': ['crew'],
          'before_photo_url': 'https://synthetic.supabase.co/before.jpg',
          if (kind == 'report') 'report_ids': ['report'],
          if (kind == 'cluster') 'cluster_id': 'cluster',
        });
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              fcTaskDetailNotifierProvider(
                'task',
              ).overrideWith(() => EvidenceTask(task)),
              fcLocalPhotoRepositoryProvider.overrideWithValue(EmptyPhotos()),
              fcLocalRepositoryProvider.overrideWithValue(EmptyOutbox()),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const FieldCrewTaskDetailScreen(taskId: 'task'),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(FcPhotoUploadSection), findsNothing);
        expect(find.byIcon(Icons.add_a_photo), findsNothing);
        expect(find.text('Unable to Work This Site'), findsNothing);
        expect(find.text('Citizen evidence'), findsOneWidget);
        expect(
          task.beforePhotoUrl,
          isNotNull,
        ); // Existing data is preserved, not deleted.
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  for (final dark in [false, true]) {
    testWidgets('Before allows five and After requirement wraps / $dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final count in [4, 5]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: FcPhotoUploadSection(
                  evidencePhotos: const [],
                  isAssigned: true,
                  isAfterEnabled: false,
                  beforeSlots: [
                    for (var i = 0; i < count; i++)
                      FcPhotoSlot(
                        remoteUrl: 'https://synthetic.invalid/$i.jpg',
                        remoteId: 'p$i',
                      ),
                  ],
                  onUpload: (_, _) async {},
                  onDelete: (_, _) async {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Before Photos ($count/5)'), findsOneWidget);
        await tester.ensureVisible(find.text('Before Photos ($count/5)'));
        await tester.drag(find.byType(ListView).first, const Offset(-800, 0));
        await tester.pumpAndSettle();
        expect(
          find.byIcon(Icons.add_a_photo),
          count == 4 ? findsOneWidget : findsNothing,
        );
        await tester.ensureVisible(find.text('Acknowledge report first'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
    testWidgets(
      'crew evidence stays in app, supports video and empty placeholder / $dark',
      (tester) async {
        final video = SyntheticVideoController(File('synthetic.mp4'));
        Widget section(List<dynamic> media) => MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: FcPhotoUploadSection(
                evidencePhotos: media,
                isAssigned: false,
                videoControllerFactory: (_) => video,
                onUpload: (_, _) async {},
                onDelete: (_, _) async {},
              ),
            ),
          ),
        );
        await tester.pumpWidget(section([]));
        await tester.pumpAndSettle();
        expect(find.text('Citizen evidence unavailable'), findsOneWidget);
        expect(find.text('No citizen photos provided'), findsNothing);
        await tester.pumpWidget(
          section([
            {'url': 'https://synthetic.invalid/photo.jpg'},
          ]),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(PrivateMediaImage).first);
        await tester.pumpAndSettle();
        expect(find.byType(FullScreenImageView), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          section([
            {
              'url': 'https://synthetic.invalid/video.mp4',
              'resource_type': 'video',
            },
          ]),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.play_circle_outline));
        await tester.pumpAndSettle();
        expect(find.text('Citizen video'), findsOneWidget);
        await tester.tap(find.byTooltip('Play report video'));
        await tester.pump();
        expect(video.value.isPlaying, isTrue);
        await tester.tap(find.byTooltip('Pause report video'));
        await tester.pump();
        expect(video.value.isPlaying, isFalse);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(video.released, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'rebuilt task details shows named crew, true report counts and responsive filters / $dark',
      (tester) async {
        tester.view.physicalSize = Size(dark ? 320 : 390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final task = CleanupTask.fromJson({
          'id': 'task',
          'title': 'Clear waste beside the San Nicolas public market',
          'description':
              'Visit each linked report and record its individual outcome.',
          'status': 'in_progress',
          'priority': 'high',
          'location': 'POINT(121.075 14.561)',
          'street_address': 'Caruncho Avenue, San Nicolas, Pasig City',
          'assigned_crew_ids': ['crew'],
          'assigned_team': {'name': 'Crew Alpha'},
          'assigned_members': [
            {'id': 'crew', 'full_name': 'Alexandra Rivera'},
          ],
          'report_ids': ['r1', 'r2', 'r3'],
        });
        final reports = [
          for (var i = 1; i <= 3; i++)
            ReportModel.fromJson({
              'id': 'r$i',
              'title': 'Report $i: Waste near the public market entrance',
              'status': i == 1 ? 'resolved' : 'unresolved',
              'issue_type': 'waste',
              'cleanup_task_id': 'task',
              'validation_status': 'approved',
              'description': 'A detailed concern at this specific location.',
            }),
        ];
        final state = FcTaskDetailState(
          task: task,
          reports: reports,
          evidenceByReport: {'r1': [], 'r2': [], 'r3': []},
        );
        const preview = Key('task-details-preview');
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              fcTaskDetailNotifierProvider(
                'task',
              ).overrideWith(() => EvidenceTask(task, initial: state)),
              fcLocalRepositoryProvider.overrideWithValue(EmptyOutbox()),
              fcLocalPhotoRepositoryProvider.overrideWithValue(EmptyPhotos()),
            ],
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(dark ? 2 : 1)),
                child: RepaintBoundary(key: preview, child: child!),
              ),
              home: const FieldCrewTaskDetailScreen(taskId: 'task'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Crew Alpha'), findsOneWidget);
        expect(find.text('Alexandra Rivera'), findsOneWidget);
        expect(find.textContaining('Caruncho Avenue'), findsOneWidget);
        expect(find.text('1 of 3 linked reports handled'), findsOneWidget);
        expect(find.textContaining('42/200'), findsNothing);
        expect(find.byType(FcPhotoUploadSection), findsNothing);
        expect(find.text('Unable to Work This Site'), findsNothing);
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
              '$output/task-details-${dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.scrollUntilVisible(
          find.text('Open (2)'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Open (2)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open (2)'));
        await tester.pumpAndSettle();
        expect(
          find.text('Report 1: Waste near the public market entrance'),
          findsNothing,
        );
        expect(
          find.text('Report 2: Waste near the public market entrance'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        if (!dark) {
          final actions = find.byTooltip(
            'Actions for Report 2: Waste near the public market entrance',
          );
          await tester.ensureVisible(actions);
          await tester.tap(actions);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Already clear on arrival'));
          await tester.pumpAndSettle();
          expect(find.text('Photograph the clear site'), findsOneWidget);
          expect(find.text('Open report'), findsWidgets);
          expect(
            find.textContaining('No Before photo is required.'),
            findsOneWidget,
          );
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
        }
      },
    );
  }
  testWidgets(
    'gallery distinguishes API failure, empty results and canonical URL photos',
    (tester) async {
      final report = ReportModel.fromJson({
        'id': 'r',
        'title': 'Waste evidence',
      });
      for (final failed in [true, false]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SingleChildScrollView(
                child: FcPhotoGalleryCard(
                  reports: [report],
                  evidenceByReport: failed ? {} : {'r': []},
                  error: failed ? 'Evidence unavailable' : null,
                  onRetry: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          find.text('Evidence unavailable'),
          failed ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('No citizen photo evidence on these reports.'),
          failed ? findsNothing : findsOneWidget,
        );
      }
      const source = 'https://synthetic.invalid/citizen-photo.jpg';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FcPhotoGalleryCard(
              reports: [report],
              evidenceByReport: const {
                'r': [
                  {'url': source, 'resource_type': 'image'},
                ],
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.widget<PrivateMediaImage>(find.byType(PrivateMediaImage)).source,
        source,
      );
      expect(
        find.text('No citizen photo evidence on these reports.'),
        findsNothing,
      );
    },
  );
}
