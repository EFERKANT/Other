import 'package:meta/meta.dart';

import 'brew_method.dart';

/// Öğütücü tipi (KHV-FR-ONB-001).
enum GrinderType {
  /// Öğütücü yok, hazır öğütülmüş kahve kullanılıyor.
  none,

  /// Bıçaklı (blade) öğütücü.
  blade,

  /// El ile çalışan burr grinder.
  handBurr,

  /// Elektrikli burr grinder.
  electricBurr;

  /// Burr grinder ise `true`.
  bool get isBurr => this == handBurr || this == electricBurr;
}

/// Kettle tipi (KHV-FR-ONB-001).
enum KettleType {
  /// Geniş ağızlı standart kettle.
  standard,

  /// Gooseneck (ince akışlı) kettle.
  gooseneck,

  /// Sıcaklık ayarlı gooseneck kettle.
  temperatureControlled;

  /// Derece bazlı sıcaklık ayarı varsa `true`.
  bool get hasTemperatureControl => this == temperatureControlled;

  /// İnce akış kontrolü varsa `true`.
  bool get isGooseneck => this != standard;
}

/// Ekipman kategorileri (Bölüm 5).
enum EquipmentCategory {
  /// Demleme aracı veya makinesi.
  brewer,

  /// Öğütücü.
  grinder,

  /// Terazi.
  scale,

  /// Kettle.
  kettle,

  /// Su filtresi.
  waterFilter,
}

/// Kullanıcının sahip olduğu tek bir ekipman (KHV-FR-ONB-004).
///
/// Adı kullanıcının yazdığı serbest metindir ([freeText]); uygulama marka
/// ve model listesi sunmaz (KB-017).
@immutable
class OwnedEquipment {
  /// Bir ekipman kaydı oluşturur.
  const OwnedEquipment({required this.category, this.method, this.freeText});

  /// JSON'dan okur.
  factory OwnedEquipment.fromJson(Map<String, Object?> json) => OwnedEquipment(
    category: EquipmentCategory.values.byName(json['category']! as String),
    method: json['method'] == null
        ? null
        : BrewMethod.parse(json['method']! as String),
    // Katalog kaldırılmadan önce kaydedilen seçim kaybolmaz.
    freeText: json['freeText'] as String? ?? json['catalogModelId'] as String?,
  );

  /// Ekipmanın kategorisi.
  final EquipmentCategory category;

  /// Demleme aracıysa ilişkili yöntem.
  final BrewMethod? method;

  /// Kullanıcının yazdığı model adı.
  final String? freeText;

  /// JSON'a yazar.
  Map<String, Object?> toJson() => {
    'category': category.name,
    if (method != null) 'method': method!.id,
    if (freeText != null) 'freeText': freeText,
  };

  @override
  bool operator ==(Object other) =>
      other is OwnedEquipment &&
      other.category == category &&
      other.method == method &&
      other.freeText == freeText;

  @override
  int get hashCode => Object.hash(category, method, freeText);
}

/// Kullanıcının ekipman profili (KHV-FR-ONB-001, KHV-HMI-016).
///
/// Öğütücü, terazi ve kettle bilgisi ilgili özellik ilk kullanıldığında
/// sorulduğundan `null` olabilir; `null` "henüz sorulmadı" anlamına gelir.
@immutable
class EquipmentProfile {
  /// Bir ekipman profili oluşturur.
  const EquipmentProfile({
    this.brewers = const {},
    this.grinder,
    this.hasScale,
    this.kettle,
    this.hasWaterFilter = false,
    this.items = const [],
  });

  /// JSON'dan okur.
  factory EquipmentProfile.fromJson(Map<String, Object?> json) =>
      EquipmentProfile(
        brewers: {
          for (final id in (json['brewers'] as List<Object?>? ?? const []))
            BrewMethod.parse(id! as String),
        },
        grinder: json['grinder'] == null
            ? null
            : GrinderType.values.byName(json['grinder']! as String),
        hasScale: json['hasScale'] as bool?,
        kettle: json['kettle'] == null
            ? null
            : KettleType.values.byName(json['kettle']! as String),
        hasWaterFilter: json['hasWaterFilter'] as bool? ?? false,
        items: [
          for (final i in (json['items'] as List<Object?>? ?? const []))
            OwnedEquipment.fromJson((i! as Map).cast<String, Object?>()),
        ],
      );

  /// Boş profil (kurulum atlandığında).
  static const empty = EquipmentProfile();

  /// Sahip olunan demleme araçlarının yöntemleri.
  final Set<BrewMethod> brewers;

  /// Öğütücü tipi; `null` ise henüz sorulmadı.
  final GrinderType? grinder;

  /// Terazi durumu; `null` ise henüz sorulmadı.
  final bool? hasScale;

  /// Kettle tipi; `null` ise henüz sorulmadı.
  final KettleType? kettle;

  /// Su filtresi veya uygun şişe suyu kullanılıyorsa `true`.
  final bool hasWaterFilter;

  /// Marka/model bilgisi girilmiş ekipmanlar.
  final List<OwnedEquipment> items;

  /// Terazi kesin olarak varsa `true`.
  bool get scaleConfirmed => hasScale ?? false;

  /// Sıcaklık ayarlı kettle kesin olarak varsa `true`.
  bool get hasTemperatureKettle => kettle?.hasTemperatureControl ?? false;

  /// Değiştirilmiş bir kopya döndürür.
  EquipmentProfile copyWith({
    Set<BrewMethod>? brewers,
    GrinderType? grinder,
    bool? hasScale,
    KettleType? kettle,
    bool? hasWaterFilter,
    List<OwnedEquipment>? items,
  }) => EquipmentProfile(
    brewers: brewers ?? this.brewers,
    grinder: grinder ?? this.grinder,
    hasScale: hasScale ?? this.hasScale,
    kettle: kettle ?? this.kettle,
    hasWaterFilter: hasWaterFilter ?? this.hasWaterFilter,
    items: items ?? this.items,
  );

  /// JSON'a yazar.
  Map<String, Object?> toJson() => {
    'brewers': [for (final b in brewers) b.id],
    if (grinder != null) 'grinder': grinder!.name,
    if (hasScale != null) 'hasScale': hasScale,
    if (kettle != null) 'kettle': kettle!.name,
    'hasWaterFilter': hasWaterFilter,
    'items': [for (final i in items) i.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is EquipmentProfile &&
      _setEquals(other.brewers, brewers) &&
      other.grinder == grinder &&
      other.hasScale == hasScale &&
      other.kettle == kettle &&
      other.hasWaterFilter == hasWaterFilter &&
      _listEquals(other.items, items);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(brewers),
    grinder,
    hasScale,
    kettle,
    hasWaterFilter,
    Object.hashAll(items),
  );
}

bool _setEquals<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.containsAll(b);

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Bölüm 2'deki kullanıcı profilleri.
enum UserProfile {
  /// P1 Yeni başlayan.
  beginner('P1'),

  /// P2 Meraklı ev baristası.
  enthusiast('P2'),

  /// P3 Espresso kullanıcısı.
  espresso('P3'),

  /// P4 Türk kahvesi kullanıcısı.
  turkish('P4'),

  /// P5 Ekipman alacak kullanıcı.
  shopper('P5');

  const UserProfile(this.code);

  /// Dokümandaki profil kodu (P1-P5).
  final String code;

  /// İleri parametreler (sıcaklık ince ayarı, TDS, extraction) varsayılan
  /// olarak gizlenmeli mi (KHV-HMI-017).
  bool get hidesAdvancedParameters => this == beginner || this == shopper;
}
