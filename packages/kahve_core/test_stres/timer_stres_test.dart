import 'dart:io';
import 'dart:math';

import 'package:kahve_core/kahve_core.dart';
import 'package:test/test.dart';

import '../test/helpers.dart';

/// Zamanlayıcı stres testleri (KHV-NFR-002, NFR-003, KHV-FR-BRW-011).
///
/// Uygulama zamanlayıcıyı 100 ms'de bir yoklar; işletim sistemi bu aralığı
/// geciktirebilir. Bu testler düzensiz yoklama, rastgele işlem dizileri ve
/// saatlerce süren demlemelerde zamanlayıcının tutarlı kaldığını denetler.
void main() {
  final bundle = loadBundle();
  final seed =
      int.tryParse(Platform.environment['STRES_TOHUM'] ?? '') ?? 20261125;

  test('10 dakikalık demleme, düzensiz yoklama: geçişler planlanan anda '
      '(KHV-NFR-002)', () {
    final rnd = Random(seed);
    // 10 dakika: 20 adım x 30 sn.
    final steps = [
      for (var i = 0; i < 20; i++)
        BrewStep(title: 'A$i', trigger: StepTrigger.time, durationS: 30),
    ];
    final t = BrewTimer(steps)..start(0);
    var now = 0;
    final advancedAt = <int, int>{};
    var maxGap = 0;
    while (!t.view(now).finished) {
      // 16-400 ms arası düzensiz yoklama; arada bir 2 sn'lik takılma.
      final gap = rnd.nextInt(20) == 0 ? 2000 : 16 + rnd.nextInt(384);
      maxGap = max(maxGap, gap);
      now += gap;
      for (final e in t.tick(now)) {
        if (e is StepAdvanced) advancedAt[e.stepIndex] = now;
      }
    }
    final v = t.view(now);
    // Toplam süre yoklama aralığından bağımsız olarak tam 10 dakika.
    expect(v.totalElapsedMs, 600000);
    for (var i = 1; i < 20; i++) {
      final planned = i * 30000;
      // Olay en geç bir yoklama gecikmesiyle gelir, erken asla.
      expect(advancedAt[i]! - planned, inInclusiveRange(0, maxGap));
    }
    // Adım başlangıçları planlanan anlara sabit: sapma birikmez.
    expect(t.view(now).stepIndex, 19);
  });

  test('100 ms yoklamada sapma ±0,5 sn içinde (KHV-NFR-002)', () {
    final steps = [
      for (var i = 0; i < 40; i++)
        BrewStep(title: 'A$i', trigger: StepTrigger.time, durationS: 15),
    ];
    final t = BrewTimer(steps)..start(0);
    var now = 0;
    var worst = 0;
    while (!t.view(now).finished) {
      now += 100;
      for (final e in t.tick(now)) {
        if (e is StepAdvanced) {
          worst = max(worst, (now - e.stepIndex * 15000).abs());
        }
      }
    }
    expect(worst, lessThanOrEqualTo(500));
  });

  test('rastgele işlem dizileri: değişmezler korunur (KHV-NFR-003)', () {
    final rnd = Random(seed);
    for (var run = 0; run < 2000; run++) {
      final recipe = bundle.recipes[rnd.nextInt(bundle.recipes.length)];
      var t = BrewTimer(recipe.steps)..start(0);
      var now = 0;
      var lastTotal = 0;
      for (var op = 0; op < 60; op++) {
        now += rnd.nextInt(3) == 0 ? rnd.nextInt(120000) : rnd.nextInt(3000);
        switch (rnd.nextInt(8)) {
          case 0:
            t.pause(now);
          case 1:
            t.resume(now);
          case 2:
            t.skip(now);
          case 3:
            t.undoSkip(now);
          case 4:
            t.confirm(now);
          case 5:
            // Uygulama sonlandırılıp geri yüklendi.
            final snap = BrewTimerSnapshot.fromJson(t.snapshot(now).toJson());
            final gap = rnd.nextInt(60000) - 5000;
            t = BrewTimer.restore(
              recipe.steps,
              snap,
              nowMs: 0,
              elapsedSinceSnapshotMs: gap,
            );
            now = 0;
          default:
            t.tick(now);
        }
        final v = t.view(now);
        expect(v.stepIndex, inInclusiveRange(0, recipe.steps.length - 1));
        expect(
          v.totalElapsedMs,
          greaterThanOrEqualTo(lastTotal),
          reason: 'süre geri gitmez (run $run, op $op)',
        );
        expect(v.stepElapsedMs, greaterThanOrEqualTo(0));
        expect(v.stepElapsedMs, lessThanOrEqualTo(v.totalElapsedMs));
        if (v.stepRemainingMs != null) {
          expect(v.stepRemainingMs, greaterThanOrEqualTo(0));
        }
        if (v.paused) {
          expect(
            t.view(now + 99999).totalElapsedMs,
            v.totalElapsedMs,
            reason: 'duraklatılmış süre ilerlemez',
          );
        }
        lastTotal = v.totalElapsedMs;
      }
    }
  });

  test('18 saatlik cold brew saniyelik yoklamayla biter, sapma yok '
      '(KHV-FR-BRW-009)', () {
    final cold = bundle.recipes.firstWhere(
      (r) => r.method == BrewMethod.coldBrew,
    );
    final steps = [
      for (final s in cold.steps)
        s.durationS != null && s.durationS! > 3600
            ? s.copyWith(durationS: 18 * 3600)
            : s,
    ];
    final t = BrewTimer(steps)..start(0);
    t.confirm(1000);
    var now = 1000;
    while (t.view(now).stepIndex == 1) {
      now += 1000;
      t.tick(now);
    }
    expect(now, 1000 + 18 * 3600 * 1000);
    expect(t.view(now).stepElapsedMs, 0);
  });
}
