import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../state/brew_state.dart';
import '../state/providers.dart';
import '../state/settings.dart';
import 'common.dart';
import 'labels.dart';

class _Flag {
  bool done = false;
}

/// Uygulama oturumu başına bir kez aktif demleme kontrolü.
final _resumeCheckProvider = Provider((ref) => _Flag());

/// Ana ekran: favoriler, ekipmana uygun tarifler, arama, aktif uzun
/// demlemeler (UC-01, UC-07, KHV-FR-RCP-011, RCP-012, BRW-010).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Kesinti sonrası aktif demlemeye doğrudan dön (KHV-HMI-023).
    final flag = ref.read(_resumeCheckProvider);
    if (!flag.done) {
      flag.done = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final active = await loadActiveBrew(ref);
        if (active != null && mounted) context.push('/brew');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final recipes = ref.watch(allRecipesProvider);
    final longBrews = ref.watch(longBrewsProvider).value ?? const [];
    final owned = settings.equipment.brewers;
    final filtered = [
      for (final r in recipes)
        if (matchesQuery(_query, [r.name, methodName(r.method)])) r,
    ];
    final favorites = filtered.where((r) => r.favorite).toList();
    final mine = filtered
        .where((r) => !r.favorite && owned.contains(r.method))
        .toList();
    final others = filtered
        .where((r) => !r.favorite && !owned.contains(r.method))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demle'),
        actions: [
          IconButton(
            tooltip: 'Hesaplayıcı',
            icon: const Icon(Icons.calculate_outlined),
            onPressed: () => context.push('/calculator'),
          ),
          IconButton(
            tooltip: 'Yardım ve sözlük',
            icon: const Icon(Icons.help_outline),
            onPressed: () => context.push('/help'),
          ),
        ],
      ),
      body: ContentGate(
        builder: (context, content) => ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SearchBar(
                hintText: 'Tarif veya yöntem ara',
                leading: const Icon(Icons.search),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            for (final b in longBrews) _LongBrewCard(brew: b),
            if (favorites.isNotEmpty) ...[
              const SectionTitle('Favoriler'),
              for (final r in favorites) _RecipeTile(r, quickStart: true),
            ],
            if (mine.isNotEmpty) ...[
              const SectionTitle('Ekipmanınızla'),
              for (final r in mine) _RecipeTile(r),
            ],
            if (others.isNotEmpty) ...[
              SectionTitle(owned.isEmpty ? 'Tüm yöntemler' : 'Diğer yöntemler'),
              for (final r in others) _RecipeTile(r),
            ],
            if (filtered.isEmpty)
              const EmptyState(
                icon: Icons.search_off,
                title: 'Sonuç yok',
                message: 'Farklı bir kelimeyle aramayı deneyin.',
              ),
          ],
        ),
      ),
    );
  }
}

class _RecipeTile extends ConsumerWidget {
  const _RecipeTile(this.recipe, {this.quickStart = false});

  final Recipe recipe;
  final bool quickStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = recipe;
    final subtitle = r.method.isCupBased
        ? '${r.cups ?? 1} fincan · ${formatNumber(r.coffeeG)} g kahve'
        : r.method.isEspresso
        ? '${formatNumber(r.coffeeG)} g → ${formatNumber(r.waterG)} g'
        : '${formatNumber(r.coffeeG)} g · ${formatNumber(r.waterG)} g su · '
              '${formatRatio(r.ratio)}';
    return ListTile(
      leading: Icon(methodIcon(r.method)),
      title: Text(r.name),
      subtitle: Text(
        '${methodName(r.method)}${r.owner == RecipeOwner.user ? ' · Benim' : ''}'
        '\n$subtitle',
      ),
      isThreeLine: true,
      onTap: () => context.push('/recipe/${r.id}'),
      // Tek dokunuşla favori tarifi başlat (UC-07).
      trailing: quickStart
          ? IconButton.filled(
              tooltip: '${r.name} hemen başlat',
              icon: const Icon(Icons.play_arrow),
              onPressed: () => context.push('/brew?recipe=${r.id}&quick=1'),
            )
          : const Icon(Icons.chevron_right),
    );
  }
}

class _LongBrewCard extends ConsumerWidget {
  const _LongBrewCard({required this.brew});

  final LongBrew brew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final done = !now.isBefore(brew.endsAt);
    final fmt = DateFormat('d MMM HH:mm', 'tr_TR');
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ListTile(
        leading: Icon(methodIcon(brew.recipe.method)),
        title: Text(brew.recipe.name),
        subtitle: Text(done ? 'Hazır' : 'Bitiş: ${fmt.format(brew.endsAt)}'),
        trailing: FilledButton.tonal(
          onPressed: () =>
              context.push('/brew?long=${Uri.encodeComponent(brew.id)}'),
          child: Text(done ? 'Tamamla' : 'Aç'),
        ),
      ),
    );
  }
}
