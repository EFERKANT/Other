import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../data/database.dart';
import '../state/providers.dart';
import '../state/settings.dart';
import 'common.dart';
import 'labels.dart';

/// Tat değerlendirmesi ve dial-in asistanı (UC-03, UC-04,
/// KHV-FR-DIA-001 - DIA-006, KHV-FR-BRW-008, KHV-HMI-013 - HMI-015).
class TasteScreen extends ConsumerStatefulWidget {
  const TasteScreen({super.key, required this.brewId});

  final String brewId;

  @override
  ConsumerState<TasteScreen> createState() => _TasteScreenState();
}

class _TasteScreenState extends ConsumerState<TasteScreen> {
  Brew? _brew;
  Recipe? _recipe;
  Offset _point = Offset.zero;
  bool _sourAndBitter = false;
  bool _flat = false;
  final _observations = <ProcessObservation>{};
  int _score = 3;
  double? _yieldG;
  final _notes = TextEditingController();
  DialInResult? _result;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final b = await ref.read(databaseProvider).brewById(widget.brewId);
    if (!mounted || b == null) return;
    final r = brewRecipe(b);
    setState(() {
      _brew = b;
      _recipe = r;
      _notes.text = b.notes;
      _yieldG = r.method.isEspresso ? r.waterG : null;
      final auto = b.actualTimeS == null
          ? null
          : observeDuration(r, b.actualTimeS!);
      if (auto != null && !r.method.isEspresso) _observations.add(auto);
    });
  }

  ShotEvaluation? get _shot {
    final r = _recipe;
    final b = _brew;
    if (r == null || !r.method.isEspresso || b?.actualTimeS == null) {
      return null;
    }
    return evaluateShot(
      r,
      doseG: r.coffeeG,
      yieldG: _yieldG ?? r.waterG,
      timeS: b!.actualTimeS!,
    );
  }

  TasteAssessment _assessment() {
    final obs = {..._observations};
    final shot = _shot?.observation;
    if (shot != null) obs.add(shot);
    return TasteAssessment(
      score: _score,
      extraction: _point.dx,
      strength: -_point.dy,
      sourAndBitter: _sourAndBitter,
      flat: _flat,
      observations: obs,
    );
  }

  Future<void> _evaluate() async {
    final engine = ref.read(dialInEngineProvider);
    final r = _recipe!;
    if (engine == null) return;
    final db = ref.read(databaseProvider);
    final past = await db.lineage(_brew!.lineageId, excludeId: _brew!.id);
    final history = [
      for (final p in past.length > 3 ? past.sublist(past.length - 3) : past)
        if (brewAssessment(p) case final a?)
          DialInAttempt(
            assessment: a,
            symptom: DialInEngine.detectSymptom(r.method, a),
            acceptedCorrection: p.correctionAccepted ? brewCorrection(p) : null,
          ),
    ];
    int? beanAge;
    if (_brew!.beanId != null) {
      final bean = await db.beanById(_brew!.beanId!);
      if (bean?.roastDate != null) {
        beanAge = daysSinceRoast(bean!.roastDate!, ref.read(clockProvider)());
      }
    }
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    setState(() {
      _result = engine.evaluate(
        method: r.method,
        current: _assessment(),
        history: history,
        equipment: settings.equipment,
        beanAgeDays: beanAge,
      );
    });
  }

  /// Değerlendirmeyi kaydeder; kabul edilen öneri tarifin bir sonraki
  /// demlemesine uygulanır (KHV-FR-DIA-005).
  Future<void> _save({required bool accept}) async {
    if (_saving) return;
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final r = _recipe!;
    final c = _result?.correction;
    final a = _assessment();
    await db.updateBrew(
      widget.brewId,
      BrewsCompanion(
        assessmentJson: Value(jsonEncode(a.toJson())),
        score: Value(a.score),
        correctionJson: Value(c == null ? null : jsonEncode(c.toJson())),
        correctionAccepted: Value(accept && c != null),
        notes: Value(_notes.text.trim()),
      ),
    );
    await db.logEvent('taste', {
      'brewId': widget.brewId,
      'score': a.score,
      if (c != null) 'ruleId': c.ruleId,
      'accepted': accept,
    });
    String? nextRecipeId;
    if (accept && c != null && c.isParametric) {
      var next = applyCorrection(r, c);
      if (!r.editable || ref.read(recipeByIdProvider(r.id)) == null) {
        next = next.copyWith(
          id: ref.read(idProvider)(),
          sourceRecipeId: r.sourceRecipeId ?? r.id,
          owner: RecipeOwner.user,
          name: r.editable ? r.name : '${r.name} (ayarım)',
          favorite: false,
        );
      }
      await db.saveUserRecipe(next);
      nextRecipeId = next.id;
    }
    if (!mounted) return;
    if (nextRecipeId != null) {
      context.go('/recipe/$nextRecipeId');
    } else {
      context.go('/log/${widget.brewId}');
    }
  }

  Future<void> _notSure() async {
    final answers = <String, String>{};
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => _Questionnaire(answers: answers),
    );
    if (done != true) return;
    final a = assessmentFromAnswers(answers, score: _score);
    setState(() {
      _point = Offset(a.extraction, -a.strength);
      _sourAndBitter = a.sourAndBitter;
      _flat = a.flat;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = _recipe;
    if (r == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final t = Theme.of(context).textTheme;
    final shot = _shot;
    final notes = _assessment().notes;
    return Scaffold(
      appBar: AppBar(title: const Text('Tadı nasıldı?')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(r.name, style: t.titleMedium),
          if (_brew!.actualTimeS != null)
            Text('Süre: ${formatDuration(_brew!.actualTimeS!)}'),
          if (shot != null) ...[
            const SectionTitle('Shot'),
            NumberStepper(
              label: 'Çıktı ağırlığı',
              value: _yieldG ?? r.waterG,
              unit: 'g',
              step: 0.5,
              min: 5,
              max: 100,
              showSlider: false,
              onChanged: (v) => setState(() {
                _yieldG = v;
                _result = null;
              }),
            ),
            _ShotSummary(shot: shot, recipe: r),
          ],
          const SectionTitle('Tat'),
          const Text(
            'Fincandaki tadı alanda işaretleyin. Merkez dengeli demektir.',
          ),
          const SizedBox(height: 8),
          TastePad(
            value: _point,
            onChanged: (p) => setState(() {
              _point = p;
              _result = null;
            }),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final n in notes)
                Chip(
                  avatar: Icon(tasteNoteIcon(n), size: 18),
                  label: Text(tasteNoteName(n)),
                ),
            ],
          ),
          for (final n in notes)
            Text(
              '${tasteNoteName(n)}: ${tasteNoteExample(n)}',
              style: t.bodySmall,
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _notSure,
              icon: const Icon(Icons.quiz_outlined),
              label: const Text('Emin değilim'),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _sourAndBitter,
            title: const Text('Hem ekşi hem acı'),
            subtitle: const Text('Aynı yudumda keskinlik ve kurutan acılık'),
            onChanged: (v) => setState(() {
              _sourAndBitter = v ?? false;
              _result = null;
            }),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _flat,
            title: Text(tasteNoteName(TasteNote.flat)),
            subtitle: Text(tasteNoteExample(TasteNote.flat)),
            onChanged: (v) => setState(() {
              _flat = v ?? false;
              _result = null;
            }),
          ),
          for (final o in observationsFor(r.method))
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _observations.contains(o),
              title: Text(observationName(o)),
              onChanged: (v) => setState(() {
                v == true ? _observations.add(o) : _observations.remove(o);
                _result = null;
              }),
            ),
          const SectionTitle('Puan'),
          _ScoreBar(
            score: _score,
            onChanged: (s) => setState(() {
              _score = s;
              _result = null;
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Not (isteğe bağlı)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_result == null)
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: _evaluate,
              child: const Text('Öneriyi göster'),
            )
          else
            _ResultCard(
              result: _result!,
              saving: _saving,
              onAccept: () => _save(accept: true),
              onSkip: () => _save(accept: false),
            ),
        ],
      ),
    );
  }
}

