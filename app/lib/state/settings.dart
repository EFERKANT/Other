import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import 'providers.dart';

/// Uyarı kanalları (KHV-FR-BRW-003, KHV-HMI-005).
enum AlertChannel { visual, sound, vibration }

/// Eşleştirilmiş Bluetooth terazi (KHV-FR-SCL-002, SCL-003, KB-028).
/// Yalnız cihazda saklanır; destek talebinde de cihaz kimliği gönderilmez.
@immutable
class PairedScale {
  const PairedScale({
    required this.deviceId,
    required this.name,
    required this.protocol,
    this.supportedId,
  });

  factory PairedScale.fromJson(Map<String, Object?> j) => PairedScale(
    deviceId: j['deviceId']! as String,
    name: j['name']! as String,
    protocol: j['protocol']! as String,
    supportedId: j['supportedId'] as String?,
  );

  /// Platformun cihaz kimliği.
  final String deviceId;

  /// Cihazın yayınladığı ad.
  final String name;

  /// Ağırlığı çözen açık protokol.
  final String protocol;

  /// Desteklenen model kimliği; `null` ise dinleme modunda eşleşti.
  final String? supportedId;

  /// Dinleme modunda (tanınmayan cihaz) eşleştiyse `true`.
  bool get listenOnly => supportedId == null;

  Map<String, Object?> toJson() => {
    'deviceId': deviceId,
    'name': name,
    'protocol': protocol,
    if (supportedId != null) 'supportedId': supportedId,
  };

  @override
  bool operator ==(Object other) =>
      other is PairedScale &&
      other.deviceId == deviceId &&
      other.name == name &&
      other.protocol == protocol &&
      other.supportedId == supportedId;

  @override
  int get hashCode => Object.hash(deviceId, name, protocol, supportedId);
}

/// Kullanıcı ayarları (KHV-FR-SET-001).
@immutable
class AppSettings {
  const AppSettings({
    this.onboardingDone = false,
    this.equipment = EquipmentProfile.empty,
    this.onboardingSkipped = false,
    this.profileOverride,
    this.themeMode = ThemeMode.system,
    this.alerts = const {
      AlertChannel.visual,
      AlertChannel.sound,
      AlertChannel.vibration,
    },
    this.soundInSilentMode = false,
    this.analyticsConsent = false,
    this.crashReportConsent = false,
    this.cupMl = 200,
    this.freshnessDays = 30,
    this.seenTerms = const {},
    this.notifications = const NotificationPrefs(),
    this.voiceGuidance = true,
    this.ttsHelpShown = false,
    this.notificationPermissionAsked = false,
    this.pairedScale,
  });

  factory AppSettings.fromJson(Map<String, Object?> j) => AppSettings(
    onboardingDone: j['onboardingDone'] as bool? ?? false,
    onboardingSkipped: j['onboardingSkipped'] as bool? ?? false,
    equipment: j['equipment'] == null
        ? EquipmentProfile.empty
        : EquipmentProfile.fromJson(
            (j['equipment']! as Map).cast<String, Object?>(),
          ),
    profileOverride: j['profileOverride'] == null
        ? null
        : UserProfile.values.byName(j['profileOverride']! as String),
    themeMode: ThemeMode.values.byName(j['themeMode'] as String? ?? 'system'),
    alerts: {
      for (final a
          in (j['alerts'] as List<Object?>? ??
              const ['visual', 'sound', 'vibration']))
        AlertChannel.values.byName(a! as String),
    },
    soundInSilentMode: j['soundInSilentMode'] as bool? ?? false,
    analyticsConsent: j['analyticsConsent'] as bool? ?? false,
    crashReportConsent: j['crashReportConsent'] as bool? ?? false,
    cupMl: (j['cupMl'] as num?)?.toDouble() ?? 200,
    freshnessDays: (j['freshnessDays'] as num?)?.toInt() ?? 30,
    seenTerms: {
      for (final t in (j['seenTerms'] as List<Object?>? ?? const []))
        t! as String,
    },
    notifications: j['notifications'] == null
        ? const NotificationPrefs()
        : NotificationPrefs.fromJson(
            (j['notifications']! as Map).cast<String, Object?>(),
          ),
    voiceGuidance: j['voiceGuidance'] as bool? ?? true,
    ttsHelpShown: j['ttsHelpShown'] as bool? ?? false,
    notificationPermissionAsked:
        j['notificationPermissionAsked'] as bool? ?? false,
    pairedScale: j['pairedScale'] == null
        ? null
        : PairedScale.fromJson(
            (j['pairedScale']! as Map).cast<String, Object?>(),
          ),
  );

  final bool onboardingDone;
  final bool onboardingSkipped;
  final EquipmentProfile equipment;

  /// Kullanıcının elle seçtiği profil (KHV-FR-SET-002).
  final UserProfile? profileOverride;
  final ThemeMode themeMode;
  final Set<AlertChannel> alerts;
  final bool soundInSilentMode;

  /// Analitik rızası; varsayılan kapalı (KHV-NFR-017, KHV-HMI-039).
  final bool analyticsConsent;

