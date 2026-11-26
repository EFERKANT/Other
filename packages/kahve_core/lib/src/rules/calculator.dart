import 'package:meta/meta.dart';

import '../model/brew_method.dart';
import '../model/recipe.dart';
import '../model/taste.dart';

/// Hesaplayıcıya verilen değerlerden hangisinin hesaplanacağı.
enum CalcTarget {
  /// Kahve miktarını hesapla.
  coffee,

  /// Su miktarını hesapla.
  water,

  /// Oranı hesapla.
  ratio,
}

/// Hesaplayıcı sonucu (g ve 1:x oranı).
@immutable
class BrewAmounts {
  /// Bir sonuç oluşturur.
  const BrewAmounts({
    required this.coffeeG,
    required this.waterG,
    required this.ratio,
  });

  /// Kahve (g).
  final double coffeeG;

  /// Su (g).
  final double waterG;

  /// Oran (1:x için x).
  final double ratio;

  @override
  bool operator ==(Object other) =>
      other is BrewAmounts &&
      other.coffeeG == coffeeG &&
      other.waterG == waterG &&
      other.ratio == ratio;

  @override
  int get hashCode => Object.hash(coffeeG, waterG, ratio);

  @override
  String toString() => 'BrewAmounts($coffeeG g, $waterG g, 1:$ratio)';
}

/// Hesaplayıcı girdisi geçersiz olduğunda fırlatılır.
class CalculatorException implements Exception {
  /// Bir hata oluşturur.
  const CalculatorException(this.message);

  /// Kullanıcıya gösterilebilir açıklama.
  final String message;

  @override
  String toString() => 'CalculatorException: $message';
}

/// Oran, kahve ve su hesaplayıcısı (KHV-FR-RCP-002, RCP-003).
abstract final class BrewCalculator {
  /// Üst sınır: bir demlemede makul en büyük su miktarı (g).
  static const maxWaterG = 5000.0;

  /// Herhangi ikisi verildiğinde üçüncüyü hesaplar (KHV-FR-RCP-002).
  ///
  /// Sonuçlar 0,1 hassasiyetine yuvarlanır. Eksik veya sıfır/negatif
  /// değerlerde [CalculatorException] fırlatır.
  static BrewAmounts solve({double? coffeeG, double? waterG, double? ratio}) {
    final given = [coffeeG, waterG, ratio].where((v) => v != null).length;
    if (given < 2) {
      throw const CalculatorException('İki değer girilmelidir.');
    }
    for (final v in [coffeeG, waterG, ratio]) {
      if (v != null && (v.isNaN || v.isInfinite || v <= 0)) {
        throw const CalculatorException('Değerler sıfırdan büyük olmalıdır.');
      }
    }
    if ((waterG ?? 0) > maxWaterG) {
      throw const CalculatorException('Su miktarı çok büyük.');
    }
    if (coffeeG != null && waterG != null) {
      return BrewAmounts(
        coffeeG: round1(coffeeG),
        waterG: round1(waterG),
        ratio: round1(waterG / coffeeG),
      );
    }
    if (coffeeG != null) {
      final w = coffeeG * ratio!;
      if (w > maxWaterG) {
        throw const CalculatorException('Su miktarı çok büyük.');
      }
      return BrewAmounts(
        coffeeG: round1(coffeeG),
        waterG: round1(w),
        ratio: round1(ratio),
      );
    }
    return BrewAmounts(
      coffeeG: round1(waterG! / ratio!),
      waterG: round1(waterG),
      ratio: round1(ratio),
    );
  }

  /// Fincan sayısı ve fincan hacminden miktarları hesaplar
  /// (KHV-FR-RCP-003). Su yoğunluğu 1 g/ml kabul edilir.
  static BrewAmounts forCups({
    required int cups,
    required double cupMl,
    required double ratio,
  }) {
    if (cups <= 0 || cupMl <= 0) {
      throw const CalculatorException(
        'Fincan sayısı ve hacmi sıfırdan büyük olmalıdır.',
      );
    }
    return solve(waterG: cups * cupMl, ratio: ratio);
  }

  /// Türk kahvesi: fincan başına 6,5 g kahve ve 67,5 ml su
  /// (Bölüm 4: 6-7 g, 65-70 ml).
  static BrewAmounts turkish(int cups) {
    if (cups <= 0) {
      throw const CalculatorException('Fincan sayısı en az 1 olmalıdır.');
    }
    return BrewAmounts(
      coffeeG: round1(cups * 6.5),
      waterG: round1(cups * 67.5),
      ratio: round1(67.5 / 6.5),
    );
  }

  /// 0,1 hassasiyetine yuvarlar.
  static double round1(double v) => (v * 10).roundToDouble() / 10;
}

/// Kaşık eşdeğeri (KHV-FR-RCP-004). Değerler yaklaşıktır.
abstract final class SpoonEquivalent {
  /// Bir silme yemek kaşığı öğütülmüş kahvenin yaklaşık ağırlığı (g).
  static const tablespoonG = 6.0;

