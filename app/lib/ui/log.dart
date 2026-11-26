import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../data/database.dart';
import '../services/platform.dart';
import '../state/providers.dart';
import '../state/settings.dart';
import 'common.dart';
import 'labels.dart';
import 'share_card.dart';
import 'scene.dart';

final _date = DateFormat('d MMM y, HH:mm', 'tr_TR');
final _day = DateFormat('d MMM y', 'tr_TR');

/// Demleme günlüğü ve çekirdekler (UC-06, KHV-FR-LOG-001 - LOG-009).
class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Günlük'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Demlemeler'),
            Tab(text: 'Çekirdekler'),
          ],
        ),
      ),
      body: const TabBarView(children: [_BrewList(), _BeanList()]),
    ),
  );
}

class _BrewList extends ConsumerStatefulWidget {
  const _BrewList();

  @override
  ConsumerState<_BrewList> createState() => _BrewListState();
}

class _BrewListState extends ConsumerState<_BrewList> {
  BrewMethod? _method;
  String? _beanId;
  int _minScore = 0;

  @override
  Widget build(BuildContext context) {
    final brews = ref.watch(brewsProvider).value ?? const <Brew>[];
    final beans = ref.watch(beansProvider).value ?? const <Bean>[];
    final beanNames = {for (final b in beans) b.id: b.name};
    final filtered = [
      for (final b in brews)
        if ((_method == null || b.methodId == _method!.id) &&
            (_beanId == null || b.beanId == _beanId) &&
            (b.score ?? 0) >= _minScore)
          b,
    ];
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'manual',
        onPressed: () => context.push('/log/new'),
        icon: const Icon(Icons.edit_note),
        label: const Text('Elle kaydet'),
      ),
      body: brews.isEmpty
          ? EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'Henüz demleme yok',
              message:
                  'Rehberle yaptığınız her demleme parametreleri ve tadıyla '
                  'burada saklanır.',
              actionLabel: 'İlk demlemeyi başlat',
              onAction: () => context.go('/'),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                // Filtreler (KHV-FR-LOG-002).
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      _FilterMenu<BrewMethod?>(
                        label: _method == null
                            ? 'Yöntem'
                            : methodName(_method!),
                        active: _method != null,
                        items: {
                          null: 'Tümü',
                          for (final m in BrewMethod.values) m: methodName(m),
                        },
                        onSelected: (v) => setState(() => _method = v),
                      ),
                      const SizedBox(width: 8),
                      _FilterMenu<String?>(
                        label: _beanId == null
                            ? 'Çekirdek'
                            : beanNames[_beanId] ?? 'Çekirdek',
                        active: _beanId != null,
                        items: {null: 'Tümü', ...beanNames},
                        onSelected: (v) => setState(() => _beanId = v),
                      ),
                      const SizedBox(width: 8),
                      _FilterMenu<int>(
                        label: _minScore == 0 ? 'Puan' : '$_minScore+ puan',
                        active: _minScore > 0,
                        items: {
                          0: 'Tümü',
                          for (var i = 1; i <= 5; i++) i: '$i ve üzeri',
                        },
                        onSelected: (v) => setState(() => _minScore = v),
                      ),
                    ],
                  ),
                ),
                if (filtered.isEmpty)
                  const EmptyState(
                    icon: Icons.filter_alt_off,
                    title: 'Filtreye uyan kayıt yok',
                    message: 'Filtreleri değiştirmeyi deneyin.',
                  ),
                for (final b in filtered)
                  ListTile(
                    leading: MethodGlyph(BrewMethod.parse(b.methodId)),
                    title: Text(brewRecipe(b).name),
                    subtitle: Text(
                      [
                        _date.format(b.brewedAt),
                        if (b.beanId != null && beanNames[b.beanId] != null)
                          beanNames[b.beanId]!,
                      ].join(' · '),
                    ),
                    trailing: b.score == null
                        ? const Text('Değerlendirilmedi')
                        : Text('${b.score}/5'),
                    onTap: () => context.push('/log/${b.id}'),
                  ),
              ],
            ),
    );
  }
}

