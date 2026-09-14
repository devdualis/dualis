// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TriageOutboxTable extends TriageOutbox
    with TableInfo<$TriageOutboxTable, TriageOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TriageOutboxTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _clientSessionIdMeta = const VerificationMeta(
    'clientSessionId',
  );
  @override
  late final GeneratedColumn<String> clientSessionId = GeneratedColumn<String>(
    'client_session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verticalMeta = const VerificationMeta(
    'vertical',
  );
  @override
  late final GeneratedColumn<String> vertical = GeneratedColumn<String>(
    'vertical',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepAnswersJsonMeta = const VerificationMeta(
    'stepAnswersJson',
  );
  @override
  late final GeneratedColumn<String> stepAnswersJson = GeneratedColumn<String>(
    'step_answers_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _narrativeMeta = const VerificationMeta(
    'narrative',
  );
  @override
  late final GeneratedColumn<String> narrative = GeneratedColumn<String>(
    'narrative',
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
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientSessionId,
    vertical,
    stepAnswersJson,
    narrative,
    status,
    attempts,
    lastError,
    createdAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'triage_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<TriageOutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_session_id')) {
      context.handle(
        _clientSessionIdMeta,
        clientSessionId.isAcceptableOrUnknown(
          data['client_session_id']!,
          _clientSessionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientSessionIdMeta);
    }
    if (data.containsKey('vertical')) {
      context.handle(
        _verticalMeta,
        vertical.isAcceptableOrUnknown(data['vertical']!, _verticalMeta),
      );
    } else if (isInserting) {
      context.missing(_verticalMeta);
    }
    if (data.containsKey('step_answers_json')) {
      context.handle(
        _stepAnswersJsonMeta,
        stepAnswersJson.isAcceptableOrUnknown(
          data['step_answers_json']!,
          _stepAnswersJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stepAnswersJsonMeta);
    }
    if (data.containsKey('narrative')) {
      context.handle(
        _narrativeMeta,
        narrative.isAcceptableOrUnknown(data['narrative']!, _narrativeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
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
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TriageOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TriageOutboxData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      clientSessionId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}client_session_id'],
          )!,
      vertical:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}vertical'],
          )!,
      stepAnswersJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}step_answers_json'],
          )!,
      narrative: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}narrative'],
      ),
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      attempts:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}attempts'],
          )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $TriageOutboxTable createAlias(String alias) {
    return $TriageOutboxTable(attachedDatabase, alias);
  }
}

