import 'package:meta/meta.dart';

import 'brew_method.dart';

/// Bir rehber mod adımının nasıl biteceği (KHV-HMI-003).
enum StepTrigger {
  /// Adım süresi dolunca kendiliğinden geçer.
  time,

  /// Hedef kümülatif ağırlığa ulaşılınca geçer. Bluetooth terazi olmadan
  /// ağırlık okunamadığından süre verilmişse süreyle, verilmemişse kullanıcı
  /// onayıyla ilerler.
  weight,

  /// Beklenen gözlem gerçekleşince kullanıcı onayıyla geçer
  /// (ör. "kenarlarda köpük kabarınca").
  confirm,
}

/// Adımda gösterilecek emniyet uyarısı türü (KHV-CNT-006, KHV-HMI-021).
enum SafetyWarning {
  /// Sıcak su.
  hotWater,

  /// Buhar çubuğu.
  steamWand,

  /// Moka pot basınç valfi.
  pressureValve,

  /// Ocak kullanımı.
  stove,
}

/// Tarifin sıralı bir adımı (Bölüm 9, Adım varlığı).
@immutable
class BrewStep {
  /// Bir adım oluşturur.
  const BrewStep({
    required this.title,
    required this.trigger,
    this.description = '',
    this.targetWaterG,
    this.durationS,
    this.observation,
    this.safety,
  });

  /// JSON'dan okur.
  factory BrewStep.fromJson(Map<String, Object?> json) => BrewStep(
    title: json['title']! as String,
    description: json['description'] as String? ?? '',
    trigger: StepTrigger.values.byName(json['trigger']! as String),
    targetWaterG: (json['targetWaterG'] as num?)?.toDouble(),
    durationS: (json['durationS'] as num?)?.toInt(),
    observation: json['observation'] as String?,
    safety: json['safety'] == null
        ? null
        : SafetyWarning.values.byName(json['safety']! as String),
  );

  /// Kısa adım komutu (ör. "Bloom").
  final String title;

  /// Açıklama.
  final String description;

  /// Geçiş tetikleyicisi.
  final StepTrigger trigger;

  /// Adım sonunda ulaşılacak kümülatif su ağırlığı (g).
  final double? targetWaterG;

  /// Adım süresi (sn).
  final int? durationS;

  /// Onay gerektiren adımda beklenen gözlem.
  final String? observation;

  /// Adıma bağlı emniyet uyarısı.
  final SafetyWarning? safety;

  /// Süreyle kendiliğinden geçen bir adımsa `true`.
  bool get advancesByTime =>
      durationS != null &&
      (trigger == StepTrigger.time || trigger == StepTrigger.weight);

  /// Değiştirilmiş bir kopya döndürür.
  BrewStep copyWith({double? targetWaterG, int? durationS}) => BrewStep(
    title: title,
    description: description,
    trigger: trigger,
    targetWaterG: targetWaterG ?? this.targetWaterG,
    durationS: durationS ?? this.durationS,
    observation: observation,
    safety: safety,
  );

  /// JSON'a yazar.
  Map<String, Object?> toJson() => {
    'title': title,
    if (description.isNotEmpty) 'description': description,
    'trigger': trigger.name,
    if (targetWaterG != null) 'targetWaterG': targetWaterG,
    if (durationS != null) 'durationS': durationS,
    if (observation != null) 'observation': observation,
    if (safety != null) 'safety': safety!.name,
  };

  @override
  bool operator ==(Object other) =>
      other is BrewStep &&
      other.title == title &&
      other.description == description &&
      other.trigger == trigger &&
      other.targetWaterG == targetWaterG &&
      other.durationS == durationS &&
      other.observation == observation &&
      other.safety == safety;

  @override
  int get hashCode => Object.hash(
    title,
    description,
    trigger,
    targetWaterG,
    durationS,
    observation,
    safety,
  );
}

/// Tarifin sahibi.
enum RecipeOwner {
  /// İçerik yönetiminden gelen sistem tarifi; düzenlenemez
  /// (KHV-FR-RCP-013).
  system,

