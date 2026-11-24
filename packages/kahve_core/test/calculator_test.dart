import 'package:kahve_core/kahve_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('BrewCalculator.solve (KHV-FR-RCP-002)', () {
    test('kahve + oran → su', () {
      expect(
        BrewCalculator.solve(coffeeG: 15, ratio: 16),
        const BrewAmounts(coffeeG: 15, waterG: 240, ratio: 16),
      );
    });
    test('su + oran → kahve, 0,1 yuvarlama', () {
      final a = BrewCalculator.solve(waterG: 250, ratio: 16);
      expect(a.coffeeG, 15.6);
    });
    test('kahve + su → oran', () {
      expect(BrewCalculator.solve(coffeeG: 15, waterG: 250).ratio, 16.7);
    });
    test('üçü verilirse oran kahve ve sudan hesaplanır', () {
      expect(
        BrewCalculator.solve(coffeeG: 10, waterG: 150, ratio: 99).ratio,
        15,
      );
    });
    test('tek değer hata', () {
      expect(
        () => BrewCalculator.solve(coffeeG: 15),
        throwsA(isA<CalculatorException>()),
      );
    });
    for (final bad in [0.0, -1.0, double.nan, double.infinity]) {
      test('geçersiz değer $bad', () {
        expect(
          () => BrewCalculator.solve(coffeeG: bad, ratio: 16),
          throwsA(isA<CalculatorException>()),
        );
      });
    }
    test('çok büyük su', () {
      expect(
        () => BrewCalculator.solve(coffeeG: 1000, ratio: 16),
        throwsA(isA<CalculatorException>()),
      );
      expect(
        () => BrewCalculator.solve(waterG: 6000, ratio: 16),
        throwsA(isA<CalculatorException>()),
      );
    });
    test('hata mesajı', () {
      expect(const CalculatorException('x').toString(), contains('x'));
      expect(
        const BrewAmounts(coffeeG: 1, waterG: 2, ratio: 2).toString(),
        contains('1.0'),
      );
    });
  });

  group('fincan hesabı (KHV-FR-RCP-003)', () {
    test('2 fincan x 200 ml, 1:16', () {
      final a = BrewCalculator.forCups(cups: 2, cupMl: 200, ratio: 16);
      expect(a.waterG, 400);
      expect(a.coffeeG, 25);
    });
    test('geçersiz fincan', () {
      expect(
        () => BrewCalculator.forCups(cups: 0, cupMl: 200, ratio: 16),
        throwsA(isA<CalculatorException>()),
      );
    });
    test('Türk kahvesi fincan başına 6,5 g / 67,5 ml', () {
      final a = BrewCalculator.turkish(2);
      expect(a.coffeeG, 13);
      expect(a.waterG, 135);
      expect(
        () => BrewCalculator.turkish(0),
        throwsA(isA<CalculatorException>()),
      );
    });
  });

  test('kaşık eşdeğeri yarım kaşık hassasiyetinde (KHV-FR-RCP-004)', () {
    expect(SpoonEquivalent.spoons(15, BrewMethod.v60), 2.5);
    expect(SpoonEquivalent.spoons(13, BrewMethod.turkish), 2);
    expect(SpoonEquivalent.spoonName(BrewMethod.turkish), 'tatlı kaşığı');
    expect(SpoonEquivalent.spoonName(BrewMethod.v60), 'yemek kaşığı');
  });

  group('kaynama sonrası bekleme (KHV-FR-RCP-008)', () {
    test('sıcaklık bandlarına göre', () {
      expect(boilWaitSeconds(BrewMethod.v60, 98), 10);
      expect(boilWaitSeconds(BrewMethod.v60, 96), 30);
      expect(boilWaitSeconds(BrewMethod.v60, 94), 45);
      expect(boilWaitSeconds(BrewMethod.v60, 90), 90);
      expect(boilWaitSeconds(BrewMethod.aeropress, 85), 150);
      expect(boilWaitSeconds(BrewMethod.aeropress, 80), 240);
    });
    test('soğuk başlanan yöntemlerde yok', () {
      expect(boilWaitSeconds(BrewMethod.turkish, 90), isNull);
      expect(boilWaitSeconds(BrewMethod.coldBrew, 20), isNull);
      expect(boilWaitSeconds(BrewMethod.v60, null), isNull);
      expect(boilWaitSeconds(BrewMethod.mokaPot, 90), 0);
    });
  });

  group('aralık uyarıları (KHV-HMI-012)', () {
    test('V60 için 1:3 oran uyarı verir, engellemez', () {
      expect(rangeWarnings(BrewMethod.v60, ratio: 3), {RangeWarning.ratio});
    });
    test('normal değerler uyarı vermez', () {
      for (final m in BrewMethod.values) {
        final r = recipeOf(loadBundle(), m);
        expect(
          rangeWarnings(
            m,
            coffeeG: r.coffeeG,
            ratio: r.ratio,
            temperatureC: r.temperatureC,
          ),
          isEmpty,
          reason: m.id,
        );
      }
    });
    test('doz ve sıcaklık', () {
      expect(
        rangeWarnings(BrewMethod.espresso, coffeeG: 40, temperatureC: 70),
        {RangeWarning.coffee, RangeWarning.temperature},
      );
      expect(rangeWarnings(BrewMethod.coldBrew, temperatureC: 5), isEmpty);
    });
  });

  group('ölçekleme (KHV-FR-RCP-010)', () {
    final v60 = recipeOf(loadBundle(), BrewMethod.v60);
    test('doz iki katına çıkınca adım ağırlıkları da iki katı', () {
      final s = scaleRecipe(v60, coffeeG: 30);
      expect(s.waterG, 500);
      expect(s.ratio, closeTo(v60.ratio, 0.01));
      for (var i = 0; i < v60.steps.length; i++) {
        expect(s.steps[i].durationS, v60.steps[i].durationS);
        if (v60.steps[i].targetWaterG != null) {
          expect(s.steps[i].targetWaterG, v60.steps[i].targetWaterG! * 2);
        }
      }
    });
    test('su üzerinden ölçekleme', () {
      expect(scaleRecipe(v60, waterG: 125).coffeeG, 7.5);
    });
    test('argüman hataları', () {
      expect(() => scaleRecipe(v60), throwsArgumentError);
      expect(
        () => scaleRecipe(v60, coffeeG: 1, waterG: 1),
        throwsArgumentError,
      );
      expect(() => scaleRecipe(v60, coffeeG: -1), throwsArgumentError);
    });
    test('Türk kahvesi fincan ölçekleme', () {
      final t = recipeOf(loadBundle(), BrewMethod.turkish);
      final s = scaleTurkishCups(t, 3);
      expect(s.cups, 3);
      expect(s.coffeeG, 19.5);
    });
  });

  group('espresso shot (KHV-FR-BRW-008)', () {
    final esp = recipeOf(loadBundle(), BrewMethod.espresso);
    test('hedef aralıkta', () {
      final e = evaluateShot(esp, doseG: 18, yieldG: 36, timeS: 28);
      expect(e.ratio, 2);
      expect(e.timeInRange, isTrue);
      expect(e.ratioDelta, 0);
      expect(e.observation, isNull);
    });
    test('hızlı shot', () {
      final e = evaluateShot(esp, doseG: 18, yieldG: 40, timeS: 18);
      expect(e.timeDeltaS, -7);
      expect(e.observation, ProcessObservation.shotFast);
      expect(e.ratioDelta, 0.2);
    });
    test('yavaş shot', () {
      final e = evaluateShot(esp, doseG: 18, yieldG: 30, timeS: 40);
      expect(e.timeDeltaS, 10);
      expect(e.observation, ProcessObservation.shotSlow);
    });
    test('geçersiz girdi', () {
      expect(
        () => evaluateShot(esp, doseG: 0, yieldG: 30, timeS: 20),
        throwsA(isA<CalculatorException>()),
      );
    });
  });

  test('süre gözlemleri', () {
    final b = loadBundle();
    expect(
      observeDuration(recipeOf(b, BrewMethod.v60), 250),
      ProcessObservation.slowDrawdown,
    );
    expect(observeDuration(recipeOf(b, BrewMethod.v60), 200), isNull);
    expect(
      observeDuration(recipeOf(b, BrewMethod.chemex), 400),
      ProcessObservation.slowDrawdown,
    );
    expect(
      observeDuration(recipeOf(b, BrewMethod.espresso), 15),
      ProcessObservation.shotFast,
    );
    expect(
      observeDuration(recipeOf(b, BrewMethod.espresso), 40),
      ProcessObservation.shotSlow,
    );
    expect(observeDuration(recipeOf(b, BrewMethod.espresso), 28), isNull);
    expect(observeDuration(recipeOf(b, BrewMethod.frenchPress), 999), isNull);
  });
}
