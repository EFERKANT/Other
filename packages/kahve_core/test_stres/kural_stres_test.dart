import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:kahve_core/kahve_core.dart';
import 'package:test/test.dart';

import '../test/helpers.dart';

/// İş kuralları için rastgele girdi (fuzz) stres testleri.
void main() {
  final bundle = loadBundle();
  final engine = DialInEngine(bundle.rules);
  final seed =
      int.tryParse(Platform.environment['STRES_TOHUM'] ?? '') ?? 20261125;

  TasteAssessment randomTaste(Random r) => TasteAssessment(
    score: 1 + r.nextInt(5),
    extraction: r.nextDouble() * 2 - 1,
    strength: r.nextDouble() * 2 - 1,
    sourAndBitter: r.nextInt(6) == 0,
    flat: r.nextInt(6) == 0,
    observations: {
      for (final o in ProcessObservation.values)
        if (r.nextInt(8) == 0) o,
    },
  );

  test('dial-in: 50.000 rastgele değerlendirme, her zaman en fazla bir '
      'öneri (KHV-FR-DIA-002, DIA-006)', () {
    final r = Random(seed);
    for (var i = 0; i < 50000; i++) {
      final method = BrewMethod.values[r.nextInt(BrewMethod.values.length)];
      final history = [
        for (var h = 0; h < r.nextInt(5); h++)
          () {
            final a = randomTaste(r);
            final s = DialInEngine.detectSymptom(method, a);
            final c = s == null
                ? null
                : engine.evaluate(method: method, current: a).correction;
            return DialInAttempt(
              assessment: a,
              symptom: s,
              acceptedCorrection: r.nextBool() ? c : null,
            );
          }(),
      ];
      final current = randomTaste(r);
      final result = engine.evaluate(
        method: method,
        current: current,
        history: history,
        beanAgeDays: r.nextInt(90),
      );
      expect(result.isBalanced, result.symptom == null);
      if (result.symptom != null) {
        expect(
          result.correction,
          isNotNull,
          reason: 'her belirtinin kuralı var: ${result.symptom}',
        );
        expect(result.correction!.text, isNotEmpty);
        expect(result.correction!.reason, isNotEmpty);
      } else {
        expect(result.correction, isNull);
      }
    }
  });

  test('düzeltmeyi art arda 30 kez uygulamak tarifi bozmaz '
      '(KHV-FR-DIA-005)', () {
    final r = Random(seed);
    for (final base in bundle.recipes) {
      for (var run = 0; run < 50; run++) {
        var recipe = base;
        for (var k = 0; k < 30; k++) {
          final rules = [
            for (final rule in bundle.rules)
              if (rule.appliesTo(recipe.method)) rule,
          ];
          recipe = applyCorrection(
            recipe,
            Correction.fromRule(rules[r.nextInt(rules.length)]),
          );
          expect(recipe.coffeeG.isFinite && recipe.coffeeG > 0, isTrue);
          expect(recipe.waterG.isFinite && recipe.waterG > 0, isTrue);
          expect(recipe.ratio.isFinite, isTrue);
          final t = recipe.temperatureC;
          if (t != null) expect(t, inInclusiveRange(70, 100));
          for (final s in recipe.steps) {
            if (s.durationS != null) expect(s.durationS, greaterThan(0));
          }
        }
      }
    }
  });

  test('paylaşım bağlantısı: 20.000 bozuk girdi yalnız doğrulama hatası '
      'verir (KHV-FR-SOC-009)', () {
    final r = Random(seed);
    final valid = encodeSharedRecipe(bundle.recipes.first);
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_=%/.';
    for (var i = 0; i < 20000; i++) {
      String payload;
      switch (r.nextInt(3)) {
        case 0:
          payload = String.fromCharCodes([
            for (var k = 0; k < r.nextInt(300); k++)
              chars.codeUnitAt(r.nextInt(chars.length)),
          ]);
        case 1:
          final b = valid.split('');
          for (var k = 0; k < 1 + r.nextInt(5); k++) {
            b[r.nextInt(b.length)] = chars[r.nextInt(chars.length)];
          }
          payload = b.join();
        default:
          payload = valid.substring(0, r.nextInt(valid.length));
      }
      try {
        final recipe = decodeSharedRecipe(payload, newId: 'x');
        expect(validateRecipe(recipe), isEmpty);
      } on RecipeValidationException catch (e) {
        expect(e.reasons, isNotEmpty);
      }
    }
  });

  test('paylaşım JSON alanları rastgele bozulur: çökme yok, geçerli tarif '
      'veya gerekçeli ret (KHV-FR-SOC-009)', () {
    final r = Random(seed);
    final values = <Object?>[
      null,
      -1,
      0,
      1e12,
      double.maxFinite,
      'x',
      '',
      true,
      [],
      {},
      15.5,
      'v60',
      'yok',
      [null],
      {'title': 'x'},
    ];
    for (var i = 0; i < 20000; i++) {
      final base = bundle.recipes[r.nextInt(bundle.recipes.length)];
      final j = base.toJson();
      final keys = j.keys.toList();
      for (var k = 0; k < 1 + r.nextInt(3); k++) {
        j[keys[r.nextInt(keys.length)]] = values[r.nextInt(values.length)];
      }
      final payload = base64Url.encode(
        utf8.encode(jsonEncode({'v': 1, 'recipe': j})),
      );
      try {
        final recipe = decodeSharedRecipe(payload, newId: 'x');
        expect(validateRecipe(recipe), isEmpty);
      } on RecipeValidationException catch (e) {
        expect(e.reasons, isNotEmpty);
      }
    }
  });

  test('hesaplayıcı: 100.000 rastgele girdi, sonuç sonlu ya da açık hata '
      '(KHV-FR-RCP-002)', () {
    final r = Random(seed);
    final specials = [0.0, -0.0, -1.0, 1e-9, 1e9, double.nan, double.infinity];
    double? pick() => switch (r.nextInt(5)) {
      0 => null,
      1 => specials[r.nextInt(specials.length)],
      _ => r.nextDouble() * 2000,
    };
    for (var i = 0; i < 100000; i++) {
      try {
        final a = BrewCalculator.solve(
          coffeeG: pick(),
          waterG: pick(),
          ratio: pick(),
        );
        for (final v in [a.coffeeG, a.waterG, a.ratio]) {
          expect(v.isFinite && v >= 0, isTrue);
        }
      } on CalculatorException catch (e) {
        expect(e.message, isNotEmpty);
      }
    }
  });

  test('Türkçe sayı girişi: rastgele metin çökme yapmaz (KHV-NFR-031)', () {
    final r = Random(seed);
    const chars = '0123456789,.- abcçğıöşü+e';
    for (var i = 0; i < 50000; i++) {
      final s = String.fromCharCodes([
        for (var k = 0; k < r.nextInt(12); k++)
          chars.codeUnitAt(r.nextInt(chars.length)),
      ]);
      final v = parseNumber(s);
      if (v != null) {
        expect(v.isFinite, isTrue);
        expect(parseNumber(formatNumber(v, decimals: 6)), closeTo(v, 1e-6));
      }
    }
  });
}
