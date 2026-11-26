import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import 'dart:convert';

import '../services/platform.dart';
import '../state/brew_state.dart';
import '../state/maintenance_state.dart';
import '../state/providers.dart';
import '../state/settings.dart';
import 'common.dart';
import 'labels.dart';
import 'scene.dart';

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
          // Bluetooth terazi eşleştirme (KB-028).
          ListTile(
            leading: const Icon(Icons.scale),
            title: const Text('Terazi'),
            subtitle: Text(s.pairedScale?.name ?? 'Elle giriş'),
            onTap: () => context.push('/settings/scale'),
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
          SwitchListTile(
            secondary: const Icon(Icons.record_voice_over_outlined),
            title: const Text('Sesli adım komutu'),
            subtitle: const Text('Ör. "150 grama kadar dök"'),
            value: s.voiceGuidance,
            onChanged: (v) => ctrl.change((x) => x.copyWith(voiceGuidance: v)),
          ),
          const SectionTitle('Bildirimler'),
          for (final (type, label) in const [
            (NotificationType.brewStep, 'Arka planda adım geçişleri'),
            (NotificationType.longBrewDone, 'Uzun demleme bitişi'),
            (NotificationType.lowStock, 'Çekirdek azaldı'),
            (NotificationType.freshness, 'Çekirdek tazeliği'),
            (NotificationType.maintenance, 'Bakım zamanı'),
          ])
            SwitchListTile(
              title: Text(label),
              value: s.notifications.enabled.contains(type),
              onChanged: (v) => ctrl.change(
                (x) => x.copyWith(
                  notifications: x.notifications.copyWith(
                    enabled: v
                        ? {...x.notifications.enabled, type}
                        : ({...x.notifications.enabled}..remove(type)),
                  ),
                ),
              ),
            ),
          SwitchListTile(
            title: const Text('Sessiz saatler'),
            subtitle: Text(
              '${_hm(s.notifications.quietStartMin)} - '
              '${_hm(s.notifications.quietEndMin)} arası hatırlatıcı '
              'gönderilmez. Günde en fazla 2 hatırlatıcı.',
            ),
            value: s.notifications.quietHoursEnabled,
            onChanged: (v) => ctrl.change(
              (x) => x.copyWith(
                notifications: x.notifications.copyWith(quietHoursEnabled: v),
              ),
            ),
          ),
          if (s.notifications.quietHoursEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _pickTime(context, ref, start: true),
                    child: Text(
                      'Başlangıç ${_hm(s.notifications.quietStartMin)}',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _pickTime(context, ref, start: false),
                    child: Text('Bitiş ${_hm(s.notifications.quietEndMin)}'),
                  ),
                ],
              ),
            ),
          ListTile(
            leading: const Icon(Icons.build_outlined),
            title: const Text('Bakım hatırlatıcıları'),
            subtitle: Text(
              '${(ref.watch(maintenanceProvider).value ?? const []).length} '
              'görev',
            ),
            onTap: () => context.push('/settings/maintenance'),
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
            leading: const Icon(Icons.upload_file_outlined),
            title: const Text('Verimi dışa aktar'),
            subtitle: const Text(
              'Günlük, tarifler ve çekirdekler tek dosyada; başka cihaza '
              'taşıyabilirsiniz.',
            ),
            onTap: () => _export(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Yedekten geri yükle'),
            onTap: () => _import(context, ref),
          ),
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
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Hata bildir veya öneri gönder'),
            onTap: () => context.push('/feedback'),
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

  static String _hm(int min) =>
      '${(min ~/ 60).toString().padLeft(2, '0')}:'
      '${(min % 60).toString().padLeft(2, '0')}';

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref, {
    required bool start,
  }) async {
    final p =
        (ref.read(settingsProvider).value ?? const AppSettings()).notifications;
    final current = start ? p.quietStartMin : p.quietEndMin;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (t == null) return;
    final m = t.hour * 60 + t.minute;
    await ref
        .read(settingsProvider.notifier)
        .change(
          (x) => x.copyWith(
            notifications: start
                ? x.notifications.copyWith(quietStartMin: m)
                : x.notifications.copyWith(quietEndMin: m),
          ),
        );
  }

  /// Yerel veriyi dosya olarak dışa aktarır (KHV-NFR-030).
  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final now = ref.read(clockProvider)();
    final data = await ref.read(databaseProvider).exportAll(at: now);
    final day =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    await ref
        .read(sharerProvider)
        .shareFile(
          utf8.encode(const JsonEncoder.withIndent(' ').convert(data)),
          name: 'ev-kahvesi-yedek-$day.json',
          mimeType: 'application/json',
        );
  }

  /// Yedek dosyasını doğrulayıp geri yükler (KHV-NFR-030).
  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final text = await ref.read(filePickProvider).pickJson();
    if (text == null || !context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Yedek geri yüklensin mi?'),
        content: const Text(
          'Bu cihazdaki mevcut günlük, tarif, çekirdek ve ayarların yerini '
          'yedekteki veriler alır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Geri yükle'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    String message;
    try {
      final json = (jsonDecode(text) as Map).cast<String, Object?>();
      await ref.read(databaseProvider).importAll(json);
      ref
        ..invalidate(settingsProvider)
        ..invalidate(longBrewsProvider)
        ..invalidate(maintenanceProvider);
      message = 'Yedek geri yüklendi.';
    } on FormatException catch (e) {
      message = e.message;
    } on Object {
      message = 'Dosya okunamadı. Ev Kahvesi yedek dosyası seçin.';
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
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

/// Ekipman profili düzenleme; kullanıcının kendi aracının adı serbest metinle
/// girilir, marka listesi sunulmaz (KHV-FR-ONB-003, ONB-004, KB-017).
class EquipmentProfileScreen extends ConsumerWidget {
  const EquipmentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider).value ?? const AppSettings();
    final eq = s.equipment;
    final ctrl = ref.read(settingsProvider.notifier);
    Future<void> set(EquipmentProfile e) =>
        ctrl.change((x) => x.copyWith(equipment: e));
    String? modelOf(EquipmentCategory cat, {BrewMethod? method}) => eq.items
        .where((i) => i.category == cat && i.method == method)
        .firstOrNull
        ?.freeText;

    Future<void> pickModel(EquipmentCategory cat, {BrewMethod? method}) async {
      final result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (c) => _ModelNameSheet(initial: modelOf(cat, method: method)),
      );
      if (result == null) return;
      await set(
        eq.copyWith(
          items: [
            for (final i in eq.items)
              if (!(i.category == cat && i.method == method)) i,
            if (result.isNotEmpty)
              OwnedEquipment(category: cat, method: method, freeText: result),
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
              secondary: MethodGlyph(m),
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
              onTap: () => pickModel(EquipmentCategory.brewer, method: m),
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
              onTap: () => pickModel(EquipmentCategory.grinder),
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

/// Kullanıcının kendi aracının adı; boş bırakılırsa kayıt silinir.
class _ModelNameSheet extends StatefulWidget {
  const _ModelNameSheet({this.initial});

  final String? initial;

  @override
  State<_ModelNameSheet> createState() => _ModelNameSheetState();
}

class _ModelNameSheetState extends State<_ModelNameSheet> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
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
            controller: _text,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Aracınızın adı',
              helperText: 'Kendiniz için not; uygulama marka önermez.',
            ),
            onSubmitted: (v) => Navigator.pop(context, v.trim()),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.pop(context, _text.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    ),
  );
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
          'Ekipman rehberi marka veya model önermez; uygulama fiyat ve satın '
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