  /// Bir tepeleme tatlı kaşığı Türk kahvesinin yaklaşık ağırlığı (g).
  static const turkishTeaspoonG = 6.5;

  /// [coffeeG] için kaşık sayısını yarım kaşık hassasiyetinde döndürür.
  static double spoons(double coffeeG, BrewMethod method) {
    final per = method == BrewMethod.turkish ? turkishTeaspoonG : tablespoonG;
    return (coffeeG / per * 2).roundToDouble() / 2;
  }

  /// Kaşık türünün adı.
  static String spoonName(BrewMethod method) =>
      method == BrewMethod.turkish ? 'tatlı kaşığı' : 'yemek kaşığı';
}

/// Sıcaklık ayarlı kettle yoksa kaynama sonrası bekleme süresi
/// (KHV-FR-RCP-008, Bölüm 3 "Kaynar suyu bekletin").
///
/// Soğuk başlanan yöntemlerde (Türk kahvesi, cold brew) veya hedef sıcaklık
/// yoksa `null` döner.
int? boilWaitSeconds(BrewMethod method, double? targetC) {
  if (targetC == null) return null;
  if (method == BrewMethod.turkish || method == BrewMethod.coldBrew) {
    return null;
  }
  if (method == BrewMethod.mokaPot) return 0;
  if (targetC >= 97) return 10;
  if (targetC >= 95) return 30;
  if (targetC >= 92) return 45;
  if (targetC >= 88) return 90;
  if (targetC >= 84) return 150;
  return 240;
}

/// Bir parametrenin yönteme göre makul aralığı.
@immutable
class ParamRange {
  /// Bir aralık oluşturur.
  const ParamRange(this.min, this.max);

  /// Alt sınır.
  final double min;

  /// Üst sınır.
  final double max;

  /// [v] aralıkta ise `true`.
  bool contains(double v) => v >= min && v <= max;
}

/// Yönteme göre olası aralıklar (KHV-HMI-012, KHV-FR-SOC-009).
///
/// Bölüm 4 başlangıç değerlerinden geniş tutulmuştur; dışına çıkan değer
/// engellenmez, uyarılır.
@immutable
class MethodLimits {
  /// Bir sınır kümesi oluşturur.
  const MethodLimits({
    required this.ratio,
    required this.coffeeG,
    this.temperatureC,
  });

  /// Oran (1:x) aralığı.
  final ParamRange ratio;

  /// Doz aralığı (g).
  final ParamRange coffeeG;

  /// Sıcaklık aralığı (°C); soğuk yöntemlerde `null`.
  final ParamRange? temperatureC;

  /// Yöntemin sınırları.
  static MethodLimits of(BrewMethod m) => switch (m) {
    BrewMethod.v60 || BrewMethod.chemex => const MethodLimits(
      ratio: ParamRange(12, 20),
      coffeeG: ParamRange(8, 80),
      temperatureC: ParamRange(85, 100),
    ),
    BrewMethod.frenchPress => const MethodLimits(
      ratio: ParamRange(10, 18),
      coffeeG: ParamRange(8, 120),
      temperatureC: ParamRange(85, 100),
    ),
    BrewMethod.aeropress => const MethodLimits(
      ratio: ParamRange(6, 18),
      coffeeG: ParamRange(8, 35),
      temperatureC: ParamRange(75, 100),
    ),
    BrewMethod.dripMachine => const MethodLimits(
      ratio: ParamRange(14, 20),
      coffeeG: ParamRange(10, 150),
    ),
    BrewMethod.mokaPot => const MethodLimits(
      ratio: ParamRange(5, 12),
      coffeeG: ParamRange(5, 60),
    ),
    BrewMethod.espresso => const MethodLimits(
      ratio: ParamRange(1, 4),
      coffeeG: ParamRange(6, 25),
      temperatureC: ParamRange(85, 98),
    ),
    BrewMethod.turkish => const MethodLimits(
      ratio: ParamRange(7, 14),
      coffeeG: ParamRange(4, 60),
    ),
    BrewMethod.coldBrew => const MethodLimits(
      ratio: ParamRange(4, 18),
      coffeeG: ParamRange(20, 500),
    ),
  };
}

/// Aralık dışı parametre uyarısı.
enum RangeWarning {
  /// Oran aralık dışında.
  ratio,

  /// Doz aralık dışında.
  coffee,

  /// Sıcaklık aralık dışında.
  temperature,
}

/// Değerleri yöntem aralıklarıyla karşılaştırır; uyarıları döndürür,
/// engellemez (KHV-HMI-012).
Set<RangeWarning> rangeWarnings(
  BrewMethod method, {
  double? coffeeG,
  double? ratio,
  double? temperatureC,
}) {
  final l = MethodLimits.of(method);
  return {
    if (ratio != null && !l.ratio.contains(ratio)) RangeWarning.ratio,
    if (coffeeG != null && !l.coffeeG.contains(coffeeG)) RangeWarning.coffee,
    if (temperatureC != null &&
        l.temperatureC != null &&
        !l.temperatureC!.contains(temperatureC))
      RangeWarning.temperature,
  };
}

