import 'package:meta/meta.dart';

import '../model/brew_method.dart';
import '../model/equipment.dart';
import '../model/recipe.dart';
import '../model/taste.dart';

/// Bölüm 6'daki belirtiler.
enum Symptom {
  /// Ekşi, keskin, kısa biten tat.
  underExtraction,

  /// Acı, buruk, ağzı kurutan tat.
  overExtraction,

  /// Hem ekşi hem acı.
  unevenExtraction,

  /// Sulu, zayıf ama dengeli.
  weak,

  /// Çok yoğun, ağır ama dengeli.
  strong,

  /// Düz, kartonsu, aromasız.
  stale,

  /// Klor, metal veya kireç tadı.
  waterQuality,

  /// Pour over süresi aşıldı, filtre tıkanıyor.
  slowDrawdown,

  /// Espresso 20 sn'den kısa aktı.
  shotFast,

  /// Espresso 35 sn'den uzun aktı.
  shotSlow,

  /// Türk kahvesi köpüksüz.
  turkishNoFoam,

  /// Türk kahvesi taştı.
  turkishOverflow,

  /// Moka pot yanık ve metalik.
  mokaBurnt;

  /// Extraction ekseninde ters belirtisi (yalnız ekşi/acı için).
  Symptom? get opposite => switch (this) {
    underExtraction => overExtraction,
    overExtraction => underExtraction,
    shotFast => shotSlow,
    shotSlow => shotFast,
    _ => null,
  };

  /// Extraction sorunuysa `true` (Bölüm 6, kural 2).
  bool get isExtraction =>
      this == underExtraction ||
      this == overExtraction ||
      this == shotFast ||
      this == shotSlow ||
      this == slowDrawdown;

  /// Strength sorunuysa `true` (Bölüm 6, kural 3).
  bool get isStrength => this == weak || this == strong;
}

/// Düzeltmenin değiştirdiği değişken.
enum CorrectionVariable {
  /// Öğütme inceliği.
  grind,

  /// Su sıcaklığı.
  temperature,

  /// Temas süresi.
  time,

  /// Kahve:su oranı.
  ratio,

  /// Kahve dozu.
  dose,

  /// Döküş, dağıtım veya tamp tekniği.
  technique,

  /// Çekirdek seçimi veya tazeliği.
  beans,

  /// Su kalitesi.
  water,

  /// Ocak ateşi.
  heat,

  /// Ekipman.
  equipment,
}

/// Düzeltme yönü.
enum CorrectionDirection {
  /// Daha ince öğütme.
  finer,

  /// Daha kalın öğütme.
  coarser,

  /// Değeri artır (oran için: daha fazla su).
  increase,

  /// Değeri azalt (oran için: daha az su, daha yoğun).
  decrease,

  /// Yönü olmayan tavsiye.
  none;

  /// Ters yön.
  CorrectionDirection get inverse => switch (this) {
    finer => coarser,
    coarser => finer,
    increase => decrease,
    decrease => increase,
    none => none,
  };
}

/// İçerik tablosundan gelen bir düzeltme kuralı (KHV-CNT-002).
@immutable
class CorrectionRule {
  /// Bir kural oluşturur.
  const CorrectionRule({
    required this.id,
    required this.symptom,
    required this.tier,
    required this.variable,
    required this.direction,
    required this.text,
    required this.reason,
    this.amount = 0,
    this.methods = const {},
  });

  /// JSON'dan okur.
  factory CorrectionRule.fromJson(Map<String, Object?> json) => CorrectionRule(
    id: json['id']! as String,
    symptom: Symptom.values.byName(json['symptom']! as String),
    tier: (json['tier']! as num).toInt(),
    methods: {
      for (final m in (json['methods'] as List<Object?>? ?? const []))
        BrewMethod.parse(m! as String),
    },
    variable: CorrectionVariable.values.byName(json['variable']! as String),
    direction: CorrectionDirection.values.byName(json['direction']! as String),
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    text: json['text']! as String,
    reason: json['reason']! as String,
  );

