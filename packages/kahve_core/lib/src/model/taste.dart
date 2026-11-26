import 'package:meta/meta.dart';

/// Kullanıcıya gösterilen tat seçenekleri (KHV-FR-DIA-001).
enum TasteNote {
  /// Ekşi, keskin.
  sour,

  /// Acı, buruk.
  bitter,

  /// Sulu, zayıf.
  watery,

  /// Çok yoğun, ağır.
  strong,

  /// Düz, aromasız, kartonsu.
  flat,

  /// Dengeli.
  balanced,
}

/// Demleme sırasında veya sonrasında gözlenen süreç olayları.
///
/// Bir kısmı zamanlayıcı verisinden otomatik türetilir
/// ([slowDrawdown], [shotFast], [shotSlow]).
enum ProcessObservation {
  /// Pour over süresi aşıldı veya filtre tıkandı.
  slowDrawdown,

  /// Espresso 20 sn'den kısa aktı.
  shotFast,

  /// Espresso 35 sn'den uzun aktı.
  shotSlow,

  /// Türk kahvesi köpüksüz oldu.
  noFoam,

  /// Türk kahvesi taştı.
  overflow,

  /// Moka pot yanık ve metalik tat verdi.
  burnt,

  /// Klor, metal veya kireç tadı.
  offWaterTaste,
}

/// Demleme sonrası tat değerlendirmesi (KHV-FR-DIA-001, KHV-HMI-013).
///
/// İki boyutlu seçim alanından gelir: [extraction] ekşi (-1) ile acı (+1)
/// arası, [strength] sulu (-1) ile yoğun (+1) arası. Merkez dengelidir.
/// İki boyutlu alanda gösterilemeyen durumlar ayrı bayraklarla tutulur.
@immutable
class TasteAssessment {
  /// Bir tat değerlendirmesi oluşturur.
  TasteAssessment({
    required this.score,
    this.extraction = 0,
    this.strength = 0,
    this.sourAndBitter = false,
    this.flat = false,
    this.observations = const {},
  }) : assert(score >= 1 && score <= 5, 'Puan 1-5 arası olmalı'),
       assert(extraction >= -1 && extraction <= 1),
       assert(strength >= -1 && strength <= 1);

  /// JSON'dan okur.
  factory TasteAssessment.fromJson(Map<String, Object?> json) =>
      TasteAssessment(
        score: (json['score']! as num).toInt(),
        extraction: (json['extraction'] as num?)?.toDouble() ?? 0,
        strength: (json['strength'] as num?)?.toDouble() ?? 0,
        sourAndBitter: json['sourAndBitter'] as bool? ?? false,
        flat: json['flat'] as bool? ?? false,
        observations: {
          for (final o in (json['observations'] as List<Object?>? ?? const []))
            ProcessObservation.values.byName(o! as String),
        },
      );

  /// Bir eksenin "nötr" kabul edildiği mutlak eşik.
  static const neutralBand = 0.25;

  /// 1-5 puan.
  final int score;

  /// Ekşi (-1) ile acı (+1) arası konum.
  final double extraction;

  /// Sulu (-1) ile yoğun (+1) arası konum.
  final double strength;

  /// Hem ekşi hem acı tat (düzensiz extraction belirtisi).
  final bool sourAndBitter;

  /// Düz, kartonsu, aromasız tat.
  final bool flat;

  /// Süreç gözlemleri.
  final Set<ProcessObservation> observations;

  /// Seçimin gösterim için tat notlarına çevrilmiş hali.
  Set<TasteNote> get notes {
    final result = <TasteNote>{};
    if (sourAndBitter) {
      result.addAll([TasteNote.sour, TasteNote.bitter]);
    } else if (extraction <= -neutralBand) {
      result.add(TasteNote.sour);
    } else if (extraction >= neutralBand) {
      result.add(TasteNote.bitter);
    }
    if (strength <= -neutralBand) result.add(TasteNote.watery);
    if (strength >= neutralBand) result.add(TasteNote.strong);
    if (flat) result.add(TasteNote.flat);
    if (result.isEmpty) result.add(TasteNote.balanced);
    return result;
  }

  /// Değerlendirme dengeli ve süreç sorunu yoksa `true`.
  bool get isBalanced =>
      observations.isEmpty &&
      notes.length == 1 &&
      notes.first == TasteNote.balanced;

  /// Ek gözlemlerle bir kopya döndürür.
  TasteAssessment withObservations(Set<ProcessObservation> extra) =>
      TasteAssessment(
        score: score,
        extraction: extraction,
        strength: strength,
        sourAndBitter: sourAndBitter,
        flat: flat,
        observations: {...observations, ...extra},
      );

  /// JSON'a yazar.
  Map<String, Object?> toJson() => {
    'score': score,
    'extraction': extraction,
    'strength': strength,
    if (sourAndBitter) 'sourAndBitter': true,
    if (flat) 'flat': true,
    if (observations.isNotEmpty)
      'observations': [for (final o in observations) o.name],
  };
}