class _FilterMenu<T> extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.items,
    required this.onSelected,
    required this.active,
  });

  final String label;
  final Map<T, String> items;
  final ValueChanged<T> onSelected;
  final bool active;

  @override
  Widget build(BuildContext context) => MenuAnchor(
    menuChildren: [
      for (final e in items.entries)
        MenuItemButton(
          onPressed: () => onSelected(e.key),
          child: Text(e.value),
        ),
    ],
    builder: (context, controller, _) => FilterChip(
      label: Text(label),
      selected: active,
      onSelected: (_) =>
          controller.isOpen ? controller.close() : controller.open(),
    ),
  );
}

/// Demleme kaydı ayrıntısı (KHV-FR-LOG-001, LOG-003, LOG-007).
class BrewDetailScreen extends ConsumerWidget {
  const BrewDetailScreen({super.key, required this.brewId});

  final String brewId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brews = ref.watch(brewsProvider).value ?? const <Brew>[];
    final b = brews.where((x) => x.id == brewId).firstOrNull;
    if (b == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.menu_book_outlined,
          title: 'Kayıt bulunamadı',
          message: 'Bu kayıt silinmiş olabilir.',
        ),
      );
    }
    final r = brewRecipe(b);
    final a = brewAssessment(b);
    final c = brewCorrection(b);
    final beans = ref.watch(beansProvider).value ?? const <Bean>[];
    final bean = beans.where((x) => x.id == b.beanId).firstOrNull;
    final t = Theme.of(context).textTheme;

    Future<void> delete() async {
      final db = ref.read(databaseProvider);
      await db.deleteBrew(b.id);
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      // Silme 5 sn içinde geri alınabilir (KHV-FR-LOG-007).
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: const Text('Kayıt silindi'),
          action: SnackBarAction(
            label: 'Geri al',
            onPressed: () => db.restoreBrew(b),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(r.name),
        actions: [
          IconButton(
            tooltip: 'Paylaş',
            icon: const Icon(Icons.ios_share),
            onPressed: () => showShareSheet(
              context,
              recipe: r,
              beanName: bean?.name,
              score: a?.score,
              actualTimeS: b.actualTimeS,
              onShare: (png, link) => ref
                  .read(sharerProvider)
                  .shareFile(
                    png,
                    name: 'ev-kahvesi-demleme.png',
                    mimeType: 'image/png',
                    text: '${r.name}\n$link',
                  ),
            ),
          ),
          IconButton(
            tooltip: 'Notu düzenle',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editNote(context, ref, b),
          ),
          IconButton(
            tooltip: 'Kaydı sil',
            icon: const Icon(Icons.delete_outline),
            onPressed: delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_date.format(b.brewedAt), style: t.titleMedium),
          Text(methodName(r.method)),
          const SectionTitle('Parametreler'),
          _row('Kahve', '${formatNumber(r.coffeeG)} g'),
          _row(
            r.method.isEspresso ? 'Çıktı' : 'Su',
            '${formatNumber(r.waterG)} g',
          ),
          _row('Oran', formatRatio(r.ratio)),
          _row(
            'Öğütme',
            r.grind.label +
                (r.grind.offset != 0
                    ? ' (${r.grind.offset > 0 ? '+' : ''}${r.grind.offset} kademe)'
                    : ''),
          ),
          if (r.temperatureC != null)
            _row('Sıcaklık', '${formatNumber(r.temperatureC!)} °C'),
          if (b.actualTimeS != null)
            _row('Gerçekleşen süre', formatDuration(b.actualTimeS!)),
          if (b.actualCoffeeG != null)
            _row('Tartılan kahve', '${formatNumber(b.actualCoffeeG!)} g'),
          if (b.actualWaterG != null)
            _row(
              r.method.isEspresso ? 'Ölçülen çıktı' : 'Ölçülen su',
              '${formatNumber(b.actualWaterG!)} g',
            ),
          if (bean != null) _row('Çekirdek', bean.name),
          if (b.manual) _row('Kayıt', 'Elle girildi'),
          const SectionTitle('Tat'),
          if (a == null)
            FilledButton.tonal(
              onPressed: () => context.push('/taste/${b.id}'),
              child: const Text('Tadı değerlendir'),
            )
          else ...[
            _row('Puan', '${a.score}/5'),
            Wrap(
              spacing: 8,
              children: [
                for (final n in a.notes)
                  Chip(
                    avatar: Icon(tasteNoteIcon(n), size: 18),
                    label: Text(tasteNoteName(n)),
                  ),
                for (final o in a.observations)
                  Chip(label: Text(observationName(o))),
              ],
            ),
          ],
          if (c != null) ...[
            const SectionTitle('Öneri'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                b.correctionAccepted
                    ? Icons.check_circle
                    : Icons.lightbulb_outline,
              ),
              title: Text(c.text),
              subtitle: Text(
                '${b.correctionAccepted ? 'Uygulandı' : 'Uygulanmadı'} · ${c.reason}',
              ),
            ),
          ],
          if (b.notes.isNotEmpty) ...[const SectionTitle('Not'), Text(b.notes)],
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            // Aynı parametrelerle yeni demleme (KHV-FR-LOG-003).
            onPressed: () => context.push('/brew', extra: r),
            icon: const Icon(Icons.replay),
            label: const Text('Aynı parametrelerle demle'),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(k)),
        Flexible(child: Text(v, textAlign: TextAlign.end)),
      ],
    ),
  );

  Future<void> _editNote(BuildContext context, WidgetRef ref, Brew b) async {
    final c = TextEditingController(text: b.notes);
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Not'),
        content: TextField(controller: c, maxLines: 4, autofocus: true),
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
    if (text == null) return;
    await ref
        .read(databaseProvider)
        .updateBrew(b.id, BrewsCompanion(notes: Value(text)));
  }
}

