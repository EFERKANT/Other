import 'package:meta/meta.dart';

/// Serbest metinde engellenen içerik türleri (KHV-FR-COM-007).
enum BlockedContent {
  /// Web adresi.
  url,

  /// Telefon numarası.
  phone,

  /// E-posta adresi.
  email,
}

final _email = RegExp(r'[\w.+-]+@[\w-]+(\.[\w-]+)+', unicode: true);
final _url = RegExp(
  r'(https?://|www\.)\S+|\b[\w-]+\.(com|net|org|io|app|me|co|tr|info|biz)(\.[a-z]{2})?\b(/\S*)?',
  caseSensitive: false,
);
// Boşluk, tire, nokta veya parantezle ayrılmış en az 10 rakam.
final _phone = RegExp(r'(\+?\d[\s().-]*){10,}');

/// Metinde web adresi, telefon numarası veya e-posta varsa türlerini döndürür
/// (KHV-FR-COM-007). Paylaşılan tarif, profil hikayesi ve etkinlik metinleri
/// bu kurala tabidir (KHV-FR-SOC-011).
Set<BlockedContent> detectBlockedContent(String text) {
  final found = <BlockedContent>{};
  var rest = text;
  if (_email.hasMatch(rest)) {
    found.add(BlockedContent.email);
    rest = rest.replaceAll(_email, ' ');
  }
  if (_url.hasMatch(rest)) found.add(BlockedContent.url);
  if (_phone.hasMatch(rest)) found.add(BlockedContent.phone);
  return found;
}

/// Şikayet gerekçeleri (KHV-FR-EVT-008, EVT-013, KHV-FR-ADM-006).
enum ReportReason {
  /// Emniyet: tehdit, taciz, tehlikeli davranış.
  safety,

  /// Etkinlik sonrası "sorun yaşadım" bildirimi.
  problemAfterEvent,

  /// Uygunsuz içerik.
  inappropriate,

  /// Sahte etkinlik veya hesap.
  fake,

  /// İstenmeyen ticari içerik.
  spam,

  /// Diğer.
  other,
}

/// Şikayet edilen öğe türü.
enum ReportTarget {
  /// Kullanıcı.
  user,

  /// Etkinlik.
  event,

  /// Paylaşılan tarif.
  recipe,
}

/// Bir şikayet kaydı.
@immutable
class Report {
  /// Bir şikayet oluşturur.
  const Report({
    required this.id,
    required this.reporterId,
    required this.target,
    required this.targetId,
    required this.reason,
    required this.at,
  });

  /// Kimlik.
  final String id;

  /// Şikayet eden.
  final String reporterId;

  /// Şikayet edilen öğe türü.
  final ReportTarget target;

  /// Şikayet edilen öğe.
  final String targetId;

  /// Gerekçe.
  final ReportReason reason;

  /// Şikayet anı.
  final DateTime at;
}

int _rank(ReportReason r) => switch (r) {
  ReportReason.safety => 0,
  ReportReason.problemAfterEvent => 1,
  ReportReason.inappropriate => 2,
  ReportReason.fake => 3,
  ReportReason.spam => 4,
  ReportReason.other => 5,
};

/// Moderasyon kuyruğu sırası (KHV-FR-ADM-006, EVT-013): emniyet en üstte,
/// ardından etkinlik sonrası sorun bildirimleri; aynı öncelikte aynı öğeye
/// gelen şikayet sayısı fazla olan, sonra eski olan önce.
List<Report> prioritizeReports(Iterable<Report> reports) {
  final list = reports.toList();
  final perTarget = <String, int>{};
  for (final r in list) {
    final key = '${r.target.name}:${r.targetId}';
    perTarget[key] = (perTarget[key] ?? 0) + 1;
  }
  int count(Report r) => perTarget['${r.target.name}:${r.targetId}']!;
  list.sort((a, b) {
    final byReason = _rank(a.reason).compareTo(_rank(b.reason));
    if (byReason != 0) return byReason;
    final byCount = count(b).compareTo(count(a));
    if (byCount != 0) return byCount;
    return a.at.compareTo(b.at);
  });
  return list;
}
