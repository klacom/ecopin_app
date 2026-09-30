import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:logging/logging.dart';

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

class CacheService {
  Database? _db;
  final log = Logger('CacheService');

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cache_v1.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_tasks (
            id TEXT PRIMARY KEY,
            json_data TEXT,
            updated_at INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE cached_reports (
            id TEXT PRIMARY KEY,
            json_data TEXT,
            updated_at INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE offline_mutations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action_type TEXT,
            target_id TEXT,
            payload_json TEXT,
            created_at INTEGER
          )
        ''');
      },
    );
  }

  // --- Tasks ---

  Future<void> cacheTasks(List<CleanupTask> tasks) async {
    try {
      final db = await database;
      final batch = db.batch();
      for (var task in tasks) {
        batch.insert(
          'cached_tasks',
          {
            'id': task.id,
            'json_data': jsonEncode(task.toJson()),
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      log.severe('Failed to cache tasks', e);
    }
  }

  Future<List<CleanupTask>> getCachedTasks() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('cached_tasks');
      return maps.map((map) {
        return CleanupTask.fromJson(jsonDecode(map['json_data'] as String));
      }).toList();
    } catch (e) {
      log.severe('Failed to read cached tasks', e);
      return [];
    }
  }
  
  Future<CleanupTask?> getCachedTaskById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'cached_tasks',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return CleanupTask.fromJson(jsonDecode(maps.first['json_data'] as String));
      }
      return null;
    } catch (e) {
      log.severe('Failed to read cached task', e);
      return null;
    }
  }

  // --- Reports ---

  Future<void> cacheReports(List<ReportModel> reports) async {
    try {
      final db = await database;
      final batch = db.batch();
      for (var report in reports) {
        batch.insert(
          'cached_reports',
          {
            'id': report.id,
            'json_data': jsonEncode(report.toJson()),
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      log.severe('Failed to cache reports', e);
    }
  }

  Future<List<ReportModel>> getCachedReports() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('cached_reports');
      return maps.map((map) {
        return ReportModel.fromJson(jsonDecode(map['json_data'] as String));
      }).toList();
    } catch (e) {
      log.severe('Failed to read cached reports', e);
      return [];
    }
  }
  
  Future<ReportModel?> getCachedReportById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'cached_reports',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return ReportModel.fromJson(jsonDecode(maps.first['json_data'] as String));
      }
      return null;
    } catch (e) {
      log.severe('Failed to read cached report', e);
      return null;
    }
  }
  
  Future<void> clearCache() async {
    try {
      final db = await database;
      await db.delete('cached_tasks');
      await db.delete('cached_reports');
    } catch (e) {
      log.severe('Failed to clear cache', e);
    }
  }

  // --- Offline Mutations ---
  Future<void> queueMutation({
    required String actionType,
    required String targetId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final db = await database;
      await db.insert('offline_mutations', {
        'action_type': actionType,
        'target_id': targetId,
        'payload_json': jsonEncode(payload),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      log.severe('Failed to queue offline mutation', e);
    }
  }

  Future<List<Map<String, dynamic>>> getPendingMutations() async {
    try {
      final db = await database;
      return await db.query('offline_mutations', orderBy: 'created_at ASC');
    } catch (e) {
      log.severe('Failed to read offline mutations', e);
      return [];
    }
  }

  Future<void> deleteMutation(int id) async {
    try {
      final db = await database;
      await db.delete('offline_mutations', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      log.severe('Failed to delete offline mutation', e);
    }
  }
}