/// Rehber mod olmadan elle demleme kaydı (KHV-FR-LOG-006).
class ManualBrewScreen extends ConsumerStatefulWidget {
  const ManualBrewScreen({super.key});

  @override
  ConsumerState<ManualBrewScreen> createState() => _ManualBrewScreenState();
}

class _ManualBrewScreenState extends ConsumerState<ManualBrewScreen> {
  BrewMethod _method = BrewMethod.v60;
  double _coffee = 15;
  double _water = 250;
  double _timeS = 180;
  String? _beanId;

  Future<void> _save() async {
    final content = await ref.read(contentProvider.future);
    final base = content.recipes.firstWhere((r) => r.method == _method);
    final recipe = scaleRecipe(
      base,
      waterG: _water,
    ).copyWith(coffeeG: _coffee, name: '${methodName(_method)} (elle)');
    final id = ref.read(idProvider)();
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    await ref
        .read(databaseProvider)
        .insertBrew(
          BrewsCompanion.insert(
            id: id,
            brewedAt: ref.read(clockProvider)(),
            recipeId: base.id,
            lineageId: base.id,
            methodId: _method.id,
            recipeJson: jsonEncode(recipe.toJson()),
            beanId: Value(_beanId),
            equipmentJson: Value(jsonEncode(settings.equipment.toJson())),
            actualTimeS: Value(_timeS.round()),
            manual: const Value(true),
          ),
          doseG: _coffee,
        );
    if (mounted) context.pushReplacement('/taste/$id');
  }

