import 'package:meta/meta.dart';

import '../rules/dial_in.dart';
import '../rules/maintenance.dart';
import '../scale/registry.dart';
import 'brew_method.dart';
import 'recipe.dart';

/// Bir yöntemin editoryal içeriği (KHV-CNT-001).
@immutable
class MethodContent {
  /// Bir yöntem içeriği oluşturur.
  const MethodContent({
    required this.method,
    required this.name,
    required this.summary,
    required this.checklist,
    required this.tips,
    required this.requiredEquipment,
  });

  /// JSON'dan okur.
  factory MethodContent.fromJson(Map<String, Object?> j) => MethodContent(
    method: BrewMethod.parse(j['id']! as String),
    name: j['name']! as String,
    summary: j['summary']! as String,
    checklist: _strings(j['checklist']),
    tips: _strings(j['tips']),
    requiredEquipment: j['requiredEquipment']! as String,
  );

  /// Yöntem.
  final BrewMethod method;

  /// Görünen ad.
  final String name;

  /// Kısa açıklama.
  final String summary;

  /// Hazırlık kontrol listesi (KHV-FR-BRW-001).
  final List<String> checklist;

  /// Püf noktaları.
  final List<String> tips;

  /// Zorunlu ek ekipman açıklaması.
  final String requiredEquipment;
}

/// Sözlük terimi (KHV-FR-HLP-001, KHV-HMI-018).
@immutable
class GlossaryTerm {
  /// Bir terim oluşturur.
  const GlossaryTerm(this.term, this.definition);

  /// JSON'dan okur.
  factory GlossaryTerm.fromJson(Map<String, Object?> j) =>
      GlossaryTerm(j['term']! as String, j['definition']! as String);

  /// Terim.
  final String term;

  /// Kısa açıklama.
  final String definition;
}

/// Ekipman kataloğu kaydı (KHV-FR-EQP-003, KHV-CNT-004).
@immutable
class CatalogModel {
  /// Bir katalog kaydı oluşturur.
  const CatalogModel({
    required this.id,
    required this.category,
    required this.brand,
    required this.model,
    required this.verifiedAt,
    this.methods = const {},
    this.usesFilter = false,
    this.budget = Budget.mid,
    this.notes = '',
  });

  /// JSON'dan okur.
  factory CatalogModel.fromJson(Map<String, Object?> j) => CatalogModel(
    id: j['id']! as String,
    category: j['category']! as String,
    brand: j['brand']! as String,
    model: j['model']! as String,
    verifiedAt: DateTime.parse(j['verifiedAt']! as String),
    methods: {
      for (final m in (j['methods'] as List<Object?>? ?? const []))
        BrewMethod.parse(m! as String),
    },
    usesFilter: j['usesFilter'] as bool? ?? false,
    budget: Budget.values.byName(j['budget'] as String? ?? 'mid'),
    notes: j['notes'] as String? ?? '',
  );

  /// Kimlik.
  final String id;

  /// Kategori kimliği ([EquipmentGuide.id]).
  final String category;

  /// Marka.
  final String brand;

  /// Model.
  final String model;

  /// Son doğrulama tarihi.
  final DateTime verifiedAt;

  /// İlgili yöntemler; boşsa tümü.
  final Set<BrewMethod> methods;

  /// Filtre kullanıyor mu.
  final bool usesFilter;

  /// Bütçe aralığı.
  final Budget budget;

  /// Editoryal not.
  final String notes;

  /// "Marka Model".
  String get displayName => '$brand $model';

  /// Son doğrulamadan bu yana 6 ay geçtiyse `true` (KHV-CNT-004).
  bool isStale(DateTime today) =>
      today.difference(verifiedAt) > const Duration(days: 183);
}

/// Bütçe aralığı (KHV-FR-EQP-001).
enum Budget {
  /// Giriş seviyesi.
  low,

  /// Orta.
  mid,

  /// Üst.
  high,
}

/// Ekipman kategorisi seçim rehberi (Bölüm 5, KHV-FR-EQP-002).
@immutable
class EquipmentGuide {
  /// Bir rehber oluşturur.
  const EquipmentGuide({
    required this.id,
    required this.name,
    required this.lookFor,
    required this.avoid,
    this.methods = const {},
  });

  /// JSON'dan okur.
  factory EquipmentGuide.fromJson(Map<String, Object?> j) => EquipmentGuide(
    id: j['id']! as String,
    name: j['name']! as String,
    lookFor: _strings(j['lookFor']),
    avoid: _strings(j['avoid']),
    methods: {
      for (final m in (j['methods'] as List<Object?>? ?? const []))
        BrewMethod.parse(m! as String),
    },
  );

  /// Kategori kimliği.
  final String id;

  /// Görünen ad.
  final String name;

