import 'package:meta/meta.dart';

/// Desteklenen terazinin hukuki dayanağı (KHV-FR-SCL-001, Bölüm 15.1).
/// Tersine mühendislik ile elde edilmiş protokoller bu listede yer alamaz.
enum ScaleSource {
  /// Üreticinin resmi SDK'sı.
  officialSdk,

  /// Üreticinin açık yayımladığı protokol.
  openProtocol,

  /// Üreticinin yazılı izniyle kullanılan protokol.
  manufacturerPermission,
}

/// Bir terazinin Bluetooth reklamından okunan bilgiler.
@immutable
class BleAdvertisement {
  /// Bir reklam kaydı oluşturur.
  const BleAdvertisement({
    required this.name,
    this.serviceUuids = const [],
    this.manufacturerIds = const [],
  });

  /// Yayınlanan ad.
  final String name;

  /// Yayınlanan servis UUID'leri.
  final List<String> serviceUuids;

  /// Üretici verisindeki şirket kimlikleri.
  final List<int> manufacturerIds;
}

/// Desteklenen terazinin Bluetooth parmak izi (KHV-FR-SCL-002).
@immutable
class ScaleFingerprint {
  /// Bir parmak izi oluşturur.
  const ScaleFingerprint({
    this.namePrefixes = const [],
    this.serviceUuids = const [],
    this.manufacturerId,
  });

  /// JSON'dan okur.
  factory ScaleFingerprint.fromJson(Map<String, Object?> j) => ScaleFingerprint(
    namePrefixes: [
      for (final n in (j['namePrefixes'] as List<Object?>? ?? const []))
        n! as String,
    ],
    serviceUuids: [
      for (final u in (j['serviceUuids'] as List<Object?>? ?? const []))
        normalizeUuid(u! as String),
    ],
    manufacturerId: (j['manufacturerId'] as num?)?.toInt(),
  );

  /// Ad önekleri; biri eşleşmeli.
  final List<String> namePrefixes;

  /// Servis UUID'leri; verilmişse biri reklamda bulunmalı.
  final List<String> serviceUuids;

  /// Üretici kimliği; verilmişse reklamda bulunmalı.
  final int? manufacturerId;

  /// Parmak izi en az bir ölçüt içeriyorsa `true`.
  bool get isUsable =>
      namePrefixes.isNotEmpty ||
      serviceUuids.isNotEmpty ||
      manufacturerId != null;

  /// Reklam parmak iziyle eşleşiyor mu: verilen her ölçüt sağlanmalı.
  bool matches(BleAdvertisement ad) {
    if (!isUsable) return false;
    if (namePrefixes.isNotEmpty &&
        !namePrefixes.any(
          (p) => ad.name.toLowerCase().startsWith(p.toLowerCase()),
        )) {
      return false;
    }
    if (serviceUuids.isNotEmpty) {
      final adv = {for (final u in ad.serviceUuids) normalizeUuid(u)};
      if (!serviceUuids.map(normalizeUuid).any(adv.contains)) return false;
    }
    if (manufacturerId != null &&
        !ad.manufacturerIds.contains(manufacturerId)) {
      return false;
    }
    return true;
  }
}

/// Kısa (16 bit) veya uzun UUID'yi küçük harfli 128 bit biçime getirir.
String normalizeUuid(String uuid) {
  final u = uuid.trim().toLowerCase();
  if (RegExp(r'^[0-9a-f]{4}$').hasMatch(u)) {
    return '0000$u-0000-1000-8000-00805f9b34fb';
  }
  return u;
}

/// Desteklenen terazi modeli (KHV-FR-SCL-001).
@immutable
class SupportedScale {
  /// Bir model kaydı oluşturur.
  const SupportedScale({
    required this.id,
    required this.brand,
    required this.model,
    required this.source,
    required this.licenseRef,
    required this.licenseReviewedAt,
    required this.protocol,
    required this.fingerprint,
    this.supportsTare = false,
    this.supportsTimer = false,
    this.platforms = const {'android', 'ios'},
  });

  /// JSON'dan okur.
  factory SupportedScale.fromJson(Map<String, Object?> j) => SupportedScale(
    id: j['id']! as String,
    brand: j['brand']! as String,
    model: j['model']! as String,
    source: ScaleSource.values.byName(j['source']! as String),
    licenseRef: j['licenseRef']! as String,
    licenseReviewedAt: DateTime.parse(j['licenseReviewedAt']! as String),
    protocol: j['protocol']! as String,
    fingerprint: ScaleFingerprint.fromJson(
      (j['fingerprint']! as Map).cast<String, Object?>(),
    ),
    supportsTare: j['supportsTare'] as bool? ?? false,
    supportsTimer: j['supportsTimer'] as bool? ?? false,
    platforms: {
      for (final p in (j['platforms'] as List<Object?>? ?? ['android', 'ios']))
        p! as String,
    },
  );

  /// Kimlik.
  final String id;

  /// Marka (mağaza metinlerinde yalnız lisans/izin kapsamında,
  /// KHV-NFR-045).
  final String brand;

  /// Model.
  final String model;

