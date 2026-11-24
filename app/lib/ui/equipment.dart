import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../state/providers.dart';
import '../state/settings.dart';
import 'common.dart';
import 'labels.dart';

final _verified = DateFormat('MMMM y', 'tr_TR');

/// Ekipman rehberi (UC-05, KHV-FR-EQP-001 - EQP-006). Fiyat ve satın alma
/// bağlantısı gösterilmez (KHV-FR-EQP-006).
class EquipmentScreen extends ConsumerStatefulWidget {
  const EquipmentScreen({super.key});

  @override
  ConsumerState<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends ConsumerState<EquipmentScreen> {
  BrewMethod? _method;
  Budget? _budget;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final beans = ref.watch(beansProvider).value ?? const [];
    final usesFresh = beans.any((b) => b.roastDate != null && !b.archived);
    final next = nextPurchase(settings.equipment, usesFreshBeans: usesFresh);
    return Scaffold(
      appBar: AppBar(title: const Text('Ekipman')),
      body: ContentGate(
        builder: (context, content) {
          final guides = [
            for (final g in content.guides)
              if (_method == null ||
                  g.methods.isEmpty ||
                  g.methods.contains(_method))
                g,
          ];
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (next != null)
                Card(
                  margin: const EdgeInsets.all(16),
                  child: ListTile(
                    leading: const Icon(Icons.trending_up),
                    title: const Text('Sıradaki önerimiz'),
                    subtitle: Text(purchaseName(next)),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Tadı en çok iyileştiren yatırım demleme aracı değil, burr '
                  "grinder'dır. Öncelik: taze çekirdek, burr grinder, terazi, "
                  'gooseneck kettle, demleme aracı, su.',
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    for (final m in [null, ...BrewMethod.values])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            m == null ? 'Tüm yöntemler' : methodName(m),
                          ),
                          selected: _method == m,
                          onSelected: (_) => setState(() => _method = m),
                        ),
                      ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    for (final b in [null, ...Budget.values])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            b == null ? 'Tüm bütçeler' : budgetName(b),
                          ),
                          selected: _budget == b,
                          onSelected: (_) => setState(() => _budget = b),
                        ),
                      ),
                  ],
                ),
              ),
              for (final g in guides)
                _GuideCard(
                  guide: g,
                  models: [
                    for (final c in content.catalog)
                      if (c.category == g.id &&
                          (_budget == null || c.budget == _budget) &&
                          (_method == null ||
                              c.methods.isEmpty ||
                              c.methods.contains(_method)))
                        c,
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.guide, required this.models});

  final EquipmentGuide guide;
  final List<CatalogModel> models;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ExpansionTile(
        title: Text(guide.name, style: t.titleMedium),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dikkat edin', style: t.labelLarge),
          for (final l in guide.lookFor) _bullet(Icons.check, l),
          const SizedBox(height: 8),
          Text('Kaçının', style: t.labelLarge),
          for (final a in guide.avoid) _bullet(Icons.block, a),
          if (models.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Örnek modeller', style: t.labelLarge),
            for (final m in models)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(m.displayName),
                subtitle: Text(
                  '${budgetName(m.budget)} bütçe · Son doğrulama '
                  '${_verified.format(m.verifiedAt)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/equipment/model/${m.id}'),
              ),
          ] else if (guide.id == 'turkish')
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Örnek modeller içerik ekibince eklenecek.'),
            ),
        ],
      ),
    );
  }

  Widget _bullet(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

/// Katalog modeli sayfası; editoryal kriterler (KHV-FR-EQP-005).
class ModelScreen extends ConsumerWidget {
  const ModelScreen({super.key, required this.modelId});

  final String modelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentGate(
      builder: (context, content) {
        final m = content.catalog.where((c) => c.id == modelId).firstOrNull;
        if (m == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.devices_other,
              title: 'Model bulunamadı',
              message: 'Bu model katalogdan kaldırılmış olabilir.',
            ),
          );
        }
        final g = content.guides.firstWhere((g) => g.id == m.category);
        final stale = m.isStale(ref.watch(clockProvider)());
        return Scaffold(
          appBar: AppBar(title: Text(m.displayName)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(g.name, style: Theme.of(context).textTheme.titleMedium),
              Text(
                'Son doğrulama: ${_verified.format(m.verifiedAt)}'
                '${stale ? ' (güncelliği gözden geçiriliyor)' : ''}',
              ),
              if (m.methods.isNotEmpty)
                Text('Yöntem: ${m.methods.map(methodName).join(', ')}'),
              if (m.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(m.notes),
              ],
              const SectionTitle('Bu kategoride dikkat edilecekler'),
              for (final l in g.lookFor) Text('• $l'),
              const SectionTitle('Kaçınılacak durumlar'),
              for (final a in g.avoid) Text('• $a'),
              const SizedBox(height: 16),
              const Text(
                'Kullanıcı deneyimleri ikinci sürümde bu sayfaya eklenecek.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );
      },
    );
  }
}