  /// Kural kimliği.
  final String id;

  /// İlgili belirti.
  final Symptom symptom;

  /// 1: ilk düzeltme, 2: ikinci düzeltme.
  final int tier;

  /// Kuralın geçerli olduğu yöntemler; boşsa tüm yöntemler.
  final Set<BrewMethod> methods;

  /// Değiştirilecek değişken.
  final CorrectionVariable variable;

  /// Yön.
  final CorrectionDirection direction;

  /// Miktar (kademe, °C, sn, oran birimi veya g).
  final double amount;

  /// Kullanıcıya gösterilecek kısa öneri.
  final String text;

  /// "Neden" açıklaması (KHV-FR-DIA-004).
  final String reason;

  /// Kural [method] için geçerliyse `true`.
  bool appliesTo(BrewMethod method) =>
      methods.isEmpty || methods.contains(method);
}

/// Önerinin türü.
enum CorrectionKind {
  /// Tek değişkende ayarlama.
  adjust,

  /// Bir önceki ayara dönüş (Bölüm 6, kural 4).
  revert,
}

/// Kullanıcıya sunulan tek düzeltme önerisi (KHV-FR-DIA-003).
@immutable
class Correction {
  /// Bir öneri oluşturur.
  const Correction({
    required this.symptom,
    required this.variable,
    required this.direction,
    required this.amount,
    required this.text,
    required this.reason,
    this.ruleId,
    this.tier = 1,
    this.kind = CorrectionKind.adjust,
  });

  /// Bir kuraldan öneri oluşturur.
  factory Correction.fromRule(CorrectionRule rule) => Correction(
    ruleId: rule.id,
    symptom: rule.symptom,
    tier: rule.tier,
    variable: rule.variable,
    direction: rule.direction,
    amount: rule.amount,
    text: rule.text,
    reason: rule.reason,
  );

  /// JSON'dan okur.
  factory Correction.fromJson(Map<String, Object?> json) => Correction(
    ruleId: json['ruleId'] as String?,
    symptom: Symptom.values.byName(json['symptom']! as String),
    tier: (json['tier'] as num?)?.toInt() ?? 1,
    kind: CorrectionKind.values.byName(json['kind'] as String? ?? 'adjust'),
    variable: CorrectionVariable.values.byName(json['variable']! as String),
    direction: CorrectionDirection.values.byName(json['direction']! as String),
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    text: json['text']! as String,
    reason: json['reason']! as String,
  );

  /// Kaynak kural kimliği.
  final String? ruleId;

  /// Önerinin hedeflediği belirti.
  final Symptom symptom;

  /// Kuralın kademesi (1 veya 2).
  final int tier;

  /// Öneri türü.
  final CorrectionKind kind;

  /// Değiştirilecek değişken.
  final CorrectionVariable variable;

  /// Yön.
  final CorrectionDirection direction;

  /// Miktar.
  final double amount;

  /// Kısa öneri metni.
  final String text;

  /// "Neden" açıklaması.
  final String reason;

  /// Tarif parametresini değiştiren bir öneri ise `true`.
  bool get isParametric => const {
    CorrectionVariable.grind,
    CorrectionVariable.temperature,
    CorrectionVariable.time,
    CorrectionVariable.ratio,
    CorrectionVariable.dose,
  }.contains(variable);

  /// JSON'a yazar.
  Map<String, Object?> toJson() => {
    if (ruleId != null) 'ruleId': ruleId,
    'symptom': symptom.name,
    'tier': tier,
    'kind': kind.name,
    'variable': variable.name,
    'direction': direction.name,
    'amount': amount,
    'text': text,
    'reason': reason,
  };
}

/// Aynı tarif zincirinde daha önce yapılmış bir deneme.
@immutable
class DialInAttempt {
  /// Bir deneme kaydı oluşturur.
  const DialInAttempt({
    required this.assessment,
    this.symptom,
    this.acceptedCorrection,
  });

