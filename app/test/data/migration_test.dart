import 'dart:io';

import 'package:drift/native.dart';
import 'package:ev_kahvesi/data/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Her şema sürümünden güncel sürüme kayıpsız taşıma (KHV-NFR-028).
/// Yeni sürümde `schemas/schema_vN.sql` eklenir ve bu teste satır eklenir.
void main() {
  test('v1 → güncel: demleme kayıtları korunur, yeni alanlar boş', () async {
    final raw = sqlite3.openInMemory();
    raw.execute(File('test/data/schemas/schema_v1.sql').readAsStringSync());
    raw.execute('''
      INSERT INTO brews (id, brewed_at, recipe_id, lineage_id, method_id,
        recipe_json, score, notes)
      VALUES ('b1', 1764000000, 'sys-v60', 'sys-v60', 'v60', '{}', 4, 'not');
      INSERT INTO kv_entries (key, value) VALUES ('settings', '{"a":1}');
      INSERT INTO beans (id, name, created_at, remaining_g)
      VALUES ('k1', 'Kenya', 1764000000, 200);
      PRAGMA user_version = 1;
    ''');
    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(db.close);
    final b = await db.brewById('b1');
    expect(b, isNotNull);
    expect(b!.score, 4);
    expect(b.notes, 'not');
    expect(b.actualCoffeeG, isNull);
    expect(b.actualWaterG, isNull);
    expect(await db.readJson('settings'), {'a': 1});
    expect((await db.beanById('k1'))!.remainingG, 200);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), db.schemaVersion);
  });
}
