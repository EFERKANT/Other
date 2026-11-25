import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

/// Arayüz metinleri ve simgeler (Türkçe, KHV-NFR-010).
String methodName(BrewMethod m) => switch (m) {
  BrewMethod.v60 => 'V60 / Pour over',
  BrewMethod.chemex => 'Chemex',
  BrewMethod.frenchPress => 'French Press',
  BrewMethod.aeropress => 'AeroPress',
  BrewMethod.dripMachine => 'Filtre kahve makinesi',
  BrewMethod.mokaPot => 'Moka pot',
  BrewMethod.espresso => 'Espresso',
  BrewMethod.turkish => 'Türk kahvesi',
  BrewMethod.coldBrew => 'Cold brew',
};

/// Kurulumdaki ekipman görselleri yerine kullanılan simgeler (KHV-HMI-016).
IconData methodIcon(BrewMethod m) => switch (m) {
  BrewMethod.v60 => Icons.filter_alt_outlined,
  BrewMethod.chemex => Icons.hourglass_bottom,
  BrewMethod.frenchPress => Icons.coffee_maker_outlined,
  BrewMethod.aeropress => Icons.compress,
  BrewMethod.dripMachine => Icons.coffee_maker,
  BrewMethod.mokaPot => Icons.local_fire_department_outlined,
  BrewMethod.espresso => Icons.coffee,
  BrewMethod.turkish => Icons.emoji_food_beverage_outlined,
  BrewMethod.coldBrew => Icons.ac_unit,
};

String grinderName(GrinderType g) => switch (g) {
  GrinderType.none => 'Yok, hazır öğütülmüş',
  GrinderType.blade => 'Bıçaklı (blade)',
  GrinderType.handBurr => 'El burr grinder',
  GrinderType.electricBurr => 'Elektrikli burr grinder',
};

String kettleName(KettleType k) => switch (k) {
  KettleType.standard => 'Standart',
  KettleType.gooseneck => 'Gooseneck',
  KettleType.temperatureControlled => 'Sıcaklık ayarlı',
};

String profileName(UserProfile p) => switch (p) {
  UserProfile.beginner => 'P1 Yeni başlayan',
  UserProfile.enthusiast => 'P2 Meraklı ev baristası',
  UserProfile.espresso => 'P3 Espresso kullanıcısı',
  UserProfile.turkish => 'P4 Türk kahvesi kullanıcısı',
  UserProfile.shopper => 'P5 Ekipman alacak kullanıcı',
};

String tasteNoteName(TasteNote n) => switch (n) {
  TasteNote.sour => 'Ekşi',
  TasteNote.bitter => 'Acı',
  TasteNote.watery => 'Sulu',
  TasteNote.strong => 'Yoğun',
  TasteNote.flat => 'Düz / aromasız',
  TasteNote.balanced => 'Dengeli',
};

/// Günlük hayattan örnekler (KHV-HMI-014).
String tasteNoteExample(TasteNote n) => switch (n) {
  TasteNote.sour => 'Limon sıkılmış su gibi keskin, çabuk biten',
  TasteNote.bitter => 'Fazla demlenmiş çay gibi kurutan',
  TasteNote.watery => 'Sulandırılmış meyve suyu gibi ince',
  TasteNote.strong => 'Koyu şurup gibi ağır',
  TasteNote.flat => 'Karton veya bayat ekmek gibi',
  TasteNote.balanced => 'Tatlı, temiz ve dengeli',
};

/// Renk yanında simge (KHV-HMI-024).
IconData tasteNoteIcon(TasteNote n) => switch (n) {
  TasteNote.sour => Icons.water_drop_outlined,
  TasteNote.bitter => Icons.local_fire_department_outlined,
  TasteNote.watery => Icons.opacity,
  TasteNote.strong => Icons.fitness_center,
  TasteNote.flat => Icons.crop_square,
  TasteNote.balanced => Icons.check_circle_outline,
};

