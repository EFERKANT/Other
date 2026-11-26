import 'dart:async';

import 'package:ev_kahvesi/services/ble.dart';
import 'package:ev_kahvesi/state/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

/// Bağlı bir Bluetooth teraziyi taklit eder (KHV-ARC-007 arayüzü).
class FakeLiveScale implements Scale {
  final weightsCtrl = StreamController<WeightReading>.broadcast();
  final connCtrl = StreamController<ScaleConnection>.broadcast();
  WeightReading? _latest;
  var tares = 0;

  void emit(double g, DateTime at) {
    _latest = WeightReading(g, at);
    weightsCtrl.add(_latest!);
  }

  @override
  String get name => 'Test terazisi';
  @override
  bool get isManual => false;
  @override
  bool get supportsTare => true;
  @override
  bool get supportsTimer => false;
  @override
  ScaleConnection get status => ScaleConnection.connected;
  @override
  WeightReading? get latest => _latest;
  @override
  Stream<WeightReading> get weights => weightsCtrl.stream;
  @override
  Stream<ScaleConnection> get connection => connCtrl.stream;
  @override
  Future<void> tare() async => tares++;
  @override
  Future<void> startTimer() async {}
  @override
  Future<void> stopTimer() async {}
  @override
  Future<void> dispose() async {}
}

Future<void> openRecipe(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await settle(tester);
  await tester.tap(find.text('Rehberle demle'));
  await settle(tester);
}

void main() {
  testWidgets('elle ağırlık girişi demleme kaydına yalnız sonuç olarak '
      'yazılır (KHV-ARC-007, SCL-009)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    await openRecipe(tester, 'Espresso 1:2');
    // Terazisi olana tartılan doz sorulur.
    expect(find.text('Tartılan kahve'), findsOneWidget);
    await tester.tap(find.byTooltip('Tartılan kahve artır'));
    await settle(tester, 4);
    await tester.tap(find.text('Demlemeyi başlat'));
    await settle(tester, 6);
    await tester.tap(find.textContaining('Adım '));
    await settle(tester, 4);
    expect(find.text('36 g'), findsOneWidget);
    await tester.tap(find.text('Terazideki değeri gir'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), '37,5');
    await tester.tap(find.text('Kaydet'));
    await settle(tester);
    expect(find.text('Terazi: 37,5 g'), findsOneWidget);
    env.clock.advance(const Duration(seconds: 27));
    await settle(tester, 4);
    await tester.tap(find.textContaining('Adım '));
    await settle(tester);
    expect(find.text('Tadı nasıldı?'), findsOneWidget);
    // BRW-008: çıktı ağırlığı girilen değerle gelir.
    expect(find.text('37,5 g'), findsOneWidget);
    final brew = (await tester.runAsync(() => env.db.watchBrews().first))!
        .single;
    expect(brew.actualCoffeeG, 18.1);
    expect(brew.actualWaterG, 37.5);
    final bean = brew.beanId;
    expect(bean, isNull);
  });

  testWidgets('bağlı terazi ağırlık adımını ilerletir, tutarsız veride '
      'adım onaya döner (KHV-FR-SCL-004, SCL-005)', (tester) async {
    final scale = FakeLiveScale();
    final env = await setUpEnv(
      tester,
      settings: v60User,
      configure: (e) => e.scaleFactory = () => scale,
    );
    await settle(tester);
    await openRecipe(tester, 'V60 başlangıç');
    await tester.tap(find.text('Demlemeyi başlat'));
    await settle(tester, 6);
    expect(find.text('Adım 1/6'), findsOneWidget);
    // Süre dolsa da ağırlık beklenir.
    env.clock.advance(const Duration(seconds: 15));
    await settle(tester, 4);
    expect(find.text('Adım 1/6'), findsOneWidget);
    await tester.tap(find.text('Dara'));
    expect(scale.tares, 1);
    scale.emit(15, env.clock.wall);
    await settle(tester, 2);
    scale.emit(29.5, env.clock.wall.add(const Duration(milliseconds: 500)));
    await settle(tester, 4);
    expect(find.text('Adım 2/6'), findsOneWidget);
    env.clock.advance(const Duration(seconds: 35));
    await settle(tester, 4);
    expect(find.text('Adım 3/6'), findsOneWidget);
    // 1 sn içinde 500 g'dan fazla sıçrama.
    scale.emit(40, env.clock.wall);
    await settle(tester, 2);
    scale.emit(700, env.clock.wall.add(const Duration(milliseconds: 300)));
    await settle(tester, 4);
    expect(find.textContaining('Terazi verisi tutarsız'), findsOneWidget);
    expect(
      find.text('Adım 3/6'),
      findsOneWidget,
      reason: '700 g hedefi geçse de ilerlemez',
    );
    await tester.tap(find.textContaining('Adım '));
    await settle(tester, 4);
    expect(find.text('Adım 4/6'), findsOneWidget, reason: 'onayla ilerler');
  });

  bluetoothScaleTests();
}

Future<void> openScaleScreen(WidgetTester tester) async {
  await tester.tap(find.text('Ayarlar'));
  await settle(tester);
  await tester.tap(find.text('Terazi'));
  await settle(tester);
}

