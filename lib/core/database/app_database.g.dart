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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OfflineReportsTable offlineReports = $OfflineReportsTable(this);
  late final $OfflineTaskUpdatesTable offlineTaskUpdates =
      $OfflineTaskUpdatesTable(this);
  late final $OfflineMediaTable offlineMedia = $OfflineMediaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    offlineReports,
    offlineTaskUpdates,
    offlineMedia,
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OfflineReportsTableTableManager get offlineReports =>
      $$OfflineReportsTableTableManager(_db, _db.offlineReports);
  $$OfflineTaskUpdatesTableTableManager get offlineTaskUpdates =>
      $$OfflineTaskUpdatesTableTableManager(_db, _db.offlineTaskUpdates);
  $$OfflineMediaTableTableManager get offlineMedia =>
      $$OfflineMediaTableTableManager(_db, _db.offlineMedia);
}
