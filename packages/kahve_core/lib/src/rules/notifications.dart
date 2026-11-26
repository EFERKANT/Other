import 'package:meta/meta.dart';

/// Bildirim türleri; tercihler tür bazında tutulur (KHV-ARC-005,
/// KHV-FR-ENG-008).
enum NotificationType {
  /// Arka planda rehberli demleme adım geçişi (KHV-FR-BRW-005).
  brewStep,

  /// Uzun süreli demlemenin bitişi (KHV-FR-BRW-009).
  longBrewDone,

  /// Çekirdek stoğu azaldı (KHV-FR-ENG-004).
  lowStock,

  /// Çekirdek tazeliğini yitiriyor (KHV-FR-ENG-005).
  freshness,

  /// Bakım zamanı (KHV-FR-ENG-001).
  maintenance;

  /// Kullanıcının başlattığı demlemeye ait, zaman kritik uyarı mı.
  ///
  /// Bu uyarılar sessiz saatlere ve günlük sınıra tabi değildir: kullanıcı
  /// demlemeyi o anda kendisi başlatmıştır ve uyarı geciktirilirse demleme
  /// bozulur.
  bool get isBrewAlert => this == brewStep || this == longBrewDone;
}

/// Kullanıcının bildirim tercihleri (KHV-FR-ENG-008).
@immutable
class NotificationPrefs {
  /// Tercihleri oluşturur. Sessiz saatler gün içindeki dakika olarak
  /// verilir; başlangıç bitişten büyükse aralık gece yarısını aşar.
  const NotificationPrefs({
    this.enabled = const {
      NotificationType.brewStep,
      NotificationType.longBrewDone,
      NotificationType.lowStock,
      NotificationType.freshness,
      NotificationType.maintenance,
    },
    this.quietStartMin = 22 * 60,
    this.quietEndMin = 8 * 60,
    this.quietHoursEnabled = true,
  });

  /// JSON'dan okur.
  factory NotificationPrefs.fromJson(Map<String, Object?> j) =>
      NotificationPrefs(
        enabled: {
          for (final t
              in (j['enabled'] as List<Object?>? ??
                  [for (final t in NotificationType.values) t.name]))
            NotificationType.values.byName(t! as String),
        },
        quietStartMin: (j['quietStartMin'] as num?)?.toInt() ?? 22 * 60,
        quietEndMin: (j['quietEndMin'] as num?)?.toInt() ?? 8 * 60,
        quietHoursEnabled: j['quietHoursEnabled'] as bool? ?? true,
      );

  /// Günde gönderilecek en fazla bildirim (demleme uyarıları hariç).
  static const dailyLimit = 2;

  /// Açık bildirim türleri.
  final Set<NotificationType> enabled;

  /// Sessiz saat başlangıcı (gün içi dakika).
  final int quietStartMin;

  /// Sessiz saat bitişi (gün içi dakika).
  final int quietEndMin;

  /// Sessiz saatler etkin mi.
  final bool quietHoursEnabled;

  /// [at] anı sessiz saatlerin içinde mi.
  bool isQuiet(DateTime at) {
    if (!quietHoursEnabled || quietStartMin == quietEndMin) return false;
    final m = at.hour * 60 + at.minute;
    return quietStartMin < quietEndMin
        ? m >= quietStartMin && m < quietEndMin
        : m >= quietStartMin || m < quietEndMin;
  }

  /// Sessiz saat içindeki [at] için sessiz saatlerin bittiği an.
  DateTime quietEnd(DateTime at) {
    var end = DateTime(
      at.year,
      at.month,
      at.day,
      quietEndMin ~/ 60,
      quietEndMin % 60,
    );
    if (!end.isAfter(at)) end = end.add(const Duration(days: 1));
    return end;
  }

  /// Değiştirilmiş kopya.
  NotificationPrefs copyWith({
    Set<NotificationType>? enabled,
    int? quietStartMin,
    int? quietEndMin,
    bool? quietHoursEnabled,
  }) => NotificationPrefs(
    enabled: enabled ?? this.enabled,
    quietStartMin: quietStartMin ?? this.quietStartMin,
    quietEndMin: quietEndMin ?? this.quietEndMin,
    quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
  );

  /// JSON'a yazar.
  Map<String, Object?> toJson() => {
    'enabled': [for (final t in enabled) t.name],
    'quietStartMin': quietStartMin,
    'quietEndMin': quietEndMin,
    'quietHoursEnabled': quietHoursEnabled,
  };
}

/// Bir bildirimin ne zaman gönderileceğine karar verir
/// (KHV-FR-ENG-008).
///
/// [sentOn] o güne kadar gönderilmiş veya planlanmış, demleme uyarısı
/// olmayan bildirimlerin gönderim anlarıdır. Bildirim gönderilmeyecekse
/// `null` döner; sessiz saatteyse sessiz saatin bitişine ertelenir.
DateTime? scheduleNotification(
  NotificationType type,
  DateTime at,
  NotificationPrefs prefs, {
  Iterable<DateTime> sentOn = const [],
}) {
  if (!prefs.enabled.contains(type)) return null;
  if (type.isBrewAlert) return at;
  final deliverAt = prefs.isQuiet(at) ? prefs.quietEnd(at) : at;
  final sameDay = sentOn.where(
    (d) =>
        d.year == deliverAt.year &&
        d.month == deliverAt.month &&
        d.day == deliverAt.day,
  );
  if (sameDay.length >= NotificationPrefs.dailyLimit) return null;
  return deliverAt;
}