  /// Kullanıcının kendi tarifi.
  user,
}

/// Öğütme ayarı: yönteme göre metin tanımı, isteğe bağlı kullanıcı
/// öğütücüsündeki kademe ve dial-in düzeltmelerinden gelen göreli kayma.
@immutable
class GrindSetting {
  /// Bir öğütme ayarı oluşturur.
  const GrindSetting(this.label, {this.clicks, this.offset = 0});

  /// JSON'dan okur.
  factory GrindSetting.fromJson(Map<String, Object?> json) => GrindSetting(
    json['label']! as String,
    clicks: (json['clicks'] as num?)?.toInt(),
    offset: (json['offset'] as num?)?.toInt() ?? 0,
  );

  /// İnsan okunur tanım (ör. "Orta-ince").
  final String label;

  /// Kullanıcının öğütücüsündeki kademe (varsa).
  final int? clicks;

  /// Kademe bilinmiyorsa başlangıç tanımına göre kayma; negatif değer
  /// daha ince, pozitif değer daha kalın öğütme demektir.
  final int offset;

  /// [steps] kademe kalınlaştırılmış (negatifse inceltilmiş) kopya döndürür.
  GrindSetting adjust(int steps) => clicks != null
      ? GrindSetting(label, clicks: clicks! + steps, offset: offset)
      : GrindSetting(label, offset: offset + steps);

  /// JSON'a yazar.
  Map<String, Object?> toJson() => {
    'label': label,
    if (clicks != null) 'clicks': clicks,
    if (offset != 0) 'offset': offset,
  };

  @override
  bool operator ==(Object other) =>
      other is GrindSetting &&
      other.label == label &&
      other.clicks == clicks &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(label, clicks, offset);
}

/// Bir tarif (Bölüm 9, Tarif varlığı; KHV-ARC-001).
///
/// Oran [ratio] "1 g kahveye düşen su (g)" olarak tutulur: 1:16 için 16.
/// Espresso'da [waterG] çıktı (fincandaki) ağırlığıdır.
@immutable
class Recipe {
  /// Bir tarif oluşturur.
  const Recipe({
    required this.id,
    required this.method,
    required this.name,
    required this.coffeeG,
    required this.waterG,
    required this.grind,
    required this.steps,
    this.version = 1,
    this.sourceRecipeId,
    this.owner = RecipeOwner.system,
    this.temperatureC,
    this.targetTimeS,
    this.targetTimeMaxS,
    this.cups,
    this.notes = '',
    this.source = '',
    this.favorite = false,
  });

  /// JSON'dan okur.
  factory Recipe.fromJson(Map<String, Object?> json) => Recipe(
    id: json['id']! as String,
    version: (json['version'] as num?)?.toInt() ?? 1,
    sourceRecipeId: json['sourceRecipeId'] as String?,
    method: BrewMethod.parse(json['method']! as String),
    name: json['name']! as String,
    owner: json['owner'] == null
        ? RecipeOwner.system
        : RecipeOwner.values.byName(json['owner']! as String),
    coffeeG: (json['coffeeG']! as num).toDouble(),
    waterG: (json['waterG']! as num).toDouble(),
    grind: GrindSetting.fromJson(
      (json['grind']! as Map).cast<String, Object?>(),
    ),
    temperatureC: (json['temperatureC'] as num?)?.toDouble(),
    targetTimeS: (json['targetTimeS'] as num?)?.toInt(),
    targetTimeMaxS: (json['targetTimeMaxS'] as num?)?.toInt(),
    cups: (json['cups'] as num?)?.toInt(),
    notes: json['notes'] as String? ?? '',
    source: json['source'] as String? ?? '',
    favorite: json['favorite'] as bool? ?? false,
    steps: [
      for (final s in json['steps']! as List<Object?>)
        BrewStep.fromJson((s! as Map).cast<String, Object?>()),
    ],
  );

