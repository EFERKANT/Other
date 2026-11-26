import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../services/platform.dart';
import '../state/providers.dart';
import '../state/settings.dart';
import 'common.dart';
import 'labels.dart';
import 'share_card.dart';

/// Tarif ve hesaplayıcı ekranı (KHV-FR-RCP-002 - RCP-008, RCP-010,
/// RCP-013, KHV-HMI-011, HMI-012, HMI-016, HMI-017).
class RecipeDetailScreen extends ConsumerStatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  /// Bu demleme için düzenlenen çalışma kopyası.
  Recipe? _work;
  bool _showAdvanced = false;

  /// Oranı değiştirir: doz sabit kalır, su ve adım hedefleri ölçeklenir.
  Recipe _setRatio(Recipe r, double ratio) =>
      scaleRecipe(r, waterG: r.coffeeG * ratio).copyWith(coffeeG: r.coffeeG);

  @override
  Widget build(BuildContext context) {
    final base = ref.watch(recipeByIdProvider(widget.recipeId));
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    if (base == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ref.watch(contentProvider).isLoading
            ? const Center(child: CircularProgressIndicator())
            : const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Tarif bulunamadı',
                message: 'Bu tarif silinmiş olabilir.',
              ),
      );
    }
    final r = _work ?? base;
    final dirty = _work != null;
    final eq = settings.equipment;
    final profile = settings.profile;
    final advancedVisible = !profile.hidesAdvancedParameters || _showAdvanced;
    final warnings = rangeWarnings(
      r.method,
      coffeeG: r.coffeeG,
      ratio: r.ratio,
      temperatureC: r.temperatureC,
    );
    final missing = missingEquipment(r.method, eq);
    final content = ref.watch(contentProvider).value;
    final methodContent = content?.method(r.method);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(r.name),
        actions: [
          // Favori durumu düzenlenen kopyadan değil kayıtlı tariften okunur;
          // miktar değiştirildikten sonra da yıldız tepki verir (KB-016,
          // KHV-FR-RCP-011).
          IconButton(
            tooltip: base.favorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
            // Yıldız yalnız puan içindir; favori yer imidir (KB-018).
            icon: Icon(base.favorite ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () => ref
                .read(databaseProvider)
                .setFavorite(base.id, favorite: !base.favorite),
          ),
          PopupMenuButton<String>(
            tooltip: 'Diğer işlemler',
            onSelected: (v) => switch (v) {
              'copy' => _saveAsMine(r),
              'share' => _share(r),
              'rename' => _rename(base),
              'delete' => _delete(r),
              _ => null,
            },
            itemBuilder: (c) => [
              const PopupMenuItem(
                value: 'copy',
                child: Text('Kendi tarifim olarak kaydet'),
              ),
              if (ref.read(contentProvider).value?.flag('share') ?? true)
                const PopupMenuItem(value: 'share', child: Text('Paylaş')),
              if (r.editable) ...[
                const PopupMenuItem(
                  value: 'rename',
                  child: Text('Yeniden adlandır'),
                ),
                const PopupMenuItem(value: 'delete', child: Text('Sil')),
              ],
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          Text(methodName(r.method), style: t.titleMedium),
          if (methodContent != null) Text(methodContent.summary),
          if (r.source.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Kaynak: ${r.source}', style: t.bodySmall),
            ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            _MissingCard(missing: missing),
          ],
          ..._equipmentQuestions(r.method, eq),
          const SectionTitle('Miktarlar'),
          ..._amounts(r, eq, warnings),
          if (profile.hidesAdvancedParameters)
            SwitchListTile(
              title: const Text('Ayrıntılar'),
              subtitle: const Text('Sıcaklık ve süre ince ayarı'),
              value: _showAdvanced,
              onChanged: (v) => setState(() => _showAdvanced = v),
            ),
          if (advancedVisible) ..._advanced(r, warnings),
          _temperatureHint(r, eq),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.grain, size: 18),
                label: Text('Öğütme: ${_grindText(r.grind)}'),
              ),
              const TermChip('Grind size'),
              if (r.method == BrewMethod.v60 || r.method == BrewMethod.chemex)
                const TermChip('Bloom'),
              const TermChip('Extraction'),
            ],
          ),
          const SectionTitle('Adımlar'),
          for (final (i, s) in r.steps.indexed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(s.title),
              subtitle: Text(
                [
                  if (s.targetWaterG != null)
                    'Hedef ${formatNumber(s.targetWaterG!)} g',
                  if (s.durationS != null) formatDuration(s.durationS!),
                  if (s.observation != null) s.observation!,
                ].join(' · '),
              ),
            ),
          if (methodContent != null) ...[
            const SectionTitle('Püf noktaları'),
            for (final tip in methodContent.tips)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(tip)),
                  ],
                ),
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (dirty)
                Wrap(
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _work = null),
                      child: const Text('Sıfırla'),
                    ),
                    if (r.editable)
                      TextButton(
                        onPressed: () => _saveEdits(r),
                        child: const Text('Kaydet'),
                      ),
                  ],
                ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: () => context.push('/brew', extra: r),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Rehberle demle'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _grindText(GrindSetting g) {
    final parts = [g.label];
    if (g.clicks != null) parts.add('kademe ${g.clicks}');
    if (g.offset != 0) {
      parts.add(
        g.offset < 0
            ? '${-g.offset} kademe daha ince'
            : '${g.offset} kademe daha kalın',
      );
    }
    return parts.join(', ');
  }

  void _set(Recipe r) => setState(() => _work = r);

  List<Widget> _amounts(Recipe r, EquipmentProfile eq, Set<RangeWarning> w) {
    const ratioWarn = 'Bu oran yöntem için alışılmışın dışında.';
    const coffeeWarn = 'Bu miktar yöntem için alışılmışın dışında.';
    final spoons = eq.hasScale == true
        ? null
        : 'Terazi yoksa: yaklaşık '
              '${formatNumber(SpoonEquivalent.spoons(r.coffeeG, r.method))} '
              '${SpoonEquivalent.spoonName(r.method)}';
    if (r.method.isCupBased) {
      return [
        NumberStepper(
          label: 'Fincan',
          value: (r.cups ?? 1).toDouble(),
          unit: 'fincan',
          min: 1,
          max: 6,
          decimals: 0,
          showSlider: false,
          onChanged: (v) => _set(scaleTurkishCups(r, v.round())),
        ),
        Text(
          '${formatNumber(r.coffeeG)} g kahve · ${formatNumber(r.waterG)} ml '
          'soğuk su (fincanla ölçün)',
        ),
        if (spoons != null) Text(spoons),
      ];
    }
    if (r.method.isEspresso) {
      return [
        NumberStepper(
          label: 'Doz',
          value: r.coffeeG,
          unit: 'g',
          step: 0.5,
          min: 5,
          max: 30,
          warning: w.contains(RangeWarning.coffee) ? coffeeWarn : null,
          onChanged: (v) => _set(_setRatio(r.copyWith(coffeeG: v), r.ratio)),
        ),
        NumberStepper(
          label: 'Çıktı',
          value: r.waterG,
          unit: 'g',
          step: 1,
          min: 10,
          max: 100,
          warning: w.contains(RangeWarning.ratio) ? ratioWarn : null,
          onChanged: (v) =>
              _set(scaleRecipe(r, waterG: v).copyWith(coffeeG: r.coffeeG)),
        ),
        Text('Oran ${formatRatio(r.ratio)}'),
      ];
    }
    return [
      NumberStepper(
        label: 'Kahve',
        value: r.coffeeG,
        unit: 'g',
        step: 0.5,
        min: 1,
        max: 150,
        warning: w.contains(RangeWarning.coffee) ? coffeeWarn : null,
        onChanged: (v) => _set(scaleRecipe(r, coffeeG: v)),
      ),
      NumberStepper(
        label: 'Oran',
        prefix: '1:',
        value: BrewCalculator.round1(r.ratio),
        unit: '',
        step: 0.5,
        min: 2,
        max: 25,
        warning: w.contains(RangeWarning.ratio) ? ratioWarn : null,
        onChanged: (v) => _set(_setRatio(r, v)),
      ),
      NumberStepper(
        label: 'Su',
        value: r.waterG,
        unit: 'g',
        step: 10,
        min: 20,
        max: 2000,
        decimals: 0,
        onChanged: (v) => _set(scaleRecipe(r, waterG: v)),
      ),
      if (spoons != null) Text(spoons),
    ];
  }

  List<Widget> _advanced(Recipe r, Set<RangeWarning> w) => [
    if (r.temperatureC != null)
      NumberStepper(
        label: 'Su sıcaklığı',
        value: r.temperatureC!,
        unit: '°C',
        step: 1,
        min: 70,
        max: 100,
        decimals: 0,
        warning: w.contains(RangeWarning.temperature)
            ? 'Bu sıcaklık yöntem için alışılmışın dışında.'
            : null,
        onChanged: (v) => _set(r.copyWith(temperatureC: v)),
      ),
    if (r.targetTimeS != null)
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.timer_outlined),
        title: const Text('Hedef süre'),
        subtitle: Text(
          r.targetTimeMaxS != null && r.targetTimeMaxS != r.targetTimeS
              ? '${formatDuration(r.targetTimeS!)} - ${formatDuration(r.targetTimeMaxS!)}'
              : formatDuration(r.targetTimeS!),
        ),
      ),
  ];

  /// Sıcaklık ayarlı kettle yoksa bekleme talimatı (KHV-FR-RCP-008).
  Widget _temperatureHint(Recipe r, EquipmentProfile eq) {
    final wait = boilWaitSeconds(r.method, r.temperatureC);
    if (r.method == BrewMethod.turkish || r.method == BrewMethod.coldBrew) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.thermostat),
        title: Text('Soğuk suyla başlanır'),
      );
    }
    if (wait == null || eq.hasTemperatureKettle) {
      return const SizedBox.shrink();
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.thermostat),
      title: Text(
        wait == 0
            ? 'Hazneye kaynamış su koyun'
            : 'Suyu kaynatın, yaklaşık $wait saniye bekletin',
      ),
      subtitle: r.temperatureC == null
          ? null
          : Text('Hedef yaklaşık ${formatNumber(r.temperatureC!)} °C'),
    );
  }

  /// Öğütücü, terazi ve kettle ilk kullanıldığında sorulur (KHV-HMI-016).
  List<Widget> _equipmentQuestions(BrewMethod m, EquipmentProfile eq) {
    final ctrl = ref.read(settingsProvider.notifier);
    Future<void> set(EquipmentProfile Function(EquipmentProfile) f) =>
        ctrl.change((s) => s.copyWith(equipment: f(s.equipment)));
    return [
      if (eq.hasScale == null)
        _Question(
          title: 'Teraziniz var mı?',
          options: const ['Var', 'Yok'],
          onSelected: (i) => set((e) => e.copyWith(hasScale: i == 0)),
        ),
      if (eq.grinder == null && m != BrewMethod.turkish)
        _Question(
          title: 'Öğütücünüz hangisi?',
          options: [for (final g in GrinderType.values) grinderName(g)],
          onSelected: (i) =>
              set((e) => e.copyWith(grinder: GrinderType.values[i])),
        ),
      if (eq.kettle == null &&
          m != BrewMethod.turkish &&
          m != BrewMethod.coldBrew &&
          m != BrewMethod.dripMachine &&
          m != BrewMethod.espresso)
        _Question(
          title: 'Kettle tipiniz?',
          options: [for (final k in KettleType.values) kettleName(k)],
          onSelected: (i) =>
              set((e) => e.copyWith(kettle: KettleType.values[i])),
        ),
    ];
  }

  Future<String?> _askName(String initial) {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tarif adı'),
        content: TextField(controller: c, autofocus: true, maxLength: 80),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  /// Tarifi görsel kart ve bağlantıyla paylaşır (KHV-FR-SOC-001..003).
  Future<void> _share(Recipe r) => showShareSheet(
    context,
    recipe: r,
    onShare: (png, link) => ref
        .read(sharerProvider)
        .shareFile(
          png,
          name: 'ev-kahvesi-tarif.png',
          mimeType: 'image/png',
          text: '${r.name}\n$link',
        ),
  );

  /// Tarifi kopyalayıp kendi tarifi olarak kaydeder (KHV-FR-RCP-006).
  Future<void> _saveAsMine(Recipe r) async {
    final name = await _askName('${r.name} (benim)');
    if (name == null || name.isEmpty) return;
    final copy = r.copyWith(
      id: ref.read(idProvider)(),
      version: 1,
      sourceRecipeId: r.sourceRecipeId ?? r.id,
      name: name,
      owner: RecipeOwner.user,
      favorite: false,
    );
    await ref.read(databaseProvider).saveUserRecipe(copy);
    if (!mounted) return;
    setState(() => _work = null);
    context.pushReplacement('/recipe/${copy.id}');
  }

  Future<void> _saveEdits(Recipe r) async {
    await ref
        .read(databaseProvider)
        .saveUserRecipe(r.copyWith(version: r.version + 1));
    setState(() => _work = null);
  }

  /// Yalnız adı değiştirir; kaydedilmemiş miktar düzenlemesi yazılmaz, yeni
  /// ad düzenlenen kopyaya da işlenir (KB-019, KHV-FR-RCP-006).
  Future<void> _rename(Recipe base) async {
    final name = await _askName(base.name);
    if (name == null || name.isEmpty) return;
    await ref.read(databaseProvider).saveUserRecipe(base.copyWith(name: name));
    if (mounted && _work != null) {
      setState(() => _work = _work!.copyWith(name: name));
    }
  }

  /// Silme; demleme kayıtları korunur (KHV-FR-RCP-014).
  Future<void> _delete(Recipe r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Tarif silinsin mi?'),
        content: const Text(
          'Bu tarifle yaptığınız demleme kayıtları günlükte kalır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(databaseProvider).deleteUserRecipe(r.id);
    if (mounted) context.pop();
  }
}

class _MissingCard extends StatelessWidget {
  const _MissingCard({required this.missing});

  final Set<MissingEquipment> missing;

  @override
  Widget build(BuildContext context) {
    String text(MissingEquipment m) => switch (m) {
      MissingEquipment.brewer => 'Bu demleme aracı profilinizde yok',
      MissingEquipment.scale => 'Bu yöntem için terazi gerekir',
      MissingEquipment.grinder => 'Bu yöntem için burr grinder gerekir',
      MissingEquipment.gooseneckKettle =>
        'Gooseneck kettle önerilir; standart kettle akışı kontrol edemez',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 8),
                Text('Eksik ekipman'),
              ],
            ),
            for (final m in missing) Text('• ${text(m)}'),
          ],
        ),
      ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({
    required this.title,
    required this.options,
    required this.onSelected,
  });

  final String title;
  final List<String> options;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, o) in options.indexed)
                OutlinedButton(onPressed: () => onSelected(i), child: Text(o)),
            ],
          ),
        ],
      ),
    ),
  );
}