  @override
  Widget build(BuildContext context) {
    final beans = (ref.watch(beansProvider).value ?? const <Bean>[])
        .where((b) => !b.archived)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Elle kaydet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<BrewMethod>(
            isExpanded: true,
            initialValue: _method,
            decoration: const InputDecoration(
              labelText: 'Yöntem',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final m in BrewMethod.values)
                DropdownMenuItem(value: m, child: Text(methodName(m))),
            ],
            onChanged: (m) => setState(() => _method = m ?? _method),
          ),
          NumberStepper(
            label: 'Kahve',
            value: _coffee,
            unit: 'g',
            step: 0.5,
            min: 1,
            max: 150,
            onChanged: (v) => setState(() => _coffee = v),
          ),
          NumberStepper(
            label: _method.isEspresso ? 'Çıktı' : 'Su',
            value: _water,
            unit: 'g',
            step: _method.isEspresso ? 1 : 10,
            min: 10,
            max: 2000,
            decimals: 0,
            onChanged: (v) => setState(() => _water = v),
          ),
          NumberStepper(
            label: 'Süre',
            value: _timeS,
            unit: 'sn',
            step: 5,
            min: 5,
            max: 3600,
            decimals: 0,
            onChanged: (v) => setState(() => _timeS = v),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: _beanId,
            decoration: const InputDecoration(
              labelText: 'Çekirdek (isteğe bağlı)',
              border: OutlineInputBorder(),
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
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: _save,
            child: const Text('Kaydet ve tadı değerlendir'),
          ),
        ),
      ),
    );
  }
}

class _BeanList extends ConsumerWidget {
  const _BeanList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beans = ref.watch(beansProvider).value ?? const <Bean>[];
    final brews = ref.watch(brewsProvider).value ?? const <Brew>[];
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final today = ref.watch(clockProvider)();
    final avg = averageDose([for (final b in brews) brewRecipe(b).coffeeG]);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'bean',
        onPressed: () => context.push('/beans/new'),
        icon: const Icon(Icons.add),
        label: const Text('Çekirdek ekle'),
      ),
      body: beans.isEmpty
          ? EmptyState(
              icon: Icons.grain,
              title: 'Kayıtlı çekirdek yok',
              message:
                  'Çekirdek eklerseniz kavurma tarihinden geçen günü ve kalan '
                  'stoğu takip ederiz.',
              actionLabel: 'Çekirdek ekle',
              onAction: () => context.push('/beans/new'),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                for (final b in beans)
                  ListTile(
                    leading: Icon(
                      b.archived ? Icons.inventory_2_outlined : Icons.grain,
                    ),
                    title: Text(b.name + (b.archived ? ' (arşiv)' : '')),
                    subtitle: Text(
                      [
                        if (b.roaster.isNotEmpty) b.roaster,
                        if (b.roastDate != null)
                          'Kavrulalı ${daysSinceRoast(b.roastDate!, today)} gün'
                              '${isPastFreshness(b.roastDate!, today, thresholdDays: settings.freshnessDays) ? ' · tazeliğini yitiriyor' : ''}',
                        if (b.remainingG != null)
                          'Kalan ${formatNumber(b.remainingG!)} g'
                              '${isLowStock(b.remainingG!, avg) ? ' · azaldı' : ''}',
                      ].join(' · '),
                    ),
                    onTap: () => context.push('/beans/${b.id}'),
                  ),
              ],
            ),
    );
  }
}

/// Çekirdek ekleme/düzenleme (KHV-FR-LOG-004, LOG-008, LOG-009).
class BeanEditScreen extends ConsumerStatefulWidget {
  const BeanEditScreen({super.key, this.beanId});

  final String? beanId;

  @override
  ConsumerState<BeanEditScreen> createState() => _BeanEditScreenState();
}

