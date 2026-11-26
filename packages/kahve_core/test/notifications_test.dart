import 'package:kahve_core/kahve_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('bildirim politikası (KHV-FR-ENG-008, ARC-005)', () {
    const prefs = NotificationPrefs();

    test('sessiz saat gece yarısını aşar', () {
      expect(prefs.isQuiet(DateTime(2026, 1, 1, 23)), isTrue);
      expect(prefs.isQuiet(DateTime(2026, 1, 1, 7, 59)), isTrue);
      expect(prefs.isQuiet(DateTime(2026, 1, 1, 8)), isFalse);
      expect(prefs.isQuiet(DateTime(2026, 1, 1, 12)), isFalse);
    });

    test('gün içi sessiz aralık ve kapalı sessiz saat', () {
      const p = NotificationPrefs(quietStartMin: 13 * 60, quietEndMin: 14 * 60);
      expect(p.isQuiet(DateTime(2026, 1, 1, 13, 30)), isTrue);
      expect(p.isQuiet(DateTime(2026, 1, 1, 14)), isFalse);
      expect(
        p
            .copyWith(quietHoursEnabled: false)
            .isQuiet(DateTime(2026, 1, 1, 13, 30)),
        isFalse,
      );
      expect(
        const NotificationPrefs(
          quietStartMin: 60,
          quietEndMin: 60,
        ).isQuiet(DateTime(2026, 1, 1, 1)),
        isFalse,
      );
    });

    test('sessiz saatteki bildirim sabaha ertelenir', () {
      expect(
        scheduleNotification(
          NotificationType.lowStock,
          DateTime(2026, 1, 1, 23),
          prefs,
        ),
        DateTime(2026, 1, 2, 8),
      );
      expect(
        scheduleNotification(
          NotificationType.lowStock,
          DateTime(2026, 1, 2, 6),
          prefs,
        ),
        DateTime(2026, 1, 2, 8),
      );
    });

    test('günde en fazla 2 bildirim', () {
      final at = DateTime(2026, 1, 1, 12);
      expect(
        scheduleNotification(
          NotificationType.freshness,
          at,
          prefs,
          sentOn: [DateTime(2026, 1, 1, 9), DateTime(2026, 1, 1, 10)],
        ),
        isNull,
      );
      expect(
        scheduleNotification(
          NotificationType.freshness,
          at,
          prefs,
          sentOn: [DateTime(2026, 1, 1, 9), DateTime(2025, 12, 31, 10)],
        ),
        at,
      );
    });

    test('demleme uyarıları sessiz saat ve sınıra tabi değil', () {
      final night = DateTime(2026, 1, 1, 23, 30);
      expect(
        scheduleNotification(
          NotificationType.longBrewDone,
          night,
          prefs,
          sentOn: [night, night],
        ),
        night,
      );
      expect(NotificationType.brewStep.isBrewAlert, isTrue);
      expect(NotificationType.maintenance.isBrewAlert, isFalse);
    });

    test('kapatılan tür gönderilmez', () {
      final p = prefs.copyWith(enabled: {NotificationType.brewStep});
      expect(
        scheduleNotification(
          NotificationType.maintenance,
          DateTime(2026, 1, 1, 12),
          p,
        ),
        isNull,
      );
    });

    test('JSON gidiş-dönüş', () {
      final p = prefs.copyWith(
        enabled: {NotificationType.lowStock},
        quietStartMin: 60,
        quietEndMin: 120,
        quietHoursEnabled: false,
      );
      final back = NotificationPrefs.fromJson(p.toJson());
      expect(back.toJson(), p.toJson());
      expect(
        NotificationPrefs.fromJson(const {}).enabled,
        NotificationType.values.toSet(),
      );
    });
  });

  group('bakım (KHV-FR-ENG-001, ENG-002, ENG-009)', () {
    final templates = loadBundle().maintenance;
    final now = DateTime(2026, 11, 25);

    test('ekipmana göre görev oluşturulur', () {
      final tasks = syncMaintenanceTasks(
        const [],
        templates,
        const EquipmentProfile(
          brewers: {BrewMethod.espresso},
          grinder: GrinderType.electricBurr,
        ),
        now: now,
      );
      expect(
        tasks.map((t) => t.templateId),
        containsAll([
          'descale-espresso',
          'backflush',
          'gasket',
          'grinder-clean',
        ]),
      );
      expect(tasks.map((t) => t.templateId), isNot(contains('descale-drip')));
    });

    test('ekipman çıkarılınca şablon görevi kalkar, elle görev kalır', () {
      final custom = MaintenanceTask(
        id: 'c1',
        title: 'Kendi makinem',
        intervalDays: 10,
        startedAt: now,
      );
      final first = syncMaintenanceTasks(
        [custom],
        templates,
        const EquipmentProfile(brewers: {BrewMethod.dripMachine}),
        now: now,
      );
      expect(first.map((t) => t.templateId), contains('descale-drip'));
      final second = syncMaintenanceTasks(
        first,
        templates,
        const EquipmentProfile(brewers: {BrewMethod.v60}),
        now: now,
      );
      expect(second.single.id, 'c1');
    });

    test('mevcut görev korunur, tekrar eklenmez', () {
      const e = EquipmentProfile(brewers: {BrewMethod.mokaPot});
      final a = syncMaintenanceTasks(const [], templates, e, now: now);
      final done = [a.single.markDone(now.add(const Duration(days: 3)))];
      final b = syncMaintenanceTasks(done, templates, e, now: now);
      expect(b, hasLength(1));
      expect(b.single.lastDoneAt, now.add(const Duration(days: 3)));
    });

    test('sonraki tarih tamamlanmadan itibaren hesaplanır (ENG-002)', () {
      final t = MaintenanceTask(
        id: 'x',
        title: 'Kireç',
        intervalDays: 60,
        startedAt: DateTime(2026, 1, 1),
      );
      expect(t.dueAt, DateTime(2026, 3, 2));
      expect(t.isDue(DateTime(2026, 3, 2)), isTrue);
      expect(t.isDue(DateTime(2026, 3, 1)), isFalse);
      final done = t.markDone(DateTime(2026, 3, 10));
      expect(done.dueAt, DateTime(2026, 5, 9));
      expect(done.copyWith(intervalDays: 30).dueAt, DateTime(2026, 4, 9));
      expect(t.copyWith(enabled: false).isDue(DateTime(2027)), isFalse);
      expect(MaintenanceTask.fromJson(done.toJson()).toJson(), done.toJson());
      expect(t.copyWith(title: 'Y').title, 'Y');
    });

    test('burr grinder şartı', () {
      final g = templates.firstWhere((t) => t.id == 'grinder-clean');
      expect(
        g.appliesTo(const EquipmentProfile(grinder: GrinderType.blade)),
        isFalse,
      );
      expect(
        g.appliesTo(const EquipmentProfile(grinder: GrinderType.handBurr)),
        isTrue,
      );
    });
  });

  test('özellik bayrakları (KHV-ARC-006)', () {
    final b = loadBundle();
    expect(b.flag('share'), isTrue);
    expect(b.flag('tanımsız'), isTrue);
    expect(b.flag('tanımsız', fallback: false), isFalse);
  });
}