  /// Çökme raporu rızası; varsayılan kapalı (KHV-NFR-033).
  final bool crashReportConsent;
  final double cupMl;
  final int freshnessDays;

  /// İlk açıklaması gösterilmiş terimler (KHV-HMI-018).
  final Set<String> seenTerms;

  /// Tür bazlı bildirim tercihleri ve sessiz saatler (KHV-FR-ENG-008).
  final NotificationPrefs notifications;

  /// Sesli adım komutu (KHV-HMI-007).
  final bool voiceGuidance;

  /// Türkçe ses paketi yardımı gösterildi mi (KHV-FR-BRW-013).
  final bool ttsHelpShown;

  /// Bildirim ön izin ekranı gösterildi mi (KHV-HMI-037).
  final bool notificationPermissionAsked;

  /// Eşleştirilmiş terazi; yoksa ağırlık elle girilir.
  final PairedScale? pairedScale;

  /// Etkin profil.
  UserProfile get profile =>
      profileOverride ?? assignProfile(equipment, skipped: onboardingSkipped);

  /// [channel] kapatılabilir mi: en az iki kanal açık kalmalıdır
  /// (KHV-HMI-005).
  bool canDisable(AlertChannel channel) =>
      !alerts.contains(channel) || alerts.length > 2;

  AppSettings copyWith({
    bool? onboardingDone,
    bool? onboardingSkipped,
    EquipmentProfile? equipment,
    UserProfile? profileOverride,
    bool clearProfileOverride = false,
    ThemeMode? themeMode,
    Set<AlertChannel>? alerts,
    bool? soundInSilentMode,
    bool? analyticsConsent,
    bool? crashReportConsent,
    double? cupMl,
    int? freshnessDays,
    Set<String>? seenTerms,
    NotificationPrefs? notifications,
    bool? voiceGuidance,
    bool? ttsHelpShown,
    bool? notificationPermissionAsked,
    PairedScale? pairedScale,
    bool clearPairedScale = false,
  }) => AppSettings(
    onboardingDone: onboardingDone ?? this.onboardingDone,
    onboardingSkipped: onboardingSkipped ?? this.onboardingSkipped,
    equipment: equipment ?? this.equipment,
    profileOverride: clearProfileOverride
        ? null
        : profileOverride ?? this.profileOverride,
    themeMode: themeMode ?? this.themeMode,
    alerts: alerts ?? this.alerts,
    soundInSilentMode: soundInSilentMode ?? this.soundInSilentMode,
    analyticsConsent: analyticsConsent ?? this.analyticsConsent,
    crashReportConsent: crashReportConsent ?? this.crashReportConsent,
    cupMl: cupMl ?? this.cupMl,
    freshnessDays: freshnessDays ?? this.freshnessDays,
    seenTerms: seenTerms ?? this.seenTerms,
    notifications: notifications ?? this.notifications,
    voiceGuidance: voiceGuidance ?? this.voiceGuidance,
    ttsHelpShown: ttsHelpShown ?? this.ttsHelpShown,
    notificationPermissionAsked:
        notificationPermissionAsked ?? this.notificationPermissionAsked,
    pairedScale: clearPairedScale ? null : pairedScale ?? this.pairedScale,
  );

  Map<String, Object?> toJson() => {
    'onboardingDone': onboardingDone,
    'onboardingSkipped': onboardingSkipped,
    'equipment': equipment.toJson(),
    if (profileOverride != null) 'profileOverride': profileOverride!.name,
    'themeMode': themeMode.name,
    'alerts': [for (final a in alerts) a.name],
    'soundInSilentMode': soundInSilentMode,
    'analyticsConsent': analyticsConsent,
    'crashReportConsent': crashReportConsent,
    'cupMl': cupMl,
    'freshnessDays': freshnessDays,
    'seenTerms': seenTerms.toList(),
    'notifications': notifications.toJson(),
    'voiceGuidance': voiceGuidance,
    'ttsHelpShown': ttsHelpShown,
    'notificationPermissionAsked': notificationPermissionAsked,
    if (pairedScale != null) 'pairedScale': pairedScale!.toJson(),
  };
}

/// Ayarları veritabanında saklayan denetleyici.
class SettingsController extends AsyncNotifier<AppSettings> {
  static const _key = 'settings';

  @override
  Future<AppSettings> build() async {
    final json = await ref.watch(databaseProvider).readJson(_key);
    return json == null ? const AppSettings() : AppSettings.fromJson(json);
  }

  Future<void> change(AppSettings Function(AppSettings s) fn) async {
    final current = state.value ?? await future;
    final next = fn(current);
    state = AsyncData(next);
    await ref.read(databaseProvider).writeJson(_key, next.toJson());
  }

  /// Uyarı kanalını açar/kapatır; son iki kanal kapatılamaz.
  Future<bool> toggleAlert(AlertChannel c) async {
    final s = state.value ?? await future;
    if (s.alerts.contains(c)) {
      if (!s.canDisable(c)) return false;
      await change((s) => s.copyWith(alerts: {...s.alerts}..remove(c)));
    } else {
      await change((s) => s.copyWith(alerts: {...s.alerts, c}));
    }
    return true;
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);
