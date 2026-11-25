import 'package:meta/meta.dart';

import '../model/brew_method.dart';
import 'moderation.dart';

/// Kahve deneyim seviyesi (KHV-FR-PRO-001).
enum CoffeeExperience {
  /// Yeni başlıyorum.
  beginner,

  /// Bir süredir demliyorum.
  intermediate,

  /// Deneyimliyim.
  advanced,

  /// Profesyonel (barista, kavurmacı).
  professional,
}

/// Topluluk profili (KHV-FR-PRO-001). Kişi fotoğrafı, telefon, doğum tarihi,
/// tam adres ve cihaz konumu tutulmaz (Bölüm 16.1, KHV-NFR-046).
@immutable
class CommunityProfile {
  /// Bir profil oluşturur.
  const CommunityProfile({
    required this.userId,
    required this.nickname,
    required this.province,
    required this.experience,
    this.district,
    this.favoriteMethods = const {},
    this.story = '',
    this.curiosities = const [],
    this.instagram,
    this.hidden = false,
    this.showEquipment = false,
  });

  /// Hikaye için en fazla karakter.
  static const maxStoryLength = 500;

  /// Kullanıcı kimliği.
  final String userId;

  /// Takma ad.
  final String nickname;

  /// İl; kullanıcının elle seçtiği (KHV-NFR-046).
  final String province;

  /// İlçe; isteğe bağlı, elle seçilir.
  final String? district;

  /// Deneyim seviyesi.
  final CoffeeExperience experience;

  /// Sevdiği yöntemler.
  final Set<BrewMethod> favoriteMethods;

  /// Kahve hikayesi (en fazla 500 karakter).
  final String story;

  /// Merak ettiği konular.
  final List<String> curiosities;

  /// Instagram kullanıcı adı; yalnız biçimi doğrulanır (KHV-FR-PRO-002).
  final String? instagram;

  /// Gizli profil (KHV-FR-PRO-005).
  final bool hidden;

  /// Ekipman profilinden ekipman gösterilsin mi (KHV-FR-PRO-001).
  final bool showEquipment;
}

/// Profilin doğrulama hataları; boşsa geçerli (KHV-FR-PRO-001, PRO-002,
/// KHV-FR-COM-007).
List<String> validateProfile(CommunityProfile p) => [
  if (p.nickname.trim().length < 3 || p.nickname.trim().length > 30)
    'Takma ad 3-30 karakter olmalıdır.',
  if (p.province.trim().isEmpty) 'İl seçilmelidir.',
  if (p.story.length > CommunityProfile.maxStoryLength)
    'Kahve hikayesi en fazla 500 karakter olabilir.',
  if (detectBlockedContent(p.story).isNotEmpty ||
      p.curiosities.any((c) => detectBlockedContent(c).isNotEmpty))
    'Profil metinlerinde bağlantı, telefon veya e-posta paylaşılamaz.',
  if (p.instagram != null && normalizeInstagram(p.instagram!) == null)
    'Instagram kullanıcı adı geçersiz.',
];

final _igName = RegExp(r'^(?!.*\.\.)(?!\.)[a-z0-9._]{1,30}(?<!\.)$');

/// Instagram kullanıcı adını biçim olarak doğrular ve küçük harfe çevirir
/// (KHV-FR-PRO-002). Baştaki `@` kabul edilir; bağlantı kabul edilmez.
/// Uygulama Instagram'a bağlanmaz, ad yalnız gösterilir.
String? normalizeInstagram(String input) {
  var s = input.trim().toLowerCase();
  if (s.startsWith('@')) s = s.substring(1);
  return _igName.hasMatch(s) ? s : null;
}

/// Kullanıcının bir etkinlikteki rolü.
enum EventRole {
  /// Düzenleyen.
  organizer,

  /// Onaylanmış katılımcı.
  approved,

  /// Başvurmuş (beklemede, yedek veya reddedilmiş).
  applicant,
}

/// İki kullanıcının ortak etkinliklerdeki rolleri: her etkinlik için
/// (izleyenin rolü, profil sahibinin rolü).
typedef SharedEventRoles = List<(EventRole viewer, EventRole owner)>;

/// Instagram kullanıcı adı [viewer] için görünür mü (KHV-FR-PRO-003):
/// yalnız aynı etkinlikte düzenleyen ile onaylanmış katılımcı ilişkisi
/// olanlara ve profil sahibinin başvurduğu etkinliğin düzenleyenine.
/// Engelleme her durumda gizler (KHV-FR-EVT-008).
bool canSeeInstagram({
  required String viewerId,
  required CommunityProfile owner,
  required SharedEventRoles shared,
  bool blocked = false,
}) {
  if (owner.instagram == null) return false;
  if (viewerId == owner.userId) return true;
  if (blocked) return false;
  return shared.any(
    (r) =>
        (r.$1 == EventRole.organizer &&
            (r.$2 == EventRole.approved || r.$2 == EventRole.applicant)) ||
        (r.$1 == EventRole.approved && r.$2 == EventRole.organizer),
  );
}

/// Profil [viewer] için görünür mü (KHV-FR-PRO-005, EVT-008): gizli profili
/// yalnız sahibinin başvurduğu etkinliklerin düzenleyenleri görür.
bool canSeeProfile({
  required String viewerId,
  required CommunityProfile owner,
  required SharedEventRoles shared,
  bool blocked = false,
}) {
  if (viewerId == owner.userId) return true;
  if (blocked) return false;
  if (!owner.hidden) return true;
  return shared.any(
    (r) =>
        r.$1 == EventRole.organizer &&
        (r.$2 == EventRole.applicant || r.$2 == EventRole.approved),
  );
}

/// Profilde gösterilen özet (KHV-FR-PRO-004).
@immutable
class ProfileSummary {
  /// Bir özet oluşturur.
  const ProfileSummary({
    required this.sharedRecipes,
    required this.averageTastingScore,
    required this.attendedEvents,
    required this.organizedEvents,
  });

  /// Paylaştığı tarif sayısı.
  final int sharedRecipes;

  /// Tariflerinin ortalama tadım puanı; oy yoksa `null`.
  final double? averageTastingScore;

  /// Onaylanıp katıldığı etkinlik sayısı.
  final int attendedEvents;

  /// Düzenlediği etkinlik sayısı.
  final int organizedEvents;
}
