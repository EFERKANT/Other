import 'package:meta/meta.dart';

import '../model/recipe.dart';

/// Zamanlayıcının ürettiği olaylar.
sealed class TimerEvent {
  const TimerEvent();
}

/// Süreli adımın bitmesine 5 sn kala ön uyarı (KHV-HMI-004).
final class PreWarning extends TimerEvent {
  /// Bir ön uyarı oluşturur.
  const PreWarning(this.stepIndex);

  /// Bitmek üzere olan adım.
  final int stepIndex;
}

/// Son 3 saniye geri sayımı (KHV-HMI-004).
final class CountdownTick extends TimerEvent {
  /// Bir geri sayım olayı oluşturur.
  const CountdownTick(this.stepIndex, this.secondsLeft);

  /// Adım.
  final int stepIndex;

  /// Kalan saniye (3, 2, 1).
  final int secondsLeft;
}

/// Yeni adıma geçildi.
final class StepAdvanced extends TimerEvent {
  /// Bir geçiş olayı oluşturur.
  const StepAdvanced(this.stepIndex);

  /// Yeni adım.
  final int stepIndex;
}

/// Demleme bitti (KHV-FR-BRW-007).
final class BrewFinished extends TimerEvent {
  /// Bir bitiş olayı oluşturur.
  const BrewFinished(this.totalElapsedMs);

  /// Duraklamalar hariç toplam süre (ms).
  final int totalElapsedMs;
}

/// Zamanlayıcının anlık görünümü.
@immutable
class TimerView {
  /// Bir görünüm oluşturur.
  const TimerView({
    required this.stepIndex,
    required this.stepCount,
    required this.stepElapsedMs,
    required this.totalElapsedMs,
    required this.stepRemainingMs,
    required this.paused,
    required this.finished,
    required this.waitingForConfirm,
    required this.canUndoSkip,
  });

  /// Aktif adım indeksi.
  final int stepIndex;

  /// Toplam adım sayısı.
  final int stepCount;

  /// Aktif adımda geçen süre (ms).
  final int stepElapsedMs;

  /// Toplam geçen süre (ms).
  final int totalElapsedMs;

  /// Aktif adımın kalan süresi (ms); süresiz adımda `null`.
  final int? stepRemainingMs;

  /// Duraklatılmış mı.
  final bool paused;

  /// Bitti mi.
  final bool finished;

  /// Adım kullanıcı onayı bekliyor mu (KHV-HMI-003).
  final bool waitingForConfirm;

  /// Son adım atlama 5 sn içinde geri alınabilir mi (KHV-HMI-009).
  final bool canUndoSkip;

  /// Kalan süre tam saniye olarak (yukarı yuvarlanmış).
  int? get stepRemainingS =>
      stepRemainingMs == null ? null : (stepRemainingMs! + 999) ~/ 1000;
}

/// Rehber mod zamanlayıcısı (KHV-FR-BRW-002 - BRW-007, BRW-011,
/// KHV-HMI-003, HMI-004, HMI-009).
///
/// Zaman dışarıdan monotonik milisaniye ([nowMs]) olarak verilir; böylece
/// motor saf ve test edilebilirdir. Uygulama katmanı bu değeri monotonik bir
/// kronometreden üretir, kesinti sonrası [BrewTimerSnapshot] ile geri yükler.
class BrewTimer {
  /// Adım listesiyle bir zamanlayıcı oluşturur.
  BrewTimer(List<BrewStep> steps) : steps = List.unmodifiable(steps) {
    if (steps.isEmpty) throw ArgumentError('Tarifte adım yok');
  }

  /// Anlık görüntüden geri yükler. [nowMs] geri yükleme anındaki monotonik
  /// zaman, [elapsedSinceSnapshotMs] kayıttan bu yana geçen gerçek süredir.
  factory BrewTimer.restore(
    List<BrewStep> steps,
    BrewTimerSnapshot s, {
    required int nowMs,
    required int elapsedSinceSnapshotMs,
  }) {
    final t = BrewTimer(steps);
    final gap = s.paused || s.finished
        ? 0
        : (elapsedSinceSnapshotMs < 0 ? 0 : elapsedSinceSnapshotMs);
    t
      .._started = s.started
      .._index = s.stepIndex
      .._paused = s.paused
      .._finished = s.finished
      .._accumulatedMs = s.totalElapsedMs + gap
      .._stepStartTotalMs = s.stepStartTotalMs
      .._runningSince = s.paused || s.finished ? null : nowMs
      .._warned = s.stepIndex
      .._lastCountdown = 0;
    return t;
  }

