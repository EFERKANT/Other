import 'dart:async';

import 'protocol.dart';
import 'registry.dart';
import 'scale.dart';

/// Bir Bluetooth cihazıyla bağlantı; uygulama katmanı platform eklentisiyle
/// gerçekler, testte sahtesi kullanılır (KHV-ARC-007).
abstract interface class BleLink {
  /// Bağlantı durumu: `true` bağlı.
  Stream<bool> get connected;

  /// Cihaza bağlanır.
  Future<void> connect();

  /// Karakteristik bildirimlerine abone olur.
  Stream<List<int>> notifications(String service, String characteristic);

  /// Karakteristiğe yazar.
  Future<void> write(String service, String characteristic, List<int> value);

  /// Bağlantıyı keser.
  Future<void> disconnect();
}

/// Bluetooth terazi (KHV-ARC-007, KHV-FR-SCL-002, SCL-003, SCL-010).
///
/// Tanınan ve desteklenen modelde dara ve zamanlayıcı komutları teraziye
/// gönderilir. Dinleme modunda eşleşen (tanınmayan) cihaza hiçbir şey
/// yazılmaz; dara yazılımla, son okumayı sıfır kabul ederek alınır.
class BleScale implements Scale {
  /// Eşleşme sonucu, protokol ve bağlantıyla bir terazi oluşturur.
  BleScale({
    required this.match,
    required this.protocol,
    required this._link,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Taramadaki sınıflandırma.
  final ScaleMatch match;

  /// Ağırlığı çözen açık protokol.
  final ScaleProtocol protocol;

  final BleLink _link;
  final DateTime Function() _clock;
  final _weights = StreamController<WeightReading>.broadcast();
  final _connection = StreamController<ScaleConnection>.broadcast();
  final _subs = <StreamSubscription<Object?>>[];
  ScaleConnection _status = ScaleConnection.disconnected;
  WeightReading? _latest;
  double? _raw;
  double _softwareTare = 0;
  bool _started = false;

  @override
  String get name => switch (match) {
    KnownScale(:final scale) => scale.displayName,
    UnknownDevice(:final advertisedName) => '$advertisedName (dinleme modu)',
  };

  @override
  bool get isManual => false;

  /// Dara her zaman alınabilir: komutla ya da yazılımla.
  @override
  bool get supportsTare => true;

  @override
  bool get supportsTimer => ScaleRegistry.canWrite(match, forTimer: true);

  bool get _canTare => ScaleRegistry.canWrite(match, forTimer: false);

  @override
  ScaleConnection get status => _status;

  @override
  WeightReading? get latest => _latest;

  @override
  Stream<WeightReading> get weights => _weights.stream;

  @override
  Stream<ScaleConnection> get connection => _connection.stream;

  void _setStatus(ScaleConnection s) {
    if (_status == s || _connection.isClosed) return;
    _status = s;
    _connection.add(s);
  }

  /// Bağlanır ve ağırlık bildirimlerini dinlemeye başlar. İkinci çağrı bir
  /// şey yapmaz.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _setStatus(ScaleConnection.connecting);
    _subs.add(
      _link.connected.listen(
        (c) => _setStatus(
          c ? ScaleConnection.connected : ScaleConnection.disconnected,
        ),
      ),
    );
    try {
      await _link.connect();
    } on Object {
      _setStatus(ScaleConnection.disconnected);
      return;
    }
    _setStatus(ScaleConnection.connected);
    _subs.add(
      _link
          .notifications(protocol.serviceUuid, protocol.weightCharacteristic)
          .listen(_onPacket, onError: (_) {}),
    );
  }

  void _onPacket(List<int> packet) {
    final grams = protocol.decodeGrams(packet);
    if (grams == null) return;
    _raw = grams;
    _emit();
  }

  void _emit() {
    final raw = _raw;
    if (raw == null || _weights.isClosed) return;
    final r = WeightReading(
      ((raw - _softwareTare) * 10).roundToDouble() / 10,
      _clock(),
    );
    _latest = r;
    _weights.add(r);
  }

  Future<void> _send(ScaleCommand c) async {
    final characteristic = protocol.commandCharacteristic;
    final bytes = protocol.command(c);
    if (characteristic == null || bytes == null) return;
    await _link.write(protocol.serviceUuid, characteristic, bytes);
  }

  @override
  Future<void> tare() async {
    if (_canTare) {
      _softwareTare = 0;
      await _send(ScaleCommand.tare);
    } else {
      _softwareTare = _raw ?? 0;
      _emit();
    }
  }

  @override
  Future<void> startTimer() async {
    if (supportsTimer) await _send(ScaleCommand.startTimer);
  }

  @override
  Future<void> stopTimer() async {
    if (supportsTimer) await _send(ScaleCommand.stopTimer);
  }

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    try {
      await _link.disconnect();
    } on Object {
      // Bağlantı zaten kopmuş olabilir.
    }
    await _weights.close();
    await _connection.close();
  }
}
