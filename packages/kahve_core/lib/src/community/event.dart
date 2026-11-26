import 'package:meta/meta.dart';

import 'moderation.dart';

/// Etkinlik türü (KHV-FR-EVT-001).
enum EventType {
  /// Workshop.
  workshop,

  /// Tadım.
  tasting,
}

/// Mekan türü (KHV-FR-EVT-001, EVT-007).
enum VenueType {
  /// Kamuya açık mekan.
  public,

  /// Ev.
  home,
}

/// Başvuru durumu (KHV-FR-EVT-003, EVT-004).
enum ApplicationStatus {
  /// Düzenleyenin kararını bekliyor.
  pending,

  /// Onaylandı.
  approved,

  /// Reddedildi; başvurana nötr bildirim gider.
  rejected,

  /// Kontenjan dolu, yedek listede.
  waitlisted,

  /// Başvuran geri çekti.
  withdrawn,
}

/// Bir etkinliğe başvuru.
@immutable
class EventApplication {
  /// Bir başvuru oluşturur.
  const EventApplication({
    required this.userId,
    required this.status,
    required this.at,
    this.note = '',
  });

  /// Başvuran.
  final String userId;

  /// Kısa not (KHV-FR-EVT-003).
  final String note;

  /// Durum.
  final ApplicationStatus status;

  /// Başvuru anı; yedek listede sıra buna göre.
  final DateTime at;

  /// Durumu değişmiş kopya.
  EventApplication withStatus(ApplicationStatus s) =>
      EventApplication(userId: userId, note: note, status: s, at: at);
}

/// Etkinlik (KHV-FR-EVT-001). Tam adres ve buluşma notu ilanın parçası
/// değildir; yalnız [addressFor] ile onaylı katılımcılara verilir.
@immutable
class CommunityEvent {
  /// Bir etkinlik oluşturur.
  const CommunityEvent({
    required this.id,
    required this.organizerId,
    required this.title,
    required this.type,
    required this.startsAt,
    required this.duration,
    required this.province,
    required this.district,
    required this.venue,
    required this.capacity,
    required this.address,
    this.conditions = '',
    this.feeText,
    this.meetingNote = '',
    this.cancelled = false,
    this.applications = const [],
  });

  /// Kimlik.
  final String id;

  /// Düzenleyen.
  final String organizerId;

  /// Başlık.
  final String title;

  /// Tür.
  final EventType type;

  /// Başlangıç.
  final DateTime startsAt;

  /// Süre.
  final Duration duration;

  /// İl (elle seçilir, KHV-NFR-046).
  final String province;

  /// İlçe (elle seçilir).
  final String district;

  /// Mekan türü.
  final VenueType venue;

  /// Kontenjan.
  final int capacity;

  /// Katılım koşulları.
  final String conditions;

  /// Ücret bilgisi; yalnız metin, uygulama içi ödeme yok (KHV-FR-EVT-012).
  final String? feeText;

  /// Tam adres; ilanda gösterilmez (KHV-FR-EVT-002).
  final String address;

  /// Buluşma notu; yalnız onaylı katılımcılara.
  final String meetingNote;

  /// İptal edildi mi.
  final bool cancelled;

  /// Başvurular.
  final List<EventApplication> applications;

  /// Bitiş anı.
  DateTime get endsAt => startsAt.add(duration);

  /// Onaylı katılımcılar.
  Iterable<String> get approvedIds => applications
      .where((a) => a.status == ApplicationStatus.approved)
      .map((a) => a.userId);

  /// Kontenjan doldu mu.
  bool get isFull => approvedIds.length >= capacity;

  /// Ev ortamı uyarısı ve emniyet önerileri gösterilmeli mi
  /// (KHV-FR-EVT-007).
  bool get needsHomeSafetyNotice => venue == VenueType.home;

  /// Kullanıcının bu etkinlikteki başvurusu.
  EventApplication? applicationOf(String userId) {
    for (final a in applications) {
      if (a.userId == userId) return a;
    }
    return null;
  }

  /// Değiştirilmiş kopya.
  CommunityEvent copyWith({
    bool? cancelled,
    DateTime? startsAt,
    List<EventApplication>? applications,
  }) => CommunityEvent(
    id: id,
    organizerId: organizerId,
    title: title,
    type: type,
    startsAt: startsAt ?? this.startsAt,
    duration: duration,
    province: province,
    district: district,
    venue: venue,
    capacity: capacity,
    conditions: conditions,
    feeText: feeText,
    address: address,
    meetingNote: meetingNote,
    cancelled: cancelled ?? this.cancelled,
    applications: applications ?? this.applications,
  );
}

/// İlanda herkese görünen alanlar (KHV-FR-EVT-002): tam adres ve buluşma
/// notu yoktur.
@immutable
class EventListing {
  /// Bir ilan görünümü oluşturur.
  EventListing.of(CommunityEvent e)
    : id = e.id,
      title = e.title,
      type = e.type,
      startsAt = e.startsAt,
      duration = e.duration,
      province = e.province,
      district = e.district,
      venue = e.venue,
      capacity = e.capacity,
      remaining = (e.capacity - e.approvedIds.length).clamp(0, e.capacity),
      conditions = e.conditions,
      feeText = e.feeText,
      cancelled = e.cancelled;

