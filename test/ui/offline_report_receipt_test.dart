import 'package:drift/native.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('offline receipt identifies actual local persistence without server acknowledgement', () async {
    dotenv.loadFromString(envString: 'SYNTHETIC_TEST=true');
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
    messenger.setMockMethodCallHandler(channel, (call) async => ['none']);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final result = await ApiClient(db).createReport(title: 'Waste beside a street', description: 'A local concern.', latitude: 14.575, longitude: 121.08, imagePaths: ['synthetic-evidence.png']);
    expect(result.data['saved_locally'], isTrue);
    expect(result.data['report'], isEmpty);
    final reports = await db.select(db.offlineReports).get();
    expect(reports, hasLength(1));
    expect(reports.single.title, 'Waste beside a street');
    expect(await db.select(db.offlineMedia).get(), hasLength(1));
  });
}
