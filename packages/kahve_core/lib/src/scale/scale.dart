import 'dart:async';

import 'package:meta/meta.dart';

/// Terazinin bağlantı durumu.
enum ScaleConnection {
  /// Bağlı değil.
  disconnected,

  /// Bağlanıyor.
  connecting,

  /// Bağlı ve ağırlık gönderiyor.
  connected,

  /// Elle giriş; fiziksel bağlantı yok (MVP).
  manual,
}

/// Teraziden gelen tek ağırlık okuması.
@immutable
class WeightReading {
  /// Bir okuma oluşturur.
  const WeightReading(this.grams, this.at, {this.stable = true});

  /// Dara sonrası ağırlık (g).
  final double grams;

  /// Okuma anı.
  final DateTime at;

  /// Terazi değeri sabit olarak bildirdiyse `true`.
  final bool stable;

  @override
  String toString() => 'WeightReading($grams g, $at)';
}

/// Ağırlık verisinin uygulamaya sunulduğu ortak terazi arayüzü
/// (KHV-ARC-007): ağırlık akışı, bağlantı durumu, dara ve zamanlayıcı.
///
/// MVP'deki tek gerçekleştirim [ManualScale] (elle giriş). Bluetooth
/// teraziler ikinci sürümde aynı arayüzü gerçekler (Bölüm 15).
abstract interface class Scale {
  /// Kullanıcıya gösterilecek ad.
  String get name;

  /// Elle giriş ise `true`.
  bool get isManual;

  /// Terazi dara komutunu destekliyorsa `true`.
  bool get supportsTare;

  /// Terazi kendi zamanlayıcısını uygulamadan kabul ediyorsa `true`.
  bool get supportsTimer;

  /// Güncel bağlantı durumu.
  ScaleConnection get status;

  /// Son okuma; henüz okuma yoksa `null`.
  WeightReading? get latest;

  /// Ağırlık okumaları.
  Stream<WeightReading> get weights;

  /// Bağlantı durumu değişiklikleri.
  Stream<ScaleConnection> get connection;

  /// Darayı alır (sıfırlar).
  Future<void> tare();

  /// Terazi zamanlayıcısını başlatır; desteklenmiyorsa bir şey yapmaz.
  Future<void> startTimer();

  /// Terazi zamanlayıcısını durdurur; desteklenmiyorsa bir şey yapmaz.
  Future<void> stopTimer();

  /// Kaynakları bırakır.
  Future<void> dispose();
}

/// Elle ağırlık girişi (KHV-ARC-007, MVP). Kullanıcının terazisinde
/// gördüğü değeri girer; değer aynı akıştan yayınlanır.
class ManualScale implements Scale {
  /// Bir elle giriş terazisi oluşturur.
  ManualScale({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final _weights = StreamController<WeightReading>.broadcast();
  final _connection = StreamController<ScaleConnection>.broadcast();
  double _tareOffset = 0;
  double? _raw;
  WeightReading? _latest;

  @override
  String get name => 'Elle giriş';

  @override
  bool get isManual => true;

  @override
  bool get supportsTare => true;

  @override
  bool get supportsTimer => false;

  @override
  ScaleConnection get status => ScaleConnection.manual;

  @override
  WeightReading? get latest => _latest;

  @override
  Stream<WeightReading> get weights => _weights.stream;

  @override
  Stream<ScaleConnection> get connection => _connection.stream;

  /// Terazide görülen değeri girer (g). Dara sonrası değer yayınlanır.
  void enter(double grams) {
    if (grams.isNaN || grams.isInfinite) {
      throw ArgumentError.value(grams, 'grams', 'Geçersiz ağırlık');
    }
    _raw = grams;
    _emit();
  }

  void _emit() {
    final raw = _raw;
    if (raw == null) return;
    final r = WeightReading(
      ((raw - _tareOffset) * 10).roundToDouble() / 10,
      _clock(),
    );
    _latest = r;
    _weights.add(r);
  }

  @override
  Future<void> tare() async {
    _tareOffset = _raw ?? 0;
    _emit();
  }

  @override
  Future<void> startTimer() async {}

  @override
  Future<void> stopTimer() async {}

  @override
  Future<void> dispose() async {
    await _weights.close();
    await _connection.close();
  }
}

/// Ağırlık verisinin tutarlılık durumu (KHV-FR-SCL-005).
enum WeightHealth {
  /// Veri tutarlı; otomatik ilerleme açık.
  ok,

  /// Negatif değer.
  negative,

  /// 1 saniye içinde 500 g'dan fazla değişim.
  jump,

  /// Bağlantı koptu.
  disconnected,
}

/// Tutarsız ağırlık verisinde otomatik ilerlemeyi durduran koruma
/// (KHV-FR-SCL-005). Bir kez bozulan veri, [reset] çağrılana kadar
/// otomatik ilerlemeyi kapalı tutar; adım kullanıcı onayına döner.
class WeightGuard {
  /// Eşiklerle bir koruma oluşturur.
  WeightGuard({
    this.maxJumpG = 500,
    this.window = const Duration(seconds: 1),
    this.negativeToleranceG = 0.5,
  });

  /// Pencere içinde izin verilen en büyük değişim (g).
  final double maxJumpG;

  /// Değişimin ölçüldüğü pencere.
  final Duration window;

  /// Dara titreşimi için küçük negatif değerlere tolerans (g).
  final double negativeToleranceG;

  final _recent = <WeightReading>[];
  WeightHealth _health = WeightHealth.ok;

  /// Güncel durum.
  WeightHealth get health => _health;

  /// Otomatik ilerlemeye izin var mı.
  bool get autoAdvanceAllowed => _health == WeightHealth.ok;

  /// Okumayı değerlendirir ve güncel durumu döndürür.
  WeightHealth feed(WeightReading r) {
    if (_health != WeightHealth.ok) return _health;
    if (r.grams < -negativeToleranceG) return _health = WeightHealth.negative;
    _recent
      ..removeWhere((p) => r.at.difference(p.at) > window)
      ..add(r);
    for (final p in _recent) {
      if ((r.grams - p.grams).abs() > maxJumpG) {
        return _health = WeightHealth.jump;
      }
    }
    return _health;
  }

  /// Bağlantı değişikliğini işler; kopma otomatik ilerlemeyi durdurur.
  WeightHealth onConnection(ScaleConnection c) {
    if (c == ScaleConnection.disconnected && _health == WeightHealth.ok) {
      _health = WeightHealth.disconnected;
    }
    return _health;
  }

  /// Kullanıcı onayından sonra korumayı sıfırlar.
  void reset() {
    _recent.clear();
    _health = WeightHealth.ok;
  }
}
