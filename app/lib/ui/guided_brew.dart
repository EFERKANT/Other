import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/database.dart';
import '../services/platform.dart';
import '../state/brew_state.dart';
import '../state/providers.dart';
import '../state/settings.dart';
import 'common.dart';

/// Rehber modun nasıl açıldığı.
@immutable
class BrewLaunch {
  const BrewLaunch({
    this.recipe,
    this.recipeId,
    this.quick = false,
    this.longBrewId,
  });

  final Recipe? recipe;
  final String? recipeId;

  /// Hazırlık listesini atla (UC-07).
  final bool quick;

  /// Arka planda izlenen uzun demlemeyi tamamla (KHV-FR-BRW-009).
  final String? longBrewId;
}

/// Rehber mod ve zamanlayıcı (UC-02, KHV-FR-BRW-001 - BRW-012,
/// KHV-HMI-001 - HMI-010, HMI-019 - HMI-023).
class GuidedBrewScreen extends ConsumerStatefulWidget {
  const GuidedBrewScreen({super.key, required this.launch});

  final BrewLaunch launch;

  @override
  ConsumerState<GuidedBrewScreen> createState() => _GuidedBrewScreenState();
}

enum _Phase { loading, checklist, running }

class _GuidedBrewScreenState extends ConsumerState<GuidedBrewScreen>
    with WidgetsBindingObserver {
  _Phase _phase = _Phase.loading;
  Recipe? _recipe;
  BrewTimer? _timer;
  String? _beanId;
  LongBrew? _longBrew;
  final _checked = <int>{};
  Timer? _ticker;
  int _lastPersistMs = 0;
  int _lastStepStartMs = 0;
  bool _flash = false;
  final _safetyStep = <SafetyWarning, int>{};
  bool _finishing = false;

  late final int Function() _clock = ref.read(monotonicMsProvider);

  int get _now => _clock();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(WakelockPlus.enable().catchError((Object _) {}));
    unawaited(_init());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    unawaited(WakelockPlus.disable().catchError((Object _) {}));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Arka plana alınırken durumu sakla (KHV-NFR-003, KHV-HMI-040).
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_persist());
    }
    if (state == AppLifecycleState.paused) unawaited(_enterBackground());
    if (state == AppLifecycleState.resumed) unawaited(_cancelBackground());
  }

  static const _ongoingId = 900;
  static const _stepBaseId = 1000;
  static const _maxStepNotifications = 20;

  /// Sesli ve bildirimde kullanılan kısa adım komutu (KHV-HMI-007).
  static String _command(BrewStep s) {
    final w = s.targetWaterG;
    if (w != null && s.title.contains('dök')) {
      return '${formatNumber(w)} grama kadar dök';
    }
    return s.title;
  }

  /// Uygulama arka plana alınınca adım geçişlerini bildirim olarak planlar
  /// (KHV-FR-BRW-005) ve kilit ekranında kalan süreyi gösterir
  /// (KHV-HMI-022, Android).
  Future<void> _enterBackground() async {
    final t = _timer;
    final r = _recipe;
    if (t == null || r == null || _longBrew != null) return;
    final v = t.view(_now);
    if (v.finished) return;
    final prefs =
        (ref.read(settingsProvider).value ?? const AppSettings()).notifications;
    final n = ref.read(notificationsProvider);
    final wall = ref.read(clockProvider)();
    try {
      if (scheduleNotification(NotificationType.brewStep, wall, prefs) !=
          null) {
        for (final (i, tr)
            in t
                .upcomingTransitions(_now)
                .take(_maxStepNotifications)
                .indexed) {
          final next = tr.stepIndex < t.steps.length
              ? t.steps[tr.stepIndex]
              : null;
          await n.schedule(
            _stepBaseId + i,
            r.name,
            next == null ? 'Demleme bitti. Tadına bakın.' : _command(next),
            wall.add(Duration(milliseconds: tr.inMs)),
          );
        }
      }
      await n.showOngoing(
        _ongoingId,
        r.name,
        'Adım ${v.stepIndex + 1}/${v.stepCount}: ${_command(t.currentStep)}',
        endsAt: v.paused || v.stepRemainingMs == null
            ? null
            : wall.add(Duration(milliseconds: v.stepRemainingMs!)),
      );
    } on Object {
      // Bildirim izni yoksa rehber mod uygulama içi uyarılarla sürer
      // (KHV-HMI-037).
    }
  }

  Future<void> _cancelBackground() async {
    final n = ref.read(notificationsProvider);
    try {
      for (var i = 0; i < _maxStepNotifications; i++) {
        await n.cancel(_stepBaseId + i);
      }
      await n.cancel(_ongoingId);
    } on Object {
      // Yok sayılır.
    }
  }

  /// Adım geçişinde sesli komut; Türkçe ses yoksa uyarı tonu
  /// (KHV-HMI-007, KHV-FR-BRW-013).
  Future<void> _speak(BrewStep step) async {
    final s = ref.read(settingsProvider).value ?? const AppSettings();
    if (!s.voiceGuidance) return;
    final speaker = ref.read(speakerProvider);
    try {
      if (await speaker.turkishAvailable()) {
        await speaker.speak(_command(step));
      } else if (!s.alerts.contains(AlertChannel.sound)) {
        await SystemSound.play(SystemSoundType.alert);
      }
    } on Object {
      // Ses motoru hatası rehber modu durdurmaz.
    }
  }

  /// Bildirime ihtiyaç duyan özellik ilk kullanıldığında, faydasını
  /// açıklayan ön izin ekranı (KHV-HMI-037). Ret ve kabul eşit ağırlıkta
  /// (KHV-HMI-039).
  Future<void> _prepare() async {
    final ctrl = ref.read(settingsProvider.notifier);
    final s = ref.read(settingsProvider).value ?? const AppSettings();
    if (!s.notificationPermissionAsked) {
      await ctrl.change((x) => x.copyWith(notificationPermissionAsked: true));
      if (!mounted) return;
      final allow = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        builder: (c) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Telefon kilitliyken de haber verelim mi?',
                  style: Theme.of(c).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ekran kapandığında veya başka uygulamaya geçtiğinizde adım '
                  'geçişlerini ve cold brew bitişini bildirimle iletiriz. '
                  'İzin vermezseniz uyarılar yalnız uygulama açıkken gelir.',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Şimdi değil'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('İzin ver'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      if (allow == true) {
        try {
          await ref.read(notificationsProvider).requestPermission();
        } on Object {
          // İzin alınamazsa uygulama içi uyarılar sürer.
        }
      }
    }
    final s2 = ref.read(settingsProvider).value ?? const AppSettings();
    if (s2.voiceGuidance && !s2.ttsHelpShown) {
      final available = await ref
          .read(speakerProvider)
          .turkishAvailable()
          .catchError((Object _) => false);
      if (!available) {
        await ctrl.change((x) => x.copyWith(ttsHelpShown: true));
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Türkçe ses bulunamadı'),
            content: const Text(
              'Sesli adım komutu için cihazınıza Türkçe ses paketi yükleyin. '
              'Android: Ayarlar > Sistem > Diller > Metin okuma > Ses '
              'verilerini yükle > Türkçe. iOS: Ayarlar > Erişilebilirlik > '
              'Seslendirilen İçerik > Sesler > Türkçe. O zamana kadar adım '
              'geçişlerinde uyarı tonu çalacağız.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Anladım'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _init() async {
    final l = widget.launch;
    if (l.longBrewId != null) {
      final list = await ref.read(longBrewsProvider.future);
      final lb = list.where((b) => b.id == l.longBrewId).firstOrNull;
      if (lb == null) return _closeEmpty();
      _longBrew = lb;
      _beanId = lb.beanId;
      final after = _stepsAfterLongStep(lb.recipe);
      _recipe = lb.recipe;
      _startTimer(
        after.isEmpty
            ? const [
                BrewStep(title: 'Demleme hazır', trigger: StepTrigger.confirm),
              ]
            : after,
      );
      return;
    }
    if (l.recipe == null && l.recipeId == null) {
      final active = await loadActiveBrew(ref);
      if (active == null) return _closeEmpty();
      _recipe = active.recipe;
      _beanId = active.beanId;
      final gap = ref.read(clockProvider)().difference(active.savedAt);
      _timer = BrewTimer.restore(
        active.recipe.steps,
        active.snapshot,
        nowMs: _now,
        elapsedSinceSnapshotMs: gap.inMilliseconds,
      );
      if (!active.snapshot.started) {
        _timer = null;
        setState(() => _phase = _Phase.checklist);
        return;
      }
      _lastStepStartMs = _now - _timer!.view(_now).stepElapsedMs;
      _beginTicking();
      setState(() => _phase = _Phase.running);
      return;
    }
    final content = await ref.read(contentProvider.future);
    if (!mounted) return;
    _recipe =
        l.recipe ??
        ref.read(recipeByIdProvider(l.recipeId!)) ??
        content.recipes.where((r) => r.id == l.recipeId).firstOrNull;
    if (_recipe == null) return _closeEmpty();
    if (l.quick) {
      _startTimer(_recipe!.steps);
    } else {
      setState(() => _phase = _Phase.checklist);
    }
  }

  void _closeEmpty() {
    if (mounted) context.canPop() ? context.pop() : context.go('/');
  }

  List<BrewStep> _stepsAfterLongStep(Recipe r) {
    final i = r.steps.indexWhere(
      (s) => (s.durationS ?? 0) > longBrewThreshold.inSeconds,
    );
    return i < 0 ? const [] : r.steps.sublist(i + 1);
  }

  Future<void> _startTimer(List<BrewStep> steps) async {
    await _prepare();
    if (!mounted) return;
    final t = BrewTimer(steps);
    _timer = t;
    _handle(t.start(_now));
    _beginTicking();
    setState(() => _phase = _Phase.running);
    unawaited(_persist());
  }

  void _beginTicking() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final t = _timer;
      if (t == null) return;
      _handle(t.tick(_now));
      if (_now - _lastPersistMs > 5000) unawaited(_persist());
      if (mounted) setState(() {});
    });
  }

  Future<void> _persist() async {
    final t = _timer;
    final r = _recipe;
    if (r == null || _longBrew != null) return;
    _lastPersistMs = _now;
    final db = ref.read(databaseProvider);
    if (t != null && t.view(_now).finished) return;
    await db.writeJson(
      activeBrewKey,
      ActiveBrew(
        recipe: r,
        snapshot:
            t?.snapshot(_now) ??
            const BrewTimerSnapshot(
              started: false,
              stepIndex: 0,
              paused: false,
              finished: false,
              totalElapsedMs: 0,
              stepStartTotalMs: 0,
            ),
        savedAt: ref.read(clockProvider)(),
        beanId: _beanId,
      ).toJson(),
    );
  }

  Set<AlertChannel> get _alerts =>
      ref.read(settingsProvider).value?.alerts ?? AlertChannel.values.toSet();

  /// Uyarılar en az iki kanaldan verilir (KHV-HMI-005).
  void _alert({required bool strong}) {
    final a = _alerts;
    if (a.contains(AlertChannel.sound)) {
      unawaited(
        SystemSound.play(
          strong ? SystemSoundType.alert : SystemSoundType.click,
        ),
      );
    }
    if (a.contains(AlertChannel.vibration)) {
      unawaited(
        strong ? HapticFeedback.heavyImpact() : HapticFeedback.selectionClick(),
      );
    }
    if (a.contains(AlertChannel.visual) && strong) {
      setState(() => _flash = true);
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _flash = false);
      });
    }
  }

  void _handle(List<TimerEvent> events) {
    for (final e in events) {
      switch (e) {
        case StepAdvanced():
          _lastStepStartMs = _now;
          if (e.stepIndex > 0) _alert(strong: true);
          unawaited(_speak(_timer!.steps[e.stepIndex]));
          unawaited(_persist());
        case PreWarning():
          _alert(strong: false);
        case CountdownTick():
          if (_alerts.contains(AlertChannel.vibration)) {
            unawaited(HapticFeedback.lightImpact());
          }
        case BrewFinished():
          _alert(strong: true);
          unawaited(_finish(e.totalElapsedMs));
      }
    }
  }

  Future<void> _finish(int totalMs) async {
    if (_finishing) return;
    _finishing = true;
    _ticker?.cancel();
    final r = _recipe!;
    final db = ref.read(databaseProvider);
    final id = ref.read(idProvider)();
    final lb = _longBrew;
    final actualS = lb != null
        ? ref.read(clockProvider)().difference(lb.startedAt).inSeconds
        : (r.method.isEspresso
              ? ((_now - _lastStepStartMs) / 1000).round()
              : (totalMs / 1000).round());
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    await db.insertBrew(
      BrewsCompanion.insert(
        id: id,
        brewedAt: ref.read(clockProvider)(),
        recipeId: r.id,
        lineageId: r.sourceRecipeId ?? r.id,
        methodId: r.method.id,
        recipeJson: jsonEncode(r.toJson()),
        beanId: Value(_beanId),
        equipmentJson: Value(jsonEncode(settings.equipment.toJson())),
        actualTimeS: Value(actualS),
      ),
      doseG: r.coffeeG,
    );
    await db.deleteKey(activeBrewKey);
    await _cancelBackground();
    if (lb != null) await ref.read(longBrewsProvider.notifier).remove(lb.id);
    if (!mounted) return;
    // Bitişte tat değerlendirme ekranı açılır (KHV-FR-BRW-007).
    context.pushReplacement('/taste/$id');
  }

  Future<void> _stop() async {
    _ticker?.cancel();
    await _cancelBackground();
    await ref.read(databaseProvider).deleteKey(activeBrewKey);
    if (mounted) context.canPop() ? context.pop() : context.go('/');
  }

  /// Uzun adımı arka plana taşır (KHV-FR-BRW-009).
  Future<void> _moveToBackground() async {
    final t = _timer!;
    final remaining = Duration(milliseconds: t.remainingPlannedMs(_now));
    final now = ref.read(clockProvider)();
    final lb = LongBrew(
      id: ref.read(idProvider)(),
      recipe: _recipe!,
      startedAt: now.subtract(
        Duration(milliseconds: t.view(_now).totalElapsedMs),
      ),
      endsAt: now.add(remaining),
      beanId: _beanId,
    );
    await ref.read(longBrewsProvider.notifier).add(lb);
    _ticker?.cancel();
    await ref.read(databaseProvider).deleteKey(activeBrewKey);
    if (mounted) context.canPop() ? context.pop() : context.go('/');
  }

  void _skip() {
    final t = _timer!;
    _handle(t.skip(_now));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: const Text('Adım atlandı'),
          action: SnackBarAction(
            label: 'Geri al',
            onPressed: () {
              if (t.undoSkip(_now)) {
                _finishing = false;
                _beginTicking();
                setState(() {});
              }
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _Phase.loading => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      _Phase.checklist => _checklist(context),
      _Phase.running => _running(context),
    };
  }

  /// Hazırlık kontrol listesi (KHV-FR-BRW-001).
  Widget _checklist(BuildContext context) {
    final r = _recipe!;
    final content = ref.watch(contentProvider).value;
    final items = content?.method(r.method).checklist ?? const <String>[];
    final beans = (ref.watch(beansProvider).value ?? const <Bean>[])
        .where((b) => !b.archived)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text('Hazırlık · ${r.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${formatNumber(r.coffeeG)} g kahve · '
            '${formatNumber(r.waterG)} g ${r.method.isEspresso ? 'çıktı' : 'su'}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final (i, item) in items.indexed)
            CheckboxListTile(
              value: _checked.contains(i),
              title: Text(item),
              onChanged: (v) => setState(
                () => v == true ? _checked.add(i) : _checked.remove(i),
              ),
            ),
          const SectionTitle('Çekirdek'),
          DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: _beanId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Kullanılan çekirdek (isteğe bağlı)',
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Seçilmedi')),
              for (final b in beans)
                DropdownMenuItem(value: b.id, child: Text(b.name)),
            ],
            onChanged: (v) => setState(() => _beanId = v),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: () => _startTimer(r.steps),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Demlemeyi başlat'),
          ),
        ),
      ),
    );
  }

  Widget _running(BuildContext context) {
    final t = _timer!;
    final v = t.view(_now);
    final step = t.currentStep;
    final next = t.nextStep;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final paused = v.paused;
    final countdown = v.stepRemainingS != null && v.stepRemainingS! <= 3
        ? v.stepRemainingS
        : null;
    // Aynı uyarı bir demlemede yalnız ilk göründüğü adımda gösterilir
    // (KHV-HMI-021).
    final safety = step.safety;
    final showSafety =
        safety != null &&
        _safetyStep.putIfAbsent(safety, () => v.stepIndex) == v.stepIndex;
    final isLongStep =
        step.advancesByTime &&
        (step.durationS ?? 0) > longBrewThreshold.inSeconds;

    // Birincil: hedef kümülatif ağırlık veya adım komutu (KHV-HMI-001).
    final primary =
        step.targetWaterG != null && step.trigger == StepTrigger.weight
        ? '${formatNumber(step.targetWaterG!)} g'
        : step.title;
    final secondary = v.stepRemainingS != null
        ? formatDuration(v.stepRemainingS!)
        : (step.observation != null
              ? '${step.observation}: dokunun'
              : 'Hazır olunca dokunun');

    final bg = paused
        ? scheme.surfaceContainerHighest
        : _flash
        ? scheme.primaryContainer
        : scheme.surface;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final body = LayoutBuilder(
      builder: (context, c) {
        final landscape = c.maxWidth > c.maxHeight;
        final primaryStyle = text.displayLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: landscape ? 64 : 72,
          color: paused ? scheme.onSurfaceVariant : scheme.onSurface,
        );
        final info = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Adım ${v.stepIndex + 1}/${v.stepCount}',
              style: text.titleMedium,
            ),
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                countdown != null ? '$countdown' : primary,
                textAlign: TextAlign.center,
                style: primaryStyle,
                maxLines: 3,
              ),
            ),
            if (countdown == null &&
                step.trigger == StepTrigger.weight &&
                step.targetWaterG != null)
              Text(
                step.title,
                style: text.titleLarge,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 12),
            Text(
              secondary,
              style: text.headlineMedium,
              textAlign: TextAlign.center,
            ),
            if (step.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(step.description, textAlign: TextAlign.center),
              ),
            const SizedBox(height: 16),
            if (next != null)
              Text(
                'Sonra: ${next.title}',
                style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
            Text('Toplam ${formatDuration(v.totalElapsedMs ~/ 1000)}'),
          ],
        );
        final controls = Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            IconButton.filledTonal(
              iconSize: 32,
              tooltip: paused ? 'Devam et' : 'Duraklat',
              onPressed: () =>
                  setState(() => paused ? t.resume(_now) : t.pause(_now)),
              icon: Icon(paused ? Icons.play_arrow : Icons.pause),
            ),
            IconButton.filledTonal(
              iconSize: 32,
              tooltip: 'Adımı atla',
              onPressed: paused ? null : _skip,
              icon: const Icon(Icons.skip_next),
            ),
            HoldButton(label: 'Bitir', onConfirmed: _stop),
            if (isLongStep && _longBrew == null)
              FilledButton.tonalIcon(
                onPressed: _moveToBackground,
                icon: const Icon(Icons.schedule),
                label: const Text('Arka planda takip et'),
              ),
          ],
        );
        final children = [
          Expanded(flex: 3, child: info),
          Padding(padding: const EdgeInsets.all(16), child: controls),
        ];
        return Column(
          children: [
            if (paused)
              Container(
                width: double.infinity,
                color: scheme.secondaryContainer,
                padding: const EdgeInsets.all(12),
                child: Text(
                  'DURAKLATILDI',
                  textAlign: TextAlign.center,
                  style: text.titleLarge?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
            if (showSafety)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SafetyBanner(safety),
              ),
            Expanded(
              child: landscape
                  ? Row(children: children)
                  : Column(children: children),
            ),
          ],
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_recipe!.name),
        automaticallyImplyLeading: false,
        backgroundColor: bg,
      ),
      body: AnimatedContainer(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 250),
        color: bg,
        child: SafeArea(
          // Onay adımlarında ekranın herhangi bir yerine dokunarak
          // ilerlenir (KHV-HMI-006).
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: v.waitingForConfirm && !paused
                ? () => setState(() => _handle(t.confirm(_now)))
                : null,
            child: Semantics(
              onTapHint: v.waitingForConfirm ? 'Sonraki adıma geç' : null,
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}
