import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../state/brew_state.dart';
import '../state/providers.dart';
import '../state/settings.dart';
import 'common.dart';
import 'labels.dart';

const appVersion = '0.1.0';

/// Tek ayarlar ekranı (KHV-FR-SET-001 - SET-003, KHV-FR-ONB-003).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider).value ?? const AppSettings();
    final ctrl = ref.read(settingsProvider.notifier);
    final eq = s.equipment;

    Future<void> toggleAlert(AlertChannel c) async {
      final ok = await ctrl.toggleAlert(c);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Uyarıların kaçmaması için en az iki kanal açık kalmalı.',
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SectionTitle('Ekipman profili'),
          ListTile(
            leading: const Icon(Icons.coffee_maker_outlined),
            title: const Text('Demleme araçları'),
            subtitle: Text(
              eq.brewers.isEmpty
                  ? 'Seçilmedi'
                  : eq.brewers.map(methodName).join(', '),
            ),
            onTap: () => context.push('/settings/equipment'),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profil seviyesi'),
            subtitle: Text(
              '${profileName(s.profile)}'
              '${s.profileOverride == null ? ' (otomatik)' : ''}',
            ),
            onTap: () => _pickProfile(context, ref, s),
          ),
          const SectionTitle('Görünüm'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Sistem')),
                ButtonSegment(value: ThemeMode.light, label: Text('Açık')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Koyu')),
              ],
              selected: {s.themeMode},
              onSelectionChanged: (v) =>
                  ctrl.change((x) => x.copyWith(themeMode: v.first)),
            ),
          ),
          const SectionTitle('Demleme uyarıları'),
          SwitchListTile(
            secondary: const Icon(Icons.flash_on_outlined),
            title: const Text('Görsel (ekran rengi)'),
            value: s.alerts.contains(AlertChannel.visual),
            onChanged: (_) => toggleAlert(AlertChannel.visual),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_outlined),
            title: const Text('Ses'),
            value: s.alerts.contains(AlertChannel.sound),
            onChanged: (_) => toggleAlert(AlertChannel.sound),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('Titreşim'),
            value: s.alerts.contains(AlertChannel.vibration),
            onChanged: (_) => toggleAlert(AlertChannel.vibration),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_off_outlined),
            title: const Text('Sessiz modda da sesli uyarı'),
            value: s.soundInSilentMode,
            onChanged: (v) =>
                ctrl.change((x) => x.copyWith(soundInSilentMode: v)),
          ),
          const SectionTitle('Çekirdek'),
          NumberStepperTile(
            label: 'Tazelik uyarısı',
            value: s.freshnessDays.toDouble(),
            unit: 'gün',
            onChanged: (v) =>
                ctrl.change((x) => x.copyWith(freshnessDays: v.round())),
          ),
          const SectionTitle('Gizlilik'),
          // Varsayılan kapalı, eşit görsel ağırlık (KHV-HMI-039).
          SwitchListTile(
            title: const Text('Anonim kullanım ölçümü'),
            subtitle: const Text(
              'Hangi özelliklerin kullanıldığını kimliğiniz olmadan sayar.',
            ),
            value: s.analyticsConsent,
            onChanged: (v) =>
                ctrl.change((x) => x.copyWith(analyticsConsent: v)),
          ),
          SwitchListTile(
            title: const Text('Çökme raporu'),
            subtitle: const Text('Kişisel veri ve serbest metin içermez.'),
            value: s.crashReportConsent,
            onChanged: (v) =>
                ctrl.change((x) => x.copyWith(crashReportConsent: v)),
          ),
          const SectionTitle('Veri'),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined),
            title: const Text('Tüm verimi sil'),
            subtitle: const Text('Günlük, tarifler, çekirdekler ve ayarlar'),
            onTap: () => _wipe(context, ref),
          ),
          const SectionTitle('Hakkında'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Yardım ve sözlük'),
            onTap: () => context.push('/help'),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Kullanım koşulları ve emniyet beyanı'),
            onTap: () => context.push('/legal'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Açık kaynak lisansları'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Ev Kahvesi',
              applicationVersion: appVersion,
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Sürüm'),
            subtitle: Text(appVersion),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProfile(
    BuildContext context,
    WidgetRef ref,
    AppSettings s,
  ) async {
    final ctrl = ref.read(settingsProvider.notifier);
    final picked = await showDialog<Object>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('Profil seviyesi'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, 'auto'),
            child: const Text('Otomatik (ekipmana göre)'),
          ),
          for (final p in UserProfile.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, p),
              child: Text(profileName(p)),
            ),
        ],
      ),
    );
    if (picked == 'auto') {
      await ctrl.change((x) => x.copyWith(clearProfileOverride: true));
    } else if (picked is UserProfile) {
      await ctrl.change((x) => x.copyWith(profileOverride: picked));
    }
  }

  /// Onay ve geri alınamazlık uyarısıyla silme (KHV-FR-SET-003).
  Future<void> _wipe(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Tüm veriler silinsin mi?'),
        content: const Text('Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(c).colorScheme.error,
              foregroundColor: Theme.of(c).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Kalıcı olarak sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(databaseProvider).wipe();
    ref
      ..invalidate(settingsProvider)
      ..invalidate(longBrewsProvider);
    if (context.mounted) context.go('/onboarding');
  }
}

