import 'package:drift/native.dart';
import 'package:ev_kahvesi/data/database.dart';
import 'package:ev_kahvesi/state/engagement.dart';
import 'package:ev_kahvesi/state/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahve_core/kahve_core.dart';

import '../helpers.dart' show FakeNotifications;

Bean bean(String id, {double? remaining, DateTime? roast}) => Bean(
  id: id,
  name: 'Çekirdek $id',
  roaster: '',
  origin: '',
  roastLevel: 'medium',
  roastDate: roast,
  packageG: 250,
  remainingG: remaining,
  archived: false,
  createdAt: DateTime(2026),
);

Brew brew(String recipeJson) => Brew(
  id: 'b',
  brewedAt: DateTime(2026),
  recipeId: 'r',
  lineageId: 'r',
  methodId: 'v60',
  recipeJson: recipeJson,
  equipmentJson: '{}',
  correctionAccepted: false,
  notes: '',
  manual: false,
);

void main() {
  final now = DateTime(2026, 11, 25, 12);

  test('stok, tazelik ve bakım hatırlatıcıları (KHV-FR-ENG-001, 004, 005)', () {
    final reminders = collectReminders(
      beans: [
        bean('a', remaining: 40),
        bean('b', remaining: 200, roast: DateTime(2026, 10, 1)),
        bean('c', remaining: 200, roast: DateTime(2026, 11, 20)),
      ],
      brews: const [],
      tasks: [
        MaintenanceTask(
          id: 't',
          title: 'Kireç çözme',
          intervalDays: 30,
          startedAt: DateTime(2026, 10, 1),
        ),
      ],
      settings: const AppSettings(),
      now: now,
    );
    // Ortalama doz yoksa stok uyarısı verilmez.
    expect(reminders.map((r) => r.type), [
      NotificationType.freshness,
      NotificationType.maintenance,
    ]);
  });

  test('günlük sınır, sessiz saat ve tekrar önleme (KHV-FR-ENG-008)', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final n = FakeNotifications();
    Reminder r(String key) =>
        (key: key, type: NotificationType.lowStock, title: key, body: '');
    final count = await scheduleReminders(
      db: db,
      notifications: n,
      reminders: [r('a'), r('b'), r('c')],
      prefs: const NotificationPrefs(),
      now: now,
    );
    expect(count, 2);
    final again = await scheduleReminders(
      db: db,
      notifications: n,
      reminders: [r('a'), r('c')],
      prefs: const NotificationPrefs(),
      now: now.add(const Duration(hours: 1)),
    );
    expect(again, 0, reason: 'a gönderildi; c günlük sınıra takıldı');
    final night = await scheduleReminders(
      db: db,
      notifications: n,
      reminders: [r('c')],
      prefs: const NotificationPrefs(),
      now: DateTime(2026, 11, 25, 23),
    );
    expect(night, 1, reason: 'ertesi sabaha ertelenir; o gün henüz boş');
  });

  test('sessiz saatte planlanan hatırlatıcı sabaha ertelenir', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final n = FakeNotifications();
    await scheduleReminders(
      db: db,
      notifications: n,
      reminders: [
        (key: 'x', type: NotificationType.freshness, title: 'x', body: ''),
      ],
      prefs: const NotificationPrefs(),
      now: DateTime(2026, 11, 25, 23),
    );
    expect(n.scheduled.values.single.$3, DateTime(2026, 11, 26, 8));
  });

  test('ortalama doza göre stok uyarısı', () {
    final reminders = collectReminders(
      beans: [bean('a', remaining: 40)],
      brews: [
        brew(
          '{"id":"r","method":"v60","name":"x","coffeeG":15,'
          '"waterG":250,"grind":{"label":"x"},"steps":[]}',
        ),
      ],
      tasks: const [],
      settings: const AppSettings(),
      now: now,
    );
    expect(reminders.single.type, NotificationType.lowStock);
    expect(reminders.single.body, contains('2 demlemelik'));
  });
}
