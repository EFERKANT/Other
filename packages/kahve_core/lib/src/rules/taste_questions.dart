import 'package:meta/meta.dart';

import '../model/taste.dart';

/// "Emin değilim" seçildiğinde sorulan yönlendirme sorusu (KHV-HMI-015).
@immutable
class TasteQuestion {
  /// Bir soru oluşturur.
  const TasteQuestion(this.id, this.text, this.options);

  /// Soru kimliği.
  final String id;

  /// Soru metni.
  final String text;

  /// Seçenekler.
  final List<TasteAnswer> options;
}

/// Bir yönlendirme sorusunun cevabı ve tat eksenlerine etkisi.
@immutable
class TasteAnswer {
  /// Bir cevap oluşturur.
  const TasteAnswer(
    this.id,
    this.text, {
    this.extraction,
    this.strength,
    this.flat = false,
  });

  /// Cevap kimliği.
  final String id;

  /// Cevap metni (günlük hayattan örnekle, KHV-HMI-014).
  final String text;

  /// Ekşi-acı ekseninde konum (verildiyse).
  final double? extraction;

  /// Sulu-yoğun ekseninde konum (verildiyse).
  final double? strength;

  /// Düz/aromasız tadı işaretler.
  final bool flat;
}

/// En fazla üç sorudan oluşan yönlendirme anketi.
const tasteQuestions = <TasteQuestion>[
  TasteQuestion(
    'finish',
    'Yudumdan sonra ağzınızda kalan his hangisine yakın?',
    [
      TasteAnswer(
        'sharp',
        'Limon sıkılmış su gibi keskin, çabuk biten',
        extraction: -0.7,
      ),
      TasteAnswer(
        'drying',
        'Fazla demlenmiş çay gibi kurutan, acı kalan',
        extraction: 0.7,
      ),
      TasteAnswer('both', 'İkisi de var', extraction: 0),
      TasteAnswer('neither', 'İkisi de değil, hoş', extraction: 0),
    ],
  ),
  TasteQuestion('body', 'Kahvenin gövdesi nasıl?', [
    TasteAnswer('thin', 'Sulandırılmış meyve suyu gibi ince', strength: -0.7),
    TasteAnswer('heavy', 'Çok ağır, koyu şurup gibi', strength: 0.7),
    TasteAnswer('ok', 'Yerinde', strength: 0),
  ]),
  TasteQuestion('aroma', 'Koku ve aroma nasıl?', [
    TasteAnswer('flat', 'Düz, karton veya bayat ekmek gibi', flat: true),
    TasteAnswer('clear', 'Belirgin, hoş', flat: false),
  ]),
];

/// Anket cevaplarından tat değerlendirmesi üretir. [answers] soru
/// kimliğinden cevap kimliğine eşlemedir; eksik cevaplar nötr sayılır.
TasteAssessment assessmentFromAnswers(
  Map<String, String> answers, {
  required int score,
}) {
  var extraction = 0.0;
  var strength = 0.0;
  var flat = false;
  var both = false;
  for (final q in tasteQuestions) {
    final id = answers[q.id];
    if (id == null) continue;
    final a = q.options.firstWhere(
      (o) => o.id == id,
      orElse: () => throw ArgumentError('Geçersiz cevap: ${q.id}=$id'),
    );
    if (a.extraction != null) extraction = a.extraction!;
    if (a.strength != null) strength = a.strength!;
    if (a.flat) flat = true;
    if (q.id == 'finish' && a.id == 'both') both = true;
  }
  return TasteAssessment(
    score: score,
    extraction: extraction,
    strength: strength,
    sourAndBitter: both,
    flat: flat,
  );
}