  /// Adım geri alma penceresi (ms).
  static const undoWindowMs = 5000;

  /// Ön uyarı süresi (ms).
  static const preWarningMs = 5000;

  /// Adımlar.
  final List<BrewStep> steps;

  bool _started = false;
  bool _paused = false;
  bool _finished = false;
  int _index = 0;
  int _accumulatedMs = 0;
  int? _runningSince;
  int _stepStartTotalMs = 0;
  int _warned = -1;
  int _lastCountdown = 0;
  _Skip? _lastSkip;

  /// Başlatıldı mı.
  bool get started => _started;

  /// Aktif adım.
  BrewStep get currentStep => steps[_index];

  /// Sonraki adım (yoksa `null`).
  BrewStep? get nextStep =>
      _index + 1 < steps.length ? steps[_index + 1] : null;

  /// Zamanlayıcıyı başlatır.
  List<TimerEvent> start(int nowMs) {
    if (_started) return const [];
    _started = true;
    _runningSince = nowMs;
    return const [StepAdvanced(0)];
  }

  /// Duraklatır (KHV-FR-BRW-006).
  void pause(int nowMs) {
    if (!_started || _paused || _finished) return;
    _accumulatedMs = _total(nowMs);
    _runningSince = null;
    _paused = true;
  }

  /// Devam ettirir.
  void resume(int nowMs) {
    if (!_paused || _finished) return;
    _paused = false;
    _runningSince = nowMs;
  }

  /// Onay bekleyen adımı veya mevcut adımı tamamlayıp sonrakine geçer.
  List<TimerEvent> confirm(int nowMs) {
    if (!_started || _finished) return const [];
    return _advance(nowMs, _total(nowMs));
  }

  /// Adımı atlar; 5 sn içinde [undoSkip] ile geri alınabilir.
  List<TimerEvent> skip(int nowMs) {
    if (!_started || _finished) return const [];
    _lastSkip = _Skip(_index, _stepStartTotalMs, nowMs);
    return _advance(nowMs, _total(nowMs), keepSkip: true);
  }

  /// Son atlamayı geri alır (KHV-HMI-009). Başarılıysa `true`.
  bool undoSkip(int nowMs) {
    final s = _lastSkip;
    if (s == null || nowMs - s.atMs > undoWindowMs) return false;
    _index = s.fromIndex;
    _stepStartTotalMs = s.stepStartTotalMs;
    if (_finished) {
      _finished = false;
      _runningSince = nowMs;
    }
    _warned = _index;
    _lastCountdown = 0;
    _lastSkip = null;
    return true;
  }

  /// Zamanı ilerletir; süresi dolan adımları geçirir ve olay üretir.
  List<TimerEvent> tick(int nowMs) {
    if (!_started || _paused || _finished) return const [];
    final events = <TimerEvent>[];
    final total = _total(nowMs);
    // Uzun kesintiden sonra birden çok adım geçebilir.
    while (!_finished) {
      final step = steps[_index];
      if (!step.advancesByTime) break;
      final end = _stepStartTotalMs + step.durationS! * 1000;
      if (total >= end) {
        events.addAll(_advance(nowMs, end));
        continue;
      }
      final remaining = end - total;
      if (remaining <= preWarningMs && _warned != _index) {
        _warned = _index;
        events.add(PreWarning(_index));
      }
      final secs = (remaining + 999) ~/ 1000;
      if (secs <= 3 && secs != _lastCountdown) {
        _lastCountdown = secs;
        events.add(CountdownTick(_index, secs));
      }
      break;
    }
    return events;
  }

  /// Anlık görünüm.
  TimerView view(int nowMs) {
    final total = _total(nowMs);
    final step = steps[_index];
    final stepElapsed = total - _stepStartTotalMs;
    final duration = step.durationS == null ? null : step.durationS! * 1000;
    return TimerView(
      stepIndex: _index,
      stepCount: steps.length,
      stepElapsedMs: stepElapsed,
      totalElapsedMs: total,
      stepRemainingMs: duration == null
          ? null
          : (duration - stepElapsed).clamp(0, duration),
      paused: _paused,
      finished: _finished,
      waitingForConfirm: _started && !_finished && !step.advancesByTime,
      canUndoSkip: _lastSkip != null && nowMs - _lastSkip!.atMs <= undoWindowMs,
    );
  }

  /// Kalıcı anlık görüntü (KHV-NFR-003).
  BrewTimerSnapshot snapshot(int nowMs) => BrewTimerSnapshot(
    started: _started,
    stepIndex: _index,
    paused: _paused,
    finished: _finished,
    totalElapsedMs: _total(nowMs),
    stepStartTotalMs: _stepStartTotalMs,
  );

