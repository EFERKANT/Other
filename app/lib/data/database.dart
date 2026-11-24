import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:kahve_core/kahve_core.dart';

part 'database.g.dart';

/// Anahtar-değer ayarları; ayarlar, ekipman profili ve aktif demleme
/// durumu JSON olarak tutulur (KHV-HMI-040, KHV-NFR-003).
class KvEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Kullanıcı tarifleri (KHV-FR-RCP-006, RCP-013).
class UserRecipes extends Table {
  TextColumn get id => text()();
  TextColumn get methodId => text()();
  TextColumn get json => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Favori tarif kimlikleri; sistem tarifleri de favorilenebilir
/// (KHV-FR-RCP-011).
class Favorites extends Table {
  TextColumn get recipeId => text()();

  @override
  Set<Column<Object>> get primaryKey => {recipeId};
}

/// Çekirdek kaydı (KHV-FR-LOG-004, LOG-008, ENG-003).
class Beans extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get roaster => text().withDefault(const Constant(''))();
  TextColumn get origin => text().withDefault(const Constant(''))();
  TextColumn get roastLevel => text().withDefault(const Constant('medium'))();
  DateTimeColumn get roastDate => dateTime().nullable()();
  RealColumn get packageG => real().nullable()();
  RealColumn get remainingG => real().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Demleme kaydı (KHV-FR-LOG-001, KHV-FR-RCP-014).
///
/// Tarifin demleme anındaki hali [recipeJson] olarak saklanır; tarif sonradan
/// silinse veya değişse de kayıt kendi parametrelerini gösterir.
class Brews extends Table {
  TextColumn get id => text()();
  DateTimeColumn get brewedAt => dateTime()();
  TextColumn get recipeId => text()();