/// Ayarlar listesinde sade sayı girişi.
class NumberStepperTile extends StatelessWidget {
  const NumberStepperTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.onChanged,
  });

  final String label;
  final double value;
  final String unit;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: NumberStepper(
      label: label,
      value: value,
      unit: unit,
      min: 7,
      max: 120,
      decimals: 0,
      showSlider: false,
      onChanged: onChanged,
    ),
  );
}

/// Ekipman profili düzenleme; marka/model katalogdan veya serbest metinle
/// (KHV-FR-ONB-003, ONB-004).
class EquipmentProfileScreen extends ConsumerWidget {
  const EquipmentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider).value ?? const AppSettings();
    final eq = s.equipment;
    final ctrl = ref.read(settingsProvider.notifier);
    Future<void> set(EquipmentProfile e) =>
        ctrl.change((x) => x.copyWith(equipment: e));
    final catalog = ref.watch(contentProvider).value?.catalog ?? const [];

    String? modelOf(EquipmentCategory cat, {BrewMethod? method}) {
      final item = eq.items
          .where((i) => i.category == cat && i.method == method)
          .firstOrNull;
      if (item == null) return null;
      if (item.freeText != null) return item.freeText;
      return catalog
          .where((c) => c.id == item.catalogModelId)
          .firstOrNull
          ?.displayName;
    }

    Future<void> pickModel(
      EquipmentCategory cat,
      Set<String> guideIds, {
      BrewMethod? method,
    }) async {
      final options = [
        for (final c in catalog)
          if (guideIds.contains(c.category) &&
              (method == null ||
                  c.methods.isEmpty ||
                  c.methods.contains(method)))
            c,
      ];
      final result = await showModalBottomSheet<OwnedEquipment>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (c) =>
            _ModelPicker(category: cat, method: method, options: options),
      );
      if (result == null) return;
      await set(
        eq.copyWith(
          items: [
            for (final i in eq.items)
              if (!(i.category == cat && i.method == method)) i,
            result,
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ekipman profili')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SectionTitle('Demleme araçları'),
          for (final m in BrewMethod.values)
            CheckboxListTile(
              secondary: Icon(methodIcon(m)),
              title: Text(methodName(m)),
              subtitle: eq.brewers.contains(m)
                  ? Text(
                      modelOf(EquipmentCategory.brewer, method: m) ??
                          'Model seçilmedi',
                    )
                  : null,
              value: eq.brewers.contains(m),
              onChanged: (v) => set(
                eq.copyWith(
                  brewers: v == true
                      ? {...eq.brewers, m}
                      : ({...eq.brewers}..remove(m)),
                ),
              ),
            ),
          for (final m in eq.brewers)
            ListTile(
              leading: const SizedBox(width: 24),
              title: Text('${methodName(m)} modeli'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => pickModel(EquipmentCategory.brewer, {
                'brewer',
                'espresso_machine',
                'drip_machine',
                'turkish',
              }, method: m),
            ),
          const SectionTitle('Öğütücü'),
          RadioGroup<GrinderType>(
            groupValue: eq.grinder,
            onChanged: (g) => set(eq.copyWith(grinder: g)),
            child: Column(
              children: [
                for (final g in GrinderType.values)
                  RadioListTile<GrinderType>(
                    value: g,
                    title: Text(grinderName(g)),
                  ),
              ],
            ),
          ),
          if (eq.grinder?.isBurr ?? false)
            ListTile(
              title: const Text('Öğütücü modeli'),
              subtitle: Text(modelOf(EquipmentCategory.grinder) ?? 'Seçilmedi'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => pickModel(EquipmentCategory.grinder, {
                'hand_grinder',
                'electric_grinder',
                'espresso_grinder',
              }),
            ),
          const SectionTitle('Terazi ve kettle'),
          SwitchListTile(
            title: const Text('Terazim var'),
            value: eq.hasScale ?? false,
            onChanged: (v) => set(eq.copyWith(hasScale: v)),
          ),
          RadioGroup<KettleType>(
            groupValue: eq.kettle,
            onChanged: (k) => set(eq.copyWith(kettle: k)),
            child: Column(
              children: [
                for (final k in KettleType.values)
                  RadioListTile<KettleType>(
                    value: k,
                    title: Text('Kettle: ${kettleName(k)}'),
                  ),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text('Su filtresi veya uygun şişe suyu kullanıyorum'),
            value: eq.hasWaterFilter,
            onChanged: (v) => set(eq.copyWith(hasWaterFilter: v)),
          ),
        ],
      ),
    );
  }
}

class _ModelPicker extends StatefulWidget {
  const _ModelPicker({
    required this.category,
    required this.method,
    required this.options,
  });

  final EquipmentCategory category;
  final BrewMethod? method;
  final List<CatalogModel> options;

  @override
  State<_ModelPicker> createState() => _ModelPickerState();
}

class _ModelPickerState extends State<_ModelPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = [
      for (final o in widget.options)
        if (matchesQuery(_query, [o.displayName])) o,
    ];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Marka veya model ara',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final o in filtered)
                    ListTile(
                      title: Text(o.displayName),
                      onTap: () => Navigator.pop(
                        context,
                        OwnedEquipment(
                          category: widget.category,
                          method: widget.method,
                          catalogModelId: o.id,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_query.trim().isNotEmpty)
              FilledButton.tonal(
                onPressed: () => Navigator.pop(
                  context,
                  OwnedEquipment(
                    category: widget.category,
                    method: widget.method,
                    freeText: _query.trim(),
                  ),
                ),
                child: Text('"${_query.trim()}" olarak kaydet'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Kullanım koşulları ve emniyet beyanı; ilk açılışta zorunlu onay değildir
/// (KHV-NFR-037).
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Koşullar ve emniyet')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SectionTitle('Emniyet'),
        Text(
          'Uygulamadaki tarifler sıcak su, buhar ve ocak kullanımı içerir. '
          'Sıcak yüzeylere dokunmayın, kaynar su dökerken kabı sabit tutun, '
          'moka pot ve espresso makinesinde üreticinin talimatlarına uyun. '
          'Cihazınızı sökmeyin ve basınç bileşenlerine müdahale etmeyin.',
        ),
        SectionTitle('Kullanım koşulları'),
        Text(
          'Tarif ve öneriler genel bilgilendirme amaçlıdır. Değerler yaygın '
          'kabul gören başlangıç noktalarıdır, kesin kural değildir. '
          'Ekipman örnekleri tavsiye niteliğindedir; uygulama fiyat ve satın '
          'alma bağlantısı göstermez.',
        ),
        SectionTitle('Kişisel veriler'),
        Text(
          'Uygulama hesap gerektirmez. Demleme günlüğünüz yalnız cihazınızda '
          'saklanır. Anonim kullanım ölçümü ve çökme raporu yalnız ayarlardan '
          'açık rıza vermeniz halinde toplanır (6698 sayılı KVKK).',
        ),
      ],
    ),
  );
}
