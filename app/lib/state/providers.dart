import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:uuid/uuid.dart';

import '../data/database.dart';

/// Yerel veritabanı; `main` içinde gerçek bağlantıyla, testlerde bellek içi
/// veritabanıyla değiştirilir.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider override edilmeli'),
);

/// Uygulamaya gömülü içerik paketi (KHV-NFR-026).
///
/// Gömülü içerik tekrar denemeyle düzelmez; otomatik yeniden deneme
/// kapalıdır, böylece hata kullanıcıya hemen gösterilir (KHV-HMI-042).
final contentProvider = FutureProvider<ContentBundle>((ref) async {
  final text = await rootBundle.loadString('assets/content/bundle.json');
  return ContentBundle.fromJson(
    (jsonDecode(text) as Map).cast<String, Object?>(),
  );
}, retry: (_, _) => null);

/// Saat kaynağı; testlerde sabitlenebilir.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final _monotonic = Stopwatch()..start();

/// Monotonik saat (ms); cihaz saati değişse de geriye gitmez
/// (KHV-FR-BRW-011). Testlerde değiştirilir.
final monotonicMsProvider = Provider<int Function()>(
  (ref) =>
      () => _monotonic.elapsedMilliseconds,
);

/// Rehber modda kullanılacak terazi (KHV-ARC-007). MVP'de elle giriş;
/// ikinci sürümde eşleştirilmiş Bluetooth terazi aynı arayüzle döner.
final scaleFactoryProvider = Provider<Scale Function()>(
  (ref) =>
      () => ManualScale(clock: ref.read(clockProvider)),
);

/// Kimlik üretici.
final idProvider = Provider<String Function()>(
  (ref) =>
      () => const Uuid().v4(),
);

final userRecipesProvider = StreamProvider<List<Recipe>>(
  (ref) => ref.watch(databaseProvider).watchUserRecipes(),
);

final favoritesProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(databaseProvider).watchFavorites(),
);

/// Sistem ve kullanıcı tarifleri; favori işaretiyle.
final allRecipesProvider = Provider<List<Recipe>>((ref) {
  final system = ref.watch(contentProvider).value?.recipes ?? const [];
  final user = ref.watch(userRecipesProvider).value ?? const [];
  final favs = ref.watch(favoritesProvider).value ?? const {};
  return [
    for (final r in [...user, ...system])
      r.copyWith(favorite: favs.contains(r.id)),
  ];
});

final recipeByIdProvider = Provider.family<Recipe?, String>((ref, id) {
  for (final r in ref.watch(allRecipesProvider)) {
    if (r.id == id) return r;
  }
  return null;
});

final beansProvider = StreamProvider<List<Bean>>(
  (ref) => ref.watch(databaseProvider).watchBeans(),
);

final brewsProvider = StreamProvider<List<Brew>>(
  (ref) => ref.watch(databaseProvider).watchBrews(),
);

final dialInEngineProvider = Provider<DialInEngine?>((ref) {
  final c = ref.watch(contentProvider).value;
  return c == null ? null : DialInEngine(c.rules);
});

/// Kaydın tarifini, demleme anındaki haliyle çözer (KHV-FR-RCP-014).
Recipe brewRecipe(Brew b) =>
    Recipe.fromJson((jsonDecode(b.recipeJson) as Map).cast<String, Object?>());

TasteAssessment? brewAssessment(Brew b) => b.assessmentJson == null
    ? null
    : TasteAssessment.fromJson(
        (jsonDecode(b.assessmentJson!) as Map).cast<String, Object?>(),
      );

Correction? brewCorrection(Brew b) => b.correctionJson == null
    ? null
    : Correction.fromJson(
        (jsonDecode(b.correctionJson!) as Map).cast<String, Object?>(),
      );
