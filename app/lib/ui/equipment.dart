import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../state/providers.dart';
import '../state/settings.dart';
import 'common.dart';
import 'labels.dart';

/// Ekipman rehberi (UC-05, KHV-FR-EQP-001 - EQP-006). Marka ve model
/// önerilmez; yalnız neye bakılacağı anlatılır (ürün sahibi kararı, KB-017).
/// Fiyat ve satın alma bağlantısı gösterilmez (KHV-FR-EQP-006).
class EquipmentScreen extends ConsumerStatefulWidget {
  const EquipmentScreen({super.key});

  @override
  ConsumerState<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends ConsumerState<EquipmentScreen> {
  BrewMethod? _method;

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
              for (final g in guides) _GuideCard(guide: g),
            ],
          );
        },
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.guide});

  final EquipmentGuide guide;

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
