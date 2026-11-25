import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:ev_kahvesi/data/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahve_core/kahve_core.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  const recipe = Recipe(
    id: 'r1',
    method: BrewMethod.v60,
    name: 'Benim V60',
    owner: RecipeOwner.user,
    coffeeG: 15,
    waterG: 250,
    grind: GrindSetting('Orta-ince'),
    steps: [BrewStep(title: 'Dök', trigger: StepTrigger.confirm)],
  );

  test('anahtar-değer JSON', () async {
    expect(await db.readJson('x'), isNull);
    await db.writeJson('x', {'a': 1});
    await db.writeJson('x', {'a': 2});
    expect(await db.readJson('x'), {'a': 2});
    await db.deleteKey('x');
    expect(await db.readJson('x'), isNull);
  });

  test('kullanıcı tarifi kaydet, favori, sil', () async {
    await db.saveUserRecipe(recipe);
    expect((await db.watchUserRecipes().first).single.name, 'Benim V60');
    await db.setFavorite('r1', favorite: true);
    expect(await db.watchFavorites().first, {'r1'});
    await db.deleteUserRecipe('r1');
    expect(await db.watchUserRecipes().first, isEmpty);
    expect(await db.watchFavorites().first, isEmpty);
  });

  test('demleme stoktan düşer, tarif silinse de kayıt kalır '
      '(KHV-FR-ENG-003, RCP-014)', () async {
    await db.saveBean(
      BeansCompanion.insert(
        id: 'b1',
        name: 'Etiyopya',
        createdAt: DateTime(2026),
        packageG: const Value(250),
        remainingG: const Value(250),
      ),
    );
    await db.saveUserRecipe(recipe);
    await db.insertBrew(
      BrewsCompanion.insert(
        id: 'br1',
        brewedAt: DateTime(2026, 11, 24),
        recipeId: 'r1',
        lineageId: 'r1',
        methodId: 'v60',
        recipeJson: '{}',
        beanId: const Value('b1'),
      ),
      doseG: 15,
    );
    expect((await db.beanById('b1'))!.remainingG, 235);
    await db.deleteUserRecipe('r1');
    expect((await db.brewById('br1'))!.recipeId, 'r1');
    expect(await db.deleteBean('b1'), isFalse, reason: 'KHV-FR-LOG-009');
  });

  test('dial-in zinciri yalnız değerlendirilmiş kayıtları döndürür', () async {
    for (var i = 0; i < 3; i++) {
      await db.insertBrew(
        BrewsCompanion.insert(
          id: 'b$i',
          brewedAt: DateTime(2026, 1, 1 + i),
          recipeId: 'r',
          lineageId: 'L',
          methodId: 'v60',
          recipeJson: '{}',
          assessmentJson: Value(i == 1 ? null : '{"score":3}'),
        ),
      );
    }
    expect((await db.lineage('L')).map((b) => b.id), ['b0', 'b2']);
    expect((await db.lineage('L', excludeId: 'b2')).map((b) => b.id), ['b0']);
  });

  test('tüm veriyi sil (KHV-FR-SET-003)', () async {
    await db.writeJson('k', {});
    await db.saveUserRecipe(recipe);
    await db.wipe();
    expect(await db.readJson('k'), isNull);
    expect(await db.watchUserRecipes().first, isEmpty);
  });

  test('güncel şema sıfırdan oluşturulur (KHV-NFR-028)', () async {
    expect(db.schemaVersion, 2);
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
        .get();
    expect(
      tables.map((r) => r.read<String>('name')),
      containsAll([
        'kv_entries',
        'user_recipes',
        'favorites',
        'beans',
        'brews',
        'event_log',
      ]),
    );
  });

  test('yedek dışa/içe aktarma (KHV-NFR-030)', () async {
    await db.writeJson('settings', {'onboardingDone': true});
    await db.saveUserRecipe(recipe);
    await db.setFavorite('r1', favorite: true);
    await db.saveBean(
      BeansCompanion.insert(
        id: 'b1',
        name: 'Kenya',
        createdAt: DateTime(2026),
        roastDate: Value(DateTime(2026, 11, 1)),
      ),
    );
    await db.insertBrew(
      BrewsCompanion.insert(
        id: 'br1',
        brewedAt: DateTime(2026, 11, 24),
        recipeId: 'r1',
        lineageId: 'r1',
        methodId: 'v60',
        recipeJson: '{}',
        beanId: const Value('b1'),
      ),
    );
    final backup = await db.exportAll(at: DateTime(2026, 11, 25));
    final other = AppDatabase(NativeDatabase.memory());
    addTearDown(other.close);
    await other.writeJson('settings', {'eski': true});
    await other.importAll(
      (jsonDecode(jsonEncode(backup)) as Map).cast<String, Object?>(),
    );
    expect(await other.readJson('settings'), {'onboardingDone': true});
    expect((await other.watchUserRecipes().first).single.id, 'r1');
    expect(await other.watchFavorites().first, {'r1'});
    expect((await other.beanById('b1'))!.roastDate, DateTime(2026, 11, 1));
    expect((await other.brewById('br1'))!.beanId, 'b1');
  });

  test('geçersiz yedek mevcut veriyi bozmaz', () async {
    await db.writeJson('settings', {'a': 1});
    expect(() => db.importAll({'app': 'baska'}), throwsFormatException);
    expect(
      () => db.importAll({'app': 'ev_kahvesi', 'format': 99}),
      throwsFormatException,
    );
    expect(
      () => db.importAll({
        'app': 'ev_kahvesi',
        'format': 1,
        'brews': [
          {'id': 'x'},
        ],
      }),
      throwsFormatException,
    );
    expect(await db.readJson('settings'), {'a': 1});
  });

  test('demleme ve içe aktarma zaman damgalı olay olarak kaydedilir '
      '(KHV-ARC-004)', () async {
    await db.insertBrew(
      BrewsCompanion.insert(
        id: 'e1',
        brewedAt: DateTime(2026, 11, 25),
        recipeId: 'r',
        lineageId: 'r',
        methodId: 'v60',
        recipeJson: '{}',
      ),
    );
    await db.logEvent('taste', {'brewId': 'e1', 'score': 4});
    final events = await db.select(db.eventLog).get();
    expect(events.map((e) => e.type), ['brew', 'taste']);
    expect(jsonDecode(events.last.payload), {'brewId': 'e1', 'score': 4});
    expect(events.every((e) => e.at.year == DateTime.now().year), isTrue);
  });

  test('kayıt zamanları enjekte edilen saatten gelir (KB-023, '
      'KHV-FR-BRW-011)', () async {
    final fixed = DateTime(2030, 1, 2, 3, 4);
    final clocked = AppDatabase(NativeDatabase.memory(), clock: () => fixed);
    addTearDown(clocked.close);
    await clocked.logEvent('test', const {});
    final events = await clocked.select(clocked.eventLog).get();
    expect(events.single.at, fixed);
  });
}