class TriageOutboxData extends DataClass
    implements Insertable<TriageOutboxData> {
  final int id;
  final String clientSessionId;
  final String vertical;
  final String stepAnswersJson;
  final String? narrative;
  final String status;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? syncedAt;
  const TriageOutboxData({
    required this.id,
    required this.clientSessionId,
    required this.vertical,
    required this.stepAnswersJson,
    this.narrative,
    required this.status,
    required this.attempts,
    this.lastError,
    required this.createdAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_session_id'] = Variable<String>(clientSessionId);
    map['vertical'] = Variable<String>(vertical);
    map['step_answers_json'] = Variable<String>(stepAnswersJson);
    if (!nullToAbsent || narrative != null) {
      map['narrative'] = Variable<String>(narrative);
    }
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  TriageOutboxCompanion toCompanion(bool nullToAbsent) {
    return TriageOutboxCompanion(
      id: Value(id),
      clientSessionId: Value(clientSessionId),
      vertical: Value(vertical),
      stepAnswersJson: Value(stepAnswersJson),
      narrative:
          narrative == null && nullToAbsent
              ? const Value.absent()
              : Value(narrative),
      status: Value(status),
      attempts: Value(attempts),
      lastError:
          lastError == null && nullToAbsent
              ? const Value.absent()
              : Value(lastError),
      createdAt: Value(createdAt),
      syncedAt:
          syncedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(syncedAt),
    );
  }

  factory TriageOutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TriageOutboxData(
      id: serializer.fromJson<int>(json['id']),
      clientSessionId: serializer.fromJson<String>(json['clientSessionId']),
      vertical: serializer.fromJson<String>(json['vertical']),
      stepAnswersJson: serializer.fromJson<String>(json['stepAnswersJson']),
      narrative: serializer.fromJson<String?>(json['narrative']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientSessionId': serializer.toJson<String>(clientSessionId),
      'vertical': serializer.toJson<String>(vertical),
      'stepAnswersJson': serializer.toJson<String>(stepAnswersJson),
      'narrative': serializer.toJson<String?>(narrative),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  TriageOutboxData copyWith({
    int? id,
    String? clientSessionId,
    String? vertical,
    String? stepAnswersJson,
    Value<String?> narrative = const Value.absent(),
    String? status,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => TriageOutboxData(
    id: id ?? this.id,
    clientSessionId: clientSessionId ?? this.clientSessionId,
    vertical: vertical ?? this.vertical,
    stepAnswersJson: stepAnswersJson ?? this.stepAnswersJson,
    narrative: narrative.present ? narrative.value : this.narrative,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  TriageOutboxData copyWithCompanion(TriageOutboxCompanion data) {
    return TriageOutboxData(
      id: data.id.present ? data.id.value : this.id,
      clientSessionId:
          data.clientSessionId.present
              ? data.clientSessionId.value
              : this.clientSessionId,
      vertical: data.vertical.present ? data.vertical.value : this.vertical,
      stepAnswersJson:
          data.stepAnswersJson.present
              ? data.stepAnswersJson.value
              : this.stepAnswersJson,
      narrative: data.narrative.present ? data.narrative.value : this.narrative,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TriageOutboxData(')
          ..write('id: $id, ')
          ..write('clientSessionId: $clientSessionId, ')
          ..write('vertical: $vertical, ')
          ..write('stepAnswersJson: $stepAnswersJson, ')
          ..write('narrative: $narrative, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientSessionId,
    vertical,
    stepAnswersJson,
    narrative,
    status,
    attempts,
    lastError,
    createdAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TriageOutboxData &&
          other.id == this.id &&
          other.clientSessionId == this.clientSessionId &&
          other.vertical == this.vertical &&
          other.stepAnswersJson == this.stepAnswersJson &&
          other.narrative == this.narrative &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt);
}

class TriageOutboxCompanion extends UpdateCompanion<TriageOutboxData> {
  final Value<int> id;
  final Value<String> clientSessionId;
  final Value<String> vertical;
  final Value<String> stepAnswersJson;
  final Value<String?> narrative;
  final Value<String> status;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime?> syncedAt;
  const TriageOutboxCompanion({
    this.id = const Value.absent(),
    this.clientSessionId = const Value.absent(),
    this.vertical = const Value.absent(),
    this.stepAnswersJson = const Value.absent(),
    this.narrative = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  TriageOutboxCompanion.insert({
    this.id = const Value.absent(),
    required String clientSessionId,
    required String vertical,
    required String stepAnswersJson,
    this.narrative = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  }) : clientSessionId = Value(clientSessionId),
       vertical = Value(vertical),
       stepAnswersJson = Value(stepAnswersJson);
  static Insertable<TriageOutboxData> custom({
    Expression<int>? id,
    Expression<String>? clientSessionId,
    Expression<String>? vertical,
    Expression<String>? stepAnswersJson,
    Expression<String>? narrative,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientSessionId != null) 'client_session_id': clientSessionId,
      if (vertical != null) 'vertical': vertical,
      if (stepAnswersJson != null) 'step_answers_json': stepAnswersJson,
      if (narrative != null) 'narrative': narrative,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  TriageOutboxCompanion copyWith({
    Value<int>? id,
    Value<String>? clientSessionId,
    Value<String>? vertical,
    Value<String>? stepAnswersJson,
    Value<String?>? narrative,
    Value<String>? status,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<DateTime?>? syncedAt,
  }) {
    return TriageOutboxCompanion(
      id: id ?? this.id,
      clientSessionId: clientSessionId ?? this.clientSessionId,
      vertical: vertical ?? this.vertical,
      stepAnswersJson: stepAnswersJson ?? this.stepAnswersJson,
      narrative: narrative ?? this.narrative,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientSessionId.present) {
      map['client_session_id'] = Variable<String>(clientSessionId.value);
    }
    if (vertical.present) {
      map['vertical'] = Variable<String>(vertical.value);
    }
    if (stepAnswersJson.present) {
      map['step_answers_json'] = Variable<String>(stepAnswersJson.value);
    }
    if (narrative.present) {
      map['narrative'] = Variable<String>(narrative.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TriageOutboxCompanion(')
          ..write('id: $id, ')
          ..write('clientSessionId: $clientSessionId, ')
          ..write('vertical: $vertical, ')
          ..write('stepAnswersJson: $stepAnswersJson, ')
          ..write('narrative: $narrative, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalSymptomDraftsTable extends LocalSymptomDrafts
    with TableInfo<$LocalSymptomDraftsTable, LocalSymptomDraft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSymptomDraftsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _verticalMeta = const VerificationMeta(
    'vertical',
  );
  @override
  late final GeneratedColumn<String> vertical = GeneratedColumn<String>(
    'vertical',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentStepMeta = const VerificationMeta(
    'currentStep',
  );
  @override
  late final GeneratedColumn<int> currentStep = GeneratedColumn<int>(
    'current_step',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stepAnswersJsonMeta = const VerificationMeta(
    'stepAnswersJson',
  );
  @override
  late final GeneratedColumn<String> stepAnswersJson = GeneratedColumn<String>(
    'step_answers_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _narrativeMeta = const VerificationMeta(
    'narrative',
  );
  @override
  late final GeneratedColumn<String> narrative = GeneratedColumn<String>(
    'narrative',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    id,
    vertical,
    currentStep,
    stepAnswersJson,
    narrative,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_symptom_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSymptomDraft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('vertical')) {
      context.handle(
        _verticalMeta,
        vertical.isAcceptableOrUnknown(data['vertical']!, _verticalMeta),
      );
    } else if (isInserting) {
      context.missing(_verticalMeta);
    }
    if (data.containsKey('current_step')) {
      context.handle(
        _currentStepMeta,
        currentStep.isAcceptableOrUnknown(
          data['current_step']!,
          _currentStepMeta,
        ),
      );
    }
    if (data.containsKey('step_answers_json')) {
      context.handle(
        _stepAnswersJsonMeta,
        stepAnswersJson.isAcceptableOrUnknown(
          data['step_answers_json']!,
          _stepAnswersJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stepAnswersJsonMeta);
    }
    if (data.containsKey('narrative')) {
      context.handle(
        _narrativeMeta,
        narrative.isAcceptableOrUnknown(data['narrative']!, _narrativeMeta),
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSymptomDraft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSymptomDraft(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      vertical:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}vertical'],
          )!,
      currentStep:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}current_step'],
          )!,
      stepAnswersJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}step_answers_json'],
          )!,
      narrative: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}narrative'],
      ),
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $LocalSymptomDraftsTable createAlias(String alias) {
    return $LocalSymptomDraftsTable(attachedDatabase, alias);
  }
}

class LocalSymptomDraft extends DataClass
    implements Insertable<LocalSymptomDraft> {
  final int id;
  final String vertical;
  final int currentStep;
  final String stepAnswersJson;
  final String? narrative;
  final DateTime updatedAt;
  const LocalSymptomDraft({
    required this.id,
    required this.vertical,
    required this.currentStep,
    required this.stepAnswersJson,
    this.narrative,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['vertical'] = Variable<String>(vertical);
    map['current_step'] = Variable<int>(currentStep);
    map['step_answers_json'] = Variable<String>(stepAnswersJson);
    if (!nullToAbsent || narrative != null) {
      map['narrative'] = Variable<String>(narrative);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalSymptomDraftsCompanion toCompanion(bool nullToAbsent) {
    return LocalSymptomDraftsCompanion(
      id: Value(id),
      vertical: Value(vertical),
      currentStep: Value(currentStep),
      stepAnswersJson: Value(stepAnswersJson),
      narrative:
          narrative == null && nullToAbsent
              ? const Value.absent()
              : Value(narrative),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalSymptomDraft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSymptomDraft(
      id: serializer.fromJson<int>(json['id']),
      vertical: serializer.fromJson<String>(json['vertical']),
      currentStep: serializer.fromJson<int>(json['currentStep']),
      stepAnswersJson: serializer.fromJson<String>(json['stepAnswersJson']),
      narrative: serializer.fromJson<String?>(json['narrative']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'vertical': serializer.toJson<String>(vertical),
      'currentStep': serializer.toJson<int>(currentStep),
      'stepAnswersJson': serializer.toJson<String>(stepAnswersJson),
      'narrative': serializer.toJson<String?>(narrative),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalSymptomDraft copyWith({
    int? id,
    String? vertical,
    int? currentStep,
    String? stepAnswersJson,
    Value<String?> narrative = const Value.absent(),
    DateTime? updatedAt,
  }) => LocalSymptomDraft(
    id: id ?? this.id,
    vertical: vertical ?? this.vertical,
    currentStep: currentStep ?? this.currentStep,
    stepAnswersJson: stepAnswersJson ?? this.stepAnswersJson,
    narrative: narrative.present ? narrative.value : this.narrative,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalSymptomDraft copyWithCompanion(LocalSymptomDraftsCompanion data) {
    return LocalSymptomDraft(
      id: data.id.present ? data.id.value : this.id,
      vertical: data.vertical.present ? data.vertical.value : this.vertical,
      currentStep:
          data.currentStep.present ? data.currentStep.value : this.currentStep,
      stepAnswersJson:
          data.stepAnswersJson.present
              ? data.stepAnswersJson.value
              : this.stepAnswersJson,
      narrative: data.narrative.present ? data.narrative.value : this.narrative,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSymptomDraft(')
          ..write('id: $id, ')
          ..write('vertical: $vertical, ')
          ..write('currentStep: $currentStep, ')
          ..write('stepAnswersJson: $stepAnswersJson, ')
          ..write('narrative: $narrative, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    vertical,
    currentStep,
    stepAnswersJson,
    narrative,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSymptomDraft &&
          other.id == this.id &&
          other.vertical == this.vertical &&
          other.currentStep == this.currentStep &&
          other.stepAnswersJson == this.stepAnswersJson &&
          other.narrative == this.narrative &&
          other.updatedAt == this.updatedAt);
}

class LocalSymptomDraftsCompanion extends UpdateCompanion<LocalSymptomDraft> {
  final Value<int> id;
  final Value<String> vertical;
  final Value<int> currentStep;
  final Value<String> stepAnswersJson;
  final Value<String?> narrative;
  final Value<DateTime> updatedAt;
  const LocalSymptomDraftsCompanion({
    this.id = const Value.absent(),
    this.vertical = const Value.absent(),
    this.currentStep = const Value.absent(),
    this.stepAnswersJson = const Value.absent(),
    this.narrative = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalSymptomDraftsCompanion.insert({
    this.id = const Value.absent(),
    required String vertical,
    this.currentStep = const Value.absent(),
    required String stepAnswersJson,
    this.narrative = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : vertical = Value(vertical),
       stepAnswersJson = Value(stepAnswersJson);
  static Insertable<LocalSymptomDraft> custom({
    Expression<int>? id,
    Expression<String>? vertical,
    Expression<int>? currentStep,
    Expression<String>? stepAnswersJson,
    Expression<String>? narrative,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vertical != null) 'vertical': vertical,
      if (currentStep != null) 'current_step': currentStep,
      if (stepAnswersJson != null) 'step_answers_json': stepAnswersJson,
      if (narrative != null) 'narrative': narrative,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalSymptomDraftsCompanion copyWith({
    Value<int>? id,
    Value<String>? vertical,
    Value<int>? currentStep,
    Value<String>? stepAnswersJson,
    Value<String?>? narrative,
    Value<DateTime>? updatedAt,
  }) {
    return LocalSymptomDraftsCompanion(
      id: id ?? this.id,
      vertical: vertical ?? this.vertical,
      currentStep: currentStep ?? this.currentStep,
      stepAnswersJson: stepAnswersJson ?? this.stepAnswersJson,
      narrative: narrative ?? this.narrative,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (vertical.present) {
      map['vertical'] = Variable<String>(vertical.value);
    }
    if (currentStep.present) {
      map['current_step'] = Variable<int>(currentStep.value);
    }
    if (stepAnswersJson.present) {
      map['step_answers_json'] = Variable<String>(stepAnswersJson.value);
    }
    if (narrative.present) {
      map['narrative'] = Variable<String>(narrative.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSymptomDraftsCompanion(')
          ..write('id: $id, ')
          ..write('vertical: $vertical, ')
          ..write('currentStep: $currentStep, ')
          ..write('stepAnswersJson: $stepAnswersJson, ')
          ..write('narrative: $narrative, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TriageOutboxTable triageOutbox = $TriageOutboxTable(this);
  late final $LocalSymptomDraftsTable localSymptomDrafts =
      $LocalSymptomDraftsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    triageOutbox,
    localSymptomDrafts,
  ];
}

typedef $$TriageOutboxTableCreateCompanionBuilder =
    TriageOutboxCompanion Function({
      Value<int> id,
      required String clientSessionId,
      required String vertical,
      required String stepAnswersJson,
      Value<String?> narrative,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
    });
typedef $$TriageOutboxTableUpdateCompanionBuilder =
    TriageOutboxCompanion Function({
      Value<int> id,
      Value<String> clientSessionId,
      Value<String> vertical,
      Value<String> stepAnswersJson,
      Value<String?> narrative,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
    });

class $$TriageOutboxTableFilterComposer
    extends Composer<_$AppDatabase, $TriageOutboxTable> {
  $$TriageOutboxTableFilterComposer({
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

  ColumnFilters<String> get clientSessionId => $composableBuilder(
    column: $table.clientSessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vertical => $composableBuilder(
    column: $table.vertical,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stepAnswersJson => $composableBuilder(
    column: $table.stepAnswersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get narrative => $composableBuilder(
    column: $table.narrative,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
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

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TriageOutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $TriageOutboxTable> {
  $$TriageOutboxTableOrderingComposer({
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

  ColumnOrderings<String> get clientSessionId => $composableBuilder(
    column: $table.clientSessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vertical => $composableBuilder(
    column: $table.vertical,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stepAnswersJson => $composableBuilder(
    column: $table.stepAnswersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get narrative => $composableBuilder(
    column: $table.narrative,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
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

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TriageOutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $TriageOutboxTable> {
  $$TriageOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientSessionId => $composableBuilder(
    column: $table.clientSessionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vertical =>
      $composableBuilder(column: $table.vertical, builder: (column) => column);

  GeneratedColumn<String> get stepAnswersJson => $composableBuilder(
    column: $table.stepAnswersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get narrative =>
      $composableBuilder(column: $table.narrative, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$TriageOutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TriageOutboxTable,
          TriageOutboxData,
          $$TriageOutboxTableFilterComposer,
          $$TriageOutboxTableOrderingComposer,
          $$TriageOutboxTableAnnotationComposer,
          $$TriageOutboxTableCreateCompanionBuilder,
          $$TriageOutboxTableUpdateCompanionBuilder,
          (
            TriageOutboxData,
            BaseReferences<_$AppDatabase, $TriageOutboxTable, TriageOutboxData>,
          ),
          TriageOutboxData,
          PrefetchHooks Function()
        > {
  $$TriageOutboxTableTableManager(_$AppDatabase db, $TriageOutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$TriageOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$TriageOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$TriageOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> clientSessionId = const Value.absent(),
                Value<String> vertical = const Value.absent(),
                Value<String> stepAnswersJson = const Value.absent(),
                Value<String?> narrative = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => TriageOutboxCompanion(
                id: id,
                clientSessionId: clientSessionId,
                vertical: vertical,
                stepAnswersJson: stepAnswersJson,
                narrative: narrative,
                status: status,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String clientSessionId,
                required String vertical,
                required String stepAnswersJson,
                Value<String?> narrative = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => TriageOutboxCompanion.insert(
                id: id,
                clientSessionId: clientSessionId,
                vertical: vertical,
                stepAnswersJson: stepAnswersJson,
                narrative: narrative,
                status: status,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
                syncedAt: syncedAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable<$TriageOutboxTable, TriageOutboxData>(
                            table,
                          ),
                          BaseReferences<
                            _$AppDatabase,
                            $TriageOutboxTable,
                            TriageOutboxData
                          >(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TriageOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TriageOutboxTable,
      TriageOutboxData,
      $$TriageOutboxTableFilterComposer,
      $$TriageOutboxTableOrderingComposer,
      $$TriageOutboxTableAnnotationComposer,
      $$TriageOutboxTableCreateCompanionBuilder,
      $$TriageOutboxTableUpdateCompanionBuilder,
      (
        TriageOutboxData,
        BaseReferences<_$AppDatabase, $TriageOutboxTable, TriageOutboxData>,
      ),
      TriageOutboxData,
      PrefetchHooks Function()
    >;
typedef $$LocalSymptomDraftsTableCreateCompanionBuilder =
    LocalSymptomDraftsCompanion Function({
      Value<int> id,
      required String vertical,
      Value<int> currentStep,
      required String stepAnswersJson,
      Value<String?> narrative,
      Value<DateTime> updatedAt,
    });
typedef $$LocalSymptomDraftsTableUpdateCompanionBuilder =
    LocalSymptomDraftsCompanion Function({
      Value<int> id,
      Value<String> vertical,
      Value<int> currentStep,
      Value<String> stepAnswersJson,
      Value<String?> narrative,
      Value<DateTime> updatedAt,
    });

class $$LocalSymptomDraftsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSymptomDraftsTable> {
  $$LocalSymptomDraftsTableFilterComposer({
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

  ColumnFilters<String> get vertical => $composableBuilder(
    column: $table.vertical,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentStep => $composableBuilder(
    column: $table.currentStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stepAnswersJson => $composableBuilder(
    column: $table.stepAnswersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get narrative => $composableBuilder(
    column: $table.narrative,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSymptomDraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSymptomDraftsTable> {
  $$LocalSymptomDraftsTableOrderingComposer({
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

  ColumnOrderings<String> get vertical => $composableBuilder(
    column: $table.vertical,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentStep => $composableBuilder(
    column: $table.currentStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stepAnswersJson => $composableBuilder(
    column: $table.stepAnswersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get narrative => $composableBuilder(
    column: $table.narrative,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSymptomDraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSymptomDraftsTable> {
  $$LocalSymptomDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vertical =>
      $composableBuilder(column: $table.vertical, builder: (column) => column);

  GeneratedColumn<int> get currentStep => $composableBuilder(
    column: $table.currentStep,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stepAnswersJson => $composableBuilder(
    column: $table.stepAnswersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get narrative =>
      $composableBuilder(column: $table.narrative, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalSymptomDraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSymptomDraftsTable,
          LocalSymptomDraft,
          $$LocalSymptomDraftsTableFilterComposer,
          $$LocalSymptomDraftsTableOrderingComposer,
          $$LocalSymptomDraftsTableAnnotationComposer,
          $$LocalSymptomDraftsTableCreateCompanionBuilder,
          $$LocalSymptomDraftsTableUpdateCompanionBuilder,
          (
            LocalSymptomDraft,
            BaseReferences<
              _$AppDatabase,
              $LocalSymptomDraftsTable,
              LocalSymptomDraft
            >,
          ),
          LocalSymptomDraft,
          PrefetchHooks Function()
        > {
  $$LocalSymptomDraftsTableTableManager(
    _$AppDatabase db,
    $LocalSymptomDraftsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$LocalSymptomDraftsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$LocalSymptomDraftsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$LocalSymptomDraftsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> vertical = const Value.absent(),
                Value<int> currentStep = const Value.absent(),
                Value<String> stepAnswersJson = const Value.absent(),
                Value<String?> narrative = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalSymptomDraftsCompanion(
                id: id,
                vertical: vertical,
                currentStep: currentStep,
                stepAnswersJson: stepAnswersJson,
                narrative: narrative,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String vertical,
                Value<int> currentStep = const Value.absent(),
                required String stepAnswersJson,
                Value<String?> narrative = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalSymptomDraftsCompanion.insert(
                id: id,
                vertical: vertical,
                currentStep: currentStep,
                stepAnswersJson: stepAnswersJson,
                narrative: narrative,
                updatedAt: updatedAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable<
                            $LocalSymptomDraftsTable,
                            LocalSymptomDraft
                          >(table),
                          BaseReferences<
                            _$AppDatabase,
                            $LocalSymptomDraftsTable,
                            LocalSymptomDraft
                          >(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSymptomDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSymptomDraftsTable,
      LocalSymptomDraft,
      $$LocalSymptomDraftsTableFilterComposer,
      $$LocalSymptomDraftsTableOrderingComposer,
      $$LocalSymptomDraftsTableAnnotationComposer,
      $$LocalSymptomDraftsTableCreateCompanionBuilder,
      $$LocalSymptomDraftsTableUpdateCompanionBuilder,
      (
        LocalSymptomDraft,
        BaseReferences<
          _$AppDatabase,
          $LocalSymptomDraftsTable,
          LocalSymptomDraft
        >,
      ),
      LocalSymptomDraft,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TriageOutboxTableTableManager get triageOutbox =>
      $$TriageOutboxTableTableManager(_db, _db.triageOutbox);
  $$LocalSymptomDraftsTableTableManager get localSymptomDrafts =>
      $$LocalSymptomDraftsTableTableManager(_db, _db.localSymptomDrafts);
}
