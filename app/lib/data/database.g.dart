// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $KvEntriesTable extends KvEntries
    with TableInfo<$KvEntriesTable, KvEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KvEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kv_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<KvEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KvEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KvEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $KvEntriesTable createAlias(String alias) {
    return $KvEntriesTable(attachedDatabase, alias);
  }
}

class KvEntry extends DataClass implements Insertable<KvEntry> {
  final String key;
  final String value;
  const KvEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KvEntriesCompanion toCompanion(bool nullToAbsent) {
    return KvEntriesCompanion(key: Value(key), value: Value(value));
  }

  factory KvEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KvEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KvEntry copyWith({String? key, String? value}) =>
      KvEntry(key: key ?? this.key, value: value ?? this.value);
  KvEntry copyWithCompanion(KvEntriesCompanion data) {
    return KvEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KvEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KvEntry && other.key == this.key && other.value == this.value);
}

class KvEntriesCompanion extends UpdateCompanion<KvEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KvEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KvEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KvEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KvEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KvEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KvEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserRecipesTable extends UserRecipes
    with TableInfo<$UserRecipesTable, UserRecipe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserRecipesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodIdMeta = const VerificationMeta(
    'methodId',
  );
  @override
  late final GeneratedColumn<String> methodId = GeneratedColumn<String>(
    'method_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, methodId, json, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_recipes';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserRecipe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('method_id')) {
      context.handle(
        _methodIdMeta,
        methodId.isAcceptableOrUnknown(data['method_id']!, _methodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_methodIdMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserRecipe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserRecipe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      methodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method_id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserRecipesTable createAlias(String alias) {
    return $UserRecipesTable(attachedDatabase, alias);
  }
}

class UserRecipe extends DataClass implements Insertable<UserRecipe> {
  final String id;
  final String methodId;
  final String json;
  final DateTime updatedAt;
  const UserRecipe({
    required this.id,
    required this.methodId,
    required this.json,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['method_id'] = Variable<String>(methodId);
    map['json'] = Variable<String>(json);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserRecipesCompanion toCompanion(bool nullToAbsent) {
    return UserRecipesCompanion(
      id: Value(id),
      methodId: Value(methodId),
      json: Value(json),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserRecipe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRecipe(
      id: serializer.fromJson<String>(json['id']),
      methodId: serializer.fromJson<String>(json['methodId']),
      json: serializer.fromJson<String>(json['json']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'methodId': serializer.toJson<String>(methodId),
      'json': serializer.toJson<String>(json),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserRecipe copyWith({
    String? id,
    String? methodId,
    String? json,
    DateTime? updatedAt,
  }) => UserRecipe(
    id: id ?? this.id,
    methodId: methodId ?? this.methodId,
    json: json ?? this.json,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserRecipe copyWithCompanion(UserRecipesCompanion data) {
    return UserRecipe(
      id: data.id.present ? data.id.value : this.id,
      methodId: data.methodId.present ? data.methodId.value : this.methodId,
      json: data.json.present ? data.json.value : this.json,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRecipe(')
          ..write('id: $id, ')
          ..write('methodId: $methodId, ')
          ..write('json: $json, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, methodId, json, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRecipe &&
          other.id == this.id &&
          other.methodId == this.methodId &&
          other.json == this.json &&
          other.updatedAt == this.updatedAt);
}

class UserRecipesCompanion extends UpdateCompanion<UserRecipe> {
  final Value<String> id;
  final Value<String> methodId;
  final Value<String> json;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserRecipesCompanion({
    this.id = const Value.absent(),
    this.methodId = const Value.absent(),
    this.json = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserRecipesCompanion.insert({
    required String id,
    required String methodId,
    required String json,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       methodId = Value(methodId),
       json = Value(json),
       updatedAt = Value(updatedAt);
  static Insertable<UserRecipe> custom({
    Expression<String>? id,
    Expression<String>? methodId,
    Expression<String>? json,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (methodId != null) 'method_id': methodId,
      if (json != null) 'json': json,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserRecipesCompanion copyWith({
    Value<String>? id,
    Value<String>? methodId,
    Value<String>? json,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserRecipesCompanion(
      id: id ?? this.id,
      methodId: methodId ?? this.methodId,
      json: json ?? this.json,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (methodId.present) {
      map['method_id'] = Variable<String>(methodId.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
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
    return (StringBuffer('UserRecipesCompanion(')
          ..write('id: $id, ')
          ..write('methodId: $methodId, ')
          ..write('json: $json, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [recipeId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Favorite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recipeId};
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final String recipeId;
  const Favorite({required this.recipeId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['recipe_id'] = Variable<String>(recipeId);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(recipeId: Value(recipeId));
  }

  factory Favorite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(recipeId: serializer.fromJson<String>(json['recipeId']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'recipeId': serializer.toJson<String>(recipeId)};
  }

  Favorite copyWith({String? recipeId}) =>
      Favorite(recipeId: recipeId ?? this.recipeId);
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('recipeId: $recipeId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => recipeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite && other.recipeId == this.recipeId);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<String> recipeId;
  final Value<int> rowid;
  const FavoritesCompanion({
    this.recipeId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoritesCompanion.insert({
    required String recipeId,
    this.rowid = const Value.absent(),
  }) : recipeId = Value(recipeId);
  static Insertable<Favorite> custom({
    Expression<String>? recipeId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recipeId != null) 'recipe_id': recipeId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoritesCompanion copyWith({Value<String>? recipeId, Value<int>? rowid}) {
    return FavoritesCompanion(
      recipeId: recipeId ?? this.recipeId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('recipeId: $recipeId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BeansTable extends Beans with TableInfo<$BeansTable, Bean> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BeansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roasterMeta = const VerificationMeta(
    'roaster',
  );
  @override
  late final GeneratedColumn<String> roaster = GeneratedColumn<String>(
    'roaster',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _roastLevelMeta = const VerificationMeta(
    'roastLevel',
  );
  @override
  late final GeneratedColumn<String> roastLevel = GeneratedColumn<String>(
    'roast_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  static const VerificationMeta _roastDateMeta = const VerificationMeta(
    'roastDate',
  );
  @override
  late final GeneratedColumn<DateTime> roastDate = GeneratedColumn<DateTime>(
    'roast_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _packageGMeta = const VerificationMeta(
    'packageG',
  );
  @override
  late final GeneratedColumn<double> packageG = GeneratedColumn<double>(
    'package_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remainingGMeta = const VerificationMeta(
    'remainingG',
  );
  @override
  late final GeneratedColumn<double> remainingG = GeneratedColumn<double>(
    'remaining_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    roaster,
    origin,
    roastLevel,
    roastDate,
    packageG,
    remainingG,
    archived,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'beans';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bean> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('roaster')) {
      context.handle(
        _roasterMeta,
        roaster.isAcceptableOrUnknown(data['roaster']!, _roasterMeta),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('roast_level')) {
      context.handle(
        _roastLevelMeta,
        roastLevel.isAcceptableOrUnknown(data['roast_level']!, _roastLevelMeta),
      );
    }
    if (data.containsKey('roast_date')) {
      context.handle(
        _roastDateMeta,
        roastDate.isAcceptableOrUnknown(data['roast_date']!, _roastDateMeta),
      );
    }
    if (data.containsKey('package_g')) {
      context.handle(
        _packageGMeta,
        packageG.isAcceptableOrUnknown(data['package_g']!, _packageGMeta),
      );
    }
    if (data.containsKey('remaining_g')) {
      context.handle(
        _remainingGMeta,
        remainingG.isAcceptableOrUnknown(data['remaining_g']!, _remainingGMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bean map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bean(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      roaster: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}roaster'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      roastLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}roast_level'],
      )!,
      roastDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}roast_date'],
      ),
      packageG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}package_g'],
      ),
      remainingG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}remaining_g'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BeansTable createAlias(String alias) {
    return $BeansTable(attachedDatabase, alias);
  }
}

class Bean extends DataClass implements Insertable<Bean> {
  final String id;
  final String name;
  final String roaster;
  final String origin;
  final String roastLevel;
  final DateTime? roastDate;
  final double? packageG;
  final double? remainingG;
  final bool archived;
  final DateTime createdAt;
  const Bean({
    required this.id,
    required this.name,
    required this.roaster,
    required this.origin,
    required this.roastLevel,
    this.roastDate,
    this.packageG,
    this.remainingG,
    required this.archived,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['roaster'] = Variable<String>(roaster);
    map['origin'] = Variable<String>(origin);
    map['roast_level'] = Variable<String>(roastLevel);
    if (!nullToAbsent || roastDate != null) {
      map['roast_date'] = Variable<DateTime>(roastDate);
    }
    if (!nullToAbsent || packageG != null) {
      map['package_g'] = Variable<double>(packageG);
    }
    if (!nullToAbsent || remainingG != null) {
      map['remaining_g'] = Variable<double>(remainingG);
    }
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BeansCompanion toCompanion(bool nullToAbsent) {
    return BeansCompanion(
      id: Value(id),
      name: Value(name),
      roaster: Value(roaster),
      origin: Value(origin),
      roastLevel: Value(roastLevel),
      roastDate: roastDate == null && nullToAbsent
          ? const Value.absent()
          : Value(roastDate),
      packageG: packageG == null && nullToAbsent
          ? const Value.absent()
          : Value(packageG),
      remainingG: remainingG == null && nullToAbsent
          ? const Value.absent()
          : Value(remainingG),
      archived: Value(archived),
      createdAt: Value(createdAt),
    );
  }

  factory Bean.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bean(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      roaster: serializer.fromJson<String>(json['roaster']),
      origin: serializer.fromJson<String>(json['origin']),
      roastLevel: serializer.fromJson<String>(json['roastLevel']),
      roastDate: serializer.fromJson<DateTime?>(json['roastDate']),
      packageG: serializer.fromJson<double?>(json['packageG']),
      remainingG: serializer.fromJson<double?>(json['remainingG']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'roaster': serializer.toJson<String>(roaster),
      'origin': serializer.toJson<String>(origin),
      'roastLevel': serializer.toJson<String>(roastLevel),
      'roastDate': serializer.toJson<DateTime?>(roastDate),
      'packageG': serializer.toJson<double?>(packageG),
      'remainingG': serializer.toJson<double?>(remainingG),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Bean copyWith({
    String? id,
    String? name,
    String? roaster,
    String? origin,
    String? roastLevel,
    Value<DateTime?> roastDate = const Value.absent(),
    Value<double?> packageG = const Value.absent(),
    Value<double?> remainingG = const Value.absent(),
    bool? archived,
    DateTime? createdAt,
  }) => Bean(
    id: id ?? this.id,
    name: name ?? this.name,
    roaster: roaster ?? this.roaster,
    origin: origin ?? this.origin,
    roastLevel: roastLevel ?? this.roastLevel,
    roastDate: roastDate.present ? roastDate.value : this.roastDate,
    packageG: packageG.present ? packageG.value : this.packageG,
    remainingG: remainingG.present ? remainingG.value : this.remainingG,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
  );
  Bean copyWithCompanion(BeansCompanion data) {
    return Bean(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      roaster: data.roaster.present ? data.roaster.value : this.roaster,
      origin: data.origin.present ? data.origin.value : this.origin,
      roastLevel: data.roastLevel.present
          ? data.roastLevel.value
          : this.roastLevel,
      roastDate: data.roastDate.present ? data.roastDate.value : this.roastDate,
      packageG: data.packageG.present ? data.packageG.value : this.packageG,
      remainingG: data.remainingG.present
          ? data.remainingG.value
          : this.remainingG,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bean(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('roaster: $roaster, ')
          ..write('origin: $origin, ')
          ..write('roastLevel: $roastLevel, ')
          ..write('roastDate: $roastDate, ')
          ..write('packageG: $packageG, ')
          ..write('remainingG: $remainingG, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    roaster,
    origin,
    roastLevel,
    roastDate,
    packageG,
    remainingG,
    archived,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bean &&
          other.id == this.id &&
          other.name == this.name &&
          other.roaster == this.roaster &&
          other.origin == this.origin &&
          other.roastLevel == this.roastLevel &&
          other.roastDate == this.roastDate &&
          other.packageG == this.packageG &&
          other.remainingG == this.remainingG &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt);
}

class BeansCompanion extends UpdateCompanion<Bean> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> roaster;
  final Value<String> origin;
  final Value<String> roastLevel;
  final Value<DateTime?> roastDate;
  final Value<double?> packageG;
  final Value<double?> remainingG;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const BeansCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.roaster = const Value.absent(),
    this.origin = const Value.absent(),
    this.roastLevel = const Value.absent(),
    this.roastDate = const Value.absent(),
    this.packageG = const Value.absent(),
    this.remainingG = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BeansCompanion.insert({
    required String id,
    required String name,
    this.roaster = const Value.absent(),
    this.origin = const Value.absent(),
    this.roastLevel = const Value.absent(),
    this.roastDate = const Value.absent(),
    this.packageG = const Value.absent(),
    this.remainingG = const Value.absent(),
    this.archived = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Bean> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? roaster,
    Expression<String>? origin,
    Expression<String>? roastLevel,
    Expression<DateTime>? roastDate,
    Expression<double>? packageG,
    Expression<double>? remainingG,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (roaster != null) 'roaster': roaster,
      if (origin != null) 'origin': origin,
      if (roastLevel != null) 'roast_level': roastLevel,
      if (roastDate != null) 'roast_date': roastDate,
      if (packageG != null) 'package_g': packageG,
      if (remainingG != null) 'remaining_g': remainingG,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BeansCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? roaster,
    Value<String>? origin,
    Value<String>? roastLevel,
    Value<DateTime?>? roastDate,
    Value<double?>? packageG,
    Value<double?>? remainingG,
    Value<bool>? archived,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return BeansCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      roaster: roaster ?? this.roaster,
      origin: origin ?? this.origin,
      roastLevel: roastLevel ?? this.roastLevel,
      roastDate: roastDate ?? this.roastDate,
      packageG: packageG ?? this.packageG,
      remainingG: remainingG ?? this.remainingG,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (roaster.present) {
      map['roaster'] = Variable<String>(roaster.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (roastLevel.present) {
      map['roast_level'] = Variable<String>(roastLevel.value);
    }
    if (roastDate.present) {
      map['roast_date'] = Variable<DateTime>(roastDate.value);
    }
    if (packageG.present) {
      map['package_g'] = Variable<double>(packageG.value);
    }
    if (remainingG.present) {
      map['remaining_g'] = Variable<double>(remainingG.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BeansCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('roaster: $roaster, ')
          ..write('origin: $origin, ')
          ..write('roastLevel: $roastLevel, ')
          ..write('roastDate: $roastDate, ')
          ..write('packageG: $packageG, ')
          ..write('remainingG: $remainingG, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BrewsTable extends Brews with TableInfo<$BrewsTable, Brew> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BrewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brewedAtMeta = const VerificationMeta(
    'brewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> brewedAt = GeneratedColumn<DateTime>(
    'brewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineageIdMeta = const VerificationMeta(
    'lineageId',
  );
  @override
  late final GeneratedColumn<String> lineageId = GeneratedColumn<String>(
    'lineage_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodIdMeta = const VerificationMeta(
    'methodId',
  );
  @override
  late final GeneratedColumn<String> methodId = GeneratedColumn<String>(
    'method_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipeJsonMeta = const VerificationMeta(
    'recipeJson',
  );
  @override
  late final GeneratedColumn<String> recipeJson = GeneratedColumn<String>(
    'recipe_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _beanIdMeta = const VerificationMeta('beanId');
  @override
  late final GeneratedColumn<String> beanId = GeneratedColumn<String>(
    'bean_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _equipmentJsonMeta = const VerificationMeta(
    'equipmentJson',
  );
  @override
  late final GeneratedColumn<String> equipmentJson = GeneratedColumn<String>(
    'equipment_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _actualTimeSMeta = const VerificationMeta(
    'actualTimeS',
  );
  @override
  late final GeneratedColumn<int> actualTimeS = GeneratedColumn<int>(
    'actual_time_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assessmentJsonMeta = const VerificationMeta(
    'assessmentJson',
  );
  @override
  late final GeneratedColumn<String> assessmentJson = GeneratedColumn<String>(
    'assessment_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _correctionJsonMeta = const VerificationMeta(
    'correctionJson',
  );
  @override
  late final GeneratedColumn<String> correctionJson = GeneratedColumn<String>(
    'correction_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _correctionAcceptedMeta =
      const VerificationMeta('correctionAccepted');
  @override
  late final GeneratedColumn<bool> correctionAccepted = GeneratedColumn<bool>(
    'correction_accepted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("correction_accepted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _manualMeta = const VerificationMeta('manual');
  @override
  late final GeneratedColumn<bool> manual = GeneratedColumn<bool>(
    'manual',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("manual" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _actualCoffeeGMeta = const VerificationMeta(
    'actualCoffeeG',
  );
  @override
  late final GeneratedColumn<double> actualCoffeeG = GeneratedColumn<double>(
    'actual_coffee_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualWaterGMeta = const VerificationMeta(
    'actualWaterG',
  );
  @override
  late final GeneratedColumn<double> actualWaterG = GeneratedColumn<double>(
    'actual_water_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    brewedAt,
    recipeId,
    lineageId,
    methodId,
    recipeJson,
    beanId,
    equipmentJson,
    actualTimeS,
    assessmentJson,
    score,
    correctionJson,
    correctionAccepted,
    notes,
    manual,
    actualCoffeeG,
    actualWaterG,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'brews';
  @override
  VerificationContext validateIntegrity(
    Insertable<Brew> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('brewed_at')) {
      context.handle(
        _brewedAtMeta,
        brewedAt.isAcceptableOrUnknown(data['brewed_at']!, _brewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_brewedAtMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('lineage_id')) {
      context.handle(
        _lineageIdMeta,
        lineageId.isAcceptableOrUnknown(data['lineage_id']!, _lineageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lineageIdMeta);
    }
    if (data.containsKey('method_id')) {
      context.handle(
        _methodIdMeta,
        methodId.isAcceptableOrUnknown(data['method_id']!, _methodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_methodIdMeta);
    }
    if (data.containsKey('recipe_json')) {
      context.handle(
        _recipeJsonMeta,
        recipeJson.isAcceptableOrUnknown(data['recipe_json']!, _recipeJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeJsonMeta);
    }
    if (data.containsKey('bean_id')) {
      context.handle(
        _beanIdMeta,
        beanId.isAcceptableOrUnknown(data['bean_id']!, _beanIdMeta),
      );
    }
    if (data.containsKey('equipment_json')) {
      context.handle(
        _equipmentJsonMeta,
        equipmentJson.isAcceptableOrUnknown(
          data['equipment_json']!,
          _equipmentJsonMeta,
        ),
      );
    }
    if (data.containsKey('actual_time_s')) {
      context.handle(
        _actualTimeSMeta,
        actualTimeS.isAcceptableOrUnknown(
          data['actual_time_s']!,
          _actualTimeSMeta,
        ),
      );
    }
    if (data.containsKey('assessment_json')) {
      context.handle(
        _assessmentJsonMeta,
        assessmentJson.isAcceptableOrUnknown(
          data['assessment_json']!,
          _assessmentJsonMeta,
        ),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('correction_json')) {
      context.handle(
        _correctionJsonMeta,
        correctionJson.isAcceptableOrUnknown(
          data['correction_json']!,
          _correctionJsonMeta,
        ),
      );
    }
    if (data.containsKey('correction_accepted')) {
      context.handle(
        _correctionAcceptedMeta,
        correctionAccepted.isAcceptableOrUnknown(
          data['correction_accepted']!,
          _correctionAcceptedMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('manual')) {
      context.handle(
        _manualMeta,
        manual.isAcceptableOrUnknown(data['manual']!, _manualMeta),
      );
    }
    if (data.containsKey('actual_coffee_g')) {
      context.handle(
        _actualCoffeeGMeta,
        actualCoffeeG.isAcceptableOrUnknown(
          data['actual_coffee_g']!,
          _actualCoffeeGMeta,
        ),
      );
    }
    if (data.containsKey('actual_water_g')) {
      context.handle(
        _actualWaterGMeta,
        actualWaterG.isAcceptableOrUnknown(
          data['actual_water_g']!,
          _actualWaterGMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Brew map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Brew(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      brewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}brewed_at'],
      )!,
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      lineageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lineage_id'],
      )!,
      methodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method_id'],
      )!,
      recipeJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_json'],
      )!,
      beanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bean_id'],
      ),
      equipmentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment_json'],
      )!,
      actualTimeS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_time_s'],
      ),
      assessmentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assessment_json'],
      ),
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      ),
      correctionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correction_json'],
      ),
      correctionAccepted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}correction_accepted'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      manual: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}manual'],
      )!,
      actualCoffeeG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}actual_coffee_g'],
      ),
      actualWaterG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}actual_water_g'],
      ),
    );
  }

  @override
  $BrewsTable createAlias(String alias) {
    return $BrewsTable(attachedDatabase, alias);
  }
}

class Brew extends DataClass implements Insertable<Brew> {
  final String id;
  final DateTime brewedAt;
  final String recipeId;

  /// Dial-in zinciri kimliği: kök (kaynak) tarifin kimliği.
  final String lineageId;
  final String methodId;
  final String recipeJson;
  final String? beanId;
  final String equipmentJson;
  final int? actualTimeS;
  final String? assessmentJson;
  final int? score;
  final String? correctionJson;
  final bool correctionAccepted;
  final String notes;
  final bool manual;

  /// Terazide tartılan kahve (g); yalnız sonuç değeri saklanır
  /// (KHV-FR-SCL-009). Şema v2.
  final double? actualCoffeeG;

  /// Terazide ölçülen toplam su veya espresso çıktısı (g). Şema v2.
  final double? actualWaterG;
  const Brew({
    required this.id,
    required this.brewedAt,
    required this.recipeId,
    required this.lineageId,
    required this.methodId,
    required this.recipeJson,
    this.beanId,
    required this.equipmentJson,
    this.actualTimeS,
    this.assessmentJson,
    this.score,
    this.correctionJson,
    required this.correctionAccepted,
    required this.notes,
    required this.manual,
    this.actualCoffeeG,
    this.actualWaterG,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['brewed_at'] = Variable<DateTime>(brewedAt);
    map['recipe_id'] = Variable<String>(recipeId);
    map['lineage_id'] = Variable<String>(lineageId);
    map['method_id'] = Variable<String>(methodId);
    map['recipe_json'] = Variable<String>(recipeJson);
    if (!nullToAbsent || beanId != null) {
      map['bean_id'] = Variable<String>(beanId);
    }
    map['equipment_json'] = Variable<String>(equipmentJson);
    if (!nullToAbsent || actualTimeS != null) {
      map['actual_time_s'] = Variable<int>(actualTimeS);
    }
    if (!nullToAbsent || assessmentJson != null) {
      map['assessment_json'] = Variable<String>(assessmentJson);
    }
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<int>(score);
    }
    if (!nullToAbsent || correctionJson != null) {
      map['correction_json'] = Variable<String>(correctionJson);
    }
    map['correction_accepted'] = Variable<bool>(correctionAccepted);
    map['notes'] = Variable<String>(notes);
    map['manual'] = Variable<bool>(manual);
    if (!nullToAbsent || actualCoffeeG != null) {
      map['actual_coffee_g'] = Variable<double>(actualCoffeeG);
    }
    if (!nullToAbsent || actualWaterG != null) {
      map['actual_water_g'] = Variable<double>(actualWaterG);
    }
    return map;
  }

  BrewsCompanion toCompanion(bool nullToAbsent) {
    return BrewsCompanion(
      id: Value(id),
      brewedAt: Value(brewedAt),
      recipeId: Value(recipeId),
      lineageId: Value(lineageId),
      methodId: Value(methodId),
      recipeJson: Value(recipeJson),
      beanId: beanId == null && nullToAbsent
          ? const Value.absent()
          : Value(beanId),
      equipmentJson: Value(equipmentJson),
      actualTimeS: actualTimeS == null && nullToAbsent
          ? const Value.absent()
          : Value(actualTimeS),
      assessmentJson: assessmentJson == null && nullToAbsent
          ? const Value.absent()
          : Value(assessmentJson),
      score: score == null && nullToAbsent
          ? const Value.absent()
          : Value(score),
      correctionJson: correctionJson == null && nullToAbsent
          ? const Value.absent()
          : Value(correctionJson),
      correctionAccepted: Value(correctionAccepted),
      notes: Value(notes),
      manual: Value(manual),
      actualCoffeeG: actualCoffeeG == null && nullToAbsent
          ? const Value.absent()
          : Value(actualCoffeeG),
      actualWaterG: actualWaterG == null && nullToAbsent
          ? const Value.absent()
          : Value(actualWaterG),
    );
  }

  factory Brew.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Brew(
      id: serializer.fromJson<String>(json['id']),
      brewedAt: serializer.fromJson<DateTime>(json['brewedAt']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      lineageId: serializer.fromJson<String>(json['lineageId']),
      methodId: serializer.fromJson<String>(json['methodId']),
      recipeJson: serializer.fromJson<String>(json['recipeJson']),
      beanId: serializer.fromJson<String?>(json['beanId']),
      equipmentJson: serializer.fromJson<String>(json['equipmentJson']),
      actualTimeS: serializer.fromJson<int?>(json['actualTimeS']),
      assessmentJson: serializer.fromJson<String?>(json['assessmentJson']),
      score: serializer.fromJson<int?>(json['score']),
      correctionJson: serializer.fromJson<String?>(json['correctionJson']),
      correctionAccepted: serializer.fromJson<bool>(json['correctionAccepted']),
      notes: serializer.fromJson<String>(json['notes']),
      manual: serializer.fromJson<bool>(json['manual']),
      actualCoffeeG: serializer.fromJson<double?>(json['actualCoffeeG']),
      actualWaterG: serializer.fromJson<double?>(json['actualWaterG']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'brewedAt': serializer.toJson<DateTime>(brewedAt),
      'recipeId': serializer.toJson<String>(recipeId),
      'lineageId': serializer.toJson<String>(lineageId),
      'methodId': serializer.toJson<String>(methodId),
      'recipeJson': serializer.toJson<String>(recipeJson),
      'beanId': serializer.toJson<String?>(beanId),
      'equipmentJson': serializer.toJson<String>(equipmentJson),
      'actualTimeS': serializer.toJson<int?>(actualTimeS),
      'assessmentJson': serializer.toJson<String?>(assessmentJson),
      'score': serializer.toJson<int?>(score),
      'correctionJson': serializer.toJson<String?>(correctionJson),
      'correctionAccepted': serializer.toJson<bool>(correctionAccepted),
      'notes': serializer.toJson<String>(notes),
      'manual': serializer.toJson<bool>(manual),
      'actualCoffeeG': serializer.toJson<double?>(actualCoffeeG),
      'actualWaterG': serializer.toJson<double?>(actualWaterG),
    };
  }

  Brew copyWith({
    String? id,
    DateTime? brewedAt,
    String? recipeId,
    String? lineageId,
    String? methodId,
    String? recipeJson,
    Value<String?> beanId = const Value.absent(),
    String? equipmentJson,
    Value<int?> actualTimeS = const Value.absent(),
    Value<String?> assessmentJson = const Value.absent(),
    Value<int?> score = const Value.absent(),
    Value<String?> correctionJson = const Value.absent(),
    bool? correctionAccepted,
    String? notes,
    bool? manual,
    Value<double?> actualCoffeeG = const Value.absent(),
    Value<double?> actualWaterG = const Value.absent(),
  }) => Brew(
    id: id ?? this.id,
    brewedAt: brewedAt ?? this.brewedAt,
    recipeId: recipeId ?? this.recipeId,
    lineageId: lineageId ?? this.lineageId,
    methodId: methodId ?? this.methodId,
    recipeJson: recipeJson ?? this.recipeJson,
    beanId: beanId.present ? beanId.value : this.beanId,
    equipmentJson: equipmentJson ?? this.equipmentJson,
    actualTimeS: actualTimeS.present ? actualTimeS.value : this.actualTimeS,
    assessmentJson: assessmentJson.present
        ? assessmentJson.value
        : this.assessmentJson,
    score: score.present ? score.value : this.score,
    correctionJson: correctionJson.present
        ? correctionJson.value
        : this.correctionJson,
    correctionAccepted: correctionAccepted ?? this.correctionAccepted,
    notes: notes ?? this.notes,
    manual: manual ?? this.manual,
    actualCoffeeG: actualCoffeeG.present
        ? actualCoffeeG.value
        : this.actualCoffeeG,
    actualWaterG: actualWaterG.present ? actualWaterG.value : this.actualWaterG,
  );
  Brew copyWithCompanion(BrewsCompanion data) {
    return Brew(
      id: data.id.present ? data.id.value : this.id,
      brewedAt: data.brewedAt.present ? data.brewedAt.value : this.brewedAt,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      lineageId: data.lineageId.present ? data.lineageId.value : this.lineageId,
      methodId: data.methodId.present ? data.methodId.value : this.methodId,
      recipeJson: data.recipeJson.present
          ? data.recipeJson.value
          : this.recipeJson,
      beanId: data.beanId.present ? data.beanId.value : this.beanId,
      equipmentJson: data.equipmentJson.present
          ? data.equipmentJson.value
          : this.equipmentJson,
      actualTimeS: data.actualTimeS.present
          ? data.actualTimeS.value
          : this.actualTimeS,
      assessmentJson: data.assessmentJson.present
          ? data.assessmentJson.value
          : this.assessmentJson,
      score: data.score.present ? data.score.value : this.score,
      correctionJson: data.correctionJson.present
          ? data.correctionJson.value
          : this.correctionJson,
      correctionAccepted: data.correctionAccepted.present
          ? data.correctionAccepted.value
          : this.correctionAccepted,
      notes: data.notes.present ? data.notes.value : this.notes,
      manual: data.manual.present ? data.manual.value : this.manual,
      actualCoffeeG: data.actualCoffeeG.present
          ? data.actualCoffeeG.value
          : this.actualCoffeeG,
      actualWaterG: data.actualWaterG.present
          ? data.actualWaterG.value
          : this.actualWaterG,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Brew(')
          ..write('id: $id, ')
          ..write('brewedAt: $brewedAt, ')
          ..write('recipeId: $recipeId, ')
          ..write('lineageId: $lineageId, ')
          ..write('methodId: $methodId, ')
          ..write('recipeJson: $recipeJson, ')
          ..write('beanId: $beanId, ')
          ..write('equipmentJson: $equipmentJson, ')
          ..write('actualTimeS: $actualTimeS, ')
          ..write('assessmentJson: $assessmentJson, ')
          ..write('score: $score, ')
          ..write('correctionJson: $correctionJson, ')
          ..write('correctionAccepted: $correctionAccepted, ')
          ..write('notes: $notes, ')
          ..write('manual: $manual, ')
          ..write('actualCoffeeG: $actualCoffeeG, ')
          ..write('actualWaterG: $actualWaterG')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    brewedAt,
    recipeId,
    lineageId,
    methodId,
    recipeJson,
    beanId,
    equipmentJson,
    actualTimeS,
    assessmentJson,
    score,
    correctionJson,
    correctionAccepted,
    notes,
    manual,
    actualCoffeeG,
    actualWaterG,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Brew &&
          other.id == this.id &&
          other.brewedAt == this.brewedAt &&
          other.recipeId == this.recipeId &&
          other.lineageId == this.lineageId &&
          other.methodId == this.methodId &&
          other.recipeJson == this.recipeJson &&
          other.beanId == this.beanId &&
          other.equipmentJson == this.equipmentJson &&
          other.actualTimeS == this.actualTimeS &&
          other.assessmentJson == this.assessmentJson &&
          other.score == this.score &&
          other.correctionJson == this.correctionJson &&
          other.correctionAccepted == this.correctionAccepted &&
          other.notes == this.notes &&
          other.manual == this.manual &&
          other.actualCoffeeG == this.actualCoffeeG &&
          other.actualWaterG == this.actualWaterG);
}

class BrewsCompanion extends UpdateCompanion<Brew> {
  final Value<String> id;
  final Value<DateTime> brewedAt;
  final Value<String> recipeId;
  final Value<String> lineageId;
  final Value<String> methodId;
  final Value<String> recipeJson;
  final Value<String?> beanId;
  final Value<String> equipmentJson;
  final Value<int?> actualTimeS;
  final Value<String?> assessmentJson;
  final Value<int?> score;
  final Value<String?> correctionJson;
  final Value<bool> correctionAccepted;
  final Value<String> notes;
  final Value<bool> manual;
  final Value<double?> actualCoffeeG;
  final Value<double?> actualWaterG;
  final Value<int> rowid;
  const BrewsCompanion({
    this.id = const Value.absent(),
    this.brewedAt = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.lineageId = const Value.absent(),
    this.methodId = const Value.absent(),
    this.recipeJson = const Value.absent(),
    this.beanId = const Value.absent(),
    this.equipmentJson = const Value.absent(),
    this.actualTimeS = const Value.absent(),
    this.assessmentJson = const Value.absent(),
    this.score = const Value.absent(),
    this.correctionJson = const Value.absent(),
    this.correctionAccepted = const Value.absent(),
    this.notes = const Value.absent(),
    this.manual = const Value.absent(),
    this.actualCoffeeG = const Value.absent(),
    this.actualWaterG = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BrewsCompanion.insert({
    required String id,
    required DateTime brewedAt,
    required String recipeId,
    required String lineageId,
    required String methodId,
    required String recipeJson,
    this.beanId = const Value.absent(),
    this.equipmentJson = const Value.absent(),
    this.actualTimeS = const Value.absent(),
    this.assessmentJson = const Value.absent(),
    this.score = const Value.absent(),
    this.correctionJson = const Value.absent(),
    this.correctionAccepted = const Value.absent(),
    this.notes = const Value.absent(),
    this.manual = const Value.absent(),
    this.actualCoffeeG = const Value.absent(),
    this.actualWaterG = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       brewedAt = Value(brewedAt),
       recipeId = Value(recipeId),
       lineageId = Value(lineageId),
       methodId = Value(methodId),
       recipeJson = Value(recipeJson);
  static Insertable<Brew> custom({
    Expression<String>? id,
    Expression<DateTime>? brewedAt,
    Expression<String>? recipeId,
    Expression<String>? lineageId,
    Expression<String>? methodId,
    Expression<String>? recipeJson,
    Expression<String>? beanId,
    Expression<String>? equipmentJson,
    Expression<int>? actualTimeS,
    Expression<String>? assessmentJson,
    Expression<int>? score,
    Expression<String>? correctionJson,
    Expression<bool>? correctionAccepted,
    Expression<String>? notes,
    Expression<bool>? manual,
    Expression<double>? actualCoffeeG,
    Expression<double>? actualWaterG,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (brewedAt != null) 'brewed_at': brewedAt,
      if (recipeId != null) 'recipe_id': recipeId,
      if (lineageId != null) 'lineage_id': lineageId,
      if (methodId != null) 'method_id': methodId,
      if (recipeJson != null) 'recipe_json': recipeJson,
      if (beanId != null) 'bean_id': beanId,
      if (equipmentJson != null) 'equipment_json': equipmentJson,
      if (actualTimeS != null) 'actual_time_s': actualTimeS,
      if (assessmentJson != null) 'assessment_json': assessmentJson,
      if (score != null) 'score': score,
      if (correctionJson != null) 'correction_json': correctionJson,
      if (correctionAccepted != null) 'correction_accepted': correctionAccepted,
      if (notes != null) 'notes': notes,
      if (manual != null) 'manual': manual,
      if (actualCoffeeG != null) 'actual_coffee_g': actualCoffeeG,
      if (actualWaterG != null) 'actual_water_g': actualWaterG,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BrewsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? brewedAt,
    Value<String>? recipeId,
    Value<String>? lineageId,
    Value<String>? methodId,
    Value<String>? recipeJson,
    Value<String?>? beanId,
    Value<String>? equipmentJson,
    Value<int?>? actualTimeS,
    Value<String?>? assessmentJson,
    Value<int?>? score,
    Value<String?>? correctionJson,
    Value<bool>? correctionAccepted,
    Value<String>? notes,
    Value<bool>? manual,
    Value<double?>? actualCoffeeG,
    Value<double?>? actualWaterG,
    Value<int>? rowid,
  }) {
    return BrewsCompanion(
      id: id ?? this.id,
      brewedAt: brewedAt ?? this.brewedAt,
      recipeId: recipeId ?? this.recipeId,
      lineageId: lineageId ?? this.lineageId,
      methodId: methodId ?? this.methodId,
      recipeJson: recipeJson ?? this.recipeJson,
      beanId: beanId ?? this.beanId,
      equipmentJson: equipmentJson ?? this.equipmentJson,
      actualTimeS: actualTimeS ?? this.actualTimeS,
      assessmentJson: assessmentJson ?? this.assessmentJson,
      score: score ?? this.score,
      correctionJson: correctionJson ?? this.correctionJson,
      correctionAccepted: correctionAccepted ?? this.correctionAccepted,
      notes: notes ?? this.notes,
      manual: manual ?? this.manual,
      actualCoffeeG: actualCoffeeG ?? this.actualCoffeeG,
      actualWaterG: actualWaterG ?? this.actualWaterG,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (brewedAt.present) {
      map['brewed_at'] = Variable<DateTime>(brewedAt.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (lineageId.present) {
      map['lineage_id'] = Variable<String>(lineageId.value);
    }
    if (methodId.present) {
      map['method_id'] = Variable<String>(methodId.value);
    }
    if (recipeJson.present) {
      map['recipe_json'] = Variable<String>(recipeJson.value);
    }
    if (beanId.present) {
      map['bean_id'] = Variable<String>(beanId.value);
    }
    if (equipmentJson.present) {
      map['equipment_json'] = Variable<String>(equipmentJson.value);
    }
    if (actualTimeS.present) {
      map['actual_time_s'] = Variable<int>(actualTimeS.value);
    }
    if (assessmentJson.present) {
      map['assessment_json'] = Variable<String>(assessmentJson.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (correctionJson.present) {
      map['correction_json'] = Variable<String>(correctionJson.value);
    }
    if (correctionAccepted.present) {
      map['correction_accepted'] = Variable<bool>(correctionAccepted.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (manual.present) {
      map['manual'] = Variable<bool>(manual.value);
    }
    if (actualCoffeeG.present) {
      map['actual_coffee_g'] = Variable<double>(actualCoffeeG.value);
    }
    if (actualWaterG.present) {
      map['actual_water_g'] = Variable<double>(actualWaterG.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BrewsCompanion(')
          ..write('id: $id, ')
          ..write('brewedAt: $brewedAt, ')
          ..write('recipeId: $recipeId, ')
          ..write('lineageId: $lineageId, ')
          ..write('methodId: $methodId, ')
          ..write('recipeJson: $recipeJson, ')
          ..write('beanId: $beanId, ')
          ..write('equipmentJson: $equipmentJson, ')
          ..write('actualTimeS: $actualTimeS, ')
          ..write('assessmentJson: $assessmentJson, ')
          ..write('score: $score, ')
          ..write('correctionJson: $correctionJson, ')
          ..write('correctionAccepted: $correctionAccepted, ')
          ..write('notes: $notes, ')
          ..write('manual: $manual, ')
          ..write('actualCoffeeG: $actualCoffeeG, ')
          ..write('actualWaterG: $actualWaterG, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventLogTable extends EventLog
    with TableInfo<$EventLogTable, EventLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventLogTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, at, type, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $EventLogTable createAlias(String alias) {
    return $EventLogTable(attachedDatabase, alias);
  }
}

class EventLogData extends DataClass implements Insertable<EventLogData> {
  final int id;
  final DateTime at;
  final String type;
  final String payload;
  const EventLogData({
    required this.id,
    required this.at,
    required this.type,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['type'] = Variable<String>(type);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  EventLogCompanion toCompanion(bool nullToAbsent) {
    return EventLogCompanion(
      id: Value(id),
      at: Value(at),
      type: Value(type),
      payload: Value(payload),
    );
  }

  factory EventLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventLogData(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      type: serializer.fromJson<String>(json['type']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'type': serializer.toJson<String>(type),
      'payload': serializer.toJson<String>(payload),
    };
  }

  EventLogData copyWith({
    int? id,
    DateTime? at,
    String? type,
    String? payload,
  }) => EventLogData(
    id: id ?? this.id,
    at: at ?? this.at,
    type: type ?? this.type,
    payload: payload ?? this.payload,
  );
  EventLogData copyWithCompanion(EventLogCompanion data) {
    return EventLogData(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      type: data.type.present ? data.type.value : this.type,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventLogData(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('type: $type, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, at, type, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventLogData &&
          other.id == this.id &&
          other.at == this.at &&
          other.type == this.type &&
          other.payload == this.payload);
}

class EventLogCompanion extends UpdateCompanion<EventLogData> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<String> type;
  final Value<String> payload;
  const EventLogCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.type = const Value.absent(),
    this.payload = const Value.absent(),
  });
  EventLogCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required String type,
    this.payload = const Value.absent(),
  }) : at = Value(at),
       type = Value(type);
  static Insertable<EventLogData> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<String>? type,
    Expression<String>? payload,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (type != null) 'type': type,
      if (payload != null) 'payload': payload,
    });
  }

  EventLogCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<String>? type,
    Value<String>? payload,
  }) {
    return EventLogCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      type: type ?? this.type,
      payload: payload ?? this.payload,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventLogCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('type: $type, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KvEntriesTable kvEntries = $KvEntriesTable(this);
  late final $UserRecipesTable userRecipes = $UserRecipesTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $BeansTable beans = $BeansTable(this);
  late final $BrewsTable brews = $BrewsTable(this);
  late final $EventLogTable eventLog = $EventLogTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    kvEntries,
    userRecipes,
    favorites,
    beans,
    brews,
    eventLog,
  ];
}

typedef $$KvEntriesTableCreateCompanionBuilder = KvEntriesCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$KvEntriesTableUpdateCompanionBuilder = KvEntriesCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$KvEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $KvEntriesTable> {
  $$KvEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KvEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $KvEntriesTable> {
  $$KvEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KvEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KvEntriesTable> {
  $$KvEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KvEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KvEntriesTable,
          KvEntry,
          $$KvEntriesTableFilterComposer,
          $$KvEntriesTableOrderingComposer,
          $$KvEntriesTableAnnotationComposer,
          $$KvEntriesTableCreateCompanionBuilder,
          $$KvEntriesTableUpdateCompanionBuilder,
          (KvEntry, BaseReferences<_$AppDatabase, $KvEntriesTable, KvEntry>),
          KvEntry,
          PrefetchHooks Function()
        > {
  $$KvEntriesTableTableManager(_$AppDatabase db, $KvEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KvEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KvEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KvEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => KvEntriesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => KvEntriesCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KvEntriesTable, KvEntry>(table),
                  BaseReferences<_$AppDatabase, $KvEntriesTable, KvEntry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KvEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KvEntriesTable,
      KvEntry,
      $$KvEntriesTableFilterComposer,
      $$KvEntriesTableOrderingComposer,
      $$KvEntriesTableAnnotationComposer,
      $$KvEntriesTableCreateCompanionBuilder,
      $$KvEntriesTableUpdateCompanionBuilder,
      (KvEntry, BaseReferences<_$AppDatabase, $KvEntriesTable, KvEntry>),
      KvEntry,
      PrefetchHooks Function()
    >;
typedef $$UserRecipesTableCreateCompanionBuilder =
    UserRecipesCompanion Function({
      required String id,
      required String methodId,
      required String json,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$UserRecipesTableUpdateCompanionBuilder =
    UserRecipesCompanion Function({
      Value<String> id,
      Value<String> methodId,
      Value<String> json,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UserRecipesTableFilterComposer
    extends Composer<_$AppDatabase, $UserRecipesTable> {
  $$UserRecipesTableFilterComposer({
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

  ColumnFilters<String> get methodId => $composableBuilder(
    column: $table.methodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserRecipesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserRecipesTable> {
  $$UserRecipesTableOrderingComposer({
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

  ColumnOrderings<String> get methodId => $composableBuilder(
    column: $table.methodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserRecipesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserRecipesTable> {
  $$UserRecipesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get methodId =>
      $composableBuilder(column: $table.methodId, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserRecipesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserRecipesTable,
          UserRecipe,
          $$UserRecipesTableFilterComposer,
          $$UserRecipesTableOrderingComposer,
          $$UserRecipesTableAnnotationComposer,
          $$UserRecipesTableCreateCompanionBuilder,
          $$UserRecipesTableUpdateCompanionBuilder,
          (
            UserRecipe,
            BaseReferences<_$AppDatabase, $UserRecipesTable, UserRecipe>,
          ),
          UserRecipe,
          PrefetchHooks Function()
        > {
  $$UserRecipesTableTableManager(_$AppDatabase db, $UserRecipesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserRecipesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserRecipesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserRecipesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> methodId = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserRecipesCompanion(
                id: id,
                methodId: methodId,
                json: json,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String methodId,
                required String json,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UserRecipesCompanion.insert(
                id: id,
                methodId: methodId,
                json: json,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserRecipesTable, UserRecipe>(table),
                  BaseReferences<_$AppDatabase, $UserRecipesTable, UserRecipe>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserRecipesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserRecipesTable,
      UserRecipe,
      $$UserRecipesTableFilterComposer,
      $$UserRecipesTableOrderingComposer,
      $$UserRecipesTableAnnotationComposer,
      $$UserRecipesTableCreateCompanionBuilder,
      $$UserRecipesTableUpdateCompanionBuilder,
      (
        UserRecipe,
        BaseReferences<_$AppDatabase, $UserRecipesTable, UserRecipe>,
      ),
      UserRecipe,
      PrefetchHooks Function()
    >;
typedef $$FavoritesTableCreateCompanionBuilder = FavoritesCompanion Function({
  required String recipeId,
  Value<int> rowid,
});
typedef $$FavoritesTableUpdateCompanionBuilder = FavoritesCompanion Function({
  Value<String> recipeId,
  Value<int> rowid,
});

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get recipeId =>
      $composableBuilder(column: $table.recipeId, builder: (column) => column);
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoritesTable,
          Favorite,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (Favorite, BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>),
          Favorite,
          PrefetchHooks Function()
        > {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> recipeId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => FavoritesCompanion(recipeId: recipeId, rowid: rowid),
          createCompanionCallback: ({
            required String recipeId,
            Value<int> rowid = const Value.absent(),
          }) => FavoritesCompanion.insert(recipeId: recipeId, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoritesTable, Favorite>(table),
                  BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoritesTable,
      Favorite,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (Favorite, BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>),
      Favorite,
      PrefetchHooks Function()
    >;
typedef $$BeansTableCreateCompanionBuilder = BeansCompanion Function({
  required String id,
  required String name,
  Value<String> roaster,
  Value<String> origin,
  Value<String> roastLevel,
  Value<DateTime?> roastDate,
  Value<double?> packageG,
  Value<double?> remainingG,
  Value<bool> archived,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$BeansTableUpdateCompanionBuilder = BeansCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> roaster,
  Value<String> origin,
  Value<String> roastLevel,
  Value<DateTime?> roastDate,
  Value<double?> packageG,
  Value<double?> remainingG,
  Value<bool> archived,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$BeansTableFilterComposer extends Composer<_$AppDatabase, $BeansTable> {
  $$BeansTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roaster => $composableBuilder(
    column: $table.roaster,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roastLevel => $composableBuilder(
    column: $table.roastLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get roastDate => $composableBuilder(
    column: $table.roastDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get packageG => $composableBuilder(
    column: $table.packageG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get remainingG => $composableBuilder(
    column: $table.remainingG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BeansTableOrderingComposer
    extends Composer<_$AppDatabase, $BeansTable> {
  $$BeansTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roaster => $composableBuilder(
    column: $table.roaster,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roastLevel => $composableBuilder(
    column: $table.roastLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get roastDate => $composableBuilder(
    column: $table.roastDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get packageG => $composableBuilder(
    column: $table.packageG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get remainingG => $composableBuilder(
    column: $table.remainingG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BeansTableAnnotationComposer
    extends Composer<_$AppDatabase, $BeansTable> {
  $$BeansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get roaster =>
      $composableBuilder(column: $table.roaster, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get roastLevel => $composableBuilder(
    column: $table.roastLevel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get roastDate =>
      $composableBuilder(column: $table.roastDate, builder: (column) => column);

  GeneratedColumn<double> get packageG =>
      $composableBuilder(column: $table.packageG, builder: (column) => column);

  GeneratedColumn<double> get remainingG => $composableBuilder(
    column: $table.remainingG,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BeansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BeansTable,
          Bean,
          $$BeansTableFilterComposer,
          $$BeansTableOrderingComposer,
          $$BeansTableAnnotationComposer,
          $$BeansTableCreateCompanionBuilder,
          $$BeansTableUpdateCompanionBuilder,
          (Bean, BaseReferences<_$AppDatabase, $BeansTable, Bean>),
          Bean,
          PrefetchHooks Function()
        > {
  $$BeansTableTableManager(_$AppDatabase db, $BeansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BeansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BeansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BeansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> roaster = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String> roastLevel = const Value.absent(),
                Value<DateTime?> roastDate = const Value.absent(),
                Value<double?> packageG = const Value.absent(),
                Value<double?> remainingG = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BeansCompanion(
                id: id,
                name: name,
                roaster: roaster,
                origin: origin,
                roastLevel: roastLevel,
                roastDate: roastDate,
                packageG: packageG,
                remainingG: remainingG,
                archived: archived,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> roaster = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String> roastLevel = const Value.absent(),
                Value<DateTime?> roastDate = const Value.absent(),
                Value<double?> packageG = const Value.absent(),
                Value<double?> remainingG = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => BeansCompanion.insert(
                id: id,
                name: name,
                roaster: roaster,
                origin: origin,
                roastLevel: roastLevel,
                roastDate: roastDate,
                packageG: packageG,
                remainingG: remainingG,
                archived: archived,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BeansTable, Bean>(table),
                  BaseReferences<_$AppDatabase, $BeansTable, Bean>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BeansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BeansTable,
      Bean,
      $$BeansTableFilterComposer,
      $$BeansTableOrderingComposer,
      $$BeansTableAnnotationComposer,
      $$BeansTableCreateCompanionBuilder,
      $$BeansTableUpdateCompanionBuilder,
      (Bean, BaseReferences<_$AppDatabase, $BeansTable, Bean>),
      Bean,
      PrefetchHooks Function()
    >;
typedef $$BrewsTableCreateCompanionBuilder = BrewsCompanion Function({
  required String id,
  required DateTime brewedAt,
  required String recipeId,
  required String lineageId,
  required String methodId,
  required String recipeJson,
  Value<String?> beanId,
  Value<String> equipmentJson,
  Value<int?> actualTimeS,
  Value<String?> assessmentJson,
  Value<int?> score,
  Value<String?> correctionJson,
  Value<bool> correctionAccepted,
  Value<String> notes,
  Value<bool> manual,
  Value<double?> actualCoffeeG,
  Value<double?> actualWaterG,
  Value<int> rowid,
});
typedef $$BrewsTableUpdateCompanionBuilder = BrewsCompanion Function({
  Value<String> id,
  Value<DateTime> brewedAt,
  Value<String> recipeId,
  Value<String> lineageId,
  Value<String> methodId,
  Value<String> recipeJson,
  Value<String?> beanId,
  Value<String> equipmentJson,
  Value<int?> actualTimeS,
  Value<String?> assessmentJson,
  Value<int?> score,
  Value<String?> correctionJson,
  Value<bool> correctionAccepted,
  Value<String> notes,
  Value<bool> manual,
  Value<double?> actualCoffeeG,
  Value<double?> actualWaterG,
  Value<int> rowid,
});

class $$BrewsTableFilterComposer extends Composer<_$AppDatabase, $BrewsTable> {
  $$BrewsTableFilterComposer({
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

  ColumnFilters<DateTime> get brewedAt => $composableBuilder(
    column: $table.brewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lineageId => $composableBuilder(
    column: $table.lineageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get methodId => $composableBuilder(
    column: $table.methodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipeJson => $composableBuilder(
    column: $table.recipeJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beanId => $composableBuilder(
    column: $table.beanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipmentJson => $composableBuilder(
    column: $table.equipmentJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualTimeS => $composableBuilder(
    column: $table.actualTimeS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assessmentJson => $composableBuilder(
    column: $table.assessmentJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctionJson => $composableBuilder(
    column: $table.correctionJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get correctionAccepted => $composableBuilder(
    column: $table.correctionAccepted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get manual => $composableBuilder(
    column: $table.manual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get actualCoffeeG => $composableBuilder(
    column: $table.actualCoffeeG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get actualWaterG => $composableBuilder(
    column: $table.actualWaterG,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BrewsTableOrderingComposer
    extends Composer<_$AppDatabase, $BrewsTable> {
  $$BrewsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get brewedAt => $composableBuilder(
    column: $table.brewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lineageId => $composableBuilder(
    column: $table.lineageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get methodId => $composableBuilder(
    column: $table.methodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipeJson => $composableBuilder(
    column: $table.recipeJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beanId => $composableBuilder(
    column: $table.beanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipmentJson => $composableBuilder(
    column: $table.equipmentJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualTimeS => $composableBuilder(
    column: $table.actualTimeS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assessmentJson => $composableBuilder(
    column: $table.assessmentJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctionJson => $composableBuilder(
    column: $table.correctionJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get correctionAccepted => $composableBuilder(
    column: $table.correctionAccepted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get manual => $composableBuilder(
    column: $table.manual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get actualCoffeeG => $composableBuilder(
    column: $table.actualCoffeeG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get actualWaterG => $composableBuilder(
    column: $table.actualWaterG,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BrewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BrewsTable> {
  $$BrewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get brewedAt =>
      $composableBuilder(column: $table.brewedAt, builder: (column) => column);

  GeneratedColumn<String> get recipeId =>
      $composableBuilder(column: $table.recipeId, builder: (column) => column);

  GeneratedColumn<String> get lineageId =>
      $composableBuilder(column: $table.lineageId, builder: (column) => column);

  GeneratedColumn<String> get methodId =>
      $composableBuilder(column: $table.methodId, builder: (column) => column);

  GeneratedColumn<String> get recipeJson => $composableBuilder(
    column: $table.recipeJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get beanId =>
      $composableBuilder(column: $table.beanId, builder: (column) => column);

  GeneratedColumn<String> get equipmentJson => $composableBuilder(
    column: $table.equipmentJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualTimeS => $composableBuilder(
    column: $table.actualTimeS,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assessmentJson => $composableBuilder(
    column: $table.assessmentJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get correctionJson => $composableBuilder(
    column: $table.correctionJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get correctionAccepted => $composableBuilder(
    column: $table.correctionAccepted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get manual =>
      $composableBuilder(column: $table.manual, builder: (column) => column);

  GeneratedColumn<double> get actualCoffeeG => $composableBuilder(
    column: $table.actualCoffeeG,
    builder: (column) => column,
  );

  GeneratedColumn<double> get actualWaterG => $composableBuilder(
    column: $table.actualWaterG,
    builder: (column) => column,
  );
}

class $$BrewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BrewsTable,
          Brew,
          $$BrewsTableFilterComposer,
          $$BrewsTableOrderingComposer,
          $$BrewsTableAnnotationComposer,
          $$BrewsTableCreateCompanionBuilder,
          $$BrewsTableUpdateCompanionBuilder,
          (Brew, BaseReferences<_$AppDatabase, $BrewsTable, Brew>),
          Brew,
          PrefetchHooks Function()
        > {
  $$BrewsTableTableManager(_$AppDatabase db, $BrewsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BrewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BrewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BrewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> brewedAt = const Value.absent(),
                Value<String> recipeId = const Value.absent(),
                Value<String> lineageId = const Value.absent(),
                Value<String> methodId = const Value.absent(),
                Value<String> recipeJson = const Value.absent(),
                Value<String?> beanId = const Value.absent(),
                Value<String> equipmentJson = const Value.absent(),
                Value<int?> actualTimeS = const Value.absent(),
                Value<String?> assessmentJson = const Value.absent(),
                Value<int?> score = const Value.absent(),
                Value<String?> correctionJson = const Value.absent(),
                Value<bool> correctionAccepted = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<bool> manual = const Value.absent(),
                Value<double?> actualCoffeeG = const Value.absent(),
                Value<double?> actualWaterG = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BrewsCompanion(
                id: id,
                brewedAt: brewedAt,
                recipeId: recipeId,
                lineageId: lineageId,
                methodId: methodId,
                recipeJson: recipeJson,
                beanId: beanId,
                equipmentJson: equipmentJson,
                actualTimeS: actualTimeS,
                assessmentJson: assessmentJson,
                score: score,
                correctionJson: correctionJson,
                correctionAccepted: correctionAccepted,
                notes: notes,
                manual: manual,
                actualCoffeeG: actualCoffeeG,
                actualWaterG: actualWaterG,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime brewedAt,
                required String recipeId,
                required String lineageId,
                required String methodId,
                required String recipeJson,
                Value<String?> beanId = const Value.absent(),
                Value<String> equipmentJson = const Value.absent(),
                Value<int?> actualTimeS = const Value.absent(),
                Value<String?> assessmentJson = const Value.absent(),
                Value<int?> score = const Value.absent(),
                Value<String?> correctionJson = const Value.absent(),
                Value<bool> correctionAccepted = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<bool> manual = const Value.absent(),
                Value<double?> actualCoffeeG = const Value.absent(),
                Value<double?> actualWaterG = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BrewsCompanion.insert(
                id: id,
                brewedAt: brewedAt,
                recipeId: recipeId,
                lineageId: lineageId,
                methodId: methodId,
                recipeJson: recipeJson,
                beanId: beanId,
                equipmentJson: equipmentJson,
                actualTimeS: actualTimeS,
                assessmentJson: assessmentJson,
                score: score,
                correctionJson: correctionJson,
                correctionAccepted: correctionAccepted,
                notes: notes,
                manual: manual,
                actualCoffeeG: actualCoffeeG,
                actualWaterG: actualWaterG,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BrewsTable, Brew>(table),
                  BaseReferences<_$AppDatabase, $BrewsTable, Brew>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BrewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BrewsTable,
      Brew,
      $$BrewsTableFilterComposer,
      $$BrewsTableOrderingComposer,
      $$BrewsTableAnnotationComposer,
      $$BrewsTableCreateCompanionBuilder,
      $$BrewsTableUpdateCompanionBuilder,
      (Brew, BaseReferences<_$AppDatabase, $BrewsTable, Brew>),
      Brew,
      PrefetchHooks Function()
    >;
typedef $$EventLogTableCreateCompanionBuilder = EventLogCompanion Function({
  Value<int> id,
  required DateTime at,
  required String type,
  Value<String> payload,
});
typedef $$EventLogTableUpdateCompanionBuilder = EventLogCompanion Function({
  Value<int> id,
  Value<DateTime> at,
  Value<String> type,
  Value<String> payload,
});

class $$EventLogTableFilterComposer
    extends Composer<_$AppDatabase, $EventLogTable> {
  $$EventLogTableFilterComposer({
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

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventLogTableOrderingComposer
    extends Composer<_$AppDatabase, $EventLogTable> {
  $$EventLogTableOrderingComposer({
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

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventLogTable> {
  $$EventLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$EventLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventLogTable,
          EventLogData,
          $$EventLogTableFilterComposer,
          $$EventLogTableOrderingComposer,
          $$EventLogTableAnnotationComposer,
          $$EventLogTableCreateCompanionBuilder,
          $$EventLogTableUpdateCompanionBuilder,
          (
            EventLogData,
            BaseReferences<_$AppDatabase, $EventLogTable, EventLogData>,
          ),
          EventLogData,
          PrefetchHooks Function()
        > {
  $$EventLogTableTableManager(_$AppDatabase db, $EventLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> at = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> payload = const Value.absent(),
          }) => EventLogCompanion(id: id, at: at, type: type, payload: payload),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                required String type,
                Value<String> payload = const Value.absent(),
              }) => EventLogCompanion.insert(
                id: id,
                at: at,
                type: type,
                payload: payload,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventLogTable, EventLogData>(table),
                  BaseReferences<_$AppDatabase, $EventLogTable, EventLogData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventLogTable,
      EventLogData,
      $$EventLogTableFilterComposer,
      $$EventLogTableOrderingComposer,
      $$EventLogTableAnnotationComposer,
      $$EventLogTableCreateCompanionBuilder,
      $$EventLogTableUpdateCompanionBuilder,
      (
        EventLogData,
        BaseReferences<_$AppDatabase, $EventLogTable, EventLogData>,
      ),
      EventLogData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KvEntriesTableTableManager get kvEntries =>
      $$KvEntriesTableTableManager(_db, _db.kvEntries);
  $$UserRecipesTableTableManager get userRecipes =>
      $$UserRecipesTableTableManager(_db, _db.userRecipes);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$BeansTableTableManager get beans =>
      $$BeansTableTableManager(_db, _db.beans);
  $$BrewsTableTableManager get brews =>
      $$BrewsTableTableManager(_db, _db.brews);
  $$EventLogTableTableManager get eventLog =>
      $$EventLogTableTableManager(_db, _db.eventLog);
}
