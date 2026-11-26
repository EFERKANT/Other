import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:ev_kahvesi/data/database.dart';
import 'package:ev_kahvesi/state/engagement.dart';
import 'package:ev_kahvesi/state/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahve_core/kahve_core.dart';

import '../test/helpers.dart' show FakeNotifications, bundle;

/// Veri katmanı yük testleri: yıllarca kullanılmış bir uygulamanın veri
/// hacmi (günde 3 demleme x 5 yıl ≈ 5.500 kayıt).
void main() {
  const brewCount = 5500;
  const beanCount = 250;
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final r = Random(7);
    await db.batch((b) {
      for (var i = 0; i < beanCount; i++) {
        b.insert(
          db.beans,
          BeansCompanion.insert(
            id: 'k$i',
            name: 'Çekirdek $i',
            createdAt: DateTime(2021).add(Duration(days: i * 7)),
            roastDate: Value(DateTime(2021).add(Duration(days: i * 7))),
            packageG: const Value(250),
            remainingG: Value(r.nextDouble() * 250),
            archived: Value(i < beanCount - 5),
          ),
        );
      }
      for (var i = 0; i < brewCount; i++) {
        final recipe = bundle.recipes[i % bundle.recipes.length];
        b.insert(
          db.brews,
          BrewsCompanion.insert(
            id: 'b$i',
            brewedAt: DateTime(2021).add(Duration(hours: i * 8)),
            recipeId: recipe.id,
            lineageId: recipe.id,
            methodId: recipe.method.id,
            recipeJson: jsonEncode(recipe.toJson()),
            beanId: Value('k${i % beanCount}'),
            score: Value(1 + r.nextInt(5)),
            assessmentJson: Value(
              jsonEncode(TasteAssessment(score: 1 + r.nextInt(5)).toJson()),
            ),
            notes: Value('not $i ' * (r.nextInt(5))),
          ),
        );
      }
    });
  });
  tearDown(() => db.close());

  Future<int> timed(Future<void> Function() f) async {
    final sw = Stopwatch()..start();
    await f();
    return sw.elapsedMilliseconds;
  }

  test('$brewCount kayıtta günlük sorgusu 1 sn altında (KHV-NFR-023: UI '
      'thread\'i bloklamayacak süre)', () async {
    late List<Brew> rows;
    final ms = await timed(() async => rows = await db.watchBrews().first);
    expect(rows, hasLength(brewCount));
    expect(rows.first.brewedAt.isAfter(rows.last.brewedAt), isTrue);
    expect(ms, lessThan(1000), reason: '$ms ms');
  });

  test(
    'dial-in zinciri sorgusu büyük günlükte hızlı (KHV-FR-DIA-006)',
    () async {
      late List<Brew> rows;
      final ms = await timed(() async => rows = await db.lineage('sys-v60'));
      expect(rows.length, greaterThan(500));
      expect(ms, lessThan(500), reason: '$ms ms');
    },
  );

  test('yedek dışa/içe aktarma büyük veriyle kayıpsız (KHV-NFR-030)', () async {
    late Map<String, Object?> backup;
    final exportMs = await timed(
      () async => backup = await db.exportAll(at: DateTime(2026, 11, 25)),
    );
    final text = jsonEncode(backup);
    final other = AppDatabase(NativeDatabase.memory());
    addTearDown(other.close);
    final importMs = await timed(
      () => other.importAll((jsonDecode(text) as Map).cast<String, Object?>()),
    );
    expect((await other.watchBrews().first).length, brewCount);
    expect((await other.watchBeans().first).length, beanCount);
    expect(
      exportMs + importMs,
      lessThan(10000),
      reason: 'dışa $exportMs ms, içe $importMs ms, ${text.length} bayt',
    );
  });

  test('hatırlatıcı hesabı büyük veriyle hızlı ve günlük sınıra uyar '
      '(KHV-FR-ENG-004, ENG-008)', () async {
    final beans = await db.watchBeans().first;
    final brews = await db.watchBrews().first;
    late List<Reminder> reminders;
    final ms = await timed(() async {
      reminders = collectReminders(
        beans: beans,
        brews: brews,
        tasks: const [],
        settings: const AppSettings(),
        now: DateTime(2026, 11, 25, 12),
      );
    });
    expect(ms, lessThan(2000), reason: '$ms ms');
    final n = FakeNotifications();
    final sent = await scheduleReminders(
      db: db,
      notifications: n,
      reminders: reminders,
      prefs: const NotificationPrefs(),
      now: DateTime(2026, 11, 25, 12),
    );
    expect(sent, lessThanOrEqualTo(NotificationPrefs.dailyLimit));
  });

  test('stok düşümü: 500 ardışık demleme negatif stok üretmez '
      '(KHV-FR-ENG-003)', () async {
    for (var i = 0; i < 500; i++) {
      await db.insertBrew(
        BrewsCompanion.insert(
          id: 'x$i',
          brewedAt: DateTime(2026, 11, 25),
          recipeId: 'r',
          lineageId: 'r',
          methodId: 'v60',
          recipeJson: '{}',
          beanId: const Value('k249'),
        ),
        doseG: 18,
      );
    }
    expect((await db.beanById('k249'))!.remainingG, 0);
  });
}
