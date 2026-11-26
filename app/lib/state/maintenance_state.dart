import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kahve_core/kahve_core.dart';

import 'providers.dart';
import 'settings.dart';

/// Bakım görevleri; ekipman profiline göre içerik şablonlarından türetilir
/// ve kullanıcı değişiklikleriyle saklanır (KHV-FR-ENG-001, ENG-002,
/// ENG-009).
class MaintenanceController extends AsyncNotifier<List<MaintenanceTask>> {
  static const _key = 'maintenance';

  @override
  Future<List<MaintenanceTask>> build() async {
    final db = ref.watch(databaseProvider);
    final content = await ref.watch(contentProvider.future);
    final settings = await ref.watch(settingsProvider.future);
    final j = await db.readJson(_key);
    final stored = [
      for (final e in (j?['items'] as List<Object?>? ?? const []))
        MaintenanceTask.fromJson((e! as Map).cast<String, Object?>()),
    ];
    if (!content.flag('maintenance')) return stored;
    return syncMaintenanceTasks(
      stored,
      content.maintenance,
      settings.equipment,
      now: ref.read(clockProvider)(),
    );
  }

  Future<void> _save(List<MaintenanceTask> items) async {
    state = AsyncData(items);
    await ref.read(databaseProvider).writeJson(_key, {
      'items': [for (final i in items) i.toJson()],
    });
  }

  Future<void> _replace(MaintenanceTask t) async => _save([
    for (final x in state.value ?? await future) x.id == t.id ? t : x,
  ]);

  /// Bakımı tamamlandı olarak işaretler (KHV-FR-ENG-002).
  Future<void> markDone(MaintenanceTask t) async {
    await _replace(t.markDone(ref.read(clockProvider)()));
    await ref.read(databaseProvider).logEvent('maintenance', {
      'id': t.id,
      'templateId': t.templateId,
    });
  }

  /// Aralığı veya açık/kapalı durumunu değiştirir (KHV-FR-ENG-001).
  Future<void> save(MaintenanceTask t) => _replace(t);

  /// Otomatik takvimi olmayan ekipman için elle bakım tanımlar
  /// (KHV-FR-ENG-009).
  Future<void> addCustom(String title, int intervalDays) async => _save([
    ...state.value ?? await future,
    MaintenanceTask(
      id: ref.read(idProvider)(),
      title: title,
      intervalDays: intervalDays,
      startedAt: ref.read(clockProvider)(),
    ),
  ]);

  Future<void> remove(MaintenanceTask t) async => _save([
    for (final x in state.value ?? await future)
      if (x.id != t.id) x,
  ]);
}

final maintenanceProvider =
    AsyncNotifierProvider<MaintenanceController, List<MaintenanceTask>>(
      MaintenanceController.new,
    );
