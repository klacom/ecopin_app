import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Tables definition
class OfflineReports extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get idempotencyKey => text().unique()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  BoolColumn get onPrivateProperty => boolean().withDefault(const Constant(false))();
  TextColumn get scaleLevel => text().nullable()();
  TextColumn get obstructionLevel => text().nullable()();
  
  // Media files (stored as comma-separated paths or JSON)
  TextColumn get imagePaths => text().nullable()();
  TextColumn get videoPath => text().nullable()();

  // Sync state
  IntColumn get syncStatus => integer().withDefault(const Constant(0))(); // 0 = pending, 1 = syncing, 2 = failed
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class OfflineTaskUpdates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer()();
  
  // Storing the payload as a JSON string
  TextColumn get payloadJson => text()();
  
  DateTimeColumn get clientKnownUpdatedAt => dateTime()();

  // Sync state
  IntColumn get syncStatus => integer().withDefault(const Constant(0))(); // 0 = pending, 1 = syncing, 2 = failed
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class OfflineMedia extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get idempotencyKey => text().unique()();
  TextColumn get imagePaths => text().nullable()();
  TextColumn get videoPath => text().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))(); // 0 = pending, 1 = syncing, 2 = failed
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [OfflineReports, OfflineTaskUpdates, OfflineMedia])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(offlineMedia);
        }
      },
    );
  }

  // Helper methods for reports
  Future<List<OfflineReport>> getPendingReports() => 

      (select(offlineReports)..where((t) => t.syncStatus.equals(0))).get();
      
  Future<void> markReportSyncing(int id) =>
      (update(offlineReports)..where((t) => t.id.equals(id)))
          .write(const OfflineReportsCompanion(syncStatus: Value(1)));
          
  Future<void> markReportFailed(int id, String error) =>
      (update(offlineReports)..where((t) => t.id.equals(id)))
          .write(OfflineReportsCompanion(syncStatus: const Value(2), syncError: Value(error)));
          
  Future<void> deleteReport(int id) =>
      (delete(offlineReports)..where((t) => t.id.equals(id))).go();

  // Helper methods for task updates
  Future<List<OfflineTaskUpdate>> getPendingTaskUpdates() => 
      (select(offlineTaskUpdates)..where((t) => t.syncStatus.equals(0))).get();
      
  Future<void> markTaskUpdateSyncing(int id) =>
      (update(offlineTaskUpdates)..where((t) => t.id.equals(id)))
          .write(const OfflineTaskUpdatesCompanion(syncStatus: Value(1)));
          
  Future<void> markTaskUpdateFailed(int id, String error) =>
      (update(offlineTaskUpdates)..where((t) => t.id.equals(id)))
          .write(OfflineTaskUpdatesCompanion(syncStatus: const Value(2), syncError: Value(error)));
          
  Future<void> deleteTaskUpdate(int id) =>
      (delete(offlineTaskUpdates)..where((t) => t.id.equals(id))).go();

  // Helper methods for media
  Future<List<OfflineMediaData>> getPendingMedia() => 
      (select(offlineMedia)..where((t) => t.syncStatus.equals(0))).get();
      
  Future<void> markMediaSyncing(int id) =>
      (update(offlineMedia)..where((t) => t.id.equals(id)))
          .write(const OfflineMediaCompanion(syncStatus: Value(1)));
          
  Future<void> markMediaFailed(int id, String error) =>
      (update(offlineMedia)..where((t) => t.id.equals(id)))
          .write(OfflineMediaCompanion(syncStatus: const Value(2), syncError: Value(error)));
          
  Future<void> deleteMedia(int id) =>
      (delete(offlineMedia)..where((t) => t.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return SqfliteQueryExecutor.inDatabaseFolder(path: file.path);
  });
}