/// Dozu veya toplam suyu değişen tarifi ölçekler (KHV-FR-RCP-010).
///
/// Tüm adımların hedef su ağırlıkları aynı oranla ölçeklenir, adım süreleri
/// değişmez. Oran korunur.
Recipe scaleRecipe(Recipe r, {double? coffeeG, double? waterG}) {
  if ((coffeeG == null) == (waterG == null)) {
    throw ArgumentError('Yalnız biri verilmelidir: coffeeG veya waterG');
  }
  final factor = coffeeG != null ? coffeeG / r.coffeeG : waterG! / r.waterG;
  if (factor <= 0 || factor.isNaN || factor.isInfinite) {
    throw ArgumentError('Ölçek katsayısı geçersiz');
  }
  return r.copyWith(
    coffeeG: BrewCalculator.round1(r.coffeeG * factor),
    waterG: BrewCalculator.round1(r.waterG * factor),
    steps: [
      for (final s in r.steps)
        s.targetWaterG == null
            ? s
            : s.copyWith(
                targetWaterG: BrewCalculator.round1(s.targetWaterG! * factor),
              ),
    ],
  );
}

/// Türk kahvesi tarifini fincan sayısına göre ölçekler.
Recipe scaleTurkishCups(Recipe r, int cups) {
  final a = BrewCalculator.turkish(cups);
  return scaleRecipe(r, coffeeG: a.coffeeG).copyWith(cups: cups);
}

/// Espresso shot değerlendirmesi (KHV-FR-BRW-008).
@immutable
class ShotEvaluation {
  /// Bir değerlendirme oluşturur.
  const ShotEvaluation({
    required this.ratio,
    required this.timeS,
    required this.targetRatio,
    required this.timeInRange,
    required this.ratioDelta,
    required this.timeDeltaS,
    this.observation,
  });

  /// Gerçekleşen oran (çıktı/doz).
  final double ratio;

  /// Gerçekleşen süre (sn).
  final int timeS;

  /// Hedef oran.
  final double targetRatio;

  /// Süre hedef aralıkta mı.
  final bool timeInRange;

  /// Gerçekleşen oran - hedef oran.
  final double ratioDelta;

  /// Hedef aralığa göre süre sapması; aralıktaysa 0.
  final int timeDeltaS;

  /// Bölüm 6 eşiklerine göre süreç gözlemi (20 sn altı, 35 sn üstü).
  final ProcessObservation? observation;
}

/// Shot'ı tarifin hedef oran ve süre aralığıyla karşılaştırır.
ShotEvaluation evaluateShot(
  Recipe recipe, {
  required double doseG,
  required double yieldG,
  required int timeS,
}) {
  if (doseG <= 0 || yieldG <= 0 || timeS < 0) {
    throw const CalculatorException('Doz, çıktı ve süre geçerli olmalıdır.');
  }
  final min = recipe.targetTimeS ?? 25;
  final max = recipe.targetTimeMaxS ?? 30;
  final ratio = BrewCalculator.round1(yieldG / doseG);
  final target = BrewCalculator.round1(recipe.ratio);
  final delta = timeS < min
      ? timeS - min
      : timeS > max
      ? timeS - max
      : 0;
  return ShotEvaluation(
    ratio: ratio,
    timeS: timeS,
    targetRatio: target,
    timeInRange: delta == 0,
    ratioDelta: BrewCalculator.round1(ratio - target),
    timeDeltaS: delta,
    observation: timeS < 20
        ? ProcessObservation.shotFast
        : timeS > 35
        ? ProcessObservation.shotSlow
        : null,
  );
}

/// Gerçekleşen demleme süresinden otomatik süreç gözlemi türetir
/// (Bölüm 6: "Pour over 4 dakikayı aşıyor").
ProcessObservation? observeDuration(Recipe recipe, int actualS) {
  switch (recipe.method) {
    case BrewMethod.v60:
      return actualS > 240 ? ProcessObservation.slowDrawdown : null;
    case BrewMethod.chemex:
      final limit = (recipe.targetTimeMaxS ?? 300) + 60;
      return actualS > limit ? ProcessObservation.slowDrawdown : null;
    case BrewMethod.espresso:
      return actualS < 20
          ? ProcessObservation.shotFast
          : actualS > 35
          ? ProcessObservation.shotSlow
          : null;
    case BrewMethod.frenchPress:
    case BrewMethod.aeropress:
    case BrewMethod.dripMachine:
    case BrewMethod.mokaPot:
    case BrewMethod.turkish:
    case BrewMethod.coldBrew:
      return null;
  }
}
