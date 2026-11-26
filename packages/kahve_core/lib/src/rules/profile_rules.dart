import '../model/brew_method.dart';
import '../model/equipment.dart';

/// Ekipman profiline göre kullanıcı profili atar (KHV-FR-ONB-002,
/// KHV-FR-ONB-005).
///
/// Öncelik: espresso makinesi → P3; yalnız Türk kahvesi → P4; demleme aracı
/// yok → P5; terazi ve burr grinder ile gram bazlı araç → P2; diğerleri → P1.
/// Kurulum atlandığında (boş profil, [skipped] = `true`) P1 atanır.
UserProfile assignProfile(EquipmentProfile e, {bool skipped = false}) {
  if (skipped) return UserProfile.beginner;
  final b = e.brewers;
  if (b.contains(BrewMethod.espresso)) return UserProfile.espresso;
  if (b.isEmpty) return UserProfile.shopper;
  if (b.every((m) => m == BrewMethod.turkish)) return UserProfile.turkish;
  final hasBurr = e.grinder?.isBurr ?? false;
  if (e.scaleConfirmed && hasBurr) return UserProfile.enthusiast;
  return UserProfile.beginner;
}

/// Satın alma önerisi kalemleri (Bölüm 5 öncelik sırası).
enum PurchaseItem {
  /// Taze çekirdek (kavurma tarihi yazılı paket).
  freshBeans,

  /// Burr grinder.
  burrGrinder,

  /// 0,1 g hassasiyetli terazi.
  scale,

  /// Gooseneck kettle.
  gooseneckKettle,

  /// Demleme aracı.
  brewer,

  /// Su filtresi veya uygun şişe suyu.
  waterFilter,

  /// Espresso grinder'ı (makineyle birlikte değerlendirilir).
  espressoGrinder,
}

/// Mevcut ekipmana göre bir sonraki öneriyi döndürür (KHV-FR-EQP-004).
///
/// [usesFreshBeans] kullanıcının kavurma tarihi bilinen çekirdek kullanıp
/// kullanmadığıdır (çekirdek kaydından türetilir). Eksik kalem yoksa `null`.
PurchaseItem? nextPurchase(EquipmentProfile e, {bool usesFreshBeans = false}) {
  final b = e.brewers;
  final grinder = e.grinder;
  if (b.contains(BrewMethod.espresso) && grinder != GrinderType.electricBurr) {
    return PurchaseItem.espressoGrinder;
  }
  if (!usesFreshBeans) return PurchaseItem.freshBeans;
  if (b.contains(BrewMethod.turkish) && b.length == 1) {
    // Türk kahvesinde toz öğütme hazır alınabilir; terazi ve su yeterlidir.
    if (!e.scaleConfirmed) return PurchaseItem.scale;
    return e.hasWaterFilter ? null : PurchaseItem.waterFilter;
  }
  if (grinder == null || !grinder.isBurr) return PurchaseItem.burrGrinder;
  if (!e.scaleConfirmed) return PurchaseItem.scale;
  final pourOver = b.contains(BrewMethod.v60) || b.contains(BrewMethod.chemex);
  if (pourOver && !(e.kettle?.isGooseneck ?? false)) {
    return PurchaseItem.gooseneckKettle;
  }
  if (b.isEmpty) return PurchaseItem.brewer;
  if (!e.hasWaterFilter) return PurchaseItem.waterFilter;
  return null;
}

/// Tarifin gerektirdiği ancak profilde olmayan ekipmanlar
/// (KHV-FR-RCP-007). `null` değerler (henüz sorulmadı) eksik sayılmaz.
Set<MissingEquipment> missingEquipment(BrewMethod m, EquipmentProfile e) => {
  if (!e.brewers.contains(m)) MissingEquipment.brewer,
  if (m == BrewMethod.espresso && e.hasScale == false) MissingEquipment.scale,
  if (m == BrewMethod.espresso && e.grinder != null && !e.grinder!.isBurr)
    MissingEquipment.grinder,
  if ((m == BrewMethod.v60 || m == BrewMethod.chemex) &&
      e.kettle == KettleType.standard)
    MissingEquipment.gooseneckKettle,
};

/// Eksik ekipman türleri.
enum MissingEquipment {
  /// Demleme aracı.
  brewer,

  /// Terazi.
  scale,

  /// Uygun öğütücü.
  grinder,

  /// Gooseneck kettle (önerilir).
  gooseneckKettle,
}