class _BeanEditScreenState extends ConsumerState<BeanEditScreen> {
  final _name = TextEditingController();
  final _roaster = TextEditingController();
  final _origin = TextEditingController();
  String _roastLevel = 'medium';
  DateTime? _roastDate;
  double? _packageG = 250;
  double? _remainingG;
  bool _archived = false;
  bool _loaded = false;
  DateTime? _createdAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.beanId != null) {
      final b = await ref.read(databaseProvider).beanById(widget.beanId!);
      if (b != null) {
        _name.text = b.name;
        _roaster.text = b.roaster;
        _origin.text = b.origin;
        _roastLevel = b.roastLevel;
        _roastDate = b.roastDate;
        _packageG = b.packageG;
        _remainingG = b.remainingG;
        _archived = b.archived;
        _createdAt = b.createdAt;
      }
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _name.dispose();
    _roaster.dispose();
    _origin.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Çekirdeğe bir ad verin.')));
      return;
    }
    await ref
        .read(databaseProvider)
        .saveBean(
          BeansCompanion.insert(
            id: widget.beanId ?? ref.read(idProvider)(),
            name: _name.text.trim(),
            roaster: Value(_roaster.text.trim()),
            origin: Value(_origin.text.trim()),
            roastLevel: Value(_roastLevel),
            roastDate: Value(_roastDate),
            packageG: Value(_packageG),
            remainingG: Value(
              widget.beanId == null ? _packageG : (_remainingG ?? _packageG),
            ),
            archived: Value(_archived),
            createdAt: _createdAt ?? ref.read(clockProvider)(),
          ),
        );
    if (mounted) context.pop();
  }

  /// Silme geri alınamaz; önce onay istenir (KB-022, KHV-HMI-009).
  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Çekirdek silinsin mi?'),
        content: const Text(
          'Bu işlem geri alınamaz. Bitmiş çekirdeği arşivlemek de '
          'yeni demlemede listelenmemesini sağlar.',
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
    if (confirmed != true || !mounted) return;
    final ok = await ref.read(databaseProvider).deleteBean(widget.beanId!);
    if (!mounted) return;
    if (ok) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bu çekirdekle demleme kaydı var; silinemez, arşivleyebilirsiniz.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final today = ref.watch(clockProvider)();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.beanId == null ? 'Çekirdek ekle' : 'Çekirdek'),
        actions: [
          if (widget.beanId != null)
            IconButton(
              tooltip: 'Sil',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Ad',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _roaster,
            decoration: const InputDecoration(
              labelText: 'Kavurmacı',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _origin,
            decoration: const InputDecoration(
              labelText: 'Menşe',
              border: OutlineInputBorder(),
            ),
          ),
          const SectionTitle('Kavurma derecesi'),
          SegmentedButton<String>(
            segments: [
              for (final l in const ['light', 'medium', 'dark'])
                ButtonSegment(value: l, label: Text(roastLevelName(l))),
            ],
            selected: {_roastLevel},
            onSelectionChanged: (s) => setState(() => _roastLevel = s.first),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: const Text('Kavurma tarihi'),
            subtitle: Text(
              _roastDate == null
                  ? 'Seçilmedi'
                  : '${_day.format(_roastDate!)} · ${daysSinceRoast(_roastDate!, today)} gün önce',
            ),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                firstDate: DateTime(today.year - 2),
                lastDate: today,
                initialDate: _roastDate ?? today,
              );
              if (d != null) setState(() => _roastDate = d);
            },
          ),
          NumberStepper(
            label: 'Paket',
            value: _packageG ?? 250,
            unit: 'g',
            step: 50,
            min: 50,
            max: 2000,
            decimals: 0,
            showSlider: false,
            onChanged: (v) => setState(() => _packageG = v),
          ),
          if (widget.beanId != null && _remainingG != null)
            NumberStepper(
              label: 'Kalan',
              value: _remainingG!,
              unit: 'g',
              step: 5,
              min: 0,
              max: 2000,
              decimals: 0,
              showSlider: false,
              onChanged: (v) => setState(() => _remainingG = v),
            ),
          if (widget.beanId != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bitti, arşivle'),
              subtitle: const Text(
                'Arşivlenen çekirdek yeni demlemede listelenmez.',
              ),
              value: _archived,
              onChanged: (v) => setState(() => _archived = v),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: _save,
            child: const Text('Kaydet'),
          ),
        ),
      ),
    );
  }
}