  /// Evrensel benzersiz kimlik.
  final String id;

  /// Sürüm numarası; her düzenlemede artar.
  final int version;

  /// Kopyalanan veya içe aktarılan tarifin kaynak kimliği
  /// (KHV-FR-SOC-004).
  final String? sourceRecipeId;

  /// Demleme yöntemi.
  final BrewMethod method;

  /// Tarif adı.
  final String name;

  /// Tarifin sahibi.
  final RecipeOwner owner;

  /// Kahve dozu (g).
  final double coffeeG;

  /// Su (g); espresso'da çıktı ağırlığı.
  final double waterG;

  /// Öğütme ayarı.
  final GrindSetting grind;

  /// Hedef su sıcaklığı (°C); oda sıcaklığı/soğuk ise `null`.
  final double? temperatureC;

  /// Hedef toplam süre (sn) veya hedef aralığın alt sınırı.
  final int? targetTimeS;

  /// Hedef süre aralığının üst sınırı (sn).
  final int? targetTimeMaxS;

  /// Fincan bazlı yöntemlerde fincan sayısı.
  final int? cups;

  /// Kullanıcı notu.
  final String notes;

  /// Sayısal değerlerin kaynağı (KHV-CNT-003).
  final String source;

  /// Favori işareti (KHV-FR-RCP-011).
  final bool favorite;

  /// Sıralı adımlar.
  final List<BrewStep> steps;

  /// Su/kahve oranı (1:x için x).
  double get ratio => waterG / coffeeG;

  /// Toplam planlanan adım süresi (sn); süresi olmayan adımlar sayılmaz.
  int get plannedDurationS =>
      steps.fold(0, (sum, s) => sum + (s.durationS ?? 0));

  /// Kullanıcı tarafından düzenlenebilir mi (KHV-FR-RCP-013).
  bool get editable => owner == RecipeOwner.user;

  /// Değiştirilmiş bir kopya döndürür.
  Recipe copyWith({
    String? id,
    int? version,
    String? sourceRecipeId,
    String? name,
    RecipeOwner? owner,
    double? coffeeG,
    double? waterG,
    GrindSetting? grind,
    double? temperatureC,
    int? targetTimeS,
    int? targetTimeMaxS,
    int? cups,
    String? notes,
    bool? favorite,
    List<BrewStep>? steps,
  }) => Recipe(
    id: id ?? this.id,
    version: version ?? this.version,
    sourceRecipeId: sourceRecipeId ?? this.sourceRecipeId,
    method: method,
    name: name ?? this.name,
    owner: owner ?? this.owner,
    coffeeG: coffeeG ?? this.coffeeG,
    waterG: waterG ?? this.waterG,
    grind: grind ?? this.grind,
    temperatureC: temperatureC ?? this.temperatureC,
    targetTimeS: targetTimeS ?? this.targetTimeS,
    targetTimeMaxS: targetTimeMaxS ?? this.targetTimeMaxS,
    cups: cups ?? this.cups,
    notes: notes ?? this.notes,
    source: source,
    favorite: favorite ?? this.favorite,
    steps: steps ?? this.steps,
  );

  /// JSON'a yazar.
  Map<String, Object?> toJson() => {
    'id': id,
    'version': version,
    if (sourceRecipeId != null) 'sourceRecipeId': sourceRecipeId,
    'method': method.id,
    'name': name,
    'owner': owner.name,
    'coffeeG': coffeeG,
    'waterG': waterG,
    'grind': grind.toJson(),
    if (temperatureC != null) 'temperatureC': temperatureC,
    if (targetTimeS != null) 'targetTimeS': targetTimeS,
    if (targetTimeMaxS != null) 'targetTimeMaxS': targetTimeMaxS,
    if (cups != null) 'cups': cups,
    if (notes.isNotEmpty) 'notes': notes,
    if (source.isNotEmpty) 'source': source,
    if (favorite) 'favorite': favorite,
    'steps': [for (final s in steps) s.toJson()],
  };
}