  /// Uygulama arka plandayken bildirimle duyurulacak adım geçişleri
  /// (KHV-FR-BRW-005): şu andan itibaren kaç ms sonra hangi adıma
  /// geçileceği. Onay bekleyen ilk adımda zincir durur; duraklatılmış veya
  /// bitmiş demlemede boştur. Son adımın bitişi indeks [steps] uzunluğu ile
  /// gösterilir.
  List<({int stepIndex, int inMs})> upcomingTransitions(int nowMs) {
    final v = view(nowMs);
    if (!_started || v.paused || v.finished) return const [];
    final result = <({int stepIndex, int inMs})>[];
    var offset = 0;
    for (var i = _index; i < steps.length; i++) {
      final s = steps[i];
      if (!s.advancesByTime) break;
      final remaining = i == _index
          ? (v.stepRemainingMs ?? 0)
          : s.durationS! * 1000;
      offset += remaining;
      result.add((stepIndex: i + 1, inMs: offset));
    }
    return result;
  }

  /// Kalan planlanan süre (ms): aktif adımın kalanı ile sonraki süreli
  /// adımların toplamı. Kilit ekranı/bildirim için (KHV-HMI-022).
  int remainingPlannedMs(int nowMs) {
    final v = view(nowMs);
    var sum = v.stepRemainingMs ?? 0;
    for (var i = _index + 1; i < steps.length; i++) {
      sum += (steps[i].durationS ?? 0) * 1000;
    }
    return sum;
  }

  int _total(int nowMs) =>
      _accumulatedMs + (_runningSince == null ? 0 : nowMs - _runningSince!);

  List<TimerEvent> _advance(int nowMs, int atTotal, {bool keepSkip = false}) {
    if (!keepSkip) _lastSkip = null;
    _lastCountdown = 0;
    if (_index + 1 >= steps.length) {
      _accumulatedMs = atTotal;
      _runningSince = null;
      _finished = true;
      _paused = false;
      return [BrewFinished(atTotal)];
    }
    _index++;
    _stepStartTotalMs = atTotal;
    return [StepAdvanced(_index)];
  }
}

class _Skip {
  _Skip(this.fromIndex, this.stepStartTotalMs, this.atMs);
  final int fromIndex;
  final int stepStartTotalMs;
  final int atMs;
}

/// Zamanlayıcının kalıcı durumu (KHV-NFR-003, KHV-FR-BRW-011).
@immutable
class BrewTimerSnapshot {
  /// Bir anlık görüntü oluşturur.
  const BrewTimerSnapshot({
    required this.started,
    required this.stepIndex,
    required this.paused,
    required this.finished,
    required this.totalElapsedMs,
    required this.stepStartTotalMs,
  });

  /// JSON'dan okur.
  factory BrewTimerSnapshot.fromJson(Map<String, Object?> j) =>
      BrewTimerSnapshot(
        started: j['started']! as bool,
        stepIndex: (j['stepIndex']! as num).toInt(),
        paused: j['paused']! as bool,
        finished: j['finished']! as bool,
        totalElapsedMs: (j['totalElapsedMs']! as num).toInt(),
        stepStartTotalMs: (j['stepStartTotalMs']! as num).toInt(),
      );

  /// Başlatıldı mı.
  final bool started;

  /// Aktif adım.
  final int stepIndex;

  /// Duraklatılmış mı.
  final bool paused;

  /// Bitti mi.
  final bool finished;

  /// Kayıt anındaki toplam geçen süre (ms).
  final int totalElapsedMs;

  /// Aktif adımın başladığı toplam süre (ms).
  final int stepStartTotalMs;

  /// JSON'a yazar.
  Map<String, Object?> toJson() => {
    'started': started,
    'stepIndex': stepIndex,
    'paused': paused,
    'finished': finished,
    'totalElapsedMs': totalElapsedMs,
    'stepStartTotalMs': stepStartTotalMs,
  };
}

/// Ön plan zamanlayıcısı yerine planlanmış bildirimle izlenecek uzun
/// demleme eşiği (KHV-FR-BRW-009).
const longBrewThreshold = Duration(minutes: 30);

/// Tarif uzun süreli demleme mi (ör. cold brew).
bool isLongBrew(Recipe r) =>
    Duration(seconds: r.targetTimeS ?? r.plannedDurationS) > longBrewThreshold;

/// Uzun demlemenin bitiş zamanı.
DateTime longBrewEndsAt(Recipe r, DateTime startedAt) =>
    startedAt.add(Duration(seconds: r.targetTimeS ?? r.plannedDurationS));
