import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../state/providers.dart';
import '../state/settings.dart';
import 'labels.dart';

/// İlk açılış (UC-01). Yalnız demleme aracı sorulur; öğütücü, terazi ve
/// kettle ilgili özellik ilk kullanıldığında istenir (KHV-HMI-016).
/// Hesap ve izin istenmez (KHV-HMI-038); adım atlanabilir (KHV-FR-ONB-005).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _selected = <BrewMethod>{};

  Future<void> _finish({required bool skipped}) async {
    final controller = ref.read(settingsProvider.notifier);
    await controller.change(
      (s) => s.copyWith(
        onboardingDone: true,
        onboardingSkipped: skipped,
        equipment: s.equipment.copyWith(brewers: {..._selected}),
      ),
    );
    if (!mounted) return;
    if (!skipped && _selected.isNotEmpty) {
      // İlk rehberli demlemeye en kısa yoldan (KHV-HMI-038).
      final content = await ref.read(contentProvider.future);
      if (!mounted) return;
      final first = content.recipes.firstWhere(
        (r) => _selected.contains(r.method),
      );
      context.go('/recipe/${first.id}');
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              sliver: SliverList.list(
                children: [
                  Text('Ev Kahvesi', style: t.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Elinizdeki ekipmanla adım adım demleyin, tadına göre bir '
                    'sonraki fincanı birlikte düzeltelim.',
                    style: t.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Text('Hangi demleme araçlarınız var?', style: t.titleMedium),
                  const SizedBox(height: 4),
                  const Text('Birden fazla seçebilirsiniz.'),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  childAspectRatio: 1.25,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: BrewMethod.values.length,
                itemBuilder: (context, i) {
                  final m = BrewMethod.values[i];
                  final on = _selected.contains(m);
                  return _MethodTile(
                    method: m,
                    selected: on,
                    onTap: () => setState(
                      () => on ? _selected.remove(m) : _selected.add(m),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              TextButton(
                onPressed: () => _finish(skipped: true),
                child: const Text('Şimdilik atla'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _selected.isEmpty
                    ? null
                    : () => _finish(skipped: false),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Devam'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final BrewMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label: methodName(method),
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: selected ? scheme.primaryContainer : null,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  methodIcon(method),
                  size: 36,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  methodName(method),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (selected) const Icon(Icons.check, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