  /// Dial-in zinciri kimliği: kök (kaynak) tarifin kimliği.
  TextColumn get lineageId => text()();
  TextColumn get methodId => text()();
  TextColumn get recipeJson => text()();
  TextColumn get beanId => text().nullable()();
  TextColumn get equipmentJson => text().withDefault(const Constant('{}'))();
  IntColumn get actualTimeS => integer().nullable()();
  TextColumn get assessmentJson => text().nullable()();
  IntColumn get score => integer().nullable()();
  TextColumn get correctionJson => text().nullable()();
  BoolColumn get correctionAccepted =>
      boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get manual => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Yapılandırılmış olay kaydı (KHV-ARC-004).
class EventLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get at => dateTime()();
  TextColumn get type => text()();
  TextColumn get payload => text().withDefault(const Constant('{}'))();
}

/// Uygulamanın yerel veritabanı. Şema sürümlenir (KHV-NFR-028); her şema
/// değişikliğinde [schemaVersion] artırılır ve `migration` içine adım
/// eklenir, `test/data/migration_test.dart` güncellenir.
@DriftDatabase(
  tables: [KvEntries, UserRecipes, Favorites, Beans, Brews, EventLog],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // --- Anahtar-değer ---

  Future<Map<String, Object?>?> readJson(String key) async {
    final row = await (select(
      kvEntries,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    if (row == null) return null;
    return (jsonDecode(row.value) as Map).cast<String, Object?>();
  }

  Future<void> writeJson(String key, Map<String, Object?> value) =>
      into(kvEntries).insertOnConflictUpdate(
        KvEntriesCompanion.insert(key: key, value: jsonEncode(value)),
      );

  Future<void> deleteKey(String key) =>
      (delete(kvEntries)..where((t) => t.key.equals(key))).go();

  // --- Tarifler ---

  Stream<List<Recipe>> watchUserRecipes() =>
      (select(
        userRecipes,
      )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch().map(
        (rows) => [
          for (final r in rows)
            Recipe.fromJson(
              (jsonDecode(r.json) as Map).cast<String, Object?>(),
            ),
        ],
      );

  Future<void> saveUserRecipe(Recipe r) =>
      into(userRecipes).insertOnConflictUpdate(
        UserRecipesCompanion.insert(
          id: r.id,
          methodId: r.method.id,
          json: jsonEncode(r.toJson()),
          updatedAt: DateTime.now(),
        ),
      );

  Future<void> deleteUserRecipe(String id) async {
    await (delete(userRecipes)..where((t) => t.id.equals(id))).go();
    await (delete(favorites)..where((t) => t.recipeId.equals(id))).go();
  }

  Stream<Set<String>> watchFavorites() =>
      select(favorites).watch().map((r) => {for (final f in r) f.recipeId});

  Future<void> setFavorite(String recipeId, {required bool favorite}) =>
      favorite
      ? into(
          favorites,
        ).insertOnConflictUpdate(FavoritesCompanion.insert(recipeId: recipeId))
      : (delete(favorites)..where((t) => t.recipeId.equals(recipeId))).go();

  // --- Çekirdekler ---

  Stream<List<Bean>> watchBeans({bool includeArchived = true}) {
    final q = select(beans)
      ..orderBy([
        (t) => OrderingTerm.asc(t.archived),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);
    if (!includeArchived) q.where((t) => t.archived.equals(false));
    return q.watch();
  }

  Future<Bean?> beanById(String id) =>
      (select(beans)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> saveBean(BeansCompanion b) =>
      into(beans).insertOnConflictUpdate(b);

  /// Demleme kaydı olan çekirdek silinemez (KHV-FR-LOG-009).
  Future<bool> deleteBean(String id) async {
    final used = await (select(brews)..where((t) => t.beanId.equals(id))).get();
    if (used.isNotEmpty) return false;
    await (delete(beans)..where((t) => t.id.equals(id))).go();
    return true;
  }

  // --- Demlemeler ---

  Stream<List<Brew>> watchBrews() =>
      (select(brews)..orderBy([(t) => OrderingTerm.desc(t.brewedAt)])).watch();

  Stream<Brew?> watchBrew(String id) =>
      (select(brews)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<Brew?> brewById(String id) =>
      (select(brews)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Aynı dial-in zincirindeki değerlendirilmiş demlemeler, eskiden yeniye.
  Future<List<Brew>> lineage(String lineageId, {String? excludeId}) {
    final q = select(brews)
      ..where(
        (t) =>
            t.lineageId.equals(lineageId) &
            t.assessmentJson.isNotNull() &
            (excludeId == null
                ? const Constant(true)
                : t.id.equals(excludeId).not()),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.brewedAt)]);
    return q.get();
  }

  /// Demlemeyi kaydeder; yeni kayıtta kullanılan dozu çekirdek stoğundan
  /// düşer (KHV-FR-ENG-003).
  Future<void> insertBrew(BrewsCompanion b, {double? doseG}) =>
      transaction(() async {
        await into(brews).insert(b);
        final beanId = b.beanId.present ? b.beanId.value : null;
        if (beanId != null && doseG != null) {
          final bean = await beanById(beanId);
          if (bean?.remainingG != null) {
            await (update(beans)..where((t) => t.id.equals(beanId))).write(
              BeansCompanion(
                remainingG: Value(deductStock(bean!.remainingG!, doseG)),
              ),
            );
          }
        }
        await logEvent('brew', {'id': b.id.value});
      });

  Future<void> updateBrew(String id, BrewsCompanion b) =>
      (update(brews)..where((t) => t.id.equals(id))).write(b);

  Future<void> deleteBrew(String id) =>
      (delete(brews)..where((t) => t.id.equals(id))).go();

  Future<void> restoreBrew(Brew b) => into(brews).insertOnConflictUpdate(b);

  // --- Olaylar ---

  Future<void> logEvent(String type, Map<String, Object?> payload) =>
      into(eventLog).insert(
        EventLogCompanion.insert(
          at: DateTime.now(),
          type: type,
          payload: Value(jsonEncode(payload)),
        ),
      );

  /// Tüm yerel veriyi siler (KHV-FR-SET-003).
  Future<void> wipe() => transaction(() async {
    for (final t in allTables) {
      await delete(t).go();
    }
  });
}