  /// Dikkat edilecek noktalar.
  final List<String> lookFor;

  /// Kaçınılacak durumlar.
  final List<String> avoid;

  /// İlgili yöntemler; boşsa tümü.
  final Set<BrewMethod> methods;
}

/// Uygulamaya gömülü veya içerik yönetiminden gelen içerik paketi
/// (KHV-NFR-011, KHV-NFR-026, KHV-FR-ADM-005).
@immutable
class ContentBundle {
  /// Bir paket oluşturur.
  const ContentBundle({
    required this.version,
    required this.methods,
    required this.recipes,
    required this.rules,
    required this.glossary,
    required this.guides,
    required this.catalog,
    this.maintenance = const [],
    this.flags = const {},
    this.scales = const [],
  });

  /// JSON'dan okur ve tutarlılığı doğrular.
  factory ContentBundle.fromJson(Map<String, Object?> j) {
    List<Map<String, Object?>> list(String key) => [
      for (final e in (j[key] as List<Object?>? ?? const []))
        (e! as Map).cast<String, Object?>(),
    ];
    final bundle = ContentBundle(
      version: (j['version']! as num).toInt(),
      methods: list('methods').map(MethodContent.fromJson).toList(),
      recipes: list('recipes').map(Recipe.fromJson).toList(),
      rules: list('rules').map(CorrectionRule.fromJson).toList(),
      glossary: list('glossary').map(GlossaryTerm.fromJson).toList(),
      guides: list('guides').map(EquipmentGuide.fromJson).toList(),
      catalog: list('catalog').map(CatalogModel.fromJson).toList(),
      maintenance: list('maintenance')
          .map(MaintenanceTemplate.fromJson)
          .toList(),
      scales: list('scales').map(SupportedScale.fromJson).toList(),
      flags: {
        for (final e
            in ((j['flags'] as Map?)?.cast<String, Object?>() ?? const {})
                .entries)
          e.key: e.value == true,
      },
    );
    final errors = bundle.validate();
    if (errors.isNotEmpty) {
      throw FormatException('İçerik paketi geçersiz: ${errors.join('; ')}');
    }
    return bundle;
  }

  /// İçerik sürüm numarası.
  final int version;

  /// Yöntem içerikleri.
  final List<MethodContent> methods;

  /// Sistem tarifleri.
  final List<Recipe> recipes;

  /// Düzeltme kuralları (KHV-CNT-002).
  final List<CorrectionRule> rules;

  /// Sözlük.
  final List<GlossaryTerm> glossary;

  /// Ekipman rehberleri.
  final List<EquipmentGuide> guides;

  /// Katalog modelleri.
  final List<CatalogModel> catalog;

  /// Bakım şablonları (KHV-FR-ENG-001).
  final List<MaintenanceTemplate> maintenance;

  /// Desteklenen Bluetooth teraziler (KHV-FR-SCL-001).
  final List<SupportedScale> scales;

  /// Uzaktan açılıp kapatılabilen özellik bayrakları (KHV-ARC-006).
  final Map<String, bool> flags;

  /// [name] bayrağı açık mı; tanımsız bayrak [fallback] değerini alır.
  bool flag(String name, {bool fallback = true}) => flags[name] ?? fallback;

  /// Yöntem içeriğini döndürür.
  MethodContent method(BrewMethod m) =>
      methods.firstWhere((c) => c.method == m);

  /// Tutarlılık hatalarını döndürür; boş liste geçerli demektir.
  List<String> validate() {
    final errors = <String>[];
    for (final m in BrewMethod.values) {
      if (!methods.any((c) => c.method == m)) {
        errors.add('Yöntem içeriği eksik: ${m.id}');
      }
      if (!recipes.any((r) => r.method == m)) {
        errors.add('Başlangıç tarifi eksik: ${m.id}');
      }
    }
    final ids = <String>{};
    for (final r in recipes) {
      if (!ids.add(r.id)) errors.add('Yinelenen tarif kimliği: ${r.id}');
    }
    final ruleIds = <String>{};
    for (final r in rules) {
      if (!ruleIds.add(r.id)) errors.add('Yinelenen kural kimliği: ${r.id}');
    }
    for (final s in Symptom.values) {
      if (!rules.any((r) => r.symptom == s && r.tier == 1)) {
        errors.add('İlk düzeltme kuralı eksik: ${s.name}');
      }
    }
    for (final s in scales) {
      errors.addAll(ScaleRegistry.validate(s));
    }
    final guideIds = {for (final g in guides) g.id};
    for (final c in catalog) {
      if (!guideIds.contains(c.category)) {
        errors.add('Bilinmeyen katalog kategorisi: ${c.category}');
      }
    }
    return errors;
  }
}

List<String> _strings(Object? v) => [
  for (final e in (v as List<Object?>? ?? const [])) e! as String,
];
