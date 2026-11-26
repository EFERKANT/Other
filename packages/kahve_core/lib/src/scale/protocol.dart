import 'registry.dart';

/// Teraziye gönderilebilecek komutlar (KHV-FR-SCL-010).
enum ScaleCommand {
  /// Dara.
  tare,

  /// Zamanlayıcıyı başlat.
  startTimer,

  /// Zamanlayıcıyı durdur.
  stopTimer,

  /// Zamanlayıcıyı sıfırla.
  resetTimer,
}

/// Açık lisanslı bir terazi protokolünün sürücüsü (KHV-FR-SCL-001,
/// SCL-003). Yalnız üreticinin yayımladığı protokoller buraya girer;
/// tersine mühendislikle elde edilen protokoller giremez.
abstract interface class ScaleProtocol {
  /// Protokol kimliği ([SupportedScale.protocol] ile eşleşir).
  String get id;

  /// Lisans ve belge referansı (KHV-NFR-045).
  String get licenseRef;

  /// Ağırlık verisinin servis UUID'si.
  String get serviceUuid;

  /// Ağırlık bildirimlerinin karakteristik UUID'si.
  String get weightCharacteristic;

  /// Komut karakteristiği; komut desteklenmiyorsa `null`.
  String? get commandCharacteristic;

  /// Bildirim paketinden ağırlığı (g) çözer. Paket bu protokole ait değilse,
  /// bozuksa veya ağırlık paketi değilse `null` döner.
  double? decodeGrams(List<int> packet);

  /// Komut paketini üretir; protokol komutu desteklemiyorsa `null`.
  List<int>? command(ScaleCommand command);
}

/// Uygulamanın bildiği açık lisanslı protokoller; dinleme modu bunları
/// sırayla dener (KHV-FR-SCL-003).
const openScaleProtocols = <ScaleProtocol>[BookooProtocol()];

/// Kimliğe göre protokol; bilinmiyorsa `null`.
ScaleProtocol? scaleProtocolById(String id) {
  for (final p in openScaleProtocols) {
    if (p.id == id) return p;
  }
  return null;
}

/// BOOKOO Themis Mini ve Ultra açık BLE protokolü (KB-028).
///
/// Kaynak: üreticinin MIT lisanslı belgesi,
/// github.com/BooKooCode/OpenSource, `bookoo_mini_scale/protocols.md` ve
/// `bookoo_ultra_scale/protocols.md` (son güncelleme 2026-11-17).
/// Ağırlık paketi 20 bayttır: `03 0B`, 3 bayt milisaniye, birim, işaret,
/// 3 bayt ağırlık x 100 (büyük uçlu), ..., XOR sağlaması.
class BookooProtocol implements ScaleProtocol {
  /// Protokol sürücüsünü oluşturur.
  const BookooProtocol();

  static const _product = 0x03;
  static const _typeCommand = 0x0A;
  static const _typeWeight = 0x0B;
  static const _minus = 0x2D; // ASCII '-'
  static const _ounce = 0x02;
  static const _gramsPerOunce = 28.349523125;

  @override
  String get id => 'bookoo';

  @override
  String get licenseRef =>
      'MIT, github.com/BooKooCode/OpenSource (protocols.md, 2026-11-17)';

  @override
  String get serviceUuid => normalizeUuid('0FFE');

  @override
  String get weightCharacteristic => normalizeUuid('FF11');

  @override
  String? get commandCharacteristic => normalizeUuid('FF12');

  static int _xor(Iterable<int> bytes) => bytes.fold(0, (a, b) => a ^ b);

  @override
  double? decodeGrams(List<int> p) {
    if (p.length != 20 || p[0] != _product || p[1] != _typeWeight) {
      return null;
    }
    if (_xor(p.take(19)) != p[19]) return null;
    final magnitude = (p[7] << 16 | p[8] << 8 | p[9]) / 100;
    final signed = p[6] == _minus ? -magnitude : magnitude;
    final grams = p[5] == _ounce ? signed * _gramsPerOunce : signed;
    return (grams * 100).roundToDouble() / 100;
  }

  @override
  List<int>? command(ScaleCommand command) {
    final code = switch (command) {
      ScaleCommand.tare => 0x01,
      ScaleCommand.startTimer => 0x04,
      ScaleCommand.stopTimer => 0x05,
      ScaleCommand.resetTimer => 0x06,
    };
    final body = [_product, _typeCommand, code, 0x00, 0x00];
    return [...body, _xor(body)];
  }
}