  /// Kimlik.
  final String id;

  /// Başlık.
  final String title;

  /// Tür.
  final EventType type;

  /// Başlangıç.
  final DateTime startsAt;

  /// Süre.
  final Duration duration;

  /// İl.
  final String province;

  /// İlçe.
  final String district;

  /// Mekan türü.
  final VenueType venue;

  /// Kontenjan.
  final int capacity;

  /// Kalan yer.
  final int remaining;

  /// Katılım koşulları.
  final String conditions;

  /// Ücret bilgisi metni.
  final String? feeText;

  /// İptal edildi mi.
  final bool cancelled;
}

/// Topluluk kuralı ihlali; [message] kullanıcıya gösterilir.
class CommunityRuleException implements Exception {
  /// Bir ihlal oluşturur.
  const CommunityRuleException(this.message);

  /// Açıklama.
  final String message;

  @override
  String toString() => 'CommunityRuleException: $message';
}

/// Etkinliğin doğrulama hataları (KHV-FR-EVT-001, KHV-FR-COM-007).
List<String> validateEvent(CommunityEvent e, {required DateTime now}) => [
  if (e.title.trim().length < 5 || e.title.length > 80)
    'Başlık 5-80 karakter olmalıdır.',
  if (!e.startsAt.isAfter(now)) 'Etkinlik tarihi ileride olmalıdır.',
  if (e.duration <= Duration.zero || e.duration > const Duration(hours: 12))
    'Süre 12 saati geçemez.',
  if (e.province.trim().isEmpty || e.district.trim().isEmpty)
    'İl ve ilçe seçilmelidir.',
  if (e.capacity < 1 || e.capacity > 50) 'Kontenjan 1-50 arasında olmalıdır.',
  if (e.address.trim().isEmpty)
    'Adres girilmelidir; yalnız onaylı katılımcılar görür.',
  if ([
    e.title,
    e.conditions,
    e.feeText ?? '',
  ].any((t) => detectBlockedContent(t).isNotEmpty))
    'İlan metninde bağlantı, telefon veya e-posta paylaşılamaz.',
];

/// Başvuru yapar (KHV-FR-EVT-003, EVT-006, EVT-008). Kontenjan doluysa
/// başvuru yedek listeye alınır (KHV-FR-EVT-004).
CommunityEvent applyToEvent(
  CommunityEvent e, {
  required String userId,
  required bool adultDeclared,
  required DateTime now,
  required Set<String> blockedByOrganizer,
  String note = '',
}) {
  if (!adultDeclared) {
    throw const CommunityRuleException(
      'Etkinliklere başvurmak için 18 yaşından büyük olduğunuzu beyan '
      'etmelisiniz.',
    );
  }
  if (userId == e.organizerId) {
    throw const CommunityRuleException('Kendi etkinliğinize başvuramazsınız.');
  }
  if (blockedByOrganizer.contains(userId)) {
    throw const CommunityRuleException('Bu etkinliğe başvuramazsınız.');
  }
  if (e.cancelled || !e.startsAt.isAfter(now)) {
    throw const CommunityRuleException('Etkinlik başvuruya kapalı.');
  }
  if (detectBlockedContent(note).isNotEmpty) {
    throw const CommunityRuleException(
      'Notta bağlantı, telefon veya e-posta paylaşılamaz.',
    );
  }
  final existing = e.applicationOf(userId);
  if (existing != null && existing.status != ApplicationStatus.withdrawn) {
    throw const CommunityRuleException('Bu etkinliğe zaten başvurdunuz.');
  }
  final a = EventApplication(
    userId: userId,
    note: note,
    at: now,
    status: e.isFull ? ApplicationStatus.waitlisted : ApplicationStatus.pending,
  );
  return e.copyWith(
    applications: [
      for (final x in e.applications)
        if (x.userId != userId) x,
      a,
    ],
  );
}

/// Düzenleyenin kararı (KHV-FR-EVT-004). Ret gerekçesi istenmez. Kontenjan
/// doluyken onay verilemez; yer açılınca yedek listeden sıradaki
/// [promoteFromWaitlist] ile alınır.
CommunityEvent decideApplication(
  CommunityEvent e, {
  required String actorId,
  required String userId,
  required bool approve,
}) {
  if (actorId != e.organizerId) {
    throw const CommunityRuleException('Yalnız düzenleyen karar verebilir.');
  }
  final a = e.applicationOf(userId);
  if (a == null) throw const CommunityRuleException('Başvuru bulunamadı.');
  if (approve && e.isFull && a.status != ApplicationStatus.approved) {
    throw const CommunityRuleException('Kontenjan dolu.');
  }
  final status = approve
      ? ApplicationStatus.approved
      : ApplicationStatus.rejected;
  return e.copyWith(
    applications: [
      for (final x in e.applications)
        x.userId == userId ? a.withStatus(status) : x,
    ],
  );
}

