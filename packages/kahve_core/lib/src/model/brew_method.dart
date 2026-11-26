/// Uygulamanın desteklediği dokuz demleme yöntemi (Bölüm 4).
enum BrewMethod {
  /// V60 ve benzeri konik pour over araçları.
  v60('v60', MethodCategory.pourOver),

  /// Chemex (kalın filtreli pour over).
  chemex('chemex', MethodCategory.pourOver),

  /// French Press (immersion).
  frenchPress('french_press', MethodCategory.immersion),

  /// AeroPress.
  aeropress('aeropress', MethodCategory.immersion),

  /// Elektrikli filtre kahve makinesi.
  dripMachine('drip_machine', MethodCategory.pourOver),

  /// Moka pot (ocak üstü basınçlı demleme).
  mokaPot('moka_pot', MethodCategory.pressure),

  /// Yarı otomatik espresso makinesi.
  espresso('espresso', MethodCategory.pressure),

  /// Cezve veya Türk kahve makinesi.
  turkish('turkish', MethodCategory.turkish),

  /// Cold brew (soğuk demleme).
  coldBrew('cold_brew', MethodCategory.coldBrew);

  const BrewMethod(this.id, this.category);

  /// İçerik dosyalarında kullanılan kalıcı kimlik.
  final String id;

  /// Yöntemin ait olduğu kategori.
  final MethodCategory category;

  /// [id] değerinden yöntemi bulur, bulunamazsa `null` döner.
  static BrewMethod? tryParse(String id) {
    for (final m in values) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// [id] değerinden yöntemi bulur, bulunamazsa [FormatException] fırlatır.
  static BrewMethod parse(String id) =>
      tryParse(id) ?? (throw FormatException('Bilinmeyen yöntem: $id'));

  /// Yöntemin tarifi doz/çıktı ağırlığı üzerinden tanımlanıyorsa `true`.
  bool get isEspresso => this == espresso;

  /// Yöntemin tarifi fincan sayısı üzerinden tanımlanıyorsa `true`.
  bool get isCupBased => this == turkish;

  /// Yöntem kağıt filtre durulama adımı içeriyorsa `true`.
  bool get usesPaperFilter =>
      this == v60 || this == chemex || this == aeropress || this == dripMachine;
}

/// Yöntem kategorileri (Bölüm 9, Yöntem varlığı).
enum MethodCategory {
  /// Pour over ve damlatma yöntemleri.
  pourOver,

  /// Demleme süresince kahve ile suyun temasta kaldığı yöntemler.
  immersion,

  /// Basınçlı yöntemler.
  pressure,

  /// Türk kahvesi.
  turkish,

  /// Soğuk demleme.
  coldBrew,
}
