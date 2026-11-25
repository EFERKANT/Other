import 'dart:async';

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
}