  /// Denemenin tat değerlendirmesi.
  final TasteAssessment assessment;

  /// Denemede tespit edilen belirti (dengeli ise `null`).
  final Symptom? symptom;

  /// Kullanıcının kabul ettiği öneri (varsa).
  final Correction? acceptedCorrection;
}

/// Üç denemede ilerleme olmadığında gösterilen kök neden kontrolleri
/// (KHV-FR-DIA-006, Bölüm 6 kural 5).
enum RootCauseCheck {
  /// Öğütücü homojenliği (blade grinder vb.).
  grinder,

  /// Su kalitesi.
  water,

  /// Çekirdek tazeliği.
  beanFreshness,

  /// Tartım tutarlılığı.
  scale,
}

/// Dial-in motorunun sonucu.
@immutable
class DialInResult {
  /// Bir sonuç oluşturur.
  const DialInResult({
    this.symptom,
    this.correction,
    this.rootCauseChecks = const [],
    this.suspectedRootCauses = const {},
  });

  /// Tespit edilen belirti; dengeli fincanda `null`.
  final Symptom? symptom;

  /// Tek düzeltme önerisi; dengeli fincanda `null`.
  final Correction? correction;

  /// Gösterilecek kök neden kontrol listesi; boşsa gösterilmez.
  final List<RootCauseCheck> rootCauseChecks;

  /// Ekipman profiline göre öncelikli şüphelenilen nedenler.
  final Set<RootCauseCheck> suspectedRootCauses;

  /// Dengeli sonuç, tarif olarak kaydedilmeye aday.
  bool get isBalanced => symptom == null;

  /// Kök neden kontrol listesi gösterilmeli mi.
  bool get showRootCauseChecklist => rootCauseChecks.isNotEmpty;
}

/// Tat değerlendirmesinden tek bir düzeltme üreten motor
/// (KHV-FR-DIA-002 - DIA-006, Bölüm 6 kuralları).
class DialInEngine {
  /// Kural tablosuyla bir motor oluşturur.
  DialInEngine(Iterable<CorrectionRule> rules) : _rules = List.of(rules);

  final List<CorrectionRule> _rules;

  /// Tüm kurallar.
  List<CorrectionRule> get rules => List.unmodifiable(_rules);

  /// [current] değerlendirmeden belirtiyi türetir. Öncelik: süreç
  /// gözlemleri, düzensiz extraction, bayatlık, extraction, strength.
  static Symptom? detectSymptom(BrewMethod method, TasteAssessment current) {
    final o = current.observations;
    if (method == BrewMethod.turkish) {
      if (o.contains(ProcessObservation.overflow)) {
        return Symptom.turkishOverflow;
      }
      if (o.contains(ProcessObservation.noFoam)) return Symptom.turkishNoFoam;
    }
    if (method == BrewMethod.mokaPot && o.contains(ProcessObservation.burnt)) {
      return Symptom.mokaBurnt;
    }
    if (method == BrewMethod.espresso) {
      if (o.contains(ProcessObservation.shotFast)) return Symptom.shotFast;
      if (o.contains(ProcessObservation.shotSlow)) return Symptom.shotSlow;
    }
    if (o.contains(ProcessObservation.slowDrawdown)) {
      return Symptom.slowDrawdown;
    }
    if (o.contains(ProcessObservation.offWaterTaste)) {
      return Symptom.waterQuality;
    }
    if (current.sourAndBitter) return Symptom.unevenExtraction;
    if (current.flat) return Symptom.stale;
    if (current.extraction <= -TasteAssessment.neutralBand) {
      return Symptom.underExtraction;
    }
    if (current.extraction >= TasteAssessment.neutralBand) {
      return Symptom.overExtraction;
    }
    if (current.strength <= -TasteAssessment.neutralBand) return Symptom.weak;
    if (current.strength >= TasteAssessment.neutralBand) return Symptom.strong;
    return null;
  }

