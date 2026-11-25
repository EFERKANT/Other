import 'package:kahve_core/kahve_core.dart';

import '../data/database.dart';
import '../services/platform.dart';
import 'providers.dart';
import 'settings.dart';

/// Gönderilecek tek bir hatırlatıcı.
typedef Reminder = ({
  String key,
  NotificationType type,
  String title,
  String body,
});

/// Stok, tazelik ve bakım hatırlatıcılarını belirler (KHV-FR-ENG-001,
/// ENG-004, ENG-005). Her hatırlatıcı anahtarıyla bir kez gönderilir.
List<Reminder> collectReminders({
  required List<Bean> beans,
  required List<Brew> brews,
  required List<MaintenanceTask> tasks,
  required AppSettings settings,
  required DateTime now,
}) {
  final avg = averageDose([for (final b in brews) brewRecipe(b).coffeeG]);
  return [
    for (final b in beans)
      if (!b.archived) ...[
        if (b.remainingG != null && isLowStock(b.remainingG!, avg))
          (
            key: 'stock:${b.id}:${b.packageG}',
            type: NotificationType.lowStock,
            title: '${b.name} azalıyor',
            body:
                'Yaklaşık ${brewsLeft(b.remainingG!, avg) ?? 0} demlemelik '
                'çekirdek kaldı.',
          ),
        if (b.roastDate != null &&
            isPastFreshness(
              b.roastDate!,
              now,
              thresholdDays: settings.freshnessDays,
            ))
          (
            key: 'fresh:${b.id}',
            type: NotificationType.freshness,
            title: '${b.name} tazeliğini yitiriyor',
            body:
                'Kavrulalı ${daysSinceRoast(b.roastDate!, now)} gün oldu. '
                'Aroma azalmış olabilir.',
          ),
      ],
    for (final t in tasks)
      if (t.isDue(now))
        (
          key: 'mt:${t.id}:${t.dueAt.toIso8601String()}',
          type: NotificationType.maintenance,
          title: 'Bakım zamanı: ${t.title}',
          body: 'Ayarlar > Bakım ekranından tamamlandı olarak işaretleyin.',
        ),
  ];
}

/// Hatırlatıcıları bildirim politikasına göre planlar (KHV-FR-ENG-008):
/// kapalı türler atlanır, sessiz saattekiler ertelenir, günde en fazla iki
/// bildirim gönderilir. Planlanan bildirim sayısını döndürür.
Future<int> scheduleReminders({
  required AppDatabase db,
  required AppNotifications notifications,
  required List<Reminder> reminders,
  required NotificationPrefs prefs,
  required DateTime now,
}) async {
  const logKey = 'notificationLog';
  final log = await db.readJson(logKey) ?? const {};
  final sent = [
    for (final d in (log['sent'] as List<Object?>? ?? const []))
      DateTime.parse(d! as String),
  ].where((d) => now.difference(d).inDays < 7).toList();
  final keys = {
    ...((log['keys'] as Map?)?.cast<String, Object?>() ?? const {}),
  };
  var count = 0;
  for (final r in reminders) {
    if (keys.containsKey(r.key)) continue;
    final at = scheduleNotification(r.type, now, prefs, sentOn: sent);
    if (at == null) continue;
    await notifications.schedule(
      2000 + (r.key.hashCode & 0x3ff),
      r.title,
      r.body,
      at,
    );
    sent.add(at);
    keys[r.key] = at.toIso8601String();
    count++;
  }
  await db.writeJson(logKey, {
    'sent': [for (final d in sent) d.toIso8601String()],
    'keys': keys,
  });
  return count;
}
