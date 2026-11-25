import 'package:kahve_core/kahve_core.dart';
import 'package:test/test.dart';

const s = 1000;

void main() {
  group('elle giriş terazisi (KHV-ARC-007)', () {
    test('girilen değer akıştan yayınlanır, dara uygulanır', () async {
      var now = DateTime(2026, 11, 25, 8);
      final scale = ManualScale(clock: () => now);
      expect(scale.isManual, isTrue);
      expect(scale.status, ScaleConnection.manual);
      expect(scale.supportsTare, isTrue);
      expect(scale.supportsTimer, isFalse);
      expect(scale.name, 'Elle giriş');
      expect(scale.latest, isNull);
      final readings = <double>[];
      final sub = scale.weights.listen((r) => readings.add(r.grams));
      scale.enter(320.4);
      await scale.tare();
      now = now.add(const Duration(seconds: 5));
      scale.enter(470.4);
      await Future<void>.delayed(Duration.zero);
      expect(readings, [320.4, 0, 150]);
      expect(scale.latest!.at, now);
      expect(scale.latest.toString(), contains('150.0 g'));
      await scale.startTimer();
      await scale.stopTimer();
      expect(() => scale.enter(double.nan), throwsArgumentError);
      await sub.cancel();
      await scale.dispose();
    });

    test('okuma yokken dara sıfırdır', () async {
      final scale = ManualScale();
      await scale.tare();
      scale.enter(10);
      expect(scale.latest!.grams, 10);
    });
  });

  group('tutarlılık koruması (KHV-FR-SCL-005)', () {
    final t0 = DateTime(2026, 1, 1);
    WeightReading r(double g, int ms) =>
        WeightReading(g, t0.add(Duration(milliseconds: ms)));

    test('normal döküş tutarlı', () {
      final g = WeightGuard();
      for (var i = 0; i < 20; i++) {
        expect(g.feed(r(i * 15.0, i * 200)), WeightHealth.ok);
      }
      expect(g.autoAdvanceAllowed, isTrue);
    });

    test("1 sn içinde 500 g'dan fazla değişim", () {
      final g = WeightGuard();
      g.feed(r(100, 0));
      expect(g.feed(r(650, 900)), WeightHealth.jump);
      expect(g.autoAdvanceAllowed, isFalse);
      expect(g.feed(r(650, 5000)), WeightHealth.jump, reason: 'kalıcı');
      g.reset();
      expect(g.feed(r(650, 6000)), WeightHealth.ok);
    });

    test('1 sn dışındaki büyük değişim sıçrama sayılmaz', () {
      final g = WeightGuard();
      g.feed(r(0, 0));
      expect(g.feed(r(600, 1500)), WeightHealth.ok);
    });

    test('negatif değer; küçük dara titreşimi tolere edilir', () {
      final g = WeightGuard();
      expect(g.feed(r(-0.3, 0)), WeightHealth.ok);
      expect(g.feed(r(-5, 100)), WeightHealth.negative);
    });

    test('bağlantı kopması', () {
      final g = WeightGuard();
      expect(g.onConnection(ScaleConnection.connected), WeightHealth.ok);
      expect(
        g.onConnection(ScaleConnection.disconnected),
        WeightHealth.disconnected,
      );
      expect(g.autoAdvanceAllowed, isFalse);
    });
  });

  group('zamanlayıcıda ağırlıkla ilerleme (KHV-FR-SCL-004, SCL-005)', () {
    List<BrewStep> steps() => const [
      BrewStep(
        title: 'Bloom',
        trigger: StepTrigger.weight,
        targetWaterG: 30,
        durationS: 10,
      ),
      BrewStep(title: 'Bekle', trigger: StepTrigger.time, durationS: 30),
      BrewStep(title: 'Dök', trigger: StepTrigger.weight, targetWaterG: 150),
    ];

    test('terazi yokken ağırlık adımı süreyle geçer, ağırlık yok sayılır', () {
      final t = BrewTimer(steps())..start(0);
      expect(t.feedWeight(1 * s, 40), isEmpty);
      t.tick(10 * s);
      expect(t.view(10 * s).stepIndex, 1);
    });

    test('canlı ağırlıkta süre değil ağırlık ilerletir', () {
      final t = BrewTimer(steps())
        ..weightMode = WeightMode.live
        ..start(0);
      t.tick(15 * s);
      expect(t.view(15 * s).stepIndex, 0, reason: 'süre dolsa da beklenir');
      expect(t.view(15 * s).waitingForWeight, isTrue);
      expect(t.view(15 * s).waitingForConfirm, isFalse);
      expect(t.feedWeight(16 * s, 20), isEmpty);
      expect(t.feedWeight(17 * s, 29.2).single, isA<StepAdvanced>());
      expect(t.view(17 * s).stepIndex, 1);
      expect(t.feedWeight(18 * s, 500), isEmpty, reason: 'süreli adım');
      t.tick(47 * s);
      expect(t.view(47 * s).stepIndex, 2);
      expect(t.upcomingTransitions(47 * s), isEmpty);
      expect(t.feedWeight(48 * s, 150).single, isA<BrewFinished>());
    });

    test('veri bozulunca adım kullanıcı onayına döner', () {
      final t = BrewTimer(steps())
        ..weightMode = WeightMode.live
        ..start(0);
      t.weightMode = WeightMode.degraded;
      expect(t.view(1 * s).waitingForConfirm, isTrue);
      expect(t.view(1 * s).waitingForWeight, isFalse);
      expect(t.feedWeight(2 * s, 100), isEmpty);
      t.tick(30 * s);
      expect(t.view(30 * s).stepIndex, 0);
      expect(t.confirm(31 * s).single, isA<StepAdvanced>());
    });

    test('duraklatılmışken ağırlık ilerletmez', () {
      final t = BrewTimer(steps())
        ..weightMode = WeightMode.live
        ..start(0);
      t.pause(1 * s);
      expect(t.feedWeight(2 * s, 100), isEmpty);
      expect(BrewTimer(steps()).feedWeight(0, 100), isEmpty);
    });
  });

  group('desteklenen teraziler (KHV-FR-SCL-001, SCL-002, SCL-010)', () {
    SupportedScale scale({
      String licenseRef = 'https://ornek.com/protokol',
      ScaleFingerprint fingerprint = const ScaleFingerprint(
        namePrefixes: ['Ornek Scale'],
        serviceUuids: ['fff0'],
      ),
      bool tare = true,
      bool timer = false,
      Set<String> platforms = const {'android', 'ios'},
    }) => SupportedScale(
      id: 'ornek',
      brand: 'Örnek',
      model: 'S1',
      source: ScaleSource.openProtocol,
      licenseRef: licenseRef,
      licenseReviewedAt: DateTime(2026, 11, 25),
      protocol: 'ornek-v1',
      fingerprint: fingerprint,
      supportsTare: tare,
      supportsTimer: timer,
      platforms: platforms,
    );

    test('lisans referansı veya parmak izi olmayan kayıt listeye girmez', () {
      final reg = ScaleRegistry([
        scale(),
        scale(licenseRef: ' '),
        scale(fingerprint: const ScaleFingerprint()),
      ]);
      expect(reg.scales, hasLength(1));
      expect(ScaleRegistry.validate(scale(licenseRef: '')), isNotEmpty);
    });

    test('parmak izi eşleşmesi: ad, servis UUID, üretici', () {
      final reg = ScaleRegistry([scale()]);
      final ok = reg.classify(
        const BleAdvertisement(
          name: 'ORNEK SCALE 12',
          serviceUuids: ['0000FFF0-0000-1000-8000-00805F9B34FB'],
        ),
      );
      expect(ok, isA<KnownScale>());
      expect((ok as KnownScale).scale.displayName, 'Örnek S1');
      expect(
        reg.classify(
          const BleAdvertisement(name: 'Ornek Scale', serviceUuids: ['fff1']),
        ),
        isA<UnknownDevice>(),
      );
      final unknown = reg.classify(
        const BleAdvertisement(name: 'Baska Terazi'),
      );
      expect((unknown as UnknownDevice).advertisedName, 'Baska Terazi');
      const byMfr = ScaleFingerprint(manufacturerId: 0x1234);
      expect(
        byMfr.matches(
          const BleAdvertisement(name: 'x', manufacturerIds: [0x1234]),
        ),
        isTrue,
      );
      expect(byMfr.matches(const BleAdvertisement(name: 'x')), isFalse);
      expect(
        const ScaleFingerprint().matches(const BleAdvertisement(name: 'x')),
        isFalse,
      );
    });

    test('platform kısıtı (tek platformlu SDK)', () {
      final reg = ScaleRegistry([
        scale(platforms: {'ios'}),
      ]);
      const ad = BleAdvertisement(name: 'Ornek Scale', serviceUuids: ['fff0']);
      expect(reg.classify(ad, platform: 'android'), isA<UnknownDevice>());
      expect(reg.classify(ad, platform: 'ios'), isA<KnownScale>());
    });

    test('tanınmayan cihaza asla yazılmaz', () {
      expect(
        ScaleRegistry.canWrite(const UnknownDevice('x'), forTimer: false),
        isFalse,
      );
      expect(
        ScaleRegistry.canWrite(KnownScale(scale()), forTimer: false),
        isTrue,
      );
      expect(
        ScaleRegistry.canWrite(KnownScale(scale()), forTimer: true),
        isFalse,
      );
      expect(
        ScaleRegistry.canWrite(KnownScale(scale(tare: false)), forTimer: false),
        isFalse,
      );
    });

    test('JSON ve UUID biçimi', () {
      final j = {
        'id': 'a',
        'brand': 'B',
        'model': 'M',
        'source': 'manufacturerPermission',
        'licenseRef': 'izin-2026-01',
        'licenseReviewedAt': '2026-11-25',
        'protocol': 'p',
        'fingerprint': {
          'namePrefixes': ['B'],
          'serviceUuids': ['FFF0'],
          'manufacturerId': 7,
        },
        'supportsTimer': true,
      };
      final sc = SupportedScale.fromJson(j);
      expect(
        sc.fingerprint.serviceUuids.single,
        '0000fff0-0000-1000-8000-00805f9b34fb',
      );
      expect(sc.supportsTimer, isTrue);
      expect(sc.supportsTare, isFalse);
      expect(sc.platforms, {'android', 'ios'});
      expect(
        normalizeUuid('ABCDEF01-0000-1000-8000-00805F9B34FB'),
        'abcdef01-0000-1000-8000-00805f9b34fb',
      );
    });
  });

  group('dinleme modunda teyit (KHV-FR-SCL-003)', () {
    test(
      'yalnız açık protokoller aday olur, kullanıcı teyidiyle kesinleşir',
      () {
        final p = ListenOnlyProbe(['acik-a']);
        p.observe('kapali-b', 12);
        expect(p.candidates, isEmpty);
        p.observe('acik-a', 12.3);
        expect(p.candidates, {'acik-a': 12.3});
        expect(p.confirm('kapali-b'), isFalse);
        p.reject();
        expect(p.candidates, isEmpty);
        p.observe('acik-a', 50);
        expect(p.confirm('acik-a'), isTrue);
        expect(p.confirmed, 'acik-a');
        p.observe('acik-a', 99);
        expect(p.candidates['acik-a'], 50);
      },
    );
  });
}
