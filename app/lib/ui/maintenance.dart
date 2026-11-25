import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../state/maintenance_state.dart';
import '../state/providers.dart';
import 'common.dart';

final _day = DateFormat('d MMMM y', 'tr_TR');

/// Bakım hatırlatıcıları (KHV-FR-ENG-001, ENG-002, ENG-009).
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(maintenanceProvider).value ?? const [];
    final now = ref.watch(clockProvider)();
    final templates = {
      for (final t
          in ref.watch(contentProvider).value?.maintenance ??
              const <MaintenanceTemplate>[])
        t.id: t,
    };
    final ctrl = ref.read(maintenanceProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Bakım')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCustom(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Bakım ekle'),
      ),
      body: tasks.isEmpty
          ? const EmptyState(
              icon: Icons.build_outlined,
              title: 'Bakım hatırlatıcısı yok',
              message:
                  'Ekipman profilinize espresso makinesi, filtre makinesi veya '
                  'burr grinder eklerseniz bakım takvimini otomatik '
                  'oluştururuz. Katalogda olmayan ekipman için elle '
                  'ekleyebilirsiniz.',
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                for (final t in tasks)
                  Card(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                t.isDue(now)
                                    ? Icons.notification_important_outlined
                                    : Icons.build_outlined,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                              Switch(
                                value: t.enabled,
                                onChanged: (v) =>
                                    ctrl.save(t.copyWith(enabled: v)),
                              ),
                            ],
                          ),
                          if (templates[t.templateId]?.description case final d?
                              when d.isNotEmpty)
                            Text(d),
                          const SizedBox(height: 4),
                          Text(
                            t.isDue(now)
                                ? 'Bakım zamanı geldi'
                                : 'Sonraki: ${_day.format(t.dueAt)}',
                          ),
                          if (t.lastDoneAt != null)
                            Text('Son: ${_day.format(t.lastDoneAt!)}'),
                          NumberStepper(
                            label: 'Aralık',
                            value: t.intervalDays.toDouble(),
                            unit: 'gün',
                            min: 1,
                            max: 365,
                            decimals: 0,
                            showSlider: false,
                            onChanged: (v) =>
                                ctrl.save(t.copyWith(intervalDays: v.round())),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton.tonal(
                                onPressed: () => ctrl.markDone(t),
                                child: const Text('Bugün yaptım'),
                              ),
                              if (t.templateId == null)
                                TextButton(
                                  onPressed: () => ctrl.remove(t),
                                  child: const Text('Kaldır'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _addCustom(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    var days = 30.0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          title: const Text('Bakım ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Ne yapılacak? (ör. Kireç çözme)',
                ),
              ),
              NumberStepper(
                label: 'Aralık',
                value: days,
                unit: 'gün',
                min: 1,
                max: 365,
                decimals: 0,
                showSlider: false,
                onChanged: (v) => setState(() => days = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty) {
      await ref
          .read(maintenanceProvider.notifier)
          .addCustom(title.text.trim(), days.round());
    }
  }
}
