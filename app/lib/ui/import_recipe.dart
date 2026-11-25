import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../state/providers.dart';
import 'common.dart';
import 'labels.dart';

/// Paylaşım bağlantısından gelen tarifin önizlemesi ve içe aktarılması
/// (KHV-FR-SOC-003, SOC-004, SOC-009).
class ImportRecipeScreen extends ConsumerStatefulWidget {
  const ImportRecipeScreen({super.key, required this.payload});

  final String payload;

  @override
  ConsumerState<ImportRecipeScreen> createState() => _ImportRecipeScreenState();
}

class _ImportRecipeScreenState extends ConsumerState<ImportRecipeScreen> {
  late final ({Recipe? recipe, List<String> errors}) _parsed = _parse();

  ({Recipe? recipe, List<String> errors}) _parse() {
    try {
      return (
        recipe: decodeSharedRecipe(
          widget.payload,
          newId: ref.read(idProvider)(),
        ),
        errors: const <String>[],
      );
    } on RecipeValidationException catch (e) {
      return (recipe: null, errors: e.reasons);
    }
  }

  Future<void> _save(Recipe r) async {
    await ref.read(databaseProvider).saveUserRecipe(r);
    await ref.read(databaseProvider).logEvent('import_recipe', {
      'source': r.sourceRecipeId,
    });
    if (mounted) context.go('/recipe/${r.id}');
  }

  @override
  Widget build(BuildContext context) {
    final r = _parsed.recipe;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Paylaşılan tarif')),
      body: r == null
          ? EmptyState(
              icon: Icons.link_off,
              title: 'Tarif içe aktarılamadı',
              message: _parsed.errors.join('\n'),
              actionLabel: 'Ana ekrana dön',
              onAction: () => context.go('/'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(r.name, style: t.headlineSmall),
                Text(methodName(r.method)),
                const SectionTitle('Parametreler'),
                Text('Kahve: ${formatNumber(r.coffeeG)} g'),
                Text(
                  '${r.method.isEspresso ? 'Çıktı' : 'Su'}: '
                  '${formatNumber(r.waterG)} g (${formatRatio(r.ratio)})',
                ),
                Text('Öğütme: ${r.grind.label}'),
                if (r.temperatureC != null)
                  Text('Sıcaklık: ${formatNumber(r.temperatureC!)} °C'),
                Text('${r.steps.length} adım'),
                const SizedBox(height: 12),
                const Text(
                  'Tarif tariflerinize kopya olarak eklenir; kaynağı '
                  'korunur.',
                ),
              ],
            ),
      bottomNavigationBar: r == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: () => _save(r),
                  child: const Text('Tariflerime ekle'),
                ),
              ),
            ),
    );
  }
}
