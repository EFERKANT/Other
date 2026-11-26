import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../services/ble.dart';
import '../services/platform.dart';
import '../state/providers.dart';
import '../state/settings.dart';

enum _Phase { intro, scanning, probing, unrecognized, blocked }

/// Bluetooth terazi eşleştirme (KB-028): izin açıklaması (KHV-FR-SCL-007),
/// tarama ve parmak iziyle tanıma (SCL-002), tanınmayan cihazda dinleme
/// modunda deneme ve kullanıcı teyidi (SCL-003), tanınmazsa destek talebi
/// (SCL-006). Eşleşme olmazsa ağırlık elle girilmeye devam eder.
class ScaleScreen extends ConsumerStatefulWidget {
  const ScaleScreen({super.key});

  @override
  ConsumerState<ScaleScreen> createState() => _ScaleScreenState();
}

class _ScaleScreenState extends ConsumerState<ScaleScreen> {
  _Phase _phase = _Phase.intro;
  String _blockedText = '';
  final _found = <String, FoundDevice>{};
  StreamSubscription<FoundDevice>? _scanSub;

  // Dinleme modu.
  FoundDevice? _probeDevice;
  BleLink? _probeLink;
  ListenOnlyProbe? _probe;
  final _probeSubs = <StreamSubscription<Object?>>[];

  late final ScaleRegistry _registry = ScaleRegistry(
    ref.read(contentProvider).value?.scales ?? const [],
  );

  @override
  void dispose() {
    unawaited(_scanSub?.cancel());
    unawaited(_stopProbe());
    super.dispose();
  }

  BleCentral get _ble => ref.read(bleCentralProvider);

  /// Taramayı durdurur; durmanın tamamlanması beklenmez (yerel tarafta
  /// gecikebilir, ekran akışı bekletilmez).
  void _stopScan() {
    unawaited(_scanSub?.cancel());
    _scanSub = null;
  }

  Future<void> _start() async {
    var state = await _ble.state();
    if (state == BleState.unauthorized) {
      state = await _ble.requestPermission()
          ? await _ble.state()
          : BleState.unauthorized;
    }
    if (!mounted) return;
    switch (state) {
      case BleState.ready:
        _scan();
      case BleState.off:
        _block('Telefonunuzda Bluetooth kapalı. Açıp yeniden deneyin.');
      case BleState.unauthorized:
        _block(
          'Bluetooth izni verilmedi. Telefonun Ayarlar uygulamasından izin '
          'verebilir veya ağırlığı elle girmeye devam edebilirsiniz.',
        );
      case BleState.unsupported:
        _block(
          'Bu cihaz Bluetooth LE desteklemiyor. iOS simülatöründe Bluetooth '
          'çalışmaz; gerçek bir telefonda deneyin.',
        );
    }
  }

  void _block(String text) => setState(() {
    _phase = _Phase.blocked;
    _blockedText = text;
  });

  void _scan() {
    setState(() {
      _phase = _Phase.scanning;
      _found.clear();
    });
    _stopScan();
    _scanSub = _ble.scan().listen(
      (d) => setState(() => _found[d.deviceId] = d),
      onError: (Object _) => _block(
        'Tarama başlatılamadı. Bluetooth açık mı, kontrol edip yeniden '
        'deneyin.',
      ),
    );
  }

  Future<void> _pair(PairedScale p) async {
    _stopScan();
    unawaited(_stopProbe());
    await ref
        .read(settingsProvider.notifier)
        .change((s) => s.copyWith(pairedScale: p));
    if (!mounted) return;
    setState(() => _phase = _Phase.intro);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${p.name} bağlandı.')));
  }

  Future<void> _pairKnown(FoundDevice d, SupportedScale s) => _pair(
    PairedScale(
      deviceId: d.deviceId,
      name: d.advertisement.name,
      protocol: s.protocol,
      supportedId: s.id,
    ),
  );

  /// Dinleme modu: açık protokoller tek tek dinlenir, cihaza hiçbir şey
  /// yazılmaz (KHV-FR-SCL-003, SCL-010).
  Future<void> _startProbe(FoundDevice d) async {
    _stopScan();
    final probe = ListenOnlyProbe([for (final p in openScaleProtocols) p.id]);
    final link = _ble.link(d.deviceId);
    setState(() {
      _phase = _Phase.probing;
      _probeDevice = d;
      _probe = probe;
      _probeLink = link;
    });
    try {
      await link.connect();
    } on Object {
      if (mounted) setState(() => _phase = _Phase.unrecognized);
      return;
    }
    for (final protocol in openScaleProtocols) {
      _probeSubs.add(
        link
            .notifications(protocol.serviceUuid, protocol.weightCharacteristic)
            .listen((packet) {
              final grams = protocol.decodeGrams(packet);
              if (grams == null || !mounted) return;
              setState(() => probe.observe(protocol.id, grams));
            }, onError: (Object _) {}),
      );
    }
  }

  Future<void> _stopProbe() async {
    // Liste önce devralınır: ekran kapanırken ve eşleşirken aynı anda
    // çağrılabilir.
    final subs = List.of(_probeSubs);
    _probeSubs.clear();
    for (final s in subs) {
      unawaited(s.cancel());
    }
    final link = _probeLink;
    _probeLink = null;
    if (link != null) {
      try {
        await link.disconnect();
      } on Object {
        // Bağlantı kurulmamış olabilir.
      }
    }
  }