  /// Hukuki dayanak.
  final ScaleSource source;

  /// Lisans, protokol belgesi veya izin yazısı referansı (KHV-NFR-045).
  final String licenseRef;

  /// Lisans incelemesinin kayıt tarihi (KHV-NFR-045).
  final DateTime licenseReviewedAt;

  /// Uygulamadaki protokol sürücüsünün kimliği.
  final String protocol;

  /// Bluetooth parmak izi.
  final ScaleFingerprint fingerprint;

  /// Dara komutu destekleniyor mu.
  final bool supportsTare;

  /// Zamanlayıcı komutu destekleniyor mu.
  final bool supportsTimer;

  /// Desteklenen platformlar (SDK tek platformlu olabilir).
  final Set<String> platforms;

  /// "Marka Model".
  String get displayName => '$brand $model';
}

/// Taramada bulunan cihazın sınıflandırması.
sealed class ScaleMatch {
  const ScaleMatch();
}

/// Desteklenen listede, parmak iziyle tanındı (KHV-FR-SCL-002).
final class KnownScale extends ScaleMatch {
  /// Bir eşleşme oluşturur.
  const KnownScale(this.scale);

  /// Eşleşen model.
  final SupportedScale scale;
}

/// Tanınmayan cihaz (KHV-FR-SCL-003, SCL-006).
final class UnknownDevice extends ScaleMatch {
  /// Bir kayıt oluşturur.
  const UnknownDevice(this.advertisedName);

  /// Cihazın yayınladığı ad; destek talebinde yalnız bu gönderilir.
  final String advertisedName;
}

/// Desteklenen teraziler kaydı (KHV-FR-SCL-001, SCL-002, SCL-010).
class ScaleRegistry {
  /// Model listesiyle bir kayıt oluşturur. Geçersiz kayıtlar elenir.
  ScaleRegistry(Iterable<SupportedScale> scales)
    : scales = List.unmodifiable(scales.where((s) => validate(s).isEmpty));

  /// Geçerli desteklenen modeller.
  final List<SupportedScale> scales;

  /// Kaydın desteklenen listeye girme koşullarını denetler
  /// (KHV-FR-SCL-001, KHV-NFR-045). Hata yoksa boş liste.
  static List<String> validate(SupportedScale s) => [
    if (s.licenseRef.trim().isEmpty)
      '${s.id}: lisans/protokol/izin referansı yok',
    if (!s.fingerprint.isUsable) '${s.id}: parmak izi boş',
    if (s.protocol.trim().isEmpty) '${s.id}: protokol sürücüsü yok',
  ];

  /// Reklamı sınıflandırır (KHV-FR-SCL-002).
  ScaleMatch classify(BleAdvertisement ad, {String? platform}) {
    for (final s in scales) {
      if (platform != null && !s.platforms.contains(platform)) continue;
      if (s.fingerprint.matches(ad)) return KnownScale(s);
    }
    return UnknownDevice(ad.name);
  }

  /// Cihaza yazma komutu (dara, zamanlayıcı) gönderilebilir mi
  /// (KHV-FR-SCL-010): yalnız parmak iziyle tanınan, desteklenen
  /// modellerde ve model komutu destekliyorsa.
  static bool canWrite(ScaleMatch m, {required bool forTimer}) => switch (m) {
    KnownScale(:final scale) =>
      forTimer ? scale.supportsTimer : scale.supportsTare,
    UnknownDevice() => false,
  };
}

/// Tanınmayan cihazda dinleme modunda eşleşme teyidi (KHV-FR-SCL-003).
///
/// Yalnız açık lisanslı protokoller denenir ve cihaza hiçbir şey yazılmaz.
/// Eşleşme, uygulamanın gösterdiği değerin terazi ekranındaki değerle aynı
/// olduğunu kullanıcının onaylamasıyla kesinleşir.
class ListenOnlyProbe {
  /// Açık protokollerle bir deneme oluşturur.
  ListenOnlyProbe(this.openProtocols);

  /// Denenecek açık lisanslı protokol kimlikleri.
  final List<String> openProtocols;
  final _candidates = <String, double>{};
  String? _confirmed;

  /// Kullanıcıya teyit için gösterilecek aday değerler.
  Map<String, double> get candidates => Map.unmodifiable(_candidates);

  /// Teyit edilen protokol; teyit yoksa `null`.
  String? get confirmed => _confirmed;

  /// Bir protokolün çözdüğü ağırlığı kaydeder. Açık listede olmayan
  /// protokoller yok sayılır.
  void observe(String protocol, double grams) {
    if (!openProtocols.contains(protocol) || _confirmed != null) return;
    _candidates[protocol] = grams;
  }

  /// Kullanıcı, [protocol] için gösterilen değerin terazi ekranındakiyle
  /// aynı olduğunu onaylar. Aday yoksa `false`.
  bool confirm(String protocol) {
    if (!_candidates.containsKey(protocol)) return false;
    _confirmed = protocol;
    return true;
  }

  /// Kullanıcı değerlerin eşleşmediğini bildirir; adaylar temizlenir.
  void reject() => _candidates.clear();
}
