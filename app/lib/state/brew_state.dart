import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import 'providers.dart';

/// Arka planda izlenen uzun süreli demleme (KHV-FR-BRW-009, BRW-010).
@immutable
class LongBrew {
  const LongBrew({
    required this.id,
    required this.recipe,
    required this.startedAt,
    required this.endsAt,
    this.beanId,
  });

  factory LongBrew.fromJson(Map<String, Object?> j) => LongBrew(
    id: j['id']! as String,
    recipe: Recipe.fromJson((j['recipe']! as Map).cast<String, Object?>()),
    startedAt: DateTime.parse(j['startedAt']! as String),
    endsAt: DateTime.parse(j['endsAt']! as String),
    beanId: j['beanId'] as String?,
  );

  final String id;
  final Recipe recipe;
  final DateTime startedAt;
  final DateTime endsAt;
  final String? beanId;

  Map<String, Object?> toJson() => {
    'id': id,
    'recipe': recipe.toJson(),
    'startedAt': startedAt.toIso8601String(),
    'endsAt': endsAt.toIso8601String(),
    if (beanId != null) 'beanId': beanId,
  };
}

class LongBrewsController extends AsyncNotifier<List<LongBrew>> {
  static const _key = 'longBrews';

  @override
  Future<List<LongBrew>> build() async {
    final j = await ref.watch(databaseProvider).readJson(_key);
    return [
      for (final e in (j?['items'] as List<Object?>? ?? const []))
        LongBrew.fromJson((e! as Map).cast<String, Object?>()),
    ];
  }

  Future<void> _save(List<LongBrew> items) async {
    state = AsyncData(items);
    await ref.read(databaseProvider).writeJson(_key, {
      'items': [for (final i in items) i.toJson()],
    });
  }

  Future<void> add(LongBrew b) async =>
      _save([...(state.value ?? await future), b]);

  Future<void> remove(String id) async => _save([
    for (final b in state.value ?? await future)
      if (b.id != id) b,
  ]);
}

final longBrewsProvider =
    AsyncNotifierProvider<LongBrewsController, List<LongBrew>>(
      LongBrewsController.new,
    );

/// Devam eden rehberli demlemenin kalıcı durumu (KHV-NFR-003,
/// KHV-HMI-023, KHV-HMI-040).
@immutable
class ActiveBrew {
  const ActiveBrew({
    required this.recipe,
    required this.snapshot,
    required this.savedAt,
    this.beanId,
    this.checklistDone = true,
  });

  factory ActiveBrew.fromJson(Map<String, Object?> j) => ActiveBrew(
    recipe: Recipe.fromJson((j['recipe']! as Map).cast<String, Object?>()),
    snapshot: BrewTimerSnapshot.fromJson(
      (j['snapshot']! as Map).cast<String, Object?>(),
    ),
    savedAt: DateTime.parse(j['savedAt']! as String),
    beanId: j['beanId'] as String?,
    checklistDone: j['checklistDone'] as bool? ?? true,
  );

  final Recipe recipe;
  final BrewTimerSnapshot snapshot;
  final DateTime savedAt;
  final String? beanId;
  final bool checklistDone;

  Map<String, Object?> toJson() => {
    'recipe': recipe.toJson(),
    'snapshot': snapshot.toJson(),
    'savedAt': savedAt.toIso8601String(),
    if (beanId != null) 'beanId': beanId,
    'checklistDone': checklistDone,
  };
}

const activeBrewKey = 'activeBrew';

Future<ActiveBrew?> loadActiveBrew(WidgetRef ref) async {
  final j = await ref.read(databaseProvider).readJson(activeBrewKey);
  if (j == null) return null;
  try {
    return ActiveBrew.fromJson(j);
  } on Object {
    await ref.read(databaseProvider).deleteKey(activeBrewKey);
    return null;
  }
}