/// Yer açıldığında yedek listedeki en eski başvuruyu bekleyene alır.
CommunityEvent promoteFromWaitlist(CommunityEvent e) {
  if (e.isFull) return e;
  final waiting = [
    for (final a in e.applications)
      if (a.status == ApplicationStatus.waitlisted) a,
  ]..sort((a, b) => a.at.compareTo(b.at));
  if (waiting.isEmpty) return e;
  final next = waiting.first.userId;
  return e.copyWith(
    applications: [
      for (final x in e.applications)
        x.userId == next ? x.withStatus(ApplicationStatus.pending) : x,
    ],
  );
}

/// Ret bildirimi metni: nötr, gerekçesiz (KHV-FR-EVT-004).
String rejectionNotice(CommunityEvent e) =>
    '"${e.title}" etkinliğinin katılımcı listesi tamamlandı. İlginiz için '
    'teşekkürler.';

/// Tam adres ve buluşma notu [viewerId] için görünür mü (KHV-FR-EVT-005):
/// yalnız düzenleyen ve onaylı katılımcılar; etkinlik bitişinden 24 saat
/// sonra veya iptalde gizlenir.
bool canSeeAddress(CommunityEvent e, String viewerId, DateTime now) {
  if (e.cancelled) return viewerId == e.organizerId;
  if (now.isAfter(e.endsAt.add(const Duration(hours: 24)))) return false;
  return viewerId == e.organizerId || e.approvedIds.contains(viewerId);
}

/// Tam adres etkinlik kaydından silinmeli mi (KHV-NFR-046): bitişten 30 gün
/// sonra.
bool shouldPurgeAddress(CommunityEvent e, DateTime now) =>
    now.isAfter(e.endsAt.add(const Duration(days: 30)));

/// İptal veya tarih değişikliğinde bildirim gidecek kullanıcılar
/// (KHV-FR-EVT-011): onaylı katılımcılar ve yedek listedekiler.
Set<String> changeRecipients(CommunityEvent e) => {
  for (final a in e.applications)
    if (a.status == ApplicationStatus.approved ||
        a.status == ApplicationStatus.waitlisted)
      a.userId,
};

/// Düzenleyenin tek yönlü duyurusunu alacaklar (KHV-FR-EVT-010). Yalnız
/// düzenleyen gönderebilir; özel mesajlaşma yoktur.
Set<String> announcementRecipients(CommunityEvent e, String actorId) {
  if (actorId != e.organizerId) {
    throw const CommunityRuleException(
      'Yalnız düzenleyen duyuru gönderebilir.',
    );
  }
  return e.approvedIds.toSet();
}

/// "Sorun yaşadım" bildirimi yalnız onaylı katılımcıdan, etkinlik başladıktan
/// sonra kabul edilir (KHV-FR-EVT-013).
bool canReportProblem(CommunityEvent e, String userId, DateTime now) =>
    e.approvedIds.contains(userId) && now.isAfter(e.startsAt);

/// Etkinlikte demlenen kahvelerin anonim puanlaması (KHV-FR-EVT-009).
///
/// Puanı yalnız onaylı katılımcılar verir; sonuçlar etkinlik bitince
/// görünür ve yalnız ortalama ile sayı döner, puan verenin kimliği dönmez.
class TastingBoard {
  /// Bir etkinlik için tadım tablosu oluşturur.
  TastingBoard(this.event, this.coffees);

  /// Etkinlik.
  final CommunityEvent event;

  /// Kahve adları (ör. "Etiyopya, V60").
  final List<String> coffees;
  final _scores = <int, Map<String, int>>{};

  /// Puan verir; aynı kişi aynı kahveye ikinci kez puan verirse günceller.
  void rate(String userId, int coffeeIndex, int score, DateTime now) {
    if (!event.approvedIds.contains(userId)) {
      throw const CommunityRuleException(
        'Yalnız onaylı katılımcılar puan verebilir.',
      );
    }
    if (now.isBefore(event.startsAt) || event.cancelled) {
      throw const CommunityRuleException(
        'Puanlama etkinlik başlayınca açılır.',
      );
    }
    if (score < 1 ||
        score > 5 ||
        coffeeIndex < 0 ||
        coffeeIndex >= coffees.length) {
      throw const CommunityRuleException('Geçersiz puan.');
    }
    (_scores[coffeeIndex] ??= {})[userId] = score;
  }

  /// Sonuçlar; etkinlik bitmeden `null` (KHV-FR-EVT-009).
  List<({String coffee, double? average, int count})>? results(DateTime now) {
    if (now.isBefore(event.endsAt)) return null;
    return [
      for (var i = 0; i < coffees.length; i++)
        () {
          final s = _scores[i]?.values ?? const <int>[];
          return (
            coffee: coffees[i],
            average: s.isEmpty ? null : s.reduce((a, b) => a + b) / s.length,
            count: s.length,
          );
        }(),
    ];
  }
}
