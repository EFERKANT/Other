import 'dart:async';

import 'package:kahve_core/kahve_core.dart';
import 'package:test/test.dart';

/// Belgedeki biçimde 20 baytlık BOOKOO ağırlık paketi.
List<int> bookooWeight(double grams, {int unit = 0x01}) {
  final hundredths = (grams.abs() * 100).round();
  final p = [
    0x03, 0x0B, 0x00, 0x10, 0x00, unit, //
    if (grams < 0) 0x2D else 0x2B,
    hundredths >> 16 & 0xFF, hundredths >> 8 & 0xFF, hundredths & 0xFF,
    0x2B, 0x00, 0x00, 0x50, 0x00, 0x96, 0x02, 0x01, 0x00,
  ];
  return [...p, p.fold(0, (a, b) => a ^ b)];
}

class FakeLink implements BleLink {
  final connectedCtrl = StreamController<bool>.broadcast();
  final packets = StreamController<List<int>>.broadcast();
  final writes = <List<int>>[];
  String? subscribedService;
  String? subscribedCharacteristic;
  bool failConnect = false;

  @override
  Stream<bool> get connected => connectedCtrl.stream;

  @override
  Future<void> connect() async {
    if (failConnect) throw StateError('bağlanamadı');
  }

  @override
  Stream<List<int>> notifications(String service, String characteristic) {
    subscribedService = service;
    subscribedCharacteristic = characteristic;
    return packets.stream;
  }

  @override
  Future<void> write(
    String service,
    String characteristic,
    List<int> v,
  ) async => writes.add(v);

  @override
  Future<void> disconnect() async {}
}

SupportedScale bookooMini() => SupportedScale(
  id: 'bookoo-themis-mini',
  brand: 'BOOKOO',
  model: 'Themis Mini',
  source: ScaleSource.openProtocol,
  licenseRef: const BookooProtocol().licenseRef,
  licenseReviewedAt: DateTime(2026, 11, 26),
  protocol: 'bookoo',
  fingerprint: const ScaleFingerprint(namePrefixes: ['BOOKOO_SC', 'OOKOO_SC']),
  supportsTare: true,
  supportsTimer: true,
);

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  const bookoo = BookooProtocol();

  group('BOOKOO açık protokolü (KB-028)', () {
    test('ağırlık paketi çözülür: işaret, yüzde bir gram, ons '
        '(KHV-FR-SCL-003, SCL-004)', () {
      expect(bookoo.decodeGrams(bookooWeight(18.25)), 18.25);
      expect(bookoo.decodeGrams(bookooWeight(-3.1)), -3.1);
      expect(bookoo.decodeGrams(bookooWeight(0)), 0);
      expect(bookoo.decodeGrams(bookooWeight(1, unit: 0x02)), 28.35);
    });

    test('sağlaması bozuk, kısa veya başka türdeki paket ağırlık sayılmaz '
        '(KHV-FR-SCL-005)', () {
      final bad = bookooWeight(18.25)..[19] ^= 0xFF;
      expect(bookoo.decodeGrams(bad), isNull);
      expect(bookoo.decodeGrams(bookooWeight(18.25).sublist(0, 19)), isNull);
      final other = bookooWeight(18.25)..[1] = 0x0D;
      expect(bookoo.decodeGrams(other), isNull);
    });

    test('komutlar belgedeki biçimde ve XOR sağlamalı (KHV-FR-SCL-010)', () {
      expect(bookoo.command(ScaleCommand.tare), [3, 10, 1, 0, 0, 8]);
      expect(bookoo.command(ScaleCommand.startTimer), [3, 10, 4, 0, 0, 13]);
      expect(bookoo.command(ScaleCommand.stopTimer), [3, 10, 5, 0, 0, 12]);
      expect(scaleProtocolById('bookoo'), isA<BookooProtocol>());
      expect(scaleProtocolById('kapali-protokol'), isNull);
    });

    test('Mini ve eksik harfli ad parmak iziyle tanınır (KHV-FR-SCL-002)', () {
      final reg = ScaleRegistry([bookooMini()]);
      expect(
        reg.classify(const BleAdvertisement(name: 'BOOKOO_SC 1A2B')),
        isA<KnownScale>(),
      );
      expect(
        reg.classify(const BleAdvertisement(name: 'OOKOO_SC 1A2B')),
        isA<KnownScale>(),
      );
      expect(
        reg.classify(const BleAdvertisement(name: 'Mutfak Terazisi')),
        isA<UnknownDevice>(),
      );
    });
  });

  group('Bluetooth terazi (KHV-ARC-007)', () {
    test('tanınan terazi: bağlanır, ağırlık akar, dara ve zamanlayıcı '
        'teraziye gönderilir (KHV-FR-SCL-004, SCL-010)', () async {
      final link = FakeLink();
      final scale = BleScale(
        match: KnownScale(bookooMini()),
        protocol: bookoo,
        link: link,
        clock: () => DateTime(2026, 11, 26),
      );
      final statuses = <ScaleConnection>[];
      final readings = <double>[];
      scale.connection.listen(statuses.add);
      scale.weights.listen((r) => readings.add(r.grams));
      await scale.start();
      await flush();
      expect(scale.status, ScaleConnection.connected);
      expect(statuses, [ScaleConnection.connecting, ScaleConnection.connected]);
      expect(link.subscribedCharacteristic, bookoo.weightCharacteristic);
      link.packets.add(bookooWeight(30.04));
      link.packets.add([1, 2, 3]); // gürültü yok sayılır
      await flush();
      expect(readings, [30.0]);
      expect(scale.name, 'BOOKOO Themis Mini');
      await scale.tare();
      await scale.startTimer();
      expect(link.writes, [
        bookoo.command(ScaleCommand.tare),
        bookoo.command(ScaleCommand.startTimer),
      ]);
      await scale.dispose();
    });

    test('dinleme modundaki tanınmayan cihaza hiçbir şey yazılmaz; dara '
        'yazılımla alınır (KHV-FR-SCL-003, SCL-010)', () async {
      final link = FakeLink();
      final scale = BleScale(
        match: const UnknownDevice('Mutfak Terazisi'),
        protocol: bookoo,
        link: link,
      );
      final readings = <double>[];
      scale.weights.listen((r) => readings.add(r.grams));
      await scale.start();
      link.packets.add(bookooWeight(250));
      await flush();
      await scale.tare();
      await scale.startTimer();
      await scale.stopTimer();
      await flush();
      expect(link.writes, isEmpty);
      expect(scale.supportsTimer, isFalse);
      expect(readings, [250, 0]);
      expect(scale.name, 'Mutfak Terazisi (dinleme modu)');
      await scale.dispose();
    });

    test('bağlantı kurulamaz veya koparsa durum bildirilir '
        '(KHV-FR-SCL-005)', () async {
      final failing = FakeLink()..failConnect = true;
      final a = BleScale(
        match: KnownScale(bookooMini()),
        protocol: bookoo,
        link: failing,
      );
      await a.start();
      expect(a.status, ScaleConnection.disconnected);
      await a.dispose();

      final link = FakeLink();
      final b = BleScale(
        match: KnownScale(bookooMini()),
        protocol: bookoo,
        link: link,
      );
      await b.start();
      link.connectedCtrl.add(false);
      await flush();
      expect(b.status, ScaleConnection.disconnected);
      await b.dispose();
    });
  });
}