/// İki boyutlu tat alanı: yatay ekşi-acı, dikey sulu-yoğun (KHV-HMI-013).
/// Ekran okuyucu için ayrıca seçim düğmeleri sunulur (KHV-HMI-031).
class TastePad extends StatelessWidget {
  const TastePad({super.key, required this.value, required this.onChanged});

  /// x: -1 ekşi .. +1 acı; y: -1 yoğun (üst) .. +1 sulu (alt).
  final Offset value;
  final ValueChanged<Offset> onChanged;

  void _update(Offset local, Size size) {
    final x = (local.dx / size.width * 2 - 1).clamp(-1.0, 1.0);
    final y = (local.dy / size.height * 2 - 1).clamp(-1.0, 1.0);
    // Merkeze yakın dokunuşları dengeliye yapıştır.
    final snap = Offset(x.abs() < 0.12 ? 0 : x, y.abs() < 0.12 ? 0 : y);
    onChanged(snap);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        Text('Yoğun ▲', style: t.labelLarge),
        Row(
          children: [
            RotatedBox(
              quarterTurns: 3,
              child: Text('◀ Ekşi', style: t.labelLarge),
            ),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.3,
                child: LayoutBuilder(
                  builder: (context, c) {
                    final size = Size(c.maxWidth, c.maxHeight);
                    final pos = Offset(
                      (value.dx + 1) / 2 * size.width,
                      (value.dy + 1) / 2 * size.height,
                    );
                    return Semantics(
                      label: 'Tat alanı',
                      value: _describe(value),
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTapDown: (d) => _update(d.localPosition, size),
                        onPanUpdate: (d) => _update(d.localPosition, size),
                        child: Container(
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: scheme.outline),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Container(
                                  width: size.width * 0.24,
                                  height: size.height * 0.24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: scheme.secondaryContainer,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Dengeli',
                                    style: TextStyle(
                                      color: scheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: pos.dx - 18,
                                top: pos.dy - 18,
                                child: Icon(
                                  Icons.radio_button_checked,
                                  size: 36,
                                  color: scheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            RotatedBox(
              quarterTurns: 1,
              child: Text('Acı ▶', style: t.labelLarge),
            ),
          ],
        ),
        Text('Sulu ▼', style: t.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final (label, o) in const [
              ('Ekşi', Offset(-0.7, 0)),
              ('Acı', Offset(0.7, 0)),
              ('Sulu', Offset(0, 0.7)),
              ('Yoğun', Offset(0, -0.7)),
              ('Dengeli', Offset.zero),
            ])
              ChoiceChip(
                label: Text(label),
                selected: value == o,
                onSelected: (_) => onChanged(o),
              ),
          ],
        ),
      ],
    );
  }

  static String _describe(Offset v) {
    final a = TasteAssessment(score: 3, extraction: v.dx, strength: -v.dy);
    return a.notes.map(tasteNoteName).join(', ');
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.score, required this.onChanged});

  final int score;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 1; i <= 5; i++)
        IconButton(
          iconSize: 36,
          tooltip: '$i puan',
          isSelected: i <= score,
          onPressed: () => onChanged(i),
          icon: const Icon(Icons.star_border),
          selectedIcon: const Icon(Icons.star),
        ),
    ],
  );
}

