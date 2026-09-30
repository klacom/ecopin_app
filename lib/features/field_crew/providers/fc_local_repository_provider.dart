import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_repository.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_photo_repository.dart';

/// Riverpod provider for the Field Crew local-first repository.
///
/// All Field Crew repositories that need offline read/write access should
/// depend on this provider rather than on [CacheService] directly.
final fcLocalRepositoryProvider = Provider<FcLocalRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return FcLocalRepository(db);
});

/// Riverpod provider for the Phase 3 offline photo repository.
///
/// Handles file copy, SHA-256 deduplication, and [FcLocalPhotos] DB access.
/// Never makes network calls.
final fcLocalPhotoRepositoryProvider = Provider<FcLocalPhotoRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return FcLocalPhotoRepository(db);
});
