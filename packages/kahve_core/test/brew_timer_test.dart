import 'package:kahve_core/kahve_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

const s = 1000;

List<BrewStep> steps() => const [
  BrewStep(title: 'A', trigger: StepTrigger.time, durationS: 10),
  BrewStep(
    title: 'B',
    trigger: StepTrigger.weight,
    targetWaterG: 100,
    durationS: 20,
  ),
  BrewStep(title: 'C', trigger: StepTrigger.confirm, observation: 'köpük'),
  BrewStep(title: 'D', trigger: StepTrigger.time, durationS: 5),
];

void main() {
  test('boş adım listesi reddedilir', () {
    expect(() => BrewTimer(const []), throwsArgumentError);
  });

  test('başlamadan olay üretmez', () {
    final t = BrewTimer(steps());
    expect(t.tick(0), isEmpty);
    expect(t.confirm(0), isEmpty);
    expect(t.skip(0), isEmpty);
    expect(t.started, isFalse);
    expect(t.start(0).single, isA<StepAdvanced>());
    expect(t.start(0), isEmpty);
  });

  test('süreli adımlar kendiliğinden geçer, ön uyarı ve geri sayım '
      '(KHV-HMI-004)', () {
    final t = BrewTimer(steps())..start(0);
    expect(t.tick(4 * s), isEmpty);
    final warn = t.tick(5 * s);
    expect(warn.whereType<PreWarning>().single.stepIndex, 0);
    expect(t.tick(6 * s), isEmpty);
    expect(t.tick(7 * s).whereType<CountdownTick>().single.secondsLeft, 3);
    expect(t.tick(7500), isEmpty);
    expect(t.tick(8 * s).whereType<CountdownTick>().single.secondsLeft, 2);
    expect(t.tick(9 * s).whereType<CountdownTick>().single.secondsLeft, 1);
    final adv = t.tick(10 * s);
    expect(adv.whereType<StepAdvanced>().single.stepIndex, 1);
    expect(t.view(10 * s).stepElapsedMs, 0);
    expect(t.currentStep.title, 'B');
    expect(t.nextStep!.title, 'C');
  });

  test('onay adımı kendiliğinden geçmez (KHV-HMI-003)', () {
    final t = BrewTimer(steps())..start(0);
    t.tick(30 * s);
    expect(t.view(30 * s).stepIndex, 2);
    expect(t.view(30 * s).waitingForConfirm, isTrue);
    expect(t.view(30 * s).stepRemainingMs, isNull);
    expect(t.tick(1000 * s), isEmpty);
    expect(t.view(1000 * s).stepIndex, 2);
    expect(t.confirm(1000 * s).whereType<StepAdvanced>().single.stepIndex, 3);
    final done = t.tick(1005 * s);
    expect(done.whereType<BrewFinished>().single.totalElapsedMs, 1005 * s);
    expect(t.view(2000 * s).finished, isTrue);
    expect(t.view(2000 * s).totalElapsedMs, 1005 * s);
    expect(t.tick(3000 * s), isEmpty);
  });

  test('uzun kesintiden sonra birden çok adım geçer', () {
    final t = BrewTimer(steps())..start(0);
    final ev = t.tick(100 * s);
    expect(ev.whereType<StepAdvanced>().map((e) => e.stepIndex), [1, 2]);
    expect(t.view(100 * s).stepElapsedMs, 70 * s);
  });

  test('duraklat/devam (KHV-FR-BRW-006, KHV-HMI-010)', () {
    final t = BrewTimer(steps())..start(0);
    t.pause(3 * s);
    t.pause(4 * s);
    expect(t.view(50 * s).paused, isTrue);
    expect(t.view(50 * s).totalElapsedMs, 3 * s);
    expect(t.tick(50 * s), isEmpty);
    t.resume(50 * s);
    t.resume(51 * s);
    expect(t.view(52 * s).totalElapsedMs, 5 * s);
    expect(t.view(52 * s).stepRemainingS, 5);
  });

  test('adım atlama 5 sn içinde geri alınır (KHV-HMI-009)', () {
    final t = BrewTimer(steps())..start(0);
    t.skip(2 * s);
    expect(t.view(3 * s).stepIndex, 1);
    expect(t.view(3 * s).canUndoSkip, isTrue);
    expect(t.undoSkip(6 * s), isTrue);
    expect(t.view(6 * s).stepIndex, 0);
    expect(t.view(6 * s).stepElapsedMs, 6 * s);
    expect(t.undoSkip(6 * s), isFalse);
  });

  test('5 sn sonra geri alma reddedilir', () {
    final t = BrewTimer(steps())..start(0);
    t.skip(1 * s);
    expect(t.view(7 * s).canUndoSkip, isFalse);
    expect(t.undoSkip(7 * s), isFalse);
  });

  test('son adımı atlayınca biter, geri alınca devam eder', () {
    final t = BrewTimer(const [
      BrewStep(title: 'X', trigger: StepTrigger.confirm),
    ])..start(0);
    expect(t.skip(1 * s).single, isA<BrewFinished>());
    expect(t.view(1 * s).finished, isTrue);
    expect(t.undoSkip(2 * s), isTrue);
    expect(t.view(3 * s).finished, isFalse);
    expect(t.view(3 * s).totalElapsedMs, 2 * s);
  });

  test('anlık görüntüden geri yükleme (KHV-NFR-003, KHV-FR-BRW-011)', () {
    final t = BrewTimer(steps())..start(0);
    t.tick(12 * s);
    final snap = BrewTimerSnapshot.fromJson(t.snapshot(12 * s).toJson());
    // Uygulama sonlandırıldı; 3 sn sonra yeni süreçte monotonik saat 0'dan.
    final r = BrewTimer.restore(
      steps(),
      snap,
      nowMs: 0,
      elapsedSinceSnapshotMs: 3 * s,
    );
    expect(r.started, isTrue);
    final v = r.view(0);
    expect(v.stepIndex, 1);
    expect(v.totalElapsedMs, 15 * s);
    expect(v.stepElapsedMs, 5 * s);
    expect(r.view(1 * s).totalElapsedMs, 16 * s);
  });

  test('geri yüklemede geriye giden duvar saati süreyi azaltmaz', () {
    final t = BrewTimer(steps())..start(0);
    final r = BrewTimer.restore(
      steps(),
      t.snapshot(4 * s),
      nowMs: 0,
      elapsedSinceSnapshotMs: -3600 * s,
    );
    expect(r.view(0).totalElapsedMs, 4 * s);
  });

  test('duraklatılmış anlık görüntü boşluk süresini saymaz', () {
    final t = BrewTimer(steps())..start(0);
    t.pause(4 * s);
    final r = BrewTimer.restore(
      steps(),
      t.snapshot(9 * s),
      nowMs: 0,
      elapsedSinceSnapshotMs: 100 * s,
    );
    expect(r.view(50 * s).totalElapsedMs, 4 * s);
    expect(r.view(0).paused, isTrue);
  });

  test('kalan planlanan süre (KHV-HMI-022)', () {
    final t = BrewTimer(steps())..start(0);
    expect(t.remainingPlannedMs(4 * s), 6 * s + 20 * s + 5 * s);
  });

  test('uzun demleme (KHV-FR-BRW-009)', () {
    final b = loadBundle();
    final cold = recipeOf(b, BrewMethod.coldBrew);
    expect(isLongBrew(cold), isTrue);
    expect(isLongBrew(recipeOf(b, BrewMethod.v60)), isFalse);
    final start = DateTime(2026, 11, 24, 20);
    expect(longBrewEndsAt(cold, start), DateTime(2026, 11, 25, 10));
  });

  test('her yöntemin tarifi rehber modda baştan sona tamamlanır '
      '(MVP kabul 2)', () {
    for (final r in loadBundle().recipes) {
      final t = BrewTimer(r.steps)..start(0);
      var now = 0;
      var guard = 0;
      while (!t.view(now).finished && guard++ < 100000) {
        if (t.view(now).waitingForConfirm) {
          t.confirm(now);
        } else {
          now += 1000;
          t.tick(now);
        }
      }
      expect(t.view(now).finished, isTrue, reason: r.id);
    }
  });
}
