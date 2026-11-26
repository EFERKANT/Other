import 'package:meta/meta.dart';

import 'event.dart' show CommunityRuleException;

/// Paylaşılan tarifin oy durumu (KHV-FR-SOC-012, SOC-013).
@immutable
class SharedRecipeVotes {
  /// Bir oy kaydı oluşturur.
  const SharedRecipeVotes({
    required this.recipeId,
    required this.authorId,
    required this.sharedAt,
    this.votes = const {},
    this.removed = false,
  });

  /// Ortalamanın gösterilmesi için gereken en az oy (KHV-FR-SOC-013).
  static const minVotesForAverage = 5;

  /// Paylaşılan tarif.
  final String recipeId;

  /// Paylaşan.
  final String authorId;

  /// Paylaşım anı.
  final DateTime sharedAt;

  /// Kullanıcı kimliği → puan (1-5).
  final Map<String, int> votes;

  /// Paylaşan kaldırdı mı (KHV-FR-SOC-014).
  final bool removed;

  /// Oy sayısı.
  int get count => votes.length;

  /// Ortalama; oy yoksa `null`.
  double? get average => votes.isEmpty
      ? null
      : votes.values.reduce((a, b) => a + b) / votes.length;

  /// 5'ten az oy: ortalama yerine "yeni" etiketi (KHV-FR-SOC-013).
  bool get isNew => count < minVotesForAverage;

  /// Gösterim etiketi: "yeni" veya "4,3 (12 oy)".
  String get label => isNew
      ? 'yeni'
      : '${average!.toStringAsFixed(1).replaceAll('.', ',')} ($count oy)';
}

/// Oy verir (KHV-FR-SOC-012): yalnız o tarifle demleme kaydı olan, tarifin
/// sahibi olmayan kullanıcı; her kullanıcı bir oy.
SharedRecipeVotes voteOnRecipe(
  SharedRecipeVotes r, {
  required String userId,
  required int score,
  required bool hasBrewLogWithRecipe,
}) {
  if (r.removed) {
    throw const CommunityRuleException('Tarif paylaşımdan kaldırıldı.');
  }
  if (userId == r.authorId) {
    throw const CommunityRuleException('Kendi tarifinize oy veremezsiniz.');
  }
  if (!hasBrewLogWithRecipe) {
    throw const CommunityRuleException(
      'Oy vermek için önce bu tarifle demleyip kaydetmelisiniz.',
    );
  }
  if (r.votes.containsKey(userId)) {
    throw const CommunityRuleException('Bu tarife zaten oy verdiniz.');
  }
  if (score < 1 || score > 5) {
    throw const CommunityRuleException('Puan 1-5 arasında olmalıdır.');
  }
  return SharedRecipeVotes(
    recipeId: r.recipeId,
    authorId: r.authorId,
    sharedAt: r.sharedAt,
    votes: {...r.votes, userId: score},
  );
}

/// Paylaşılan tarif sıralaması (KHV-FR-SOC-013): en az 5 oylu tarifler
/// ortalamaya, eşitlikte oy sayısına göre önce; ardından "yeni" tarifler oy
/// sayısına, eşitlikte yeniliğe göre. Kaldırılanlar listelenmez
/// (KHV-FR-SOC-014).
List<SharedRecipeVotes> rankSharedRecipes(Iterable<SharedRecipeVotes> all) {
  final live = all.where((r) => !r.removed).toList();
  live.sort((a, b) {
    if (a.isNew != b.isNew) return a.isNew ? 1 : -1;
    if (!a.isNew) {
      final byAvg = b.average!.compareTo(a.average!);
      if (byAvg != 0) return byAvg;
    }
    final byCount = b.count.compareTo(a.count);
    if (byCount != 0) return byCount;
    return b.sharedAt.compareTo(a.sharedAt);
  });
  return live;
}

/// Paylaşımı kaldırır (KHV-FR-SOC-014). Yalnız paylaşan kaldırabilir;
/// deneyenlerin demleme kayıtları cihazlarında tarifin anlık görüntüsüyle
/// korunur (KHV-FR-RCP-014).
SharedRecipeVotes removeShared(SharedRecipeVotes r, String actorId) {
  if (actorId != r.authorId) {
    throw const CommunityRuleException('Yalnız paylaşan kaldırabilir.');
  }
  return SharedRecipeVotes(
    recipeId: r.recipeId,
    authorId: r.authorId,
    sharedAt: r.sharedAt,
    votes: r.votes,
    removed: true,
  );
}