  /// Değerlendirmeyi kurallara göre yorumlar.
  ///
  /// [history] aynı tarif zincirindeki önceki denemelerdir (eskiden yeniye).
  DialInResult evaluate({
    required BrewMethod method,
    required TasteAssessment current,
    List<DialInAttempt> history = const [],
    EquipmentProfile? equipment,
    int? beanAgeDays,
  }) {
    final symptom = detectSymptom(method, current);
    final checks = _noProgress(current, history, symptom)
        ? RootCauseCheck.values
        : const <RootCauseCheck>[];
    final suspected = checks.isEmpty
        ? const <RootCauseCheck>{}
        : _suspected(equipment, beanAgeDays);

    if (symptom == null) {
      return DialInResult(
        rootCauseChecks: checks,
        suspectedRootCauses: suspected,
      );
    }

    final revert = _revertIfFlipped(symptom, history);
    final correction = revert ?? _pick(method, symptom, history);
    return DialInResult(
      symptom: symptom,
      correction: correction,
      rootCauseChecks: checks,
      suspectedRootCauses: suspected,
    );
  }

  /// Kural 4: aynı yönde iki ardışık düzeltme sonrası tat tersine dönerse
  /// bir önceki ayar hedef ayar olarak önerilir.
  Correction? _revertIfFlipped(Symptom symptom, List<DialInAttempt> history) {
    final opposite = symptom.opposite;
    if (opposite == null || history.length < 2) return null;
    final a = history[history.length - 2];
    final b = history[history.length - 1];
    final ca = a.acceptedCorrection;
    final cb = b.acceptedCorrection;
    if (ca == null || cb == null) return null;
    if (a.symptom != opposite || b.symptom != opposite) return null;
    if (ca.variable != cb.variable || ca.direction != cb.direction) {
      return null;
    }
    if (!cb.isParametric) return null;
    return Correction(
      symptom: symptom,
      tier: cb.tier,
      kind: CorrectionKind.revert,
      variable: cb.variable,
      direction: cb.direction.inverse,
      amount: cb.amount,
      text: 'Bir önceki ayara dön',
      reason:
          'Aynı yöndeki iki düzeltmeden sonra tat ters yöne geçti. '
          'Hedef ayar bir önceki denemedeki ayardır.',
    );
  }

  Correction? _pick(
    BrewMethod method,
    Symptom symptom,
    List<DialInAttempt> history,
  ) {
    final tier1 = _ruleFor(method, symptom, 1);
    final tier2 = _ruleFor(method, symptom, 2);
    if (tier1 == null) {
      return tier2 == null ? null : Correction.fromRule(tier2);
    }
    // İlk düzeltme aynı belirtide art arda iki kez uygulandı ve belirti
    // sürüyorsa ikinci düzeltmeye geçilir.
    if (tier2 != null && history.length >= 2) {
      final lastTwo = history.sublist(history.length - 2);
      final tier1Twice = lastTwo.every(
        (a) => a.symptom == symptom && a.acceptedCorrection?.ruleId == tier1.id,
      );
      if (tier1Twice) return Correction.fromRule(tier2);
    }
    return Correction.fromRule(tier1);
  }

  CorrectionRule? _ruleFor(BrewMethod method, Symptom symptom, int tier) {
    CorrectionRule? generic;
    for (final r in _rules) {
      if (r.symptom != symptom || r.tier != tier || !r.appliesTo(method)) {
        continue;
      }
      if (r.methods.isNotEmpty) return r;
      generic ??= r;
    }
    return generic;
  }

  /// KHV-FR-DIA-006: son üç denemede (mevcut dahil) puan ilk denemeye göre
  /// artmadıysa `true`.
  static bool _noProgress(
    TasteAssessment current,
    List<DialInAttempt> history,
    Symptom? symptom,
  ) {
    if (history.length < 2) return false;
    if (symptom == null && current.score >= 4) return false;
    final first = history[history.length - 2].assessment.score;
    final second = history[history.length - 1].assessment.score;
    return second <= first && current.score <= first;
  }