void bluetoothScaleTests() {
  testWidgets('izin açıklaması önce gösterilir; desteklenen terazi tek '
      'dokunuşla eşleşir (KB-028, KHV-FR-SCL-002, SCL-007)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    await openScaleScreen(tester);
    expect(find.textContaining('konumunuzu kullanmaz'), findsOneWidget);
    expect(env.ble.permissionRequests, 0, reason: 'açıklamadan önce izin yok');
    await tester.tap(find.text('Bluetooth ile terazi ara'));
    await settle(tester);
    expect(env.ble.permissionRequests, 1);
    env.ble.scanCtrl.add(
      const FoundDevice('d1', BleAdvertisement(name: 'BOOKOO_SC 1A2B')),
    );
    await settle(tester);
    expect(find.text('BOOKOO Themis Mini · destekleniyor'), findsOneWidget);
    await tester.tap(find.text('BOOKOO_SC 1A2B'));
    await settle(tester);
    final s = AppSettings.fromJson((await env.db.readJson('settings'))!);
    expect(s.pairedScale?.supportedId, 'bookoo-themis-mini');
    expect(s.pairedScale?.protocol, 'bookoo');
    expect(find.textContaining('Desteklenen model'), findsOneWidget);
  });

  testWidgets('tanınmayan cihaz dinleme modunda denenir, kullanıcı değeri '
      'onaylayınca eşleşir; cihaza hiçbir şey yazılmaz (KHV-FR-SCL-003, '
      'SCL-010)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    env.ble.current = BleState.ready;
    await openScaleScreen(tester);
    await tester.tap(find.text('Bluetooth ile terazi ara'));
    await settle(tester);
    env.ble.scanCtrl.add(
      const FoundDevice('d2', BleAdvertisement(name: 'Mutfak Terazisi')),
    );
    await settle(tester);
    expect(find.text('Tanınmıyor · dinleme modunda dene'), findsOneWidget);
    await tester.tap(find.text('Mutfak Terazisi'));
    await settle(tester);
    expect(find.text('Henüz okunabilen bir değer yok…'), findsOneWidget);
    env.ble.links['d2']!.packets.add(bookooPacket(245));
    await settle(tester);
    expect(find.text('Okunan: 245 g'), findsOneWidget);
    await tester.tap(find.text('Evet, aynı'));
    await settle(tester);
    final s = AppSettings.fromJson((await env.db.readJson('settings'))!);
    expect(s.pairedScale?.listenOnly, isTrue);
    expect(s.pairedScale?.protocol, 'bookoo');
    expect(env.ble.links['d2']!.writes, isEmpty);
    expect(find.textContaining('Dinleme modu: ağırlık okunur'), findsOneWidget);
  });

  testWidgets('değer eşleşmezse cihaz tanınmaz; destek talebinde yalnız '
      'yayınlanan ad gönderilir (KHV-FR-SCL-006)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    env.ble.current = BleState.ready;
    await openScaleScreen(tester);
    await tester.tap(find.text('Bluetooth ile terazi ara'));
    await settle(tester);
    env.ble.scanCtrl.add(
      const FoundDevice(
        'gizli-cihaz-kimligi',
        BleAdvertisement(name: 'XS-200'),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('XS-200'));
    await settle(tester);
    env.ble.links['gizli-cihaz-kimligi']!.packets.add(bookooPacket(80));
    await settle(tester);
    await tester.tap(find.text('Hayır, farklı'));
    await settle(tester);
    expect(find.text('Bu teraziyi tanıyamadık'), findsOneWidget);
    await tester.tap(find.text('Destek talebi gönder'));
    await settle(tester);
    expect(env.sharer.texts.single, contains('XS-200'));
    expect(env.sharer.texts.single, isNot(contains('gizli-cihaz-kimligi')));
    final s = AppSettings.fromJson((await env.db.readJson('settings'))!);
    expect(s.pairedScale, isNull);
  });

  testWidgets('Bluetooth yoksa (simülatör) nedeni söylenir, elle giriş sürer '
      '(KHV-FR-SCL-007)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    env.ble.current = BleState.unsupported;
    await openScaleScreen(tester);
    await tester.tap(find.text('Bluetooth ile terazi ara'));
    await settle(tester);
    expect(find.textContaining('simülatöründe Bluetooth'), findsOneWidget);
  });

  testWidgets('eşleşmiş Bluetooth terazi demlemede ağırlıkla ilerletir, dara '
      'teraziye gönderilir (KB-028, KHV-FR-SCL-004, SCL-010)', (tester) async {
    final env = await setUpEnv(
      tester,
      settings: v60User.copyWith(
        pairedScale: const PairedScale(
          deviceId: 'd1',
          name: 'BOOKOO_SC 1A2B',
          protocol: 'bookoo',
          supportedId: 'bookoo-themis-mini',
        ),
      ),
    );
    await openRecipe(tester, 'V60 başlangıç');
    await tester.tap(find.text('Demlemeyi başlat'));
    await settle(tester, 6);
    final link = env.ble.links['d1']!;
    expect(link.connects, 1);
    expect(find.text('Adım 1/6'), findsOneWidget);
    await tester.tap(find.text('Dara'));
    await settle(tester, 2);
    expect(link.writes, [const BookooProtocol().command(ScaleCommand.tare)]);
    link.packets.add(bookooPacket(15));
    await settle(tester, 2);
    env.clock.advance(const Duration(milliseconds: 500));
    link.packets.add(bookooPacket(29.6));
    await settle(tester, 4);
    expect(find.text('Adım 2/6'), findsOneWidget);
  });
}