  Future<void> _confirmProbe(String protocol) async {
    final d = _probeDevice!;
    if (!_probe!.confirm(protocol)) return;
    await _pair(
      PairedScale(
        deviceId: d.deviceId,
        name: d.advertisement.name,
        protocol: protocol,
      ),
    );
  }

  Future<void> _rejectProbe() async {
    _probe?.reject();
    unawaited(_stopProbe());
    if (mounted) setState(() => _phase = _Phase.unrecognized);
  }

  /// Destek talebi: yalnız cihazın yayınladığı ad gönderilir
  /// (KHV-FR-SCL-006).
  Future<void> _requestSupport() => ref
      .read(sharerProvider)
      .shareText(
        'Ev Kahvesi terazi destek talebi\n'
        'Cihazın yayınladığı ad: ${_probeDevice?.advertisement.name ?? '-'}',
        subject: 'Terazi destek talebi',
      );

  @override
  Widget build(BuildContext context) {
    final paired = ref.watch(settingsProvider).value?.pairedScale;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Terazi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (paired != null && _phase == _Phase.intro) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.scale),
                title: Text(paired.name),
                subtitle: Text(
                  paired.listenOnly
                      ? 'Dinleme modu: ağırlık okunur, teraziye komut '
                            'gönderilmez.'
                      : 'Desteklenen model: ağırlık okunur, dara ve '
                            'zamanlayıcı teraziden yönetilir.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref
                  .read(settingsProvider.notifier)
                  .change((s) => s.copyWith(clearPairedScale: true)),
              child: const Text('Eşleştirmeyi kaldır'),
            ),
          ] else
            ..._body(t),
        ],
      ),
    );
  }

  List<Widget> _body(TextTheme t) => switch (_phase) {
    _Phase.intro => [
      Text('Teraziniz bağlansın mı?', style: t.headlineSmall),
      const SizedBox(height: 8),
      const Text(
        'Bluetooth terazi bağlanırsa ağırlık otomatik okunur ve demleme '
        'adımları hedef ağırlığa ulaşınca kendiliğinden ilerler. Uygulama '
        'yalnız teraziyi arar; konumunuzu kullanmaz, başka cihazlara bağlanmaz.',
      ),
      const SizedBox(height: 8),
      const Text(
        'Teraziniz yoksa veya bağlanmazsa ağırlığı demleme sırasında elle '
        'girmeye devam edebilirsiniz.',
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _start,
        child: const Text('Bluetooth ile terazi ara'),
      ),
    ],
    _Phase.blocked => [
      Text(_blockedText),
      const SizedBox(height: 16),
      FilledButton(onPressed: _start, child: const Text('Yeniden dene')),
    ],
    _Phase.scanning => [
      Row(
        children: [
          const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Teraziniz açık ve yakında olsun. Aranıyor…',
              style: t.titleMedium,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (_found.isEmpty)
        const Text('Henüz bir cihaz bulunamadı.')
      else
        for (final d in _found.values) _deviceTile(d),
    ],
    _Phase.probing => _probeBody(t),
    _Phase.unrecognized => [
      Text('Bu teraziyi tanıyamadık', style: t.headlineSmall),
      const SizedBox(height: 8),
      const Text(
        'Uygulama yalnız üreticisinin açıkça yayımladığı protokolleri '
        'kullanır. Ağırlığı demleme sırasında elle girebilirsiniz. Destek '
        'talebi gönderirseniz yalnız cihazın yayınladığı ad paylaşılır.',
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _requestSupport,
        child: const Text('Destek talebi gönder'),
      ),
      const SizedBox(height: 8),
      OutlinedButton(onPressed: _scan, child: const Text('Başka cihaz ara')),
    ],
  };

  Widget _deviceTile(FoundDevice d) {
    final match = _registry.classify(d.advertisement);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.scale),
        title: Text(d.advertisement.name),
        subtitle: Text(
          match is KnownScale
              ? '${match.scale.displayName} · destekleniyor'
              : 'Tanınmıyor · dinleme modunda dene',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => switch (match) {
          KnownScale(:final scale) => _pairKnown(d, scale),
          UnknownDevice() => _startProbe(d),
        },
      ),
    );
  }

  List<Widget> _probeBody(TextTheme t) {
    final candidates = _probe?.candidates ?? const {};
    return [
      Text('Dinleme modu', style: t.headlineSmall),
      const SizedBox(height: 8),
      const Text(
        'Terazinin üstüne bir şey koyun. Uygulama terazinin gönderdiği '
        'değeri okumaya çalışıyor; teraziye hiçbir komut gönderilmez.',
      ),
      const SizedBox(height: 16),
      if (candidates.isEmpty) ...[
        const Text('Henüz okunabilen bir değer yok…'),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _rejectProbe,
          child: const Text('Okunmuyor, vazgeç'),
        ),
      ] else
        for (final MapEntry(key: protocol, value: grams) in candidates.entries)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Okunan: ${formatNumber(grams)} g',
                    style: t.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Terazinizin ekranında da bu değer mi yazıyor?'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () => _confirmProbe(protocol),
                        child: const Text('Evet, aynı'),
                      ),
                      OutlinedButton(
                        onPressed: _rejectProbe,
                        child: const Text('Hayır, farklı'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    ];
  }
}
