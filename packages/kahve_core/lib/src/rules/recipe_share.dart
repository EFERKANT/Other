import 'dart:convert';

import '../model/recipe.dart';
import 'calculator.dart';

/// Paylaşım/içe aktarma doğrulama hatası (KHV-FR-SOC-009).
class RecipeValidationException implements Exception {
  /// Bir hata oluşturur.
  const RecipeValidationException(this.reasons);

  /// Kullanıcıya gösterilecek nedenler.
  final List<String> reasons;

  @override
  String toString() => 'RecipeValidationException(${reasons.join('; ')})';
}

/// Tarifin şema ve değer aralığı doğrulaması. Hata yoksa boş liste döner.
///
/// Bu doğrulama içe aktarma içindir; değerler yöntem sınırlarının belirgin
/// dışındaysa (ör. bozuk veri) tarif reddedilir.
List<String> validateRecipe(Recipe r) {
  final errors = <String>[];
  if (r.name.trim().isEmpty || r.name.length > 80) {
    errors.add('Tarif adı 1-80 karakter olmalıdır.');
  }
  if (r.coffeeG <= 0 || r.waterG <= 0) {
    errors.add('Kahve ve su miktarı sıfırdan büyük olmalıdır.');
  } else {
    final l = MethodLimits.of(r.method);
    // İçe aktarmada uyarı aralığının yarısı kadar tolerans tanınır.
    if (r.ratio < l.ratio.min * 0.5 || r.ratio > l.ratio.max * 1.5) {
      errors.add('Oran bu yöntem için geçersiz.');
    }
    if (r.coffeeG < l.coffeeG.min * 0.5 || r.coffeeG > l.coffeeG.max * 1.5) {
      errors.add('Kahve miktarı bu yöntem için geçersiz.');
    }
  }
  final t = r.temperatureC;
  if (t != null && (t < 0 || t > 100)) {
    errors.add('Su sıcaklığı 0-100 °C arasında olmalıdır.');
  }
  if (r.steps.isEmpty || r.steps.length > 30) {
    errors.add('Tarif 1-30 adım içermelidir.');
  }
  var lastWater = 0.0;
  for (final s in r.steps) {
    if (s.title.trim().isEmpty) errors.add('Adım adı boş olamaz.');
    final d = s.durationS;
    if (d != null && (d <= 0 || d > 48 * 3600)) {
      errors.add('Adım süresi geçersiz.');
    }
    final w = s.targetWaterG;
    if (w != null) {
      if (w < lastWater) errors.add('Adım su hedefleri azalan olamaz.');
      if (w > r.waterG * 1.05 + 1) {
        errors.add('Adım su hedefi toplam suyu aşıyor.');
      }
      lastWater = w;
    }
  }
  return errors.toSet().toList();
}

/// Paylaşım bağlantısı için tarifi kodlar (KHV-FR-SOC-003, SOC-010).
///
/// Kullanıcı kimliği, cihaz bilgisi, not veya konum içermez. Sonuç
/// base64url biçimindedir.
String encodeSharedRecipe(Recipe r) {
  final json = r.toJson()
    ..remove('notes')
    ..remove('favorite')
    ..remove('owner');
  return base64Url.encode(utf8.encode(jsonEncode({'v': 1, 'recipe': json})));
}

/// Paylaşılan tarifi çözer ve doğrular (KHV-FR-SOC-009). İçe aktarılan
/// tarif yeni kimlik alır, kaynak kimliğini korur (KHV-FR-SOC-004).
Recipe decodeSharedRecipe(String payload, {required String newId}) {
  Map<String, Object?> root;
  try {
    final normalized = base64Url.normalize(payload.trim());
    final text = utf8.decode(base64Url.decode(normalized));
    root = (jsonDecode(text) as Map).cast<String, Object?>();
  } on Object {
    throw const RecipeValidationException(['Bağlantı bozuk veya eksik.']);
  }
  if (root['v'] != 1) {
    throw const RecipeValidationException([
      'Bu tarif uygulamanın daha yeni bir sürümüyle paylaşılmış.',
    ]);
  }
  Recipe source;
  try {
    source = Recipe.fromJson((root['recipe']! as Map).cast<String, Object?>());
  } on Object {
    throw const RecipeValidationException(['Tarif verisi okunamadı.']);
  }
  final errors = validateRecipe(source);
  if (errors.isNotEmpty) throw RecipeValidationException(errors);
  return source.copyWith(
    id: newId,
    version: 1,
    sourceRecipeId: source.sourceRecipeId ?? source.id,
    owner: RecipeOwner.user,
    favorite: false,
  );
}
