// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $OfflineReportsTable extends OfflineReports
    with TableInfo<$OfflineReportsTable, OfflineReport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _onPrivatePropertyMeta = const VerificationMeta(
    'onPrivateProperty',
  );
  @override
  late final GeneratedColumn<bool> onPrivateProperty = GeneratedColumn<bool>(
    'on_private_property',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("on_private_property" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _scaleLevelMeta = const VerificationMeta(
    'scaleLevel',
  );
  @override
  late final GeneratedColumn<String> scaleLevel = GeneratedColumn<String>(
    'scale_level',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _obstructionLevelMeta = const VerificationMeta(
    'obstructionLevel',
  );
  @override
  late final GeneratedColumn<String> obstructionLevel = GeneratedColumn<String>(
    'obstruction_level',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathsMeta = const VerificationMeta(
    'imagePaths',
  );
  @override
  late final GeneratedColumn<String> imagePaths = GeneratedColumn<String>(
    'image_paths',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _videoPathMeta = const VerificationMeta(
    'videoPath',
  );
  @override
  late final GeneratedColumn<String> videoPath = GeneratedColumn<String>(
    'video_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    idempotencyKey,
    title,
    description,
    latitude,
    longitude,
    onPrivateProperty,
    scaleLevel,
    obstructionLevel,
    imagePaths,
    videoPath,
    syncStatus,
    syncError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineReport> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('on_private_property')) {
      context.handle(
        _onPrivatePropertyMeta,
        onPrivateProperty.isAcceptableOrUnknown(
          data['on_private_property']!,
          _onPrivatePropertyMeta,
        ),
      );
    }
    if (data.containsKey('scale_level')) {
      context.handle(
        _scaleLevelMeta,
        scaleLevel.isAcceptableOrUnknown(data['scale_level']!, _scaleLevelMeta),
      );
    }
    if (data.containsKey('obstruction_level')) {
      context.handle(
        _obstructionLevelMeta,
        obstructionLevel.isAcceptableOrUnknown(
          data['obstruction_level']!,
          _obstructionLevelMeta,
        ),
      );
    }
    if (data.containsKey('image_paths')) {
      context.handle(
        _imagePathsMeta,
        imagePaths.isAcceptableOrUnknown(data['image_paths']!, _imagePathsMeta),
      );
    }
    if (data.containsKey('video_path')) {
      context.handle(
        _videoPathMeta,
        videoPath.isAcceptableOrUnknown(data['video_path']!, _videoPathMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineReport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineReport(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      onPrivateProperty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}on_private_property'],
      )!,
      scaleLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scale_level'],
      ),
      obstructionLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}obstruction_level'],
      ),
      imagePaths: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_paths'],
      ),
      videoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_path'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OfflineReportsTable createAlias(String alias) {
    return $OfflineReportsTable(attachedDatabase, alias);
  }
}

class OfflineReport extends DataClass implements Insertable<OfflineReport> {
  final int id;
  final String idempotencyKey;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final bool onPrivateProperty;
  final String? scaleLevel;
  final String? obstructionLevel;
  final String? imagePaths;
  final String? videoPath;
  final int syncStatus;
  final String? syncError;
  final DateTime createdAt;
  const OfflineReport({
    required this.id,
    required this.idempotencyKey,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.onPrivateProperty,
    this.scaleLevel,
    this.obstructionLevel,
    this.imagePaths,
    this.videoPath,
    required this.syncStatus,
    this.syncError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['on_private_property'] = Variable<bool>(onPrivateProperty);
    if (!nullToAbsent || scaleLevel != null) {
      map['scale_level'] = Variable<String>(scaleLevel);
    }
    if (!nullToAbsent || obstructionLevel != null) {
      map['obstruction_level'] = Variable<String>(obstructionLevel);
    }
    if (!nullToAbsent || imagePaths != null) {
      map['image_paths'] = Variable<String>(imagePaths);
    }
    if (!nullToAbsent || videoPath != null) {
      map['video_path'] = Variable<String>(videoPath);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OfflineReportsCompanion toCompanion(bool nullToAbsent) {
    return OfflineReportsCompanion(
      id: Value(id),
      idempotencyKey: Value(idempotencyKey),
      title: Value(title),
      description: Value(description),
      latitude: Value(latitude),
      longitude: Value(longitude),
      onPrivateProperty: Value(onPrivateProperty),
      scaleLevel: scaleLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(scaleLevel),
      obstructionLevel: obstructionLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(obstructionLevel),
      imagePaths: imagePaths == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePaths),
      videoPath: videoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(videoPath),
      syncStatus: Value(syncStatus),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      createdAt: Value(createdAt),
    );
  }

  factory OfflineReport.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineReport(
      id: serializer.fromJson<int>(json['id']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      onPrivateProperty: serializer.fromJson<bool>(json['onPrivateProperty']),
      scaleLevel: serializer.fromJson<String?>(json['scaleLevel']),
      obstructionLevel: serializer.fromJson<String?>(json['obstructionLevel']),
      imagePaths: serializer.fromJson<String?>(json['imagePaths']),
      videoPath: serializer.fromJson<String?>(json['videoPath']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'onPrivateProperty': serializer.toJson<bool>(onPrivateProperty),
      'scaleLevel': serializer.toJson<String?>(scaleLevel),
      'obstructionLevel': serializer.toJson<String?>(obstructionLevel),
      'imagePaths': serializer.toJson<String?>(imagePaths),
      'videoPath': serializer.toJson<String?>(videoPath),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'syncError': serializer.toJson<String?>(syncError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OfflineReport copyWith({
    int? id,
    String? idempotencyKey,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    bool? onPrivateProperty,
    Value<String?> scaleLevel = const Value.absent(),
    Value<String?> obstructionLevel = const Value.absent(),
    Value<String?> imagePaths = const Value.absent(),
    Value<String?> videoPath = const Value.absent(),
    int? syncStatus,
    Value<String?> syncError = const Value.absent(),
    DateTime? createdAt,
  }) => OfflineReport(
    id: id ?? this.id,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    title: title ?? this.title,
    description: description ?? this.description,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    onPrivateProperty: onPrivateProperty ?? this.onPrivateProperty,
    scaleLevel: scaleLevel.present ? scaleLevel.value : this.scaleLevel,
    obstructionLevel: obstructionLevel.present
        ? obstructionLevel.value
        : this.obstructionLevel,
    imagePaths: imagePaths.present ? imagePaths.value : this.imagePaths,
    videoPath: videoPath.present ? videoPath.value : this.videoPath,
    syncStatus: syncStatus ?? this.syncStatus,
    syncError: syncError.present ? syncError.value : this.syncError,
    createdAt: createdAt ?? this.createdAt,
  );
  OfflineReport copyWithCompanion(OfflineReportsCompanion data) {
    return OfflineReport(
      id: data.id.present ? data.id.value : this.id,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      onPrivateProperty: data.onPrivateProperty.present
          ? data.onPrivateProperty.value
          : this.onPrivateProperty,
      scaleLevel: data.scaleLevel.present
          ? data.scaleLevel.value
          : this.scaleLevel,
      obstructionLevel: data.obstructionLevel.present
          ? data.obstructionLevel.value
          : this.obstructionLevel,
      imagePaths: data.imagePaths.present
          ? data.imagePaths.value
          : this.imagePaths,
      videoPath: data.videoPath.present ? data.videoPath.value : this.videoPath,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineReport(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('onPrivateProperty: $onPrivateProperty, ')
          ..write('scaleLevel: $scaleLevel, ')
          ..write('obstructionLevel: $obstructionLevel, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('videoPath: $videoPath, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    idempotencyKey,
    title,
    description,
    latitude,
    longitude,
    onPrivateProperty,
    scaleLevel,
    obstructionLevel,
    imagePaths,
    videoPath,
    syncStatus,
    syncError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineReport &&
          other.id == this.id &&
          other.idempotencyKey == this.idempotencyKey &&
          other.title == this.title &&
          other.description == this.description &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.onPrivateProperty == this.onPrivateProperty &&
          other.scaleLevel == this.scaleLevel &&
          other.obstructionLevel == this.obstructionLevel &&
          other.imagePaths == this.imagePaths &&
          other.videoPath == this.videoPath &&
          other.syncStatus == this.syncStatus &&
          other.syncError == this.syncError &&
          other.createdAt == this.createdAt);
}

class OfflineReportsCompanion extends UpdateCompanion<OfflineReport> {
  final Value<int> id;
  final Value<String> idempotencyKey;
  final Value<String> title;
  final Value<String> description;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<bool> onPrivateProperty;
  final Value<String?> scaleLevel;
  final Value<String?> obstructionLevel;
  final Value<String?> imagePaths;
  final Value<String?> videoPath;
  final Value<int> syncStatus;
  final Value<String?> syncError;
  final Value<DateTime> createdAt;
  const OfflineReportsCompanion({
    this.id = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.onPrivateProperty = const Value.absent(),
    this.scaleLevel = const Value.absent(),
    this.obstructionLevel = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.videoPath = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OfflineReportsCompanion.insert({
    this.id = const Value.absent(),
    required String idempotencyKey,
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    this.onPrivateProperty = const Value.absent(),
    this.scaleLevel = const Value.absent(),
    this.obstructionLevel = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.videoPath = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : idempotencyKey = Value(idempotencyKey),
       title = Value(title),
       description = Value(description),
       latitude = Value(latitude),
       longitude = Value(longitude);
  static Insertable<OfflineReport> custom({
    Expression<int>? id,
    Expression<String>? idempotencyKey,
    Expression<String>? title,
    Expression<String>? description,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<bool>? onPrivateProperty,
    Expression<String>? scaleLevel,
    Expression<String>? obstructionLevel,
    Expression<String>? imagePaths,
    Expression<String>? videoPath,
    Expression<int>? syncStatus,
    Expression<String>? syncError,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (onPrivateProperty != null) 'on_private_property': onPrivateProperty,
      if (scaleLevel != null) 'scale_level': scaleLevel,
      if (obstructionLevel != null) 'obstruction_level': obstructionLevel,
      if (imagePaths != null) 'image_paths': imagePaths,
      if (videoPath != null) 'video_path': videoPath,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncError != null) 'sync_error': syncError,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OfflineReportsCompanion copyWith({
    Value<int>? id,
    Value<String>? idempotencyKey,
    Value<String>? title,
    Value<String>? description,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<bool>? onPrivateProperty,
    Value<String?>? scaleLevel,
    Value<String?>? obstructionLevel,
    Value<String?>? imagePaths,
    Value<String?>? videoPath,
    Value<int>? syncStatus,
    Value<String?>? syncError,
    Value<DateTime>? createdAt,
  }) {
    return OfflineReportsCompanion(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      onPrivateProperty: onPrivateProperty ?? this.onPrivateProperty,
      scaleLevel: scaleLevel ?? this.scaleLevel,
      obstructionLevel: obstructionLevel ?? this.obstructionLevel,
      imagePaths: imagePaths ?? this.imagePaths,
      videoPath: videoPath ?? this.videoPath,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (onPrivateProperty.present) {
      map['on_private_property'] = Variable<bool>(onPrivateProperty.value);
    }
    if (scaleLevel.present) {
      map['scale_level'] = Variable<String>(scaleLevel.value);
    }
    if (obstructionLevel.present) {
      map['obstruction_level'] = Variable<String>(obstructionLevel.value);
    }
    if (imagePaths.present) {
      map['image_paths'] = Variable<String>(imagePaths.value);
    }
    if (videoPath.present) {
      map['video_path'] = Variable<String>(videoPath.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineReportsCompanion(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('onPrivateProperty: $onPrivateProperty, ')
          ..write('scaleLevel: $scaleLevel, ')
          ..write('obstructionLevel: $obstructionLevel, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('videoPath: $videoPath, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $OfflineTaskUpdatesTable extends OfflineTaskUpdates
    with TableInfo<$OfflineTaskUpdatesTable, OfflineTaskUpdate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineTaskUpdatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientKnownUpdatedAtMeta =
      const VerificationMeta('clientKnownUpdatedAt');
  @override
  late final GeneratedColumn<DateTime> clientKnownUpdatedAt =
      GeneratedColumn<DateTime>(
        'client_known_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    payloadJson,
    clientKnownUpdatedAt,
    syncStatus,
    syncError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_task_updates';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineTaskUpdate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('client_known_updated_at')) {
      context.handle(
        _clientKnownUpdatedAtMeta,
        clientKnownUpdatedAt.isAcceptableOrUnknown(
          data['client_known_updated_at']!,
          _clientKnownUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientKnownUpdatedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineTaskUpdate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineTaskUpdate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      clientKnownUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_known_updated_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OfflineTaskUpdatesTable createAlias(String alias) {
    return $OfflineTaskUpdatesTable(attachedDatabase, alias);
  }
}

class OfflineTaskUpdate extends DataClass
    implements Insertable<OfflineTaskUpdate> {
  final int id;
  final int taskId;
  final String payloadJson;
  final DateTime clientKnownUpdatedAt;
  final int syncStatus;
  final String? syncError;
  final DateTime createdAt;
  const OfflineTaskUpdate({
    required this.id,
    required this.taskId,
    required this.payloadJson,
    required this.clientKnownUpdatedAt,
    required this.syncStatus,
    this.syncError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<int>(taskId);
    map['payload_json'] = Variable<String>(payloadJson);
    map['client_known_updated_at'] = Variable<DateTime>(clientKnownUpdatedAt);
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OfflineTaskUpdatesCompanion toCompanion(bool nullToAbsent) {
    return OfflineTaskUpdatesCompanion(
      id: Value(id),
      taskId: Value(taskId),
      payloadJson: Value(payloadJson),
      clientKnownUpdatedAt: Value(clientKnownUpdatedAt),
      syncStatus: Value(syncStatus),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      createdAt: Value(createdAt),
    );
  }

  factory OfflineTaskUpdate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineTaskUpdate(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<int>(json['taskId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      clientKnownUpdatedAt: serializer.fromJson<DateTime>(
        json['clientKnownUpdatedAt'],
      ),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<int>(taskId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'clientKnownUpdatedAt': serializer.toJson<DateTime>(clientKnownUpdatedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'syncError': serializer.toJson<String?>(syncError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OfflineTaskUpdate copyWith({
    int? id,
    int? taskId,
    String? payloadJson,
    DateTime? clientKnownUpdatedAt,
    int? syncStatus,
    Value<String?> syncError = const Value.absent(),
    DateTime? createdAt,
  }) => OfflineTaskUpdate(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    payloadJson: payloadJson ?? this.payloadJson,
    clientKnownUpdatedAt: clientKnownUpdatedAt ?? this.clientKnownUpdatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    syncError: syncError.present ? syncError.value : this.syncError,
    createdAt: createdAt ?? this.createdAt,
  );
  OfflineTaskUpdate copyWithCompanion(OfflineTaskUpdatesCompanion data) {
    return OfflineTaskUpdate(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      clientKnownUpdatedAt: data.clientKnownUpdatedAt.present
          ? data.clientKnownUpdatedAt.value
          : this.clientKnownUpdatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineTaskUpdate(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('clientKnownUpdatedAt: $clientKnownUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    payloadJson,
    clientKnownUpdatedAt,
    syncStatus,
    syncError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineTaskUpdate &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.payloadJson == this.payloadJson &&
          other.clientKnownUpdatedAt == this.clientKnownUpdatedAt &&
          other.syncStatus == this.syncStatus &&
          other.syncError == this.syncError &&
          other.createdAt == this.createdAt);
}

class OfflineTaskUpdatesCompanion extends UpdateCompanion<OfflineTaskUpdate> {
  final Value<int> id;
  final Value<int> taskId;
  final Value<String> payloadJson;
  final Value<DateTime> clientKnownUpdatedAt;
  final Value<int> syncStatus;
  final Value<String?> syncError;
  final Value<DateTime> createdAt;
  const OfflineTaskUpdatesCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.clientKnownUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OfflineTaskUpdatesCompanion.insert({
    this.id = const Value.absent(),
    required int taskId,
    required String payloadJson,
    required DateTime clientKnownUpdatedAt,
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : taskId = Value(taskId),
       payloadJson = Value(payloadJson),
       clientKnownUpdatedAt = Value(clientKnownUpdatedAt);
  static Insertable<OfflineTaskUpdate> custom({
    Expression<int>? id,
    Expression<int>? taskId,
    Expression<String>? payloadJson,
    Expression<DateTime>? clientKnownUpdatedAt,
    Expression<int>? syncStatus,
    Expression<String>? syncError,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (clientKnownUpdatedAt != null)
        'client_known_updated_at': clientKnownUpdatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncError != null) 'sync_error': syncError,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OfflineTaskUpdatesCompanion copyWith({
    Value<int>? id,
    Value<int>? taskId,
    Value<String>? payloadJson,
    Value<DateTime>? clientKnownUpdatedAt,
    Value<int>? syncStatus,
    Value<String?>? syncError,
    Value<DateTime>? createdAt,
  }) {
    return OfflineTaskUpdatesCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      payloadJson: payloadJson ?? this.payloadJson,
      clientKnownUpdatedAt: clientKnownUpdatedAt ?? this.clientKnownUpdatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (clientKnownUpdatedAt.present) {
      map['client_known_updated_at'] = Variable<DateTime>(
        clientKnownUpdatedAt.value,
      );
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineTaskUpdatesCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('clientKnownUpdatedAt: $clientKnownUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $OfflineMediaTable extends OfflineMedia
    with TableInfo<$OfflineMediaTable, OfflineMediaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineMediaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _imagePathsMeta = const VerificationMeta(
    'imagePaths',
  );
  @override
  late final GeneratedColumn<String> imagePaths = GeneratedColumn<String>(
    'image_paths',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _videoPathMeta = const VerificationMeta(
    'videoPath',
  );
  @override
  late final GeneratedColumn<String> videoPath = GeneratedColumn<String>(
    'video_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    idempotencyKey,
    imagePaths,
    videoPath,
    syncStatus,
    syncError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_media';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineMediaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('image_paths')) {
      context.handle(
        _imagePathsMeta,
        imagePaths.isAcceptableOrUnknown(data['image_paths']!, _imagePathsMeta),
      );
    }
    if (data.containsKey('video_path')) {
      context.handle(
        _videoPathMeta,
        videoPath.isAcceptableOrUnknown(data['video_path']!, _videoPathMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineMediaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineMediaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      imagePaths: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_paths'],
      ),
      videoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_path'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OfflineMediaTable createAlias(String alias) {
    return $OfflineMediaTable(attachedDatabase, alias);
  }
}

class OfflineMediaData extends DataClass
    implements Insertable<OfflineMediaData> {
  final int id;
  final String idempotencyKey;
  final String? imagePaths;
  final String? videoPath;
  final int syncStatus;
  final String? syncError;
  final DateTime createdAt;
  const OfflineMediaData({
    required this.id,
    required this.idempotencyKey,
    this.imagePaths,
    this.videoPath,
    required this.syncStatus,
    this.syncError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    if (!nullToAbsent || imagePaths != null) {
      map['image_paths'] = Variable<String>(imagePaths);
    }
    if (!nullToAbsent || videoPath != null) {
      map['video_path'] = Variable<String>(videoPath);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OfflineMediaCompanion toCompanion(bool nullToAbsent) {
    return OfflineMediaCompanion(
      id: Value(id),
      idempotencyKey: Value(idempotencyKey),
      imagePaths: imagePaths == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePaths),
      videoPath: videoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(videoPath),
      syncStatus: Value(syncStatus),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      createdAt: Value(createdAt),
    );
  }

  factory OfflineMediaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineMediaData(
      id: serializer.fromJson<int>(json['id']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      imagePaths: serializer.fromJson<String?>(json['imagePaths']),
      videoPath: serializer.fromJson<String?>(json['videoPath']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'imagePaths': serializer.toJson<String?>(imagePaths),
      'videoPath': serializer.toJson<String?>(videoPath),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'syncError': serializer.toJson<String?>(syncError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OfflineMediaData copyWith({
    int? id,
    String? idempotencyKey,
    Value<String?> imagePaths = const Value.absent(),
    Value<String?> videoPath = const Value.absent(),
    int? syncStatus,
    Value<String?> syncError = const Value.absent(),
    DateTime? createdAt,
  }) => OfflineMediaData(
    id: id ?? this.id,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    imagePaths: imagePaths.present ? imagePaths.value : this.imagePaths,
    videoPath: videoPath.present ? videoPath.value : this.videoPath,
    syncStatus: syncStatus ?? this.syncStatus,
    syncError: syncError.present ? syncError.value : this.syncError,
    createdAt: createdAt ?? this.createdAt,
  );
  OfflineMediaData copyWithCompanion(OfflineMediaCompanion data) {
    return OfflineMediaData(
      id: data.id.present ? data.id.value : this.id,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      imagePaths: data.imagePaths.present
          ? data.imagePaths.value
          : this.imagePaths,
      videoPath: data.videoPath.present ? data.videoPath.value : this.videoPath,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineMediaData(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('videoPath: $videoPath, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    idempotencyKey,
    imagePaths,
    videoPath,
    syncStatus,
    syncError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineMediaData &&
          other.id == this.id &&
          other.idempotencyKey == this.idempotencyKey &&
          other.imagePaths == this.imagePaths &&
          other.videoPath == this.videoPath &&
          other.syncStatus == this.syncStatus &&
          other.syncError == this.syncError &&
          other.createdAt == this.createdAt);
}

class OfflineMediaCompanion extends UpdateCompanion<OfflineMediaData> {
  final Value<int> id;
  final Value<String> idempotencyKey;
  final Value<String?> imagePaths;
  final Value<String?> videoPath;
  final Value<int> syncStatus;
  final Value<String?> syncError;
  final Value<DateTime> createdAt;
  const OfflineMediaCompanion({
    this.id = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.videoPath = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OfflineMediaCompanion.insert({
    this.id = const Value.absent(),
    required String idempotencyKey,
    this.imagePaths = const Value.absent(),
    this.videoPath = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : idempotencyKey = Value(idempotencyKey);
  static Insertable<OfflineMediaData> custom({
    Expression<int>? id,
    Expression<String>? idempotencyKey,
    Expression<String>? imagePaths,
    Expression<String>? videoPath,
    Expression<int>? syncStatus,
    Expression<String>? syncError,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (imagePaths != null) 'image_paths': imagePaths,
      if (videoPath != null) 'video_path': videoPath,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncError != null) 'sync_error': syncError,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OfflineMediaCompanion copyWith({
    Value<int>? id,
    Value<String>? idempotencyKey,
    Value<String?>? imagePaths,
    Value<String?>? videoPath,
    Value<int>? syncStatus,
    Value<String?>? syncError,
    Value<DateTime>? createdAt,
  }) {
    return OfflineMediaCompanion(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      imagePaths: imagePaths ?? this.imagePaths,
      videoPath: videoPath ?? this.videoPath,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (imagePaths.present) {
      map['image_paths'] = Variable<String>(imagePaths.value);
    }
    if (videoPath.present) {
      map['video_path'] = Variable<String>(videoPath.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineMediaCompanion(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('videoPath: $videoPath, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FcCachedReportsTable extends FcCachedReports
    with TableInfo<$FcCachedReportsTable, FcCachedReport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FcCachedReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonDataMeta = const VerificationMeta(
    'jsonData',
  );
  @override
  late final GeneratedColumn<String> jsonData = GeneratedColumn<String>(
    'json_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localSyncStateMeta = const VerificationMeta(
    'localSyncState',
  );
  @override
  late final GeneratedColumn<int> localSyncState = GeneratedColumn<int>(
    'local_sync_state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    jsonData,
    localSyncState,
    serverUpdatedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fc_cached_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<FcCachedReport> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json_data')) {
      context.handle(
        _jsonDataMeta,
        jsonData.isAcceptableOrUnknown(data['json_data']!, _jsonDataMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonDataMeta);
    }
    if (data.containsKey('local_sync_state')) {
      context.handle(
        _localSyncStateMeta,
        localSyncState.isAcceptableOrUnknown(
          data['local_sync_state']!,
          _localSyncStateMeta,
        ),
      );
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serverUpdatedAtMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FcCachedReport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FcCachedReport(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      jsonData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_data'],
      )!,
      localSyncState: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_sync_state'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_updated_at'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $FcCachedReportsTable createAlias(String alias) {
    return $FcCachedReportsTable(attachedDatabase, alias);
  }
}

class FcCachedReport extends DataClass implements Insertable<FcCachedReport> {
  final String id;
  final String jsonData;
  final int localSyncState;
  final DateTime serverUpdatedAt;
  final DateTime cachedAt;
  const FcCachedReport({
    required this.id,
    required this.jsonData,
    required this.localSyncState,
    required this.serverUpdatedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['json_data'] = Variable<String>(jsonData);
    map['local_sync_state'] = Variable<int>(localSyncState);
    map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  FcCachedReportsCompanion toCompanion(bool nullToAbsent) {
    return FcCachedReportsCompanion(
      id: Value(id),
      jsonData: Value(jsonData),
      localSyncState: Value(localSyncState),
      serverUpdatedAt: Value(serverUpdatedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory FcCachedReport.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FcCachedReport(
      id: serializer.fromJson<String>(json['id']),
      jsonData: serializer.fromJson<String>(json['jsonData']),
      localSyncState: serializer.fromJson<int>(json['localSyncState']),
      serverUpdatedAt: serializer.fromJson<DateTime>(json['serverUpdatedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'jsonData': serializer.toJson<String>(jsonData),
      'localSyncState': serializer.toJson<int>(localSyncState),
      'serverUpdatedAt': serializer.toJson<DateTime>(serverUpdatedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  FcCachedReport copyWith({
    String? id,
    String? jsonData,
    int? localSyncState,
    DateTime? serverUpdatedAt,
    DateTime? cachedAt,
  }) => FcCachedReport(
    id: id ?? this.id,
    jsonData: jsonData ?? this.jsonData,
    localSyncState: localSyncState ?? this.localSyncState,
    serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  FcCachedReport copyWithCompanion(FcCachedReportsCompanion data) {
    return FcCachedReport(
      id: data.id.present ? data.id.value : this.id,
      jsonData: data.jsonData.present ? data.jsonData.value : this.jsonData,
      localSyncState: data.localSyncState.present
          ? data.localSyncState.value
          : this.localSyncState,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FcCachedReport(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData, ')
          ..write('localSyncState: $localSyncState, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, jsonData, localSyncState, serverUpdatedAt, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FcCachedReport &&
          other.id == this.id &&
          other.jsonData == this.jsonData &&
          other.localSyncState == this.localSyncState &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.cachedAt == this.cachedAt);
}

class FcCachedReportsCompanion extends UpdateCompanion<FcCachedReport> {
  final Value<String> id;
  final Value<String> jsonData;
  final Value<int> localSyncState;
  final Value<DateTime> serverUpdatedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const FcCachedReportsCompanion({
    this.id = const Value.absent(),
    this.jsonData = const Value.absent(),
    this.localSyncState = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FcCachedReportsCompanion.insert({
    required String id,
    required String jsonData,
    this.localSyncState = const Value.absent(),
    required DateTime serverUpdatedAt,
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       jsonData = Value(jsonData),
       serverUpdatedAt = Value(serverUpdatedAt);
  static Insertable<FcCachedReport> custom({
    Expression<String>? id,
    Expression<String>? jsonData,
    Expression<int>? localSyncState,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jsonData != null) 'json_data': jsonData,
      if (localSyncState != null) 'local_sync_state': localSyncState,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FcCachedReportsCompanion copyWith({
    Value<String>? id,
    Value<String>? jsonData,
    Value<int>? localSyncState,
    Value<DateTime>? serverUpdatedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return FcCachedReportsCompanion(
      id: id ?? this.id,
      jsonData: jsonData ?? this.jsonData,
      localSyncState: localSyncState ?? this.localSyncState,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (jsonData.present) {
      map['json_data'] = Variable<String>(jsonData.value);
    }
    if (localSyncState.present) {
      map['local_sync_state'] = Variable<int>(localSyncState.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FcCachedReportsCompanion(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData, ')
          ..write('localSyncState: $localSyncState, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FcCachedTasksTable extends FcCachedTasks
    with TableInfo<$FcCachedTasksTable, FcCachedTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FcCachedTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonDataMeta = const VerificationMeta(
    'jsonData',
  );
  @override
  late final GeneratedColumn<String> jsonData = GeneratedColumn<String>(
    'json_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localSyncStateMeta = const VerificationMeta(
    'localSyncState',
  );
  @override
  late final GeneratedColumn<int> localSyncState = GeneratedColumn<int>(
    'local_sync_state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    jsonData,
    localSyncState,
    serverUpdatedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fc_cached_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<FcCachedTask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json_data')) {
      context.handle(
        _jsonDataMeta,
        jsonData.isAcceptableOrUnknown(data['json_data']!, _jsonDataMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonDataMeta);
    }
    if (data.containsKey('local_sync_state')) {
      context.handle(
        _localSyncStateMeta,
        localSyncState.isAcceptableOrUnknown(
          data['local_sync_state']!,
          _localSyncStateMeta,
        ),
      );
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serverUpdatedAtMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FcCachedTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FcCachedTask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      jsonData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_data'],
      )!,
      localSyncState: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_sync_state'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_updated_at'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $FcCachedTasksTable createAlias(String alias) {
    return $FcCachedTasksTable(attachedDatabase, alias);
  }
}

class FcCachedTask extends DataClass implements Insertable<FcCachedTask> {
  final String id;
  final String jsonData;
  final int localSyncState;
  final DateTime serverUpdatedAt;
  final DateTime cachedAt;
  const FcCachedTask({
    required this.id,
    required this.jsonData,
    required this.localSyncState,
    required this.serverUpdatedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['json_data'] = Variable<String>(jsonData);
    map['local_sync_state'] = Variable<int>(localSyncState);
    map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  FcCachedTasksCompanion toCompanion(bool nullToAbsent) {
    return FcCachedTasksCompanion(
      id: Value(id),
      jsonData: Value(jsonData),
      localSyncState: Value(localSyncState),
      serverUpdatedAt: Value(serverUpdatedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory FcCachedTask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FcCachedTask(
      id: serializer.fromJson<String>(json['id']),
      jsonData: serializer.fromJson<String>(json['jsonData']),
      localSyncState: serializer.fromJson<int>(json['localSyncState']),
      serverUpdatedAt: serializer.fromJson<DateTime>(json['serverUpdatedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'jsonData': serializer.toJson<String>(jsonData),
      'localSyncState': serializer.toJson<int>(localSyncState),
      'serverUpdatedAt': serializer.toJson<DateTime>(serverUpdatedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  FcCachedTask copyWith({
    String? id,
    String? jsonData,
    int? localSyncState,
    DateTime? serverUpdatedAt,
    DateTime? cachedAt,
  }) => FcCachedTask(
    id: id ?? this.id,
    jsonData: jsonData ?? this.jsonData,
    localSyncState: localSyncState ?? this.localSyncState,
    serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  FcCachedTask copyWithCompanion(FcCachedTasksCompanion data) {
    return FcCachedTask(
      id: data.id.present ? data.id.value : this.id,
      jsonData: data.jsonData.present ? data.jsonData.value : this.jsonData,
      localSyncState: data.localSyncState.present
          ? data.localSyncState.value
          : this.localSyncState,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FcCachedTask(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData, ')
          ..write('localSyncState: $localSyncState, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, jsonData, localSyncState, serverUpdatedAt, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FcCachedTask &&
          other.id == this.id &&
          other.jsonData == this.jsonData &&
          other.localSyncState == this.localSyncState &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.cachedAt == this.cachedAt);
}

class FcCachedTasksCompanion extends UpdateCompanion<FcCachedTask> {
  final Value<String> id;
  final Value<String> jsonData;
  final Value<int> localSyncState;
  final Value<DateTime> serverUpdatedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const FcCachedTasksCompanion({
    this.id = const Value.absent(),
    this.jsonData = const Value.absent(),
    this.localSyncState = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FcCachedTasksCompanion.insert({
    required String id,
    required String jsonData,
    this.localSyncState = const Value.absent(),
    required DateTime serverUpdatedAt,
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       jsonData = Value(jsonData),
       serverUpdatedAt = Value(serverUpdatedAt);
  static Insertable<FcCachedTask> custom({
    Expression<String>? id,
    Expression<String>? jsonData,
    Expression<int>? localSyncState,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jsonData != null) 'json_data': jsonData,
      if (localSyncState != null) 'local_sync_state': localSyncState,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FcCachedTasksCompanion copyWith({
    Value<String>? id,
    Value<String>? jsonData,
    Value<int>? localSyncState,
    Value<DateTime>? serverUpdatedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return FcCachedTasksCompanion(
      id: id ?? this.id,
      jsonData: jsonData ?? this.jsonData,
      localSyncState: localSyncState ?? this.localSyncState,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (jsonData.present) {
      map['json_data'] = Variable<String>(jsonData.value);
    }
    if (localSyncState.present) {
      map['local_sync_state'] = Variable<int>(localSyncState.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FcCachedTasksCompanion(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData, ')
          ..write('localSyncState: $localSyncState, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FcCachedEvidencesTable extends FcCachedEvidences
    with TableInfo<$FcCachedEvidencesTable, FcCachedEvidence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FcCachedEvidencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reportIdMeta = const VerificationMeta(
    'reportId',
  );
  @override
  late final GeneratedColumn<String> reportId = GeneratedColumn<String>(
    'report_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonDataMeta = const VerificationMeta(
    'jsonData',
  );
  @override
  late final GeneratedColumn<String> jsonData = GeneratedColumn<String>(
    'json_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, reportId, jsonData, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fc_cached_evidences';
  @override
  VerificationContext validateIntegrity(
    Insertable<FcCachedEvidence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('report_id')) {
      context.handle(
        _reportIdMeta,
        reportId.isAcceptableOrUnknown(data['report_id']!, _reportIdMeta),
      );
    } else if (isInserting) {
      context.missing(_reportIdMeta);
    }
    if (data.containsKey('json_data')) {
      context.handle(
        _jsonDataMeta,
        jsonData.isAcceptableOrUnknown(data['json_data']!, _jsonDataMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonDataMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FcCachedEvidence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FcCachedEvidence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      reportId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}report_id'],
      )!,
      jsonData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_data'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $FcCachedEvidencesTable createAlias(String alias) {
    return $FcCachedEvidencesTable(attachedDatabase, alias);
  }
}

class FcCachedEvidence extends DataClass
    implements Insertable<FcCachedEvidence> {
  final String id;
  final String reportId;
  final String jsonData;
  final DateTime cachedAt;
  const FcCachedEvidence({
    required this.id,
    required this.reportId,
    required this.jsonData,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['report_id'] = Variable<String>(reportId);
    map['json_data'] = Variable<String>(jsonData);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  FcCachedEvidencesCompanion toCompanion(bool nullToAbsent) {
    return FcCachedEvidencesCompanion(
      id: Value(id),
      reportId: Value(reportId),
      jsonData: Value(jsonData),
      cachedAt: Value(cachedAt),
    );
  }

  factory FcCachedEvidence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FcCachedEvidence(
      id: serializer.fromJson<String>(json['id']),
      reportId: serializer.fromJson<String>(json['reportId']),
      jsonData: serializer.fromJson<String>(json['jsonData']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'reportId': serializer.toJson<String>(reportId),
      'jsonData': serializer.toJson<String>(jsonData),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  FcCachedEvidence copyWith({
    String? id,
    String? reportId,
    String? jsonData,
    DateTime? cachedAt,
  }) => FcCachedEvidence(
    id: id ?? this.id,
    reportId: reportId ?? this.reportId,
    jsonData: jsonData ?? this.jsonData,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  FcCachedEvidence copyWithCompanion(FcCachedEvidencesCompanion data) {
    return FcCachedEvidence(
      id: data.id.present ? data.id.value : this.id,
      reportId: data.reportId.present ? data.reportId.value : this.reportId,
      jsonData: data.jsonData.present ? data.jsonData.value : this.jsonData,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FcCachedEvidence(')
          ..write('id: $id, ')
          ..write('reportId: $reportId, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, reportId, jsonData, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FcCachedEvidence &&
          other.id == this.id &&
          other.reportId == this.reportId &&
          other.jsonData == this.jsonData &&
          other.cachedAt == this.cachedAt);
}

class FcCachedEvidencesCompanion extends UpdateCompanion<FcCachedEvidence> {
  final Value<String> id;
  final Value<String> reportId;
  final Value<String> jsonData;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const FcCachedEvidencesCompanion({
    this.id = const Value.absent(),
    this.reportId = const Value.absent(),
    this.jsonData = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FcCachedEvidencesCompanion.insert({
    required String id,
    required String reportId,
    required String jsonData,
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       reportId = Value(reportId),
       jsonData = Value(jsonData);
  static Insertable<FcCachedEvidence> custom({
    Expression<String>? id,
    Expression<String>? reportId,
    Expression<String>? jsonData,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reportId != null) 'report_id': reportId,
      if (jsonData != null) 'json_data': jsonData,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FcCachedEvidencesCompanion copyWith({
    Value<String>? id,
    Value<String>? reportId,
    Value<String>? jsonData,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return FcCachedEvidencesCompanion(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      jsonData: jsonData ?? this.jsonData,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (reportId.present) {
      map['report_id'] = Variable<String>(reportId.value);
    }
    if (jsonData.present) {
      map['json_data'] = Variable<String>(jsonData.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FcCachedEvidencesCompanion(')
          ..write('id: $id, ')
          ..write('reportId: $reportId, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FcCachedNotesTable extends FcCachedNotes
    with TableInfo<$FcCachedNotesTable, FcCachedNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FcCachedNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reportIdMeta = const VerificationMeta(
    'reportId',
  );
  @override
  late final GeneratedColumn<String> reportId = GeneratedColumn<String>(
    'report_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonDataMeta = const VerificationMeta(
    'jsonData',
  );
  @override
  late final GeneratedColumn<String> jsonData = GeneratedColumn<String>(
    'json_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, reportId, jsonData, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fc_cached_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<FcCachedNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('report_id')) {
      context.handle(
        _reportIdMeta,
        reportId.isAcceptableOrUnknown(data['report_id']!, _reportIdMeta),
      );
    } else if (isInserting) {
      context.missing(_reportIdMeta);
    }
    if (data.containsKey('json_data')) {
      context.handle(
        _jsonDataMeta,
        jsonData.isAcceptableOrUnknown(data['json_data']!, _jsonDataMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonDataMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FcCachedNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FcCachedNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      reportId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}report_id'],
      )!,
      jsonData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_data'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $FcCachedNotesTable createAlias(String alias) {
    return $FcCachedNotesTable(attachedDatabase, alias);
  }
}

class FcCachedNote extends DataClass implements Insertable<FcCachedNote> {
  final String id;
  final String reportId;
  final String jsonData;
  final DateTime cachedAt;
  const FcCachedNote({
    required this.id,
    required this.reportId,
    required this.jsonData,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['report_id'] = Variable<String>(reportId);
    map['json_data'] = Variable<String>(jsonData);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  FcCachedNotesCompanion toCompanion(bool nullToAbsent) {
    return FcCachedNotesCompanion(
      id: Value(id),
      reportId: Value(reportId),
      jsonData: Value(jsonData),
      cachedAt: Value(cachedAt),
    );
  }

  factory FcCachedNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FcCachedNote(
      id: serializer.fromJson<String>(json['id']),
      reportId: serializer.fromJson<String>(json['reportId']),
      jsonData: serializer.fromJson<String>(json['jsonData']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'reportId': serializer.toJson<String>(reportId),
      'jsonData': serializer.toJson<String>(jsonData),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  FcCachedNote copyWith({
    String? id,
    String? reportId,
    String? jsonData,
    DateTime? cachedAt,
  }) => FcCachedNote(
    id: id ?? this.id,
    reportId: reportId ?? this.reportId,
    jsonData: jsonData ?? this.jsonData,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  FcCachedNote copyWithCompanion(FcCachedNotesCompanion data) {
    return FcCachedNote(
      id: data.id.present ? data.id.value : this.id,
      reportId: data.reportId.present ? data.reportId.value : this.reportId,
      jsonData: data.jsonData.present ? data.jsonData.value : this.jsonData,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FcCachedNote(')
          ..write('id: $id, ')
          ..write('reportId: $reportId, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, reportId, jsonData, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FcCachedNote &&
          other.id == this.id &&
          other.reportId == this.reportId &&
          other.jsonData == this.jsonData &&
          other.cachedAt == this.cachedAt);
}

class FcCachedNotesCompanion extends UpdateCompanion<FcCachedNote> {
  final Value<String> id;
  final Value<String> reportId;
  final Value<String> jsonData;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const FcCachedNotesCompanion({
    this.id = const Value.absent(),
    this.reportId = const Value.absent(),
    this.jsonData = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FcCachedNotesCompanion.insert({
    required String id,
    required String reportId,
    required String jsonData,
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       reportId = Value(reportId),
       jsonData = Value(jsonData);
  static Insertable<FcCachedNote> custom({
    Expression<String>? id,
    Expression<String>? reportId,
    Expression<String>? jsonData,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reportId != null) 'report_id': reportId,
      if (jsonData != null) 'json_data': jsonData,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FcCachedNotesCompanion copyWith({
    Value<String>? id,
    Value<String>? reportId,
    Value<String>? jsonData,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return FcCachedNotesCompanion(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      jsonData: jsonData ?? this.jsonData,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (reportId.present) {
      map['report_id'] = Variable<String>(reportId.value);
    }
    if (jsonData.present) {
      map['json_data'] = Variable<String>(jsonData.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FcCachedNotesCompanion(')
          ..write('id: $id, ')
          ..write('reportId: $reportId, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FcCachedPhotoMetadataTable extends FcCachedPhotoMetadata
    with TableInfo<$FcCachedPhotoMetadataTable, FcCachedPhotoMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FcCachedPhotoMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoTypeMeta = const VerificationMeta(
    'photoType',
  );
  @override
  late final GeneratedColumn<String> photoType = GeneratedColumn<String>(
    'photo_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storagePathMeta = const VerificationMeta(
    'storagePath',
  );
  @override
  late final GeneratedColumn<String> storagePath = GeneratedColumn<String>(
    'storage_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityId,
    entityType,
    photoType,
    photoUrl,
    storagePath,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fc_cached_photo_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<FcCachedPhotoMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('photo_type')) {
      context.handle(
        _photoTypeMeta,
        photoType.isAcceptableOrUnknown(data['photo_type']!, _photoTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_photoTypeMeta);
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('storage_path')) {
      context.handle(
        _storagePathMeta,
        storagePath.isAcceptableOrUnknown(
          data['storage_path']!,
          _storagePathMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FcCachedPhotoMetadataData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FcCachedPhotoMetadataData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      photoType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_type'],
      )!,
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      storagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_path'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $FcCachedPhotoMetadataTable createAlias(String alias) {
    return $FcCachedPhotoMetadataTable(attachedDatabase, alias);
  }
}

class FcCachedPhotoMetadataData extends DataClass
    implements Insertable<FcCachedPhotoMetadataData> {
  final String id;
  final String entityId;
  final String entityType;
  final String photoType;
  final String? photoUrl;
  final String? storagePath;
  final DateTime cachedAt;
  const FcCachedPhotoMetadataData({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.photoType,
    this.photoUrl,
    this.storagePath,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_id'] = Variable<String>(entityId);
    map['entity_type'] = Variable<String>(entityType);
    map['photo_type'] = Variable<String>(photoType);
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    if (!nullToAbsent || storagePath != null) {
      map['storage_path'] = Variable<String>(storagePath);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  FcCachedPhotoMetadataCompanion toCompanion(bool nullToAbsent) {
    return FcCachedPhotoMetadataCompanion(
      id: Value(id),
      entityId: Value(entityId),
      entityType: Value(entityType),
      photoType: Value(photoType),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      storagePath: storagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(storagePath),
      cachedAt: Value(cachedAt),
    );
  }

  factory FcCachedPhotoMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FcCachedPhotoMetadataData(
      id: serializer.fromJson<String>(json['id']),
      entityId: serializer.fromJson<String>(json['entityId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      photoType: serializer.fromJson<String>(json['photoType']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      storagePath: serializer.fromJson<String?>(json['storagePath']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityId': serializer.toJson<String>(entityId),
      'entityType': serializer.toJson<String>(entityType),
      'photoType': serializer.toJson<String>(photoType),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'storagePath': serializer.toJson<String?>(storagePath),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  FcCachedPhotoMetadataData copyWith({
    String? id,
    String? entityId,
    String? entityType,
    String? photoType,
    Value<String?> photoUrl = const Value.absent(),
    Value<String?> storagePath = const Value.absent(),
    DateTime? cachedAt,
  }) => FcCachedPhotoMetadataData(
    id: id ?? this.id,
    entityId: entityId ?? this.entityId,
    entityType: entityType ?? this.entityType,
    photoType: photoType ?? this.photoType,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    storagePath: storagePath.present ? storagePath.value : this.storagePath,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  FcCachedPhotoMetadataData copyWithCompanion(
    FcCachedPhotoMetadataCompanion data,
  ) {
    return FcCachedPhotoMetadataData(
      id: data.id.present ? data.id.value : this.id,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      photoType: data.photoType.present ? data.photoType.value : this.photoType,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      storagePath: data.storagePath.present
          ? data.storagePath.value
          : this.storagePath,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FcCachedPhotoMetadataData(')
          ..write('id: $id, ')
          ..write('entityId: $entityId, ')
          ..write('entityType: $entityType, ')
          ..write('photoType: $photoType, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('storagePath: $storagePath, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityId,
    entityType,
    photoType,
    photoUrl,
    storagePath,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FcCachedPhotoMetadataData &&
          other.id == this.id &&
          other.entityId == this.entityId &&
          other.entityType == this.entityType &&
          other.photoType == this.photoType &&
          other.photoUrl == this.photoUrl &&
          other.storagePath == this.storagePath &&
          other.cachedAt == this.cachedAt);
}

class FcCachedPhotoMetadataCompanion
    extends UpdateCompanion<FcCachedPhotoMetadataData> {
  final Value<String> id;
  final Value<String> entityId;
  final Value<String> entityType;
  final Value<String> photoType;
  final Value<String?> photoUrl;
  final Value<String?> storagePath;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const FcCachedPhotoMetadataCompanion({
    this.id = const Value.absent(),
    this.entityId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.photoType = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.storagePath = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FcCachedPhotoMetadataCompanion.insert({
    required String id,
    required String entityId,
    required String entityType,
    required String photoType,
    this.photoUrl = const Value.absent(),
    this.storagePath = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityId = Value(entityId),
       entityType = Value(entityType),
       photoType = Value(photoType);
  static Insertable<FcCachedPhotoMetadataData> custom({
    Expression<String>? id,
    Expression<String>? entityId,
    Expression<String>? entityType,
    Expression<String>? photoType,
    Expression<String>? photoUrl,
    Expression<String>? storagePath,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityId != null) 'entity_id': entityId,
      if (entityType != null) 'entity_type': entityType,
      if (photoType != null) 'photo_type': photoType,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (storagePath != null) 'storage_path': storagePath,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FcCachedPhotoMetadataCompanion copyWith({
    Value<String>? id,
    Value<String>? entityId,
    Value<String>? entityType,
    Value<String>? photoType,
    Value<String?>? photoUrl,
    Value<String?>? storagePath,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return FcCachedPhotoMetadataCompanion(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      photoType: photoType ?? this.photoType,
      photoUrl: photoUrl ?? this.photoUrl,
      storagePath: storagePath ?? this.storagePath,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (photoType.present) {
      map['photo_type'] = Variable<String>(photoType.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (storagePath.present) {
      map['storage_path'] = Variable<String>(storagePath.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FcCachedPhotoMetadataCompanion(')
          ..write('id: $id, ')
          ..write('entityId: $entityId, ')
          ..write('entityType: $entityType, ')
          ..write('photoType: $photoType, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('storagePath: $storagePath, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FcSyncCursorsTable extends FcSyncCursors
    with TableInfo<$FcSyncCursorsTable, FcSyncCursor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FcSyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _collectionKeyMeta = const VerificationMeta(
    'collectionKey',
  );
  @override
  late final GeneratedColumn<String> collectionKey = GeneratedColumn<String>(
    'collection_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extraJsonMeta = const VerificationMeta(
    'extraJson',
  );
  @override
  late final GeneratedColumn<String> extraJson = GeneratedColumn<String>(
    'extra_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [collectionKey, lastSyncAt, extraJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fc_sync_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<FcSyncCursor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('collection_key')) {
      context.handle(
        _collectionKeyMeta,
        collectionKey.isAcceptableOrUnknown(
          data['collection_key']!,
          _collectionKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionKeyMeta);
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSyncAtMeta);
    }
    if (data.containsKey('extra_json')) {
      context.handle(
        _extraJsonMeta,
        extraJson.isAcceptableOrUnknown(data['extra_json']!, _extraJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {collectionKey};
  @override
  FcSyncCursor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FcSyncCursor(
      collectionKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_key'],
      )!,
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      )!,
      extraJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra_json'],
      ),
    );
  }

  @override
  $FcSyncCursorsTable createAlias(String alias) {
    return $FcSyncCursorsTable(attachedDatabase, alias);
  }
}

class FcSyncCursor extends DataClass implements Insertable<FcSyncCursor> {
  final String collectionKey;
  final DateTime lastSyncAt;
  final String? extraJson;
  const FcSyncCursor({
    required this.collectionKey,
    required this.lastSyncAt,
    this.extraJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['collection_key'] = Variable<String>(collectionKey);
    map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    if (!nullToAbsent || extraJson != null) {
      map['extra_json'] = Variable<String>(extraJson);
    }
    return map;
  }

  FcSyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return FcSyncCursorsCompanion(
      collectionKey: Value(collectionKey),
      lastSyncAt: Value(lastSyncAt),
      extraJson: extraJson == null && nullToAbsent
          ? const Value.absent()
          : Value(extraJson),
    );
  }

  factory FcSyncCursor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FcSyncCursor(
      collectionKey: serializer.fromJson<String>(json['collectionKey']),
      lastSyncAt: serializer.fromJson<DateTime>(json['lastSyncAt']),
      extraJson: serializer.fromJson<String?>(json['extraJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'collectionKey': serializer.toJson<String>(collectionKey),
      'lastSyncAt': serializer.toJson<DateTime>(lastSyncAt),
      'extraJson': serializer.toJson<String?>(extraJson),
    };
  }

  FcSyncCursor copyWith({
    String? collectionKey,
    DateTime? lastSyncAt,
    Value<String?> extraJson = const Value.absent(),
  }) => FcSyncCursor(
    collectionKey: collectionKey ?? this.collectionKey,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    extraJson: extraJson.present ? extraJson.value : this.extraJson,
  );
  FcSyncCursor copyWithCompanion(FcSyncCursorsCompanion data) {
    return FcSyncCursor(
      collectionKey: data.collectionKey.present
          ? data.collectionKey.value
          : this.collectionKey,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      extraJson: data.extraJson.present ? data.extraJson.value : this.extraJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FcSyncCursor(')
          ..write('collectionKey: $collectionKey, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('extraJson: $extraJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(collectionKey, lastSyncAt, extraJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FcSyncCursor &&
          other.collectionKey == this.collectionKey &&
          other.lastSyncAt == this.lastSyncAt &&
          other.extraJson == this.extraJson);
}

class FcSyncCursorsCompanion extends UpdateCompanion<FcSyncCursor> {
  final Value<String> collectionKey;
  final Value<DateTime> lastSyncAt;
  final Value<String?> extraJson;
  final Value<int> rowid;
  const FcSyncCursorsCompanion({
    this.collectionKey = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.extraJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FcSyncCursorsCompanion.insert({
    required String collectionKey,
    required DateTime lastSyncAt,
    this.extraJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : collectionKey = Value(collectionKey),
       lastSyncAt = Value(lastSyncAt);
  static Insertable<FcSyncCursor> custom({
    Expression<String>? collectionKey,
    Expression<DateTime>? lastSyncAt,
    Expression<String>? extraJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (collectionKey != null) 'collection_key': collectionKey,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (extraJson != null) 'extra_json': extraJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FcSyncCursorsCompanion copyWith({
    Value<String>? collectionKey,
    Value<DateTime>? lastSyncAt,
    Value<String?>? extraJson,
    Value<int>? rowid,
  }) {
    return FcSyncCursorsCompanion(
      collectionKey: collectionKey ?? this.collectionKey,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      extraJson: extraJson ?? this.extraJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (collectionKey.present) {
      map['collection_key'] = Variable<String>(collectionKey.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (extraJson.present) {
      map['extra_json'] = Variable<String>(extraJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FcSyncCursorsCompanion(')
          ..write('collectionKey: $collectionKey, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('extraJson: $extraJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FcOutboxItemsTable extends FcOutboxItems
    with TableInfo<$FcOutboxItemsTable, FcOutboxItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FcOutboxItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseVersionMeta = const VerificationMeta(
    'baseVersion',
  );
  @override
  late final GeneratedColumn<String> baseVersion = GeneratedColumn<String>(
    'base_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    operationId,
    operationType,
    entityId,
    entityType,
    payloadJson,
    baseVersion,
    status,
    retryCount,
    lastError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fc_outbox_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<FcOutboxItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('base_version')) {
      context.handle(
        _baseVersionMeta,
        baseVersion.isAcceptableOrUnknown(
          data['base_version']!,
          _baseVersionMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  FcOutboxItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FcOutboxItem(
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      baseVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_version'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FcOutboxItemsTable createAlias(String alias) {
    return $FcOutboxItemsTable(attachedDatabase, alias);
  }
}

class FcOutboxItem extends DataClass implements Insertable<FcOutboxItem> {
  final String operationId;
  final String operationType;
  final String entityId;
  final String entityType;
  final String payloadJson;
  final String? baseVersion;
  final String status;
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FcOutboxItem({
    required this.operationId,
    required this.operationType,
    required this.entityId,
    required this.entityType,
    required this.payloadJson,
    this.baseVersion,
    required this.status,
    required this.retryCount,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['operation_type'] = Variable<String>(operationType);
    map['entity_id'] = Variable<String>(entityId);
    map['entity_type'] = Variable<String>(entityType);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || baseVersion != null) {
      map['base_version'] = Variable<String>(baseVersion);
    }
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FcOutboxItemsCompanion toCompanion(bool nullToAbsent) {
    return FcOutboxItemsCompanion(
      operationId: Value(operationId),
      operationType: Value(operationType),
      entityId: Value(entityId),
      entityType: Value(entityType),
      payloadJson: Value(payloadJson),
      baseVersion: baseVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseVersion),
      status: Value(status),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FcOutboxItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FcOutboxItem(
      operationId: serializer.fromJson<String>(json['operationId']),
      operationType: serializer.fromJson<String>(json['operationType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      baseVersion: serializer.fromJson<String?>(json['baseVersion']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'operationType': serializer.toJson<String>(operationType),
      'entityId': serializer.toJson<String>(entityId),
      'entityType': serializer.toJson<String>(entityType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'baseVersion': serializer.toJson<String?>(baseVersion),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FcOutboxItem copyWith({
    String? operationId,
    String? operationType,
    String? entityId,
    String? entityType,
    String? payloadJson,
    Value<String?> baseVersion = const Value.absent(),
    String? status,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FcOutboxItem(
    operationId: operationId ?? this.operationId,
    operationType: operationType ?? this.operationType,
    entityId: entityId ?? this.entityId,
    entityType: entityType ?? this.entityType,
    payloadJson: payloadJson ?? this.payloadJson,
    baseVersion: baseVersion.present ? baseVersion.value : this.baseVersion,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FcOutboxItem copyWithCompanion(FcOutboxItemsCompanion data) {
    return FcOutboxItem(
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      baseVersion: data.baseVersion.present
          ? data.baseVersion.value
          : this.baseVersion,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FcOutboxItem(')
          ..write('operationId: $operationId, ')
          ..write('operationType: $operationType, ')
          ..write('entityId: $entityId, ')
          ..write('entityType: $entityType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    operationId,
    operationType,
    entityId,
    entityType,
    payloadJson,
    baseVersion,
    status,
    retryCount,
    lastError,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FcOutboxItem &&
          other.operationId == this.operationId &&
          other.operationType == this.operationType &&
          other.entityId == this.entityId &&
          other.entityType == this.entityType &&
          other.payloadJson == this.payloadJson &&
          other.baseVersion == this.baseVersion &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FcOutboxItemsCompanion extends UpdateCompanion<FcOutboxItem> {
  final Value<String> operationId;
  final Value<String> operationType;
  final Value<String> entityId;
  final Value<String> entityType;
  final Value<String> payloadJson;
  final Value<String?> baseVersion;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FcOutboxItemsCompanion({
    this.operationId = const Value.absent(),
    this.operationType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.baseVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FcOutboxItemsCompanion.insert({
    required String operationId,
    required String operationType,
    required String entityId,
    required String entityType,
    required String payloadJson,
    this.baseVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : operationId = Value(operationId),
       operationType = Value(operationType),
       entityId = Value(entityId),
       entityType = Value(entityType),
       payloadJson = Value(payloadJson);
  static Insertable<FcOutboxItem> custom({
    Expression<String>? operationId,
    Expression<String>? operationType,
    Expression<String>? entityId,
    Expression<String>? entityType,
    Expression<String>? payloadJson,
    Expression<String>? baseVersion,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (operationType != null) 'operation_type': operationType,
      if (entityId != null) 'entity_id': entityId,
      if (entityType != null) 'entity_type': entityType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (baseVersion != null) 'base_version': baseVersion,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FcOutboxItemsCompanion copyWith({
    Value<String>? operationId,
    Value<String>? operationType,
    Value<String>? entityId,
    Value<String>? entityType,
    Value<String>? payloadJson,
    Value<String?>? baseVersion,
    Value<String>? status,
    Value<int>? retryCount,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FcOutboxItemsCompanion(
      operationId: operationId ?? this.operationId,
      operationType: operationType ?? this.operationType,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      payloadJson: payloadJson ?? this.payloadJson,
      baseVersion: baseVersion ?? this.baseVersion,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (baseVersion.present) {
      map['base_version'] = Variable<String>(baseVersion.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FcOutboxItemsCompanion(')
          ..write('operationId: $operationId, ')
          ..write('operationType: $operationType, ')
          ..write('entityId: $entityId, ')
          ..write('entityType: $entityType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FcLocalPhotosTable extends FcLocalPhotos
    with TableInfo<$FcLocalPhotosTable, FcLocalPhoto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FcLocalPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localPhotoIdMeta = const VerificationMeta(
    'localPhotoId',
  );
  @override
  late final GeneratedColumn<String> localPhotoId = GeneratedColumn<String>(
    'local_photo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoTypeMeta = const VerificationMeta(
    'photoType',
  );
  @override
  late final GeneratedColumn<String> photoType = GeneratedColumn<String>(
    'photo_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileHashMeta = const VerificationMeta(
    'fileHash',
  );
  @override
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
    'file_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteUrlMeta = const VerificationMeta(
    'remoteUrl',
  );
  @override
  late final GeneratedColumn<String> remoteUrl = GeneratedColumn<String>(
    'remote_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localPhotoId,
    entityId,
    entityType,
    photoType,
    localPath,
    fileHash,
    fileSize,
    syncStatus,
    remoteId,
    remoteUrl,
    lastError,
    retryCount,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fc_local_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<FcLocalPhoto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_photo_id')) {
      context.handle(
        _localPhotoIdMeta,
        localPhotoId.isAcceptableOrUnknown(
          data['local_photo_id']!,
          _localPhotoIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localPhotoIdMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('photo_type')) {
      context.handle(
        _photoTypeMeta,
        photoType.isAcceptableOrUnknown(data['photo_type']!, _photoTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_photoTypeMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('file_hash')) {
      context.handle(
        _fileHashMeta,
        fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('remote_url')) {
      context.handle(
        _remoteUrlMeta,
        remoteUrl.isAcceptableOrUnknown(data['remote_url']!, _remoteUrlMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localPhotoId};
  @override
  FcLocalPhoto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FcLocalPhoto(
      localPhotoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_photo_id'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      photoType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_type'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      fileHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_hash'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      remoteUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_url'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FcLocalPhotosTable createAlias(String alias) {
    return $FcLocalPhotosTable(attachedDatabase, alias);
  }
}

class FcLocalPhoto extends DataClass implements Insertable<FcLocalPhoto> {
  final String localPhotoId;
  final String entityId;
  final String entityType;
  final String photoType;
  final String localPath;
  final String? fileHash;
  final int fileSize;
  final int syncStatus;
  final String? remoteId;
  final String? remoteUrl;
  final String? lastError;
  final int retryCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FcLocalPhoto({
    required this.localPhotoId,
    required this.entityId,
    required this.entityType,
    required this.photoType,
    required this.localPath,
    this.fileHash,
    required this.fileSize,
    required this.syncStatus,
    this.remoteId,
    this.remoteUrl,
    this.lastError,
    required this.retryCount,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_photo_id'] = Variable<String>(localPhotoId);
    map['entity_id'] = Variable<String>(entityId);
    map['entity_type'] = Variable<String>(entityType);
    map['photo_type'] = Variable<String>(photoType);
    map['local_path'] = Variable<String>(localPath);
    if (!nullToAbsent || fileHash != null) {
      map['file_hash'] = Variable<String>(fileHash);
    }
    map['file_size'] = Variable<int>(fileSize);
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    if (!nullToAbsent || remoteUrl != null) {
      map['remote_url'] = Variable<String>(remoteUrl);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FcLocalPhotosCompanion toCompanion(bool nullToAbsent) {
    return FcLocalPhotosCompanion(
      localPhotoId: Value(localPhotoId),
      entityId: Value(entityId),
      entityType: Value(entityType),
      photoType: Value(photoType),
      localPath: Value(localPath),
      fileHash: fileHash == null && nullToAbsent
          ? const Value.absent()
          : Value(fileHash),
      fileSize: Value(fileSize),
      syncStatus: Value(syncStatus),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      remoteUrl: remoteUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUrl),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FcLocalPhoto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FcLocalPhoto(
      localPhotoId: serializer.fromJson<String>(json['localPhotoId']),
      entityId: serializer.fromJson<String>(json['entityId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      photoType: serializer.fromJson<String>(json['photoType']),
      localPath: serializer.fromJson<String>(json['localPath']),
      fileHash: serializer.fromJson<String?>(json['fileHash']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      remoteUrl: serializer.fromJson<String?>(json['remoteUrl']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localPhotoId': serializer.toJson<String>(localPhotoId),
      'entityId': serializer.toJson<String>(entityId),
      'entityType': serializer.toJson<String>(entityType),
      'photoType': serializer.toJson<String>(photoType),
      'localPath': serializer.toJson<String>(localPath),
      'fileHash': serializer.toJson<String?>(fileHash),
      'fileSize': serializer.toJson<int>(fileSize),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'remoteId': serializer.toJson<String?>(remoteId),
      'remoteUrl': serializer.toJson<String?>(remoteUrl),
      'lastError': serializer.toJson<String?>(lastError),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FcLocalPhoto copyWith({
    String? localPhotoId,
    String? entityId,
    String? entityType,
    String? photoType,
    String? localPath,
    Value<String?> fileHash = const Value.absent(),
    int? fileSize,
    int? syncStatus,
    Value<String?> remoteId = const Value.absent(),
    Value<String?> remoteUrl = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    int? retryCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FcLocalPhoto(
    localPhotoId: localPhotoId ?? this.localPhotoId,
    entityId: entityId ?? this.entityId,
    entityType: entityType ?? this.entityType,
    photoType: photoType ?? this.photoType,
    localPath: localPath ?? this.localPath,
    fileHash: fileHash.present ? fileHash.value : this.fileHash,
    fileSize: fileSize ?? this.fileSize,
    syncStatus: syncStatus ?? this.syncStatus,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    remoteUrl: remoteUrl.present ? remoteUrl.value : this.remoteUrl,
    lastError: lastError.present ? lastError.value : this.lastError,
    retryCount: retryCount ?? this.retryCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FcLocalPhoto copyWithCompanion(FcLocalPhotosCompanion data) {
    return FcLocalPhoto(
      localPhotoId: data.localPhotoId.present
          ? data.localPhotoId.value
          : this.localPhotoId,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      photoType: data.photoType.present ? data.photoType.value : this.photoType,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      remoteUrl: data.remoteUrl.present ? data.remoteUrl.value : this.remoteUrl,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FcLocalPhoto(')
          ..write('localPhotoId: $localPhotoId, ')
          ..write('entityId: $entityId, ')
          ..write('entityType: $entityType, ')
          ..write('photoType: $photoType, ')
          ..write('localPath: $localPath, ')
          ..write('fileHash: $fileHash, ')
          ..write('fileSize: $fileSize, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('remoteUrl: $remoteUrl, ')
          ..write('lastError: $lastError, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localPhotoId,
    entityId,
    entityType,
    photoType,
    localPath,
    fileHash,
    fileSize,
    syncStatus,
    remoteId,
    remoteUrl,
    lastError,
    retryCount,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FcLocalPhoto &&
          other.localPhotoId == this.localPhotoId &&
          other.entityId == this.entityId &&
          other.entityType == this.entityType &&
          other.photoType == this.photoType &&
          other.localPath == this.localPath &&
          other.fileHash == this.fileHash &&
          other.fileSize == this.fileSize &&
          other.syncStatus == this.syncStatus &&
          other.remoteId == this.remoteId &&
          other.remoteUrl == this.remoteUrl &&
          other.lastError == this.lastError &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FcLocalPhotosCompanion extends UpdateCompanion<FcLocalPhoto> {
  final Value<String> localPhotoId;
  final Value<String> entityId;
  final Value<String> entityType;
  final Value<String> photoType;
  final Value<String> localPath;
  final Value<String?> fileHash;
  final Value<int> fileSize;
  final Value<int> syncStatus;
  final Value<String?> remoteId;
  final Value<String?> remoteUrl;
  final Value<String?> lastError;
  final Value<int> retryCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FcLocalPhotosCompanion({
    this.localPhotoId = const Value.absent(),
    this.entityId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.photoType = const Value.absent(),
    this.localPath = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.remoteUrl = const Value.absent(),
    this.lastError = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FcLocalPhotosCompanion.insert({
    required String localPhotoId,
    required String entityId,
    required String entityType,
    required String photoType,
    required String localPath,
    this.fileHash = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.remoteUrl = const Value.absent(),
    this.lastError = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localPhotoId = Value(localPhotoId),
       entityId = Value(entityId),
       entityType = Value(entityType),
       photoType = Value(photoType),
       localPath = Value(localPath);
  static Insertable<FcLocalPhoto> custom({
    Expression<String>? localPhotoId,
    Expression<String>? entityId,
    Expression<String>? entityType,
    Expression<String>? photoType,
    Expression<String>? localPath,
    Expression<String>? fileHash,
    Expression<int>? fileSize,
    Expression<int>? syncStatus,
    Expression<String>? remoteId,
    Expression<String>? remoteUrl,
    Expression<String>? lastError,
    Expression<int>? retryCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localPhotoId != null) 'local_photo_id': localPhotoId,
      if (entityId != null) 'entity_id': entityId,
      if (entityType != null) 'entity_type': entityType,
      if (photoType != null) 'photo_type': photoType,
      if (localPath != null) 'local_path': localPath,
      if (fileHash != null) 'file_hash': fileHash,
      if (fileSize != null) 'file_size': fileSize,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (remoteId != null) 'remote_id': remoteId,
      if (remoteUrl != null) 'remote_url': remoteUrl,
      if (lastError != null) 'last_error': lastError,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FcLocalPhotosCompanion copyWith({
    Value<String>? localPhotoId,
    Value<String>? entityId,
    Value<String>? entityType,
    Value<String>? photoType,
    Value<String>? localPath,
    Value<String?>? fileHash,
    Value<int>? fileSize,
    Value<int>? syncStatus,
    Value<String?>? remoteId,
    Value<String?>? remoteUrl,
    Value<String?>? lastError,
    Value<int>? retryCount,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FcLocalPhotosCompanion(
      localPhotoId: localPhotoId ?? this.localPhotoId,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      photoType: photoType ?? this.photoType,
      localPath: localPath ?? this.localPath,
      fileHash: fileHash ?? this.fileHash,
      fileSize: fileSize ?? this.fileSize,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      lastError: lastError ?? this.lastError,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localPhotoId.present) {
      map['local_photo_id'] = Variable<String>(localPhotoId.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (photoType.present) {
      map['photo_type'] = Variable<String>(photoType.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (remoteUrl.present) {
      map['remote_url'] = Variable<String>(remoteUrl.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FcLocalPhotosCompanion(')
          ..write('localPhotoId: $localPhotoId, ')
          ..write('entityId: $entityId, ')
          ..write('entityType: $entityType, ')
          ..write('photoType: $photoType, ')
          ..write('localPath: $localPath, ')
          ..write('fileHash: $fileHash, ')
          ..write('fileSize: $fileSize, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('remoteUrl: $remoteUrl, ')
          ..write('lastError: $lastError, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OfflineReportsTable offlineReports = $OfflineReportsTable(this);
  late final $OfflineTaskUpdatesTable offlineTaskUpdates =
      $OfflineTaskUpdatesTable(this);
  late final $OfflineMediaTable offlineMedia = $OfflineMediaTable(this);
  late final $FcCachedReportsTable fcCachedReports = $FcCachedReportsTable(
    this,
  );
  late final $FcCachedTasksTable fcCachedTasks = $FcCachedTasksTable(this);
  late final $FcCachedEvidencesTable fcCachedEvidences =
      $FcCachedEvidencesTable(this);
  late final $FcCachedNotesTable fcCachedNotes = $FcCachedNotesTable(this);
  late final $FcCachedPhotoMetadataTable fcCachedPhotoMetadata =
      $FcCachedPhotoMetadataTable(this);
  late final $FcSyncCursorsTable fcSyncCursors = $FcSyncCursorsTable(this);
  late final $FcOutboxItemsTable fcOutboxItems = $FcOutboxItemsTable(this);
  late final $FcLocalPhotosTable fcLocalPhotos = $FcLocalPhotosTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    offlineReports,
    offlineTaskUpdates,
    offlineMedia,
    fcCachedReports,
    fcCachedTasks,
    fcCachedEvidences,
    fcCachedNotes,
    fcCachedPhotoMetadata,
    fcSyncCursors,
    fcOutboxItems,
    fcLocalPhotos,
  ];
}

typedef $$OfflineReportsTableCreateCompanionBuilder =
    OfflineReportsCompanion Function({
      Value<int> id,
      required String idempotencyKey,
      required String title,
      required String description,
      required double latitude,
      required double longitude,
      Value<bool> onPrivateProperty,
      Value<String?> scaleLevel,
      Value<String?> obstructionLevel,
      Value<String?> imagePaths,
      Value<String?> videoPath,
      Value<int> syncStatus,
      Value<String?> syncError,
      Value<DateTime> createdAt,
    });
typedef $$OfflineReportsTableUpdateCompanionBuilder =
    OfflineReportsCompanion Function({
      Value<int> id,
      Value<String> idempotencyKey,
      Value<String> title,
      Value<String> description,
      Value<double> latitude,
      Value<double> longitude,
      Value<bool> onPrivateProperty,
      Value<String?> scaleLevel,
      Value<String?> obstructionLevel,
      Value<String?> imagePaths,
      Value<String?> videoPath,
      Value<int> syncStatus,
      Value<String?> syncError,
      Value<DateTime> createdAt,
    });

class $$OfflineReportsTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineReportsTable> {
  $$OfflineReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onPrivateProperty => $composableBuilder(
    column: $table.onPrivateProperty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scaleLevel => $composableBuilder(
    column: $table.scaleLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get obstructionLevel => $composableBuilder(
    column: $table.obstructionLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoPath => $composableBuilder(
    column: $table.videoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineReportsTable> {
  $$OfflineReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onPrivateProperty => $composableBuilder(
    column: $table.onPrivateProperty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scaleLevel => $composableBuilder(
    column: $table.scaleLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get obstructionLevel => $composableBuilder(
    column: $table.obstructionLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoPath => $composableBuilder(
    column: $table.videoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineReportsTable> {
  $$OfflineReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<bool> get onPrivateProperty => $composableBuilder(
    column: $table.onPrivateProperty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scaleLevel => $composableBuilder(
    column: $table.scaleLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get obstructionLevel => $composableBuilder(
    column: $table.obstructionLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => column,
  );

  GeneratedColumn<String> get videoPath =>
      $composableBuilder(column: $table.videoPath, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OfflineReportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineReportsTable,
          OfflineReport,
          $$OfflineReportsTableFilterComposer,
          $$OfflineReportsTableOrderingComposer,
          $$OfflineReportsTableAnnotationComposer,
          $$OfflineReportsTableCreateCompanionBuilder,
          $$OfflineReportsTableUpdateCompanionBuilder,
          (
            OfflineReport,
            BaseReferences<_$AppDatabase, $OfflineReportsTable, OfflineReport>,
          ),
          OfflineReport,
          PrefetchHooks Function()
        > {
  $$OfflineReportsTableTableManager(
    _$AppDatabase db,
    $OfflineReportsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<bool> onPrivateProperty = const Value.absent(),
                Value<String?> scaleLevel = const Value.absent(),
                Value<String?> obstructionLevel = const Value.absent(),
                Value<String?> imagePaths = const Value.absent(),
                Value<String?> videoPath = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OfflineReportsCompanion(
                id: id,
                idempotencyKey: idempotencyKey,
                title: title,
                description: description,
                latitude: latitude,
                longitude: longitude,
                onPrivateProperty: onPrivateProperty,
                scaleLevel: scaleLevel,
                obstructionLevel: obstructionLevel,
                imagePaths: imagePaths,
                videoPath: videoPath,
                syncStatus: syncStatus,
                syncError: syncError,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String idempotencyKey,
                required String title,
                required String description,
                required double latitude,
                required double longitude,
                Value<bool> onPrivateProperty = const Value.absent(),
                Value<String?> scaleLevel = const Value.absent(),
                Value<String?> obstructionLevel = const Value.absent(),
                Value<String?> imagePaths = const Value.absent(),
                Value<String?> videoPath = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OfflineReportsCompanion.insert(
                id: id,
                idempotencyKey: idempotencyKey,
                title: title,
                description: description,
                latitude: latitude,
                longitude: longitude,
                onPrivateProperty: onPrivateProperty,
                scaleLevel: scaleLevel,
                obstructionLevel: obstructionLevel,
                imagePaths: imagePaths,
                videoPath: videoPath,
                syncStatus: syncStatus,
                syncError: syncError,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OfflineReportsTable, OfflineReport>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $OfflineReportsTable,
                    OfflineReport
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineReportsTable,
      OfflineReport,
      $$OfflineReportsTableFilterComposer,
      $$OfflineReportsTableOrderingComposer,
      $$OfflineReportsTableAnnotationComposer,
      $$OfflineReportsTableCreateCompanionBuilder,
      $$OfflineReportsTableUpdateCompanionBuilder,
      (
        OfflineReport,
        BaseReferences<_$AppDatabase, $OfflineReportsTable, OfflineReport>,
      ),
      OfflineReport,
      PrefetchHooks Function()
    >;
typedef $$OfflineTaskUpdatesTableCreateCompanionBuilder =
    OfflineTaskUpdatesCompanion Function({
      Value<int> id,
      required int taskId,
      required String payloadJson,
      required DateTime clientKnownUpdatedAt,
      Value<int> syncStatus,
      Value<String?> syncError,
      Value<DateTime> createdAt,
    });
typedef $$OfflineTaskUpdatesTableUpdateCompanionBuilder =
    OfflineTaskUpdatesCompanion Function({
      Value<int> id,
      Value<int> taskId,
      Value<String> payloadJson,
      Value<DateTime> clientKnownUpdatedAt,
      Value<int> syncStatus,
      Value<String?> syncError,
      Value<DateTime> createdAt,
    });

class $$OfflineTaskUpdatesTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineTaskUpdatesTable> {
  $$OfflineTaskUpdatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientKnownUpdatedAt => $composableBuilder(
    column: $table.clientKnownUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineTaskUpdatesTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineTaskUpdatesTable> {
  $$OfflineTaskUpdatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientKnownUpdatedAt => $composableBuilder(
    column: $table.clientKnownUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineTaskUpdatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineTaskUpdatesTable> {
  $$OfflineTaskUpdatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get clientKnownUpdatedAt => $composableBuilder(
    column: $table.clientKnownUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OfflineTaskUpdatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineTaskUpdatesTable,
          OfflineTaskUpdate,
          $$OfflineTaskUpdatesTableFilterComposer,
          $$OfflineTaskUpdatesTableOrderingComposer,
          $$OfflineTaskUpdatesTableAnnotationComposer,
          $$OfflineTaskUpdatesTableCreateCompanionBuilder,
          $$OfflineTaskUpdatesTableUpdateCompanionBuilder,
          (
            OfflineTaskUpdate,
            BaseReferences<
              _$AppDatabase,
              $OfflineTaskUpdatesTable,
              OfflineTaskUpdate
            >,
          ),
          OfflineTaskUpdate,
          PrefetchHooks Function()
        > {
  $$OfflineTaskUpdatesTableTableManager(
    _$AppDatabase db,
    $OfflineTaskUpdatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineTaskUpdatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineTaskUpdatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineTaskUpdatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> taskId = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> clientKnownUpdatedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OfflineTaskUpdatesCompanion(
                id: id,
                taskId: taskId,
                payloadJson: payloadJson,
                clientKnownUpdatedAt: clientKnownUpdatedAt,
                syncStatus: syncStatus,
                syncError: syncError,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int taskId,
                required String payloadJson,
                required DateTime clientKnownUpdatedAt,
                Value<int> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OfflineTaskUpdatesCompanion.insert(
                id: id,
                taskId: taskId,
                payloadJson: payloadJson,
                clientKnownUpdatedAt: clientKnownUpdatedAt,
                syncStatus: syncStatus,
                syncError: syncError,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OfflineTaskUpdatesTable, OfflineTaskUpdate>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $OfflineTaskUpdatesTable,
                    OfflineTaskUpdate
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineTaskUpdatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineTaskUpdatesTable,
      OfflineTaskUpdate,
      $$OfflineTaskUpdatesTableFilterComposer,
      $$OfflineTaskUpdatesTableOrderingComposer,
      $$OfflineTaskUpdatesTableAnnotationComposer,
      $$OfflineTaskUpdatesTableCreateCompanionBuilder,
      $$OfflineTaskUpdatesTableUpdateCompanionBuilder,
      (
        OfflineTaskUpdate,
        BaseReferences<
          _$AppDatabase,
          $OfflineTaskUpdatesTable,
          OfflineTaskUpdate
        >,
      ),
      OfflineTaskUpdate,
      PrefetchHooks Function()
    >;
typedef $$OfflineMediaTableCreateCompanionBuilder =
    OfflineMediaCompanion Function({
      Value<int> id,
      required String idempotencyKey,
      Value<String?> imagePaths,
      Value<String?> videoPath,
      Value<int> syncStatus,
      Value<String?> syncError,
      Value<DateTime> createdAt,
    });
typedef $$OfflineMediaTableUpdateCompanionBuilder =
    OfflineMediaCompanion Function({
      Value<int> id,
      Value<String> idempotencyKey,
      Value<String?> imagePaths,
      Value<String?> videoPath,
      Value<int> syncStatus,
      Value<String?> syncError,
      Value<DateTime> createdAt,
    });

class $$OfflineMediaTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineMediaTable> {
  $$OfflineMediaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoPath => $composableBuilder(
    column: $table.videoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineMediaTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineMediaTable> {
  $$OfflineMediaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoPath => $composableBuilder(
    column: $table.videoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineMediaTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineMediaTable> {
  $$OfflineMediaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => column,
  );

  GeneratedColumn<String> get videoPath =>
      $composableBuilder(column: $table.videoPath, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OfflineMediaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineMediaTable,
          OfflineMediaData,
          $$OfflineMediaTableFilterComposer,
          $$OfflineMediaTableOrderingComposer,
          $$OfflineMediaTableAnnotationComposer,
          $$OfflineMediaTableCreateCompanionBuilder,
          $$OfflineMediaTableUpdateCompanionBuilder,
          (
            OfflineMediaData,
            BaseReferences<_$AppDatabase, $OfflineMediaTable, OfflineMediaData>,
          ),
          OfflineMediaData,
          PrefetchHooks Function()
        > {
  $$OfflineMediaTableTableManager(_$AppDatabase db, $OfflineMediaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineMediaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineMediaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineMediaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String?> imagePaths = const Value.absent(),
                Value<String?> videoPath = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OfflineMediaCompanion(
                id: id,
                idempotencyKey: idempotencyKey,
                imagePaths: imagePaths,
                videoPath: videoPath,
                syncStatus: syncStatus,
                syncError: syncError,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String idempotencyKey,
                Value<String?> imagePaths = const Value.absent(),
                Value<String?> videoPath = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OfflineMediaCompanion.insert(
                id: id,
                idempotencyKey: idempotencyKey,
                imagePaths: imagePaths,
                videoPath: videoPath,
                syncStatus: syncStatus,
                syncError: syncError,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OfflineMediaTable, OfflineMediaData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $OfflineMediaTable,
                    OfflineMediaData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineMediaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineMediaTable,
      OfflineMediaData,
      $$OfflineMediaTableFilterComposer,
      $$OfflineMediaTableOrderingComposer,
      $$OfflineMediaTableAnnotationComposer,
      $$OfflineMediaTableCreateCompanionBuilder,
      $$OfflineMediaTableUpdateCompanionBuilder,
      (
        OfflineMediaData,
        BaseReferences<_$AppDatabase, $OfflineMediaTable, OfflineMediaData>,
      ),
      OfflineMediaData,
      PrefetchHooks Function()
    >;
typedef $$FcCachedReportsTableCreateCompanionBuilder =
    FcCachedReportsCompanion Function({
      required String id,
      required String jsonData,
      Value<int> localSyncState,
      required DateTime serverUpdatedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$FcCachedReportsTableUpdateCompanionBuilder =
    FcCachedReportsCompanion Function({
      Value<String> id,
      Value<String> jsonData,
      Value<int> localSyncState,
      Value<DateTime> serverUpdatedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$FcCachedReportsTableFilterComposer
    extends Composer<_$AppDatabase, $FcCachedReportsTable> {
  $$FcCachedReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localSyncState => $composableBuilder(
    column: $table.localSyncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FcCachedReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $FcCachedReportsTable> {
  $$FcCachedReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localSyncState => $composableBuilder(
    column: $table.localSyncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FcCachedReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FcCachedReportsTable> {
  $$FcCachedReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jsonData =>
      $composableBuilder(column: $table.jsonData, builder: (column) => column);

  GeneratedColumn<int> get localSyncState => $composableBuilder(
    column: $table.localSyncState,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$FcCachedReportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FcCachedReportsTable,
          FcCachedReport,
          $$FcCachedReportsTableFilterComposer,
          $$FcCachedReportsTableOrderingComposer,
          $$FcCachedReportsTableAnnotationComposer,
          $$FcCachedReportsTableCreateCompanionBuilder,
          $$FcCachedReportsTableUpdateCompanionBuilder,
          (
            FcCachedReport,
            BaseReferences<
              _$AppDatabase,
              $FcCachedReportsTable,
              FcCachedReport
            >,
          ),
          FcCachedReport,
          PrefetchHooks Function()
        > {
  $$FcCachedReportsTableTableManager(
    _$AppDatabase db,
    $FcCachedReportsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FcCachedReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FcCachedReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FcCachedReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> jsonData = const Value.absent(),
                Value<int> localSyncState = const Value.absent(),
                Value<DateTime> serverUpdatedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FcCachedReportsCompanion(
                id: id,
                jsonData: jsonData,
                localSyncState: localSyncState,
                serverUpdatedAt: serverUpdatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String jsonData,
                Value<int> localSyncState = const Value.absent(),
                required DateTime serverUpdatedAt,
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FcCachedReportsCompanion.insert(
                id: id,
                jsonData: jsonData,
                localSyncState: localSyncState,
                serverUpdatedAt: serverUpdatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FcCachedReportsTable, FcCachedReport>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FcCachedReportsTable,
                    FcCachedReport
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FcCachedReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FcCachedReportsTable,
      FcCachedReport,
      $$FcCachedReportsTableFilterComposer,
      $$FcCachedReportsTableOrderingComposer,
      $$FcCachedReportsTableAnnotationComposer,
      $$FcCachedReportsTableCreateCompanionBuilder,
      $$FcCachedReportsTableUpdateCompanionBuilder,
      (
        FcCachedReport,
        BaseReferences<_$AppDatabase, $FcCachedReportsTable, FcCachedReport>,
      ),
      FcCachedReport,
      PrefetchHooks Function()
    >;
typedef $$FcCachedTasksTableCreateCompanionBuilder =
    FcCachedTasksCompanion Function({
      required String id,
      required String jsonData,
      Value<int> localSyncState,
      required DateTime serverUpdatedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$FcCachedTasksTableUpdateCompanionBuilder =
    FcCachedTasksCompanion Function({
      Value<String> id,
      Value<String> jsonData,
      Value<int> localSyncState,
      Value<DateTime> serverUpdatedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$FcCachedTasksTableFilterComposer
    extends Composer<_$AppDatabase, $FcCachedTasksTable> {
  $$FcCachedTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localSyncState => $composableBuilder(
    column: $table.localSyncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FcCachedTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $FcCachedTasksTable> {
  $$FcCachedTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localSyncState => $composableBuilder(
    column: $table.localSyncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FcCachedTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $FcCachedTasksTable> {
  $$FcCachedTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jsonData =>
      $composableBuilder(column: $table.jsonData, builder: (column) => column);

  GeneratedColumn<int> get localSyncState => $composableBuilder(
    column: $table.localSyncState,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$FcCachedTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FcCachedTasksTable,
          FcCachedTask,
          $$FcCachedTasksTableFilterComposer,
          $$FcCachedTasksTableOrderingComposer,
          $$FcCachedTasksTableAnnotationComposer,
          $$FcCachedTasksTableCreateCompanionBuilder,
          $$FcCachedTasksTableUpdateCompanionBuilder,
          (
            FcCachedTask,
            BaseReferences<_$AppDatabase, $FcCachedTasksTable, FcCachedTask>,
          ),
          FcCachedTask,
          PrefetchHooks Function()
        > {
  $$FcCachedTasksTableTableManager(_$AppDatabase db, $FcCachedTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FcCachedTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FcCachedTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FcCachedTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> jsonData = const Value.absent(),
                Value<int> localSyncState = const Value.absent(),
                Value<DateTime> serverUpdatedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FcCachedTasksCompanion(
                id: id,
                jsonData: jsonData,
                localSyncState: localSyncState,
                serverUpdatedAt: serverUpdatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String jsonData,
                Value<int> localSyncState = const Value.absent(),
                required DateTime serverUpdatedAt,
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FcCachedTasksCompanion.insert(
                id: id,
                jsonData: jsonData,
                localSyncState: localSyncState,
                serverUpdatedAt: serverUpdatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FcCachedTasksTable, FcCachedTask>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FcCachedTasksTable,
                    FcCachedTask
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FcCachedTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FcCachedTasksTable,
      FcCachedTask,
      $$FcCachedTasksTableFilterComposer,
      $$FcCachedTasksTableOrderingComposer,
      $$FcCachedTasksTableAnnotationComposer,
      $$FcCachedTasksTableCreateCompanionBuilder,
      $$FcCachedTasksTableUpdateCompanionBuilder,
      (
        FcCachedTask,
        BaseReferences<_$AppDatabase, $FcCachedTasksTable, FcCachedTask>,
      ),
      FcCachedTask,
      PrefetchHooks Function()
    >;
typedef $$FcCachedEvidencesTableCreateCompanionBuilder =
    FcCachedEvidencesCompanion Function({
      required String id,
      required String reportId,
      required String jsonData,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$FcCachedEvidencesTableUpdateCompanionBuilder =
    FcCachedEvidencesCompanion Function({
      Value<String> id,
      Value<String> reportId,
      Value<String> jsonData,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$FcCachedEvidencesTableFilterComposer
    extends Composer<_$AppDatabase, $FcCachedEvidencesTable> {
  $$FcCachedEvidencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reportId => $composableBuilder(
    column: $table.reportId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FcCachedEvidencesTableOrderingComposer
    extends Composer<_$AppDatabase, $FcCachedEvidencesTable> {
  $$FcCachedEvidencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reportId => $composableBuilder(
    column: $table.reportId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FcCachedEvidencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FcCachedEvidencesTable> {
  $$FcCachedEvidencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reportId =>
      $composableBuilder(column: $table.reportId, builder: (column) => column);

  GeneratedColumn<String> get jsonData =>
      $composableBuilder(column: $table.jsonData, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$FcCachedEvidencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FcCachedEvidencesTable,
          FcCachedEvidence,
          $$FcCachedEvidencesTableFilterComposer,
          $$FcCachedEvidencesTableOrderingComposer,
          $$FcCachedEvidencesTableAnnotationComposer,
          $$FcCachedEvidencesTableCreateCompanionBuilder,
          $$FcCachedEvidencesTableUpdateCompanionBuilder,
          (
            FcCachedEvidence,
            BaseReferences<
              _$AppDatabase,
              $FcCachedEvidencesTable,
              FcCachedEvidence
            >,
          ),
          FcCachedEvidence,
          PrefetchHooks Function()
        > {
  $$FcCachedEvidencesTableTableManager(
    _$AppDatabase db,
    $FcCachedEvidencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FcCachedEvidencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FcCachedEvidencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FcCachedEvidencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> reportId = const Value.absent(),
                Value<String> jsonData = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FcCachedEvidencesCompanion(
                id: id,
                reportId: reportId,
                jsonData: jsonData,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String reportId,
                required String jsonData,
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FcCachedEvidencesCompanion.insert(
                id: id,
                reportId: reportId,
                jsonData: jsonData,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FcCachedEvidencesTable, FcCachedEvidence>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FcCachedEvidencesTable,
                    FcCachedEvidence
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FcCachedEvidencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FcCachedEvidencesTable,
      FcCachedEvidence,
      $$FcCachedEvidencesTableFilterComposer,
      $$FcCachedEvidencesTableOrderingComposer,
      $$FcCachedEvidencesTableAnnotationComposer,
      $$FcCachedEvidencesTableCreateCompanionBuilder,
      $$FcCachedEvidencesTableUpdateCompanionBuilder,
      (
        FcCachedEvidence,
        BaseReferences<
          _$AppDatabase,
          $FcCachedEvidencesTable,
          FcCachedEvidence
        >,
      ),
      FcCachedEvidence,
      PrefetchHooks Function()
    >;
typedef $$FcCachedNotesTableCreateCompanionBuilder =
    FcCachedNotesCompanion Function({
      required String id,
      required String reportId,
      required String jsonData,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$FcCachedNotesTableUpdateCompanionBuilder =
    FcCachedNotesCompanion Function({
      Value<String> id,
      Value<String> reportId,
      Value<String> jsonData,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$FcCachedNotesTableFilterComposer
    extends Composer<_$AppDatabase, $FcCachedNotesTable> {
  $$FcCachedNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reportId => $composableBuilder(
    column: $table.reportId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FcCachedNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $FcCachedNotesTable> {
  $$FcCachedNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reportId => $composableBuilder(
    column: $table.reportId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FcCachedNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FcCachedNotesTable> {
  $$FcCachedNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reportId =>
      $composableBuilder(column: $table.reportId, builder: (column) => column);

  GeneratedColumn<String> get jsonData =>
      $composableBuilder(column: $table.jsonData, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$FcCachedNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FcCachedNotesTable,
          FcCachedNote,
          $$FcCachedNotesTableFilterComposer,
          $$FcCachedNotesTableOrderingComposer,
          $$FcCachedNotesTableAnnotationComposer,
          $$FcCachedNotesTableCreateCompanionBuilder,
          $$FcCachedNotesTableUpdateCompanionBuilder,
          (
            FcCachedNote,
            BaseReferences<_$AppDatabase, $FcCachedNotesTable, FcCachedNote>,
          ),
          FcCachedNote,
          PrefetchHooks Function()
        > {
  $$FcCachedNotesTableTableManager(_$AppDatabase db, $FcCachedNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FcCachedNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FcCachedNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FcCachedNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> reportId = const Value.absent(),
                Value<String> jsonData = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FcCachedNotesCompanion(
                id: id,
                reportId: reportId,
                jsonData: jsonData,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String reportId,
                required String jsonData,
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FcCachedNotesCompanion.insert(
                id: id,
                reportId: reportId,
                jsonData: jsonData,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FcCachedNotesTable, FcCachedNote>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FcCachedNotesTable,
                    FcCachedNote
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FcCachedNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FcCachedNotesTable,
      FcCachedNote,
      $$FcCachedNotesTableFilterComposer,
      $$FcCachedNotesTableOrderingComposer,
      $$FcCachedNotesTableAnnotationComposer,
      $$FcCachedNotesTableCreateCompanionBuilder,
      $$FcCachedNotesTableUpdateCompanionBuilder,
      (
        FcCachedNote,
        BaseReferences<_$AppDatabase, $FcCachedNotesTable, FcCachedNote>,
      ),
      FcCachedNote,
      PrefetchHooks Function()
    >;
typedef $$FcCachedPhotoMetadataTableCreateCompanionBuilder =
    FcCachedPhotoMetadataCompanion Function({
      required String id,
      required String entityId,
      required String entityType,
      required String photoType,
      Value<String?> photoUrl,
      Value<String?> storagePath,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$FcCachedPhotoMetadataTableUpdateCompanionBuilder =
    FcCachedPhotoMetadataCompanion Function({
      Value<String> id,
      Value<String> entityId,
      Value<String> entityType,
      Value<String> photoType,
      Value<String?> photoUrl,
      Value<String?> storagePath,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$FcCachedPhotoMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $FcCachedPhotoMetadataTable> {
  $$FcCachedPhotoMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoType => $composableBuilder(
    column: $table.photoType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FcCachedPhotoMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $FcCachedPhotoMetadataTable> {
  $$FcCachedPhotoMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoType => $composableBuilder(
    column: $table.photoType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FcCachedPhotoMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $FcCachedPhotoMetadataTable> {
  $$FcCachedPhotoMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoType =>
      $composableBuilder(column: $table.photoType, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$FcCachedPhotoMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FcCachedPhotoMetadataTable,
          FcCachedPhotoMetadataData,
          $$FcCachedPhotoMetadataTableFilterComposer,
          $$FcCachedPhotoMetadataTableOrderingComposer,
          $$FcCachedPhotoMetadataTableAnnotationComposer,
          $$FcCachedPhotoMetadataTableCreateCompanionBuilder,
          $$FcCachedPhotoMetadataTableUpdateCompanionBuilder,
          (
            FcCachedPhotoMetadataData,
            BaseReferences<
              _$AppDatabase,
              $FcCachedPhotoMetadataTable,
              FcCachedPhotoMetadataData
            >,
          ),
          FcCachedPhotoMetadataData,
          PrefetchHooks Function()
        > {
  $$FcCachedPhotoMetadataTableTableManager(
    _$AppDatabase db,
    $FcCachedPhotoMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FcCachedPhotoMetadataTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$FcCachedPhotoMetadataTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FcCachedPhotoMetadataTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> photoType = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String?> storagePath = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FcCachedPhotoMetadataCompanion(
                id: id,
                entityId: entityId,
                entityType: entityType,
                photoType: photoType,
                photoUrl: photoUrl,
                storagePath: storagePath,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityId,
                required String entityType,
                required String photoType,
                Value<String?> photoUrl = const Value.absent(),
                Value<String?> storagePath = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FcCachedPhotoMetadataCompanion.insert(
                id: id,
                entityId: entityId,
                entityType: entityType,
                photoType: photoType,
                photoUrl: photoUrl,
                storagePath: storagePath,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $FcCachedPhotoMetadataTable,
                    FcCachedPhotoMetadataData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FcCachedPhotoMetadataTable,
                    FcCachedPhotoMetadataData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FcCachedPhotoMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FcCachedPhotoMetadataTable,
      FcCachedPhotoMetadataData,
      $$FcCachedPhotoMetadataTableFilterComposer,
      $$FcCachedPhotoMetadataTableOrderingComposer,
      $$FcCachedPhotoMetadataTableAnnotationComposer,
      $$FcCachedPhotoMetadataTableCreateCompanionBuilder,
      $$FcCachedPhotoMetadataTableUpdateCompanionBuilder,
      (
        FcCachedPhotoMetadataData,
        BaseReferences<
          _$AppDatabase,
          $FcCachedPhotoMetadataTable,
          FcCachedPhotoMetadataData
        >,
      ),
      FcCachedPhotoMetadataData,
      PrefetchHooks Function()
    >;
typedef $$FcSyncCursorsTableCreateCompanionBuilder =
    FcSyncCursorsCompanion Function({
      required String collectionKey,
      required DateTime lastSyncAt,
      Value<String?> extraJson,
      Value<int> rowid,
    });
typedef $$FcSyncCursorsTableUpdateCompanionBuilder =
    FcSyncCursorsCompanion Function({
      Value<String> collectionKey,
      Value<DateTime> lastSyncAt,
      Value<String?> extraJson,
      Value<int> rowid,
    });

class $$FcSyncCursorsTableFilterComposer
    extends Composer<_$AppDatabase, $FcSyncCursorsTable> {
  $$FcSyncCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get collectionKey => $composableBuilder(
    column: $table.collectionKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extraJson => $composableBuilder(
    column: $table.extraJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FcSyncCursorsTableOrderingComposer
    extends Composer<_$AppDatabase, $FcSyncCursorsTable> {
  $$FcSyncCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get collectionKey => $composableBuilder(
    column: $table.collectionKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extraJson => $composableBuilder(
    column: $table.extraJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FcSyncCursorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FcSyncCursorsTable> {
  $$FcSyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get collectionKey => $composableBuilder(
    column: $table.collectionKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extraJson =>
      $composableBuilder(column: $table.extraJson, builder: (column) => column);
}

class $$FcSyncCursorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FcSyncCursorsTable,
          FcSyncCursor,
          $$FcSyncCursorsTableFilterComposer,
          $$FcSyncCursorsTableOrderingComposer,
          $$FcSyncCursorsTableAnnotationComposer,
          $$FcSyncCursorsTableCreateCompanionBuilder,
          $$FcSyncCursorsTableUpdateCompanionBuilder,
          (
            FcSyncCursor,
            BaseReferences<_$AppDatabase, $FcSyncCursorsTable, FcSyncCursor>,
          ),
          FcSyncCursor,
          PrefetchHooks Function()
        > {
  $$FcSyncCursorsTableTableManager(_$AppDatabase db, $FcSyncCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FcSyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FcSyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FcSyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> collectionKey = const Value.absent(),
                Value<DateTime> lastSyncAt = const Value.absent(),
                Value<String?> extraJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FcSyncCursorsCompanion(
                collectionKey: collectionKey,
                lastSyncAt: lastSyncAt,
                extraJson: extraJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String collectionKey,
                required DateTime lastSyncAt,
                Value<String?> extraJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FcSyncCursorsCompanion.insert(
                collectionKey: collectionKey,
                lastSyncAt: lastSyncAt,
                extraJson: extraJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FcSyncCursorsTable, FcSyncCursor>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FcSyncCursorsTable,
                    FcSyncCursor
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FcSyncCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FcSyncCursorsTable,
      FcSyncCursor,
      $$FcSyncCursorsTableFilterComposer,
      $$FcSyncCursorsTableOrderingComposer,
      $$FcSyncCursorsTableAnnotationComposer,
      $$FcSyncCursorsTableCreateCompanionBuilder,
      $$FcSyncCursorsTableUpdateCompanionBuilder,
      (
        FcSyncCursor,
        BaseReferences<_$AppDatabase, $FcSyncCursorsTable, FcSyncCursor>,
      ),
      FcSyncCursor,
      PrefetchHooks Function()
    >;
typedef $$FcOutboxItemsTableCreateCompanionBuilder =
    FcOutboxItemsCompanion Function({
      required String operationId,
      required String operationType,
      required String entityId,
      required String entityType,
      required String payloadJson,
      Value<String?> baseVersion,
      Value<String> status,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$FcOutboxItemsTableUpdateCompanionBuilder =
    FcOutboxItemsCompanion Function({
      Value<String> operationId,
      Value<String> operationType,
      Value<String> entityId,
      Value<String> entityType,
      Value<String> payloadJson,
      Value<String?> baseVersion,
      Value<String> status,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$FcOutboxItemsTableFilterComposer
    extends Composer<_$AppDatabase, $FcOutboxItemsTable> {
  $$FcOutboxItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FcOutboxItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $FcOutboxItemsTable> {
  $$FcOutboxItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FcOutboxItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FcOutboxItemsTable> {
  $$FcOutboxItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FcOutboxItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FcOutboxItemsTable,
          FcOutboxItem,
          $$FcOutboxItemsTableFilterComposer,
          $$FcOutboxItemsTableOrderingComposer,
          $$FcOutboxItemsTableAnnotationComposer,
          $$FcOutboxItemsTableCreateCompanionBuilder,
          $$FcOutboxItemsTableUpdateCompanionBuilder,
          (
            FcOutboxItem,
            BaseReferences<_$AppDatabase, $FcOutboxItemsTable, FcOutboxItem>,
          ),
          FcOutboxItem,
          PrefetchHooks Function()
        > {
  $$FcOutboxItemsTableTableManager(_$AppDatabase db, $FcOutboxItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FcOutboxItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FcOutboxItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FcOutboxItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> operationId = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String?> baseVersion = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FcOutboxItemsCompanion(
                operationId: operationId,
                operationType: operationType,
                entityId: entityId,
                entityType: entityType,
                payloadJson: payloadJson,
                baseVersion: baseVersion,
                status: status,
                retryCount: retryCount,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationId,
                required String operationType,
                required String entityId,
                required String entityType,
                required String payloadJson,
                Value<String?> baseVersion = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FcOutboxItemsCompanion.insert(
                operationId: operationId,
                operationType: operationType,
                entityId: entityId,
                entityType: entityType,
                payloadJson: payloadJson,
                baseVersion: baseVersion,
                status: status,
                retryCount: retryCount,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FcOutboxItemsTable, FcOutboxItem>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FcOutboxItemsTable,
                    FcOutboxItem
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FcOutboxItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FcOutboxItemsTable,
      FcOutboxItem,
      $$FcOutboxItemsTableFilterComposer,
      $$FcOutboxItemsTableOrderingComposer,
      $$FcOutboxItemsTableAnnotationComposer,
      $$FcOutboxItemsTableCreateCompanionBuilder,
      $$FcOutboxItemsTableUpdateCompanionBuilder,
      (
        FcOutboxItem,
        BaseReferences<_$AppDatabase, $FcOutboxItemsTable, FcOutboxItem>,
      ),
      FcOutboxItem,
      PrefetchHooks Function()
    >;
typedef $$FcLocalPhotosTableCreateCompanionBuilder =
    FcLocalPhotosCompanion Function({
      required String localPhotoId,
      required String entityId,
      required String entityType,
      required String photoType,
      required String localPath,
      Value<String?> fileHash,
      Value<int> fileSize,
      Value<int> syncStatus,
      Value<String?> remoteId,
      Value<String?> remoteUrl,
      Value<String?> lastError,
      Value<int> retryCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$FcLocalPhotosTableUpdateCompanionBuilder =
    FcLocalPhotosCompanion Function({
      Value<String> localPhotoId,
      Value<String> entityId,
      Value<String> entityType,
      Value<String> photoType,
      Value<String> localPath,
      Value<String?> fileHash,
      Value<int> fileSize,
      Value<int> syncStatus,
      Value<String?> remoteId,
      Value<String?> remoteUrl,
      Value<String?> lastError,
      Value<int> retryCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$FcLocalPhotosTableFilterComposer
    extends Composer<_$AppDatabase, $FcLocalPhotosTable> {
  $$FcLocalPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localPhotoId => $composableBuilder(
    column: $table.localPhotoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoType => $composableBuilder(
    column: $table.photoType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteUrl => $composableBuilder(
    column: $table.remoteUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FcLocalPhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $FcLocalPhotosTable> {
  $$FcLocalPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localPhotoId => $composableBuilder(
    column: $table.localPhotoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoType => $composableBuilder(
    column: $table.photoType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteUrl => $composableBuilder(
    column: $table.remoteUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FcLocalPhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $FcLocalPhotosTable> {
  $$FcLocalPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localPhotoId => $composableBuilder(
    column: $table.localPhotoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoType =>
      $composableBuilder(column: $table.photoType, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get fileHash =>
      $composableBuilder(column: $table.fileHash, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get remoteUrl =>
      $composableBuilder(column: $table.remoteUrl, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FcLocalPhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FcLocalPhotosTable,
          FcLocalPhoto,
          $$FcLocalPhotosTableFilterComposer,
          $$FcLocalPhotosTableOrderingComposer,
          $$FcLocalPhotosTableAnnotationComposer,
          $$FcLocalPhotosTableCreateCompanionBuilder,
          $$FcLocalPhotosTableUpdateCompanionBuilder,
          (
            FcLocalPhoto,
            BaseReferences<_$AppDatabase, $FcLocalPhotosTable, FcLocalPhoto>,
          ),
          FcLocalPhoto,
          PrefetchHooks Function()
        > {
  $$FcLocalPhotosTableTableManager(_$AppDatabase db, $FcLocalPhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FcLocalPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FcLocalPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FcLocalPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localPhotoId = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> photoType = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<String?> fileHash = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String?> remoteUrl = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FcLocalPhotosCompanion(
                localPhotoId: localPhotoId,
                entityId: entityId,
                entityType: entityType,
                photoType: photoType,
                localPath: localPath,
                fileHash: fileHash,
                fileSize: fileSize,
                syncStatus: syncStatus,
                remoteId: remoteId,
                remoteUrl: remoteUrl,
                lastError: lastError,
                retryCount: retryCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localPhotoId,
                required String entityId,
                required String entityType,
                required String photoType,
                required String localPath,
                Value<String?> fileHash = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String?> remoteUrl = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FcLocalPhotosCompanion.insert(
                localPhotoId: localPhotoId,
                entityId: entityId,
                entityType: entityType,
                photoType: photoType,
                localPath: localPath,
                fileHash: fileHash,
                fileSize: fileSize,
                syncStatus: syncStatus,
                remoteId: remoteId,
                remoteUrl: remoteUrl,
                lastError: lastError,
                retryCount: retryCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FcLocalPhotosTable, FcLocalPhoto>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FcLocalPhotosTable,
                    FcLocalPhoto
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FcLocalPhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FcLocalPhotosTable,
      FcLocalPhoto,
      $$FcLocalPhotosTableFilterComposer,
      $$FcLocalPhotosTableOrderingComposer,
      $$FcLocalPhotosTableAnnotationComposer,
      $$FcLocalPhotosTableCreateCompanionBuilder,
      $$FcLocalPhotosTableUpdateCompanionBuilder,
      (
        FcLocalPhoto,
        BaseReferences<_$AppDatabase, $FcLocalPhotosTable, FcLocalPhoto>,
      ),
      FcLocalPhoto,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OfflineReportsTableTableManager get offlineReports =>
      $$OfflineReportsTableTableManager(_db, _db.offlineReports);
  $$OfflineTaskUpdatesTableTableManager get offlineTaskUpdates =>
      $$OfflineTaskUpdatesTableTableManager(_db, _db.offlineTaskUpdates);
  $$OfflineMediaTableTableManager get offlineMedia =>
      $$OfflineMediaTableTableManager(_db, _db.offlineMedia);
  $$FcCachedReportsTableTableManager get fcCachedReports =>
      $$FcCachedReportsTableTableManager(_db, _db.fcCachedReports);
  $$FcCachedTasksTableTableManager get fcCachedTasks =>
      $$FcCachedTasksTableTableManager(_db, _db.fcCachedTasks);
  $$FcCachedEvidencesTableTableManager get fcCachedEvidences =>
      $$FcCachedEvidencesTableTableManager(_db, _db.fcCachedEvidences);
  $$FcCachedNotesTableTableManager get fcCachedNotes =>
      $$FcCachedNotesTableTableManager(_db, _db.fcCachedNotes);
  $$FcCachedPhotoMetadataTableTableManager get fcCachedPhotoMetadata =>
      $$FcCachedPhotoMetadataTableTableManager(_db, _db.fcCachedPhotoMetadata);
  $$FcSyncCursorsTableTableManager get fcSyncCursors =>
      $$FcSyncCursorsTableTableManager(_db, _db.fcSyncCursors);
  $$FcOutboxItemsTableTableManager get fcOutboxItems =>
      $$FcOutboxItemsTableTableManager(_db, _db.fcOutboxItems);
  $$FcLocalPhotosTableTableManager get fcLocalPhotos =>
      $$FcLocalPhotosTableTableManager(_db, _db.fcLocalPhotos);
}