class _ShotSummary extends StatelessWidget {
  const _ShotSummary({required this.shot, required this.recipe});

  final ShotEvaluation shot;
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final timeText = shot.timeInRange
        ? 'Süre hedef aralıkta'
        : shot.timeDeltaS < 0
        ? 'Hedefe göre ${-shot.timeDeltaS} sn hızlı'
        : 'Hedefe göre ${shot.timeDeltaS} sn yavaş';
    return Card(
      child: ListTile(
        leading: Icon(
          shot.timeInRange ? Icons.check_circle_outline : Icons.speed,
        ),
        title: Text(
          'Oran ${formatRatio(shot.ratio)} (hedef ${formatRatio(shot.targetRatio)}) '
          '· ${shot.timeS} sn',
        ),
        subtitle: Text(
          '$timeText. Hedef ${recipe.targetTimeS ?? 25}-'
          '${recipe.targetTimeMaxS ?? 30} sn.',
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.saving,
    required this.onAccept,
    required this.onSkip,
  });

  final DialInResult result;
  final bool saving;
  final VoidCallback onAccept;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = result.correction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.isBalanced) ...[
                  Text('Dengeli bir fincan', style: t.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Bu ayarları koruyun. Tarifi favorilere ekleyerek tek '
                    'dokunuşla tekrar başlatabilirsiniz.',
                  ),
                ] else ...[
                  Text(symptomName(result.symptom!), style: t.labelLarge),
                  const SizedBox(height: 8),
                  if (c != null) ...[
                    Text('Bir sonraki denemede', style: t.bodySmall),
                    Semantics(
                      header: true,
                      child: Text(c.text, style: t.headlineSmall),
                    ),
                    const SizedBox(height: 8),
                    Text('Neden: ${c.reason}'),
                    const SizedBox(height: 8),
                    const Text(
                      'Her denemede yalnız bir değişkeni değiştirin.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        if (result.showRootCauseChecklist)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Üç denemedir ilerleme yok', style: t.titleMedium),
                  const SizedBox(height: 4),
                  const Text(
                    'Sorun tarifte değil ekipmanda, suda veya çekirdekte '
                    'olabilir. Şunları kontrol edin:',
                  ),
                  for (final check in result.rootCauseChecks)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        result.suspectedRootCauses.contains(check)
                            ? Icons.priority_high
                            : Icons.check,
                      ),
                      title: Text(rootCauseName(check)),
                      subtitle: result.suspectedRootCauses.contains(check)
                          ? const Text('Profilinize göre olası neden')
                          : null,
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        if (c != null)
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: saving ? null : onAccept,
            child: Text(
              c.isParametric ? 'Öneriyi tarife uygula' : 'Anladım, kaydet',
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: saving ? null : onSkip,
          child: Text(c == null ? 'Kaydet' : 'Öneriyi uygulamadan kaydet'),
        ),
      ],
    );
  }
}

/// "Emin değilim" için en fazla üç yönlendirme sorusu (KHV-HMI-015).
class _Questionnaire extends StatefulWidget {
  const _Questionnaire({required this.answers});

  final Map<String, String> answers;

  @override
  State<_Questionnaire> createState() => _QuestionnaireState();
}

class _QuestionnaireState extends State<_Questionnaire> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final q = tasteQuestions[_index];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Soru ${_index + 1}/${tasteQuestions.length}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(q.text, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final o in q.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () {
                    widget.answers[q.id] = o.id;
                    if (_index + 1 < tasteQuestions.length) {
                      setState(() => _index++);
                    } else {
                      Navigator.pop(context, true);
                    }
                  },
                  child: Text(o.text),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