  static Set<RootCauseCheck> _suspected(
    EquipmentProfile? equipment,
    int? beanAgeDays,
  ) {
    final result = <RootCauseCheck>{};
    final grinder = equipment?.grinder;
    if (grinder == null || !grinder.isBurr) result.add(RootCauseCheck.grinder);
    if (!(equipment?.hasWaterFilter ?? false)) {
      result.add(RootCauseCheck.water);
    }
    if (beanAgeDays == null || beanAgeDays > 30) {
      result.add(RootCauseCheck.beanFreshness);
    }
    if (!(equipment?.scaleConfirmed ?? false)) result.add(RootCauseCheck.scale);
    return result;
  }
}

/// Kabul edilen öneriyi tarifin bir sonraki demlemesine uygular
/// (KHV-FR-DIA-005). Parametrik olmayan öneriler tarifi değiştirmez.
Recipe applyCorrection(Recipe recipe, Correction c) {
  final sign = switch (c.direction) {
    CorrectionDirection.finer || CorrectionDirection.decrease => -1,
    CorrectionDirection.coarser || CorrectionDirection.increase => 1,
    CorrectionDirection.none => 0,
  };
  if (sign == 0) return recipe;
  final next = recipe.copyWith(version: recipe.version + 1);
  switch (c.variable) {
    case CorrectionVariable.grind:
      final steps = c.amount == 0 ? 1 : c.amount.round();
      return next.copyWith(grind: recipe.grind.adjust(sign * steps));
    case CorrectionVariable.temperature:
      final t = recipe.temperatureC;
      if (t == null) return recipe;
      return next.copyWith(
        temperatureC: (t + sign * c.amount).clamp(70.0, 100.0),
      );
    case CorrectionVariable.time:
      return _adjustTime(next, (sign * c.amount).round());
    case CorrectionVariable.ratio:
      final newRatio = (recipe.ratio + sign * c.amount).clamp(1.0, 30.0);
      if (recipe.method.isEspresso) {
        return _withWater(next, recipe.coffeeG * newRatio);
      }
      return next.copyWith(coffeeG: _round1(recipe.waterG / newRatio));
    case CorrectionVariable.dose:
      return next.copyWith(
        coffeeG: _round1((recipe.coffeeG + sign * c.amount).clamp(1.0, 500.0)),
      );
    case CorrectionVariable.technique:
    case CorrectionVariable.beans:
    case CorrectionVariable.water:
    case CorrectionVariable.heat:
    case CorrectionVariable.equipment:
      return recipe;
  }
}

Recipe _adjustTime(Recipe r, int deltaS) {
  // Demlemenin en uzun süreli adımı bekleme/demlenme adımıdır.
  var longest = -1;
  for (var i = 0; i < r.steps.length; i++) {
    final d = r.steps[i].durationS;
    if (d != null && (longest < 0 || d > r.steps[longest].durationS!)) {
      longest = i;
    }
  }
  final steps = [...r.steps];
  if (longest >= 0) {
    final d = steps[longest].durationS!;
    steps[longest] = steps[longest].copyWith(
      durationS: (d + deltaS).clamp(5, 1 << 30),
    );
  }
  return r.copyWith(
    steps: steps,
    targetTimeS: r.targetTimeS == null
        ? null
        : (r.targetTimeS! + deltaS).clamp(5, 1 << 30),
    targetTimeMaxS: r.targetTimeMaxS == null
        ? null
        : (r.targetTimeMaxS! + deltaS).clamp(5, 1 << 30),
  );
}

Recipe _withWater(Recipe r, double water) {
  final factor = water / r.waterG;
  return r.copyWith(
    waterG: _round1(water),
    steps: [
      for (final s in r.steps)
        s.targetWaterG == null
            ? s
            : s.copyWith(targetWaterG: _round1(s.targetWaterG! * factor)),
    ],
  );
}

double _round1(double v) => (v * 10).roundToDouble() / 10;
