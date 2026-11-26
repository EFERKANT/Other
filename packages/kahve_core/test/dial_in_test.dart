import 'package:kahve_core/kahve_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

TasteAssessment taste({
  int score = 3,
  double x = 0,
  double y = 0,
  bool both = false,
  bool flat = false,
  Set<ProcessObservation> obs = const {},
}) => TasteAssessment(
  score: score,
  extraction: x,
  strength: y,
  sourAndBitter: both,
  flat: flat,
  observations: obs,
);

void main() {
  final bundle = loadBundle();
  final engine = DialInEngine(bundle.rules);

  group('Bölüm 6 tablosu: her belirti için tek ilk düzeltme '
      '(KHV-FR-DIA-002, DIA-003)', () {
    final cases =
        <
          (
            String,
            BrewMethod,
            TasteAssessment,
            Symptom,
            CorrectionVariable,
            CorrectionDirection,
          )
        >[
          (
            'ekşi',
            BrewMethod.v60,
            taste(x: -0.8),
            Symptom.underExtraction,
            CorrectionVariable.grind,
            CorrectionDirection.finer,
          ),
          (
            'acı',
            BrewMethod.v60,
            taste(x: 0.8),
            Symptom.overExtraction,
            CorrectionVariable.grind,
            CorrectionDirection.coarser,
          ),
          (
            'hem ekşi hem acı - pour over',
            BrewMethod.v60,
            taste(both: true),
            Symptom.unevenExtraction,
            CorrectionVariable.technique,
            CorrectionDirection.none,
          ),
          (
            'hem ekşi hem acı - espresso',
            BrewMethod.espresso,
            taste(both: true),
            Symptom.unevenExtraction,
            CorrectionVariable.technique,
            CorrectionDirection.none,
          ),
          (
            'sulu dengeli',
            BrewMethod.chemex,
            taste(y: -0.8),
            Symptom.weak,
            CorrectionVariable.ratio,
            CorrectionDirection.decrease,
          ),
          (
            'yoğun dengeli',
            BrewMethod.frenchPress,
            taste(y: 0.8),
            Symptom.strong,
            CorrectionVariable.ratio,
            CorrectionDirection.increase,
          ),
          (
            'düz/kartonsu',
            BrewMethod.aeropress,
            taste(flat: true),
            Symptom.stale,
            CorrectionVariable.beans,
            CorrectionDirection.none,
          ),
          (
            'su tadı',
            BrewMethod.dripMachine,
            taste(obs: {ProcessObservation.offWaterTaste}),
            Symptom.waterQuality,
            CorrectionVariable.water,
            CorrectionDirection.none,
          ),
          (
            'pour over 4 dk üstü',
            BrewMethod.v60,
            taste(obs: {ProcessObservation.slowDrawdown}),
            Symptom.slowDrawdown,
            CorrectionVariable.grind,
            CorrectionDirection.coarser,
          ),
          (
            'espresso hızlı',
            BrewMethod.espresso,
            taste(obs: {ProcessObservation.shotFast}),
            Symptom.shotFast,
            CorrectionVariable.grind,
            CorrectionDirection.finer,
          ),
          (
            'espresso yavaş',
            BrewMethod.espresso,
            taste(obs: {ProcessObservation.shotSlow}),
            Symptom.shotSlow,
            CorrectionVariable.grind,
            CorrectionDirection.coarser,
          ),
          (
            'Türk köpüksüz',
            BrewMethod.turkish,
            taste(obs: {ProcessObservation.noFoam}),
            Symptom.turkishNoFoam,
            CorrectionVariable.heat,
            CorrectionDirection.none,
          ),
          (
            'Türk taştı',
            BrewMethod.turkish,
            taste(obs: {ProcessObservation.overflow}),
            Symptom.turkishOverflow,
            CorrectionVariable.technique,
            CorrectionDirection.none,
          ),
          (
            'moka yanık',
            BrewMethod.mokaPot,
            taste(obs: {ProcessObservation.burnt}),
            Symptom.mokaBurnt,
            CorrectionVariable.heat,
            CorrectionDirection.none,
          ),
        ];
    for (final (name, method, t, symptom, variable, direction) in cases) {
      test(name, () {
        final r = engine.evaluate(method: method, current: t);
        expect(r.symptom, symptom);
        expect(r.correction, isNotNull);
        expect(r.correction!.variable, variable);
        expect(r.correction!.direction, direction);
        expect(r.correction!.tier, 1);
        expect(r.correction!.reason, isNotEmpty, reason: 'DIA-004');
        expect(r.showRootCauseChecklist, isFalse);
      });
    }
  });

  test('yönteme özel kural genel kuraldan önce seçilir', () {
    final pour = engine.evaluate(
      method: BrewMethod.v60,
      current: taste(both: true),
    );
    final esp = engine.evaluate(
      method: BrewMethod.espresso,
      current: taste(both: true),
    );
    final other = engine.evaluate(
      method: BrewMethod.frenchPress,
      current: taste(both: true),
    );
    expect(pour.correction!.ruleId, 'uneven-1-pour');
    expect(esp.correction!.ruleId, 'uneven-1-esp');
    expect(other.correction!.ruleId, 'uneven-1');
  });

  test('yönteme ait olmayan gözlem yok sayılır', () {
    final r = engine.evaluate(
      method: BrewMethod.v60,
      current: taste(obs: {ProcessObservation.noFoam}),
    );
    expect(r.isBalanced, isTrue);
  });

  test('dengeli fincanda öneri yok', () {
    final r = engine.evaluate(method: BrewMethod.v60, current: taste(score: 5));
    expect(r.isBalanced, isTrue);
    expect(r.correction, isNull);
  });

  test('extraction strength sorunundan önce gelir (kural 2-3)', () {
    final r = engine.evaluate(
      method: BrewMethod.v60,
      current: taste(x: -0.6, y: -0.6),
    );
    expect(r.symptom, Symptom.underExtraction);
  });

  group('ardışık denemeler', () {
    Correction first(Symptom s, BrewMethod m, TasteAssessment t) =>
        engine.evaluate(method: m, current: t).correction!;

    test(
      'ilk düzeltme iki kez uygulandı, belirti sürüyor → ikinci düzeltme',
      () {
        final t = taste(x: -0.7);
        final c = first(Symptom.underExtraction, BrewMethod.v60, t);
        final history = [
          DialInAttempt(
            assessment: taste(x: -0.7, score: 2),
            symptom: Symptom.underExtraction,
            acceptedCorrection: c,
          ),
          DialInAttempt(
            assessment: taste(x: -0.5, score: 3),
            symptom: Symptom.underExtraction,
            acceptedCorrection: c,
          ),
        ];
        final r = engine.evaluate(
          method: BrewMethod.v60,
          current: taste(x: -0.4, score: 4),
          history: history,
        );
        expect(r.correction!.tier, 2);
        expect(r.correction!.variable, CorrectionVariable.temperature);
      },
    );

    test('immersion yönteminde ikinci düzeltme süre', () {
      final c = first(
        Symptom.underExtraction,
        BrewMethod.frenchPress,
        taste(x: -0.7),
      );
      final h = [
        for (var i = 0; i < 2; i++)
          DialInAttempt(
            assessment: taste(x: -0.7, score: 2 + i),
            symptom: Symptom.underExtraction,
            acceptedCorrection: c,
          ),
      ];
      final r = engine.evaluate(
        method: BrewMethod.frenchPress,
        current: taste(x: -0.7, score: 4),
        history: h,
      );
      expect(r.correction!.variable, CorrectionVariable.time);
    });

    test('kural 4: aynı yönde iki düzeltme sonrası tat tersine döndü → önceki ayar', () {
      final c = first(Symptom.underExtraction, BrewMethod.v60, taste(x: -0.7));
      final history = [
        DialInAttempt(
          assessment: taste(x: -0.7, score: 2),
          symptom: Symptom.underExtraction,
          acceptedCorrection: c,
        ),
        DialInAttempt(
          assessment: taste(x: -0.4, score: 3),
          symptom: Symptom.underExtraction,
          acceptedCorrection: c,
        ),
      ];
      final r = engine.evaluate(
        method: BrewMethod.v60,
        current: taste(x: 0.6, score: 3),
        history: history,
      );
      expect(r.correction!.kind, CorrectionKind.revert);
      expect(r.correction!.variable, CorrectionVariable.grind);
      expect(r.correction!.direction, CorrectionDirection.coarser);
    });

    test('kural 4 kabul edilmemiş öneride uygulanmaz', () {
      final history = [
        DialInAttempt(
          assessment: taste(x: -0.7, score: 2),
          symptom: Symptom.underExtraction,
        ),
        DialInAttempt(
          assessment: taste(x: -0.4, score: 3),
          symptom: Symptom.underExtraction,
        ),
      ];
      final r = engine.evaluate(
        method: BrewMethod.v60,
        current: taste(x: 0.6, score: 3),
        history: history,
      );
      expect(r.correction!.kind, CorrectionKind.adjust);
    });

    test('kural 4 farklı yönde düzeltmelerde uygulanmaz', () {
      final a = first(Symptom.underExtraction, BrewMethod.v60, taste(x: -0.7));
      final b = engine.rules.firstWhere((r) => r.id == 'under-2');
      final history = [
        DialInAttempt(
          assessment: taste(x: -0.7, score: 2),
          symptom: Symptom.underExtraction,
          acceptedCorrection: a,
        ),
        DialInAttempt(
          assessment: taste(x: -0.4, score: 3),
          symptom: Symptom.underExtraction,
          acceptedCorrection: Correction.fromRule(b),
        ),
      ];
      final r = engine.evaluate(
        method: BrewMethod.v60,
        current: taste(x: 0.6, score: 3),
        history: history,
      );
      expect(r.correction!.kind, CorrectionKind.adjust);
    });

    test('kural 4 espresso shot hızı için de geçerli', () {
      final c = first(
        Symptom.shotFast,
        BrewMethod.espresso,
        taste(obs: {ProcessObservation.shotFast}),
      );
      final history = [
        DialInAttempt(
          assessment: taste(score: 2),
          symptom: Symptom.shotFast,
          acceptedCorrection: c,
        ),
        DialInAttempt(
          assessment: taste(score: 3),
          symptom: Symptom.shotFast,
          acceptedCorrection: c,
        ),
      ];
      final r = engine.evaluate(
        method: BrewMethod.espresso,
        current: taste(score: 3, obs: {ProcessObservation.shotSlow}),
        history: history,
      );
      expect(r.correction!.kind, CorrectionKind.revert);
    });

    test('KHV-FR-DIA-006: üç denemede puan artmazsa kök neden listesi', () {
      final h = [
        DialInAttempt(
          assessment: taste(x: -0.7, score: 3),
          symptom: Symptom.underExtraction,
        ),
        DialInAttempt(
          assessment: taste(x: -0.7, score: 3),
          symptom: Symptom.underExtraction,
        ),
      ];
      final r = engine.evaluate(
        method: BrewMethod.v60,
        current: taste(x: -0.7, score: 2),
        history: h,
        equipment: const EquipmentProfile(
          grinder: GrinderType.blade,
          hasScale: true,
        ),
        beanAgeDays: 45,
      );
      expect(r.showRootCauseChecklist, isTrue);
      expect(r.rootCauseChecks, RootCauseCheck.values);
      expect(r.suspectedRootCauses, {
        RootCauseCheck.grinder,
        RootCauseCheck.water,
        RootCauseCheck.beanFreshness,
      });
      expect(r.correction, isNotNull, reason: 'öneri yine tek');
    });

    test('puan arttıysa kök neden listesi yok', () {
      final h = [
        DialInAttempt(
          assessment: taste(score: 2),
          symptom: Symptom.underExtraction,
        ),
        DialInAttempt(
          assessment: taste(score: 3),
          symptom: Symptom.underExtraction,
        ),
      ];
      final r = engine.evaluate(
        method: BrewMethod.v60,
        current: taste(x: -0.7, score: 3),
        history: h,
      );
      expect(r.showRootCauseChecklist, isFalse);
    });

    test('dengeli ve yüksek puanlı fincanda kök neden listesi yok', () {
      final h = [
        DialInAttempt(assessment: taste(score: 4)),
        DialInAttempt(assessment: taste(score: 4)),
      ];
      final r = engine.evaluate(
        method: BrewMethod.v60,
        current: taste(score: 4),
        history: h,
      );
      expect(r.showRootCauseChecklist, isFalse);
    });

    test('dengeli ama düşük puanlı üç deneme → kök neden listesi', () {
      final h = [
        DialInAttempt(assessment: taste(score: 2)),
        DialInAttempt(assessment: taste(score: 2)),
      ];
      final r = engine.evaluate(
        method: BrewMethod.v60,
        current: taste(score: 2),
        history: h,
      );
      expect(r.isBalanced, isTrue);
      expect(r.showRootCauseChecklist, isTrue);
      expect(r.suspectedRootCauses, contains(RootCauseCheck.scale));
    });
  });

  group('düzeltmeyi uygulama (KHV-FR-DIA-005)', () {
    final v60 = recipeOf(bundle, BrewMethod.v60);
    final esp = recipeOf(bundle, BrewMethod.espresso);
    final fp = recipeOf(bundle, BrewMethod.frenchPress);
    Correction of(String id) =>
        Correction.fromRule(bundle.rules.firstWhere((r) => r.id == id));

    test('öğütme bir kademe ince (kademe bilinmiyor)', () {
      final r = applyCorrection(v60, of('under-1'));
      expect(r.grind.offset, -1);
      expect(r.version, v60.version + 1);
    });
    test('öğütme kademe biliniyorsa kademe değişir', () {
      final withClicks = v60.copyWith(
        grind: const GrindSetting('Orta-ince', clicks: 20),
      );
      expect(applyCorrection(withClicks, of('over-1')).grind.clicks, 21);
    });
    test('sıcaklık', () {
      expect(applyCorrection(v60, of('under-2')).temperatureC, 96);
      expect(applyCorrection(v60, of('over-2')).temperatureC, 92);
      final noTemp = recipeOf(bundle, BrewMethod.turkish);
      expect(applyCorrection(noTemp, of('under-2')), same(noTemp));
    });
    test('süre en uzun adımda değişir', () {
      final r = applyCorrection(fp, of('under-2-imm'));
      expect(r.steps[1].durationS, fp.steps[1].durationS! + 30);
      expect(r.targetTimeS, fp.targetTimeS! + 30);
    });
    test('oran: kahve artar, su sabit', () {
      final r = applyCorrection(v60, of('weak-1'));
      expect(r.waterG, v60.waterG);
      expect(r.ratio, closeTo(v60.ratio - 1, 0.05));
    });
    test('espresso oranı: doz sabit, çıktı değişir', () {
      final r = applyCorrection(esp, of('strong-1'));
      expect(r.coffeeG, 18);
      expect(r.waterG, 54);
      expect(r.steps.last.targetWaterG, 54);
    });
    test('doz', () {
      expect(applyCorrection(esp, of('shotfast-2')).coffeeG, 18.5);
      expect(applyCorrection(esp, of('shotslow-2')).coffeeG, 17.5);
    });
    test('parametrik olmayan öneri tarifi değiştirmez', () {
      expect(applyCorrection(v60, of('stale-1')), same(v60));
      expect(of('stale-1').isParametric, isFalse);
    });
  });

  test('Correction JSON gidiş-dönüş', () {
    final c = Correction.fromRule(bundle.rules.first);
    final back = Correction.fromJson(c.toJson());
    expect(back.ruleId, c.ruleId);
    expect(back.variable, c.variable);
    expect(back.amount, c.amount);
  });

  test('Symptom yardımcıları', () {
    expect(Symptom.underExtraction.opposite, Symptom.overExtraction);
    expect(Symptom.weak.opposite, isNull);
    expect(Symptom.weak.isStrength, isTrue);
    expect(Symptom.slowDrawdown.isExtraction, isTrue);
    for (final d in CorrectionDirection.values) {
      expect(d.inverse.inverse, d);
    }
  });
}