String observationName(ProcessObservation o) => switch (o) {
  ProcessObservation.slowDrawdown => 'Süzülme çok uzun sürdü / filtre tıkandı',
  ProcessObservation.shotFast => "Shot 20 sn'den kısa aktı",
  ProcessObservation.shotSlow => "Shot 35 sn'den uzun aktı",
  ProcessObservation.noFoam => 'Köpük olmadı',
  ProcessObservation.overflow => 'Kahve taştı',
  ProcessObservation.burnt => 'Yanık ve metalik tat',
  ProcessObservation.offWaterTaste => 'Klor, metal veya kireç tadı',
};

/// Yönteme göre kullanıcının işaretleyebileceği gözlemler.
List<ProcessObservation> observationsFor(BrewMethod m) => [
  if (m == BrewMethod.turkish) ...[
    ProcessObservation.noFoam,
    ProcessObservation.overflow,
  ],
  if (m == BrewMethod.mokaPot) ProcessObservation.burnt,
  if (m == BrewMethod.v60 || m == BrewMethod.chemex)
    ProcessObservation.slowDrawdown,
  ProcessObservation.offWaterTaste,
];

String symptomName(Symptom s) => switch (s) {
  Symptom.underExtraction => 'Ekşi: under-extraction',
  Symptom.overExtraction => 'Acı: over-extraction',
  Symptom.unevenExtraction => 'Hem ekşi hem acı: düzensiz extraction',
  Symptom.weak => 'Sulu ama dengeli: düşük strength',
  Symptom.strong => 'Yoğun ama dengeli: yüksek strength',
  Symptom.stale => 'Düz ve aromasız: bayat çekirdek',
  Symptom.waterQuality => 'Su kalitesi',
  Symptom.slowDrawdown => 'Süzülme çok yavaş',
  Symptom.shotFast => 'Shot çok hızlı',
  Symptom.shotSlow => 'Shot çok yavaş',
  Symptom.turkishNoFoam => 'Köpüksüz Türk kahvesi',
  Symptom.turkishOverflow => 'Taşan Türk kahvesi',
  Symptom.mokaBurnt => 'Yanık moka pot',
};

String rootCauseName(RootCauseCheck c) => switch (c) {
  RootCauseCheck.grinder =>
    'Öğütücü: bıçaklı öğütücü homojen parçacık üretmez. Burr grinder '
        'tutarlılığı en çok artıran yatırımdır.',
  RootCauseCheck.water =>
    'Su: klor kokulu şebeke suyu yerine filtrelenmiş veya düşük-orta '
        'mineralli şişe suyu kullanın.',
  RootCauseCheck.beanFreshness =>
    'Çekirdek: kavurma tarihi bilinen, 30 günden taze çekirdek kullanın ve '
        'demlemeden hemen önce öğütün.',
  RootCauseCheck.scale =>
    'Tartım: kaşık ölçüsü belirgin sapar. 0,1 g hassasiyetli terazi '
        'tekrarlanabilirliği sağlar.',
};

String purchaseName(PurchaseItem p) => switch (p) {
  PurchaseItem.freshBeans => 'Kavurma tarihi yazılı taze çekirdek',
  PurchaseItem.burrGrinder => 'Burr grinder (el veya elektrikli)',
  PurchaseItem.scale => '0,1 g hassasiyetli, zamanlayıcılı terazi',
  PurchaseItem.gooseneckKettle => 'Gooseneck kettle',
  PurchaseItem.brewer => 'Demleme aracı (V60, AeroPress, French Press)',
  PurchaseItem.waterFilter => 'Su filtresi veya uygun şişe suyu',
  PurchaseItem.espressoGrinder =>
    'Espresso grinder: bütçesi makineden düşük tutulmamalı',
};

String safetyText(SafetyWarning w) => switch (w) {
  SafetyWarning.hotWater => 'Sıcak su: dökerken elinizi ve kabı sabit tutun.',
  SafetyWarning.steamWand => 'Buhar çubuğu: kullanım sonrası çok sıcaktır.',
  SafetyWarning.pressureValve =>
    'Basınç valfi: suyu valfin altında tutun, valfi kapatmayın.',
  SafetyWarning.stove =>
    'Ocak: sapı ocaktan uzağa çevirin, başından ayrılmayın.',
};

String roastLevelName(String level) => switch (level) {
  'light' => 'Açık',
  'dark' => 'Koyu',
  _ => 'Orta',
};
