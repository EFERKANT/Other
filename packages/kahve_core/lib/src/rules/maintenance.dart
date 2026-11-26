import 'package:meta/meta.dart';

import '../model/brew_method.dart';
import '../model/equipment.dart';

/// İçerik yönetiminden gelen bakım şablonu (KHV-FR-ENG-001).
@immutable
class MaintenanceTemplate {
  /// Bir şablon oluşturur.
  const MaintenanceTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.intervalDays,
    this.methods = const {},
    this.requiresBurrGrinder = false,
  });

  /// JSON'dan okur.
  factory MaintenanceTemplate.fromJson(Map<String, Object?> j) =>
      MaintenanceTemplate(
        id: j['id']! as String,
        title: j['title']! as String,
        description: j['description'] as String? ?? '',
        intervalDays: (j['intervalDays']! as num).toInt(),
        methods: {
          for (final m in (j['methods'] as List<Object?>? ?? const []))
            BrewMethod.parse(m! as String),
        },
        requiresBurrGrinder: j['requiresBurrGrinder'] as bool? ?? false,
      );

  /// Şablon kimliği.
  final String id;

  /// Başlık (ör. "Kireç çözme").
  final String title;

  /// Nasıl yapılacağı.
  final String description;

  /// Varsayılan aralık (gün).
  final int intervalDays;

  /// Şablonun geçerli olduğu demleme araçları; boşsa yönteme bağlı değil.
  final Set<BrewMethod> methods;

  /// Yalnız burr grinder sahiplerine öneriliyorsa `true`.
  final bool requiresBurrGrinder;

  /// Şablon [e] profili için geçerli mi.
  bool appliesTo(EquipmentProfile e) {
    if (requiresBurrGrinder && !(e.grinder?.isBurr ?? false)) return false;
    if (methods.isEmpty) return true;
    return methods.any(e.brewers.contains);
  }
}

/// Kullanıcının bir bakım görevi (KHV-FR-ENG-001, ENG-002, ENG-009).
@immutable
class MaintenanceTask {
  /// Bir görev oluşturur.
  const MaintenanceTask({
    required this.id,
    required this.title,
    required this.intervalDays,
    required this.startedAt,
    this.templateId,
    this.lastDoneAt,
    this.enabled = true,
  });

  /// JSON'dan okur.
  factory MaintenanceTask.fromJson(Map<String, Object?> j) => MaintenanceTask(
    id: j['id']! as String,
    templateId: j['templateId'] as String?,
    title: j['title']! as String,
    intervalDays: (j['intervalDays']! as num).toInt(),
    startedAt: DateTime.parse(j['startedAt']! as String),
    lastDoneAt: j['lastDoneAt'] == null
        ? null
        : DateTime.parse(j['lastDoneAt']! as String),
    enabled: j['enabled'] as bool? ?? true,
  );

  /// Kimlik.
  final String id;

  /// Kaynak şablon; kullanıcının elle tanımladığı görevde `null`.
  final String? templateId;

  /// Başlık.
  final String title;

  /// Aralık (gün); kullanıcı değiştirebilir.
  final int intervalDays;

  /// Görevin takibe alındığı an.
  final DateTime startedAt;

  /// Son tamamlanma anı.
  final DateTime? lastDoneAt;

  /// Hatırlatma açık mı.
  final bool enabled;

  /// Bir sonraki bakım tarihi: son tamamlanmadan (yoksa başlangıçtan)
  /// itibaren aralık kadar sonra (KHV-FR-ENG-002).
  DateTime get dueAt =>
      (lastDoneAt ?? startedAt).add(Duration(days: intervalDays));

  /// [now] itibarıyla bakım zamanı geldiyse `true`.
  bool isDue(DateTime now) => enabled && !now.isBefore(dueAt);

  /// Bakım tamamlandı olarak işaretlenmiş kopya.
  MaintenanceTask markDone(DateTime at) => MaintenanceTask(
    id: id,
    templateId: templateId,
    title: title,
    intervalDays: intervalDays,
    startedAt: startedAt,
    lastDoneAt: at,
    enabled: enabled,
  );

  /// Değiştirilmiş kopya.
  MaintenanceTask copyWith({int? intervalDays, bool? enabled, String? title}) =>
      MaintenanceTask(
        id: id,
        templateId: templateId,
        title: title ?? this.title,
        intervalDays: intervalDays ?? this.intervalDays,
        startedAt: startedAt,
        lastDoneAt: lastDoneAt,
        enabled: enabled ?? this.enabled,
      );

  /// JSON'a yazar.
  Map<String, Object?> toJson() => {
    'id': id,
    if (templateId != null) 'templateId': templateId,
    'title': title,
    'intervalDays': intervalDays,
    'startedAt': startedAt.toIso8601String(),
    if (lastDoneAt != null) 'lastDoneAt': lastDoneAt!.toIso8601String(),
    'enabled': enabled,
  };
}

/// Profildeki ekipmana göre eksik bakım görevlerini oluşturur; mevcut
/// görevler korunur, artık geçerli olmayan şablon görevleri çıkarılır.
/// Kullanıcının elle tanımladığı görevlere dokunulmaz (KHV-FR-ENG-009).
List<MaintenanceTask> syncMaintenanceTasks(
  List<MaintenanceTask> current,
  List<MaintenanceTemplate> templates,
  EquipmentProfile equipment, {
  required DateTime now,
}) {
  final applicable = {
    for (final t in templates)
      if (t.appliesTo(equipment)) t.id: t,
  };
  final result = <MaintenanceTask>[
    for (final task in current)
      if (task.templateId == null || applicable.containsKey(task.templateId))
        task,
  ];
  final existing = {for (final t in result) t.templateId};
  for (final t in applicable.values) {
    if (existing.contains(t.id)) continue;
    result.add(
      MaintenanceTask(
        id: 'mt-${t.id}',
        templateId: t.id,
        title: t.title,
        intervalDays: t.intervalDays,
        startedAt: now,
      ),
    );
  }
  return result;
}
