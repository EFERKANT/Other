import 'package:kahve_core/kahve_core.dart';
import 'package:test/test.dart';

final now = DateTime(2026, 12, 1, 10);

CommunityEvent event({
  int capacity = 2,
  VenueType venue = VenueType.home,
  List<EventApplication> applications = const [],
}) => CommunityEvent(
  id: 'e1',
  organizerId: 'org',
  title: 'V60 tadım akşamı',
  type: EventType.tasting,
  startsAt: DateTime(2026, 12, 10, 19),
  duration: const Duration(hours: 2),
  province: 'İstanbul',
  district: 'Kadıköy',
  venue: venue,
  capacity: capacity,
  address: 'Örnek Sk. No:1 D:3',
  meetingNote: 'Zile basın',
  applications: applications,
);

EventApplication app(String u, ApplicationStatus s, [int minute = 0]) =>
    EventApplication(
      userId: u,
      status: s,
      at: now.add(Duration(minutes: minute)),
    );

void main() {
  group('moderasyon (KHV-FR-COM-007, SOC-011)', () {
    test('bağlantı, telefon ve e-posta tespit edilir', () {
      expect(detectBlockedContent('Detaylar www.ornek.com adresinde'), {
        BlockedContent.url,
      });
      expect(detectBlockedContent('https://x.y/z'), {BlockedContent.url});
      expect(detectBlockedContent('kahve.com.tr'), {BlockedContent.url});
      expect(detectBlockedContent('Ara: 0532 123 45 67'), {
        BlockedContent.phone,
      });
      expect(detectBlockedContent('+90 (532) 123-4567'), {
        BlockedContent.phone,
      });
      expect(detectBlockedContent('ali.veli@mail.com yaz'), {
        BlockedContent.email,
      });
    });
    test('kahve metinleri yanlış alarm vermez', () {
      expect(
        detectBlockedContent(
          '15 g kahve, 250 g su, 1:16,7 oran, 93 °C, 2:30 dk',
        ),
        isEmpty,
      );
      expect(
        detectBlockedContent('Bloom 30 sn. Sonra 150 g. Toplam 3:00'),
        isEmpty,
      );
      expect(detectBlockedContent('Kavurma tarihi 01.11.2026'), isEmpty);
    });
  });

  group('şikayet önceliği (KHV-FR-ADM-006, EVT-013)', () {
    test('emniyet en üstte, sonra etkinlik sonrası sorun, sonra yoğunluk', () {
      Report r(String id, ReportReason why, String target, int m) => Report(
        id: id,
        reporterId: 'u$id',
        target: ReportTarget.user,
        targetId: target,
        reason: why,
        at: now.add(Duration(minutes: m)),
      );
      final sorted = prioritizeReports([
        r('1', ReportReason.spam, 'a', 0),
        r('2', ReportReason.other, 'b', 1),
        r('3', ReportReason.safety, 'c', 5),
        r('4', ReportReason.problemAfterEvent, 'd', 2),
        r('5', ReportReason.spam, 'e', 3),
        r('6', ReportReason.spam, 'e', 4),
        r('7', ReportReason.safety, 'f', 1),
      ]);
      expect(sorted.map((x) => x.id), ['7', '3', '4', '5', '6', '1', '2']);
    });
  });

  group('profil (KHV-FR-PRO-001, PRO-002)', () {
    CommunityProfile profile({
      String story = '',
      String? ig,
      bool hidden = false,
    }) => CommunityProfile(
      userId: 'ayse',
      nickname: 'ayse_demler',
      province: 'İzmir',
      experience: CoffeeExperience.intermediate,
      favoriteMethods: const {BrewMethod.v60},
      story: story,
      instagram: ig,
      hidden: hidden,
    );
    test('hikaye 500 karakter, metinde iletişim bilgisi yok', () {
      expect(validateProfile(profile(story: 'a' * 500)), isEmpty);
      expect(validateProfile(profile(story: 'a' * 501)), isNotEmpty);
      expect(validateProfile(profile(story: 'Yazın: a@b.com')), isNotEmpty);
    });
    test('Instagram yalnız biçim olarak doğrulanır', () {
      expect(normalizeInstagram('@Ayse.Demler_'), 'ayse.demler_');
      expect(normalizeInstagram('ayse..demler'), isNull);
      expect(normalizeInstagram('.ayse'), isNull);
      expect(normalizeInstagram('ayse.'), isNull);
      expect(normalizeInstagram('https://instagram.com/ayse'), isNull);
      expect(normalizeInstagram('a' * 31), isNull);
      expect(validateProfile(profile(ig: 'çay')), isNotEmpty);
    });

    test('Instagram görünürlüğü (KHV-FR-PRO-003)', () {
      final p = profile(ig: 'ayse');
      bool see(SharedEventRoles r, {bool blocked = false}) =>
          canSeeInstagram(viewerId: 'x', owner: p, shared: r, blocked: blocked);
      expect(see(const []), isFalse, reason: 'ilişki yok');
      expect(see(const [(EventRole.organizer, EventRole.approved)]), isTrue);
      expect(see(const [(EventRole.approved, EventRole.organizer)]), isTrue);
      expect(
        see(const [(EventRole.organizer, EventRole.applicant)]),
        isTrue,
        reason: 'başvurduğu etkinliğin düzenleyeni',
      );
      expect(
        see(const [(EventRole.applicant, EventRole.organizer)]),
        isFalse,
        reason: 'onaylanmamış başvuran düzenleyenin Instagram\'ını görmez',
      );
      expect(
        see(const [(EventRole.approved, EventRole.approved)]),
        isFalse,
        reason: 'iki katılımcı arasında ilişki yok',
      );
      expect(
        see(const [(EventRole.organizer, EventRole.approved)], blocked: true),
        isFalse,
      );
      expect(
        canSeeInstagram(viewerId: 'ayse', owner: p, shared: const []),
        isTrue,
      );
      expect(
        canSeeInstagram(
          viewerId: 'x',
          owner: profile(),
          shared: const [(EventRole.organizer, EventRole.approved)],
        ),
        isFalse,
      );
    });

    test('gizli profil (KHV-FR-PRO-005) ve engelleme (EVT-008)', () {
      final hidden = profile(hidden: true);
      expect(
        canSeeProfile(viewerId: 'x', owner: hidden, shared: const []),
        isFalse,
      );
      expect(
        canSeeProfile(
          viewerId: 'x',
          owner: hidden,
          shared: const [(EventRole.organizer, EventRole.applicant)],
        ),
        isTrue,
      );
      expect(
        canSeeProfile(
          viewerId: 'x',
          owner: hidden,
          shared: const [(EventRole.approved, EventRole.organizer)],
        ),
        isFalse,
      );
      expect(
        canSeeProfile(viewerId: 'x', owner: profile(), shared: const []),
        isTrue,
      );
      expect(
        canSeeProfile(
          viewerId: 'x',
          owner: profile(),
          shared: const [],
          blocked: true,
        ),
        isFalse,
      );
      expect(
        canSeeProfile(viewerId: 'ayse', owner: hidden, shared: const []),
        isTrue,
      );
      const s = ProfileSummary(
        sharedRecipes: 2,
        averageTastingScore: 4.5,
        attendedEvents: 1,
        organizedEvents: 0,
      );
      expect(s.sharedRecipes, 2);
    });
  });

  group('etkinlik (KHV-FR-EVT-001 - EVT-013, KHV-NFR-046)', () {
    test('ilan doğrulaması (EVT-001)', () {
      expect(validateEvent(event(), now: now), isEmpty);
      final bad = CommunityEvent(
        id: 'x',
        organizerId: 'o',
        title: 'kısa',
        type: EventType.workshop,
        startsAt: now,
        duration: Duration.zero,
        province: '',
        district: '',
        venue: VenueType.public,
        capacity: 0,
        address: '',
        conditions: 'Bilgi için 0532 123 45 67',
      );
      expect(validateEvent(bad, now: now), hasLength(7));
    });

    test('ilanda tam adres yok (EVT-002), ev uyarısı (EVT-007)', () {
      final e = event(applications: [app('a', ApplicationStatus.approved)]);
      final l = EventListing.of(e);
      expect(l.province, 'İstanbul');
      expect(l.district, 'Kadıköy');
      expect(l.venue, VenueType.home);
      expect(l.remaining, 1);
      expect(e.needsHomeSafetyNotice, isTrue);
      expect(event(venue: VenueType.public).needsHomeSafetyNotice, isFalse);
    });

    test('başvuru: 18 yaş beyanı, kendi etkinliği, engel, tekrar (EVT-003, '
        'EVT-006, EVT-008)', () {
      CommunityEvent go(
        String u, {
        bool adult = true,
        Set<String> blocked = const {},
        String note = '',
      }) => applyToEvent(
        event(),
        userId: u,
        adultDeclared: adult,
        now: now,
        blockedByOrganizer: blocked,
        note: note,
      );
      expect(go('a').applicationOf('a')!.status, ApplicationStatus.pending);
      expect(
        () => go('a', adult: false),
        throwsA(isA<CommunityRuleException>()),
      );
      expect(() => go('org'), throwsA(isA<CommunityRuleException>()));
      expect(
        () => go('a', blocked: {'a'}),
        throwsA(isA<CommunityRuleException>()),
      );
      expect(
        () => go('a', note: 'tel 05321234567'),
        throwsA(isA<CommunityRuleException>()),
      );
      final once = go('a');
      expect(
        () => applyToEvent(
          once,
          userId: 'a',
          adultDeclared: true,
          now: now,
          blockedByOrganizer: const {},
        ),
        throwsA(isA<CommunityRuleException>()),
      );
      expect(
        () => applyToEvent(
          event(),
          userId: 'a',
          adultDeclared: true,
          now: DateTime(2027),
          blockedByOrganizer: const {},
        ),
        throwsA(isA<CommunityRuleException>()),
        reason: 'geçmiş etkinlik',
      );
    });

    test('kontenjan dolunca yedek liste, yer açılınca sıradaki (EVT-004)', () {
      var e = event(capacity: 1);
      e = applyToEvent(
        e,
        userId: 'a',
        adultDeclared: true,
        now: now,
        blockedByOrganizer: const {},
      );
      e = decideApplication(e, actorId: 'org', userId: 'a', approve: true);
      e = applyToEvent(
        e,
        userId: 'b',
        adultDeclared: true,
        now: now.add(const Duration(minutes: 1)),
        blockedByOrganizer: const {},
      );
      e = applyToEvent(
        e,
        userId: 'c',
        adultDeclared: true,
        now: now.add(const Duration(minutes: 2)),
        blockedByOrganizer: const {},
      );
      expect(e.applicationOf('b')!.status, ApplicationStatus.waitlisted);
      expect(
        () => decideApplication(e, actorId: 'org', userId: 'b', approve: true),
        throwsA(isA<CommunityRuleException>()),
      );
      expect(
        () => decideApplication(e, actorId: 'b', userId: 'b', approve: true),
        throwsA(isA<CommunityRuleException>()),
      );
      expect(
        () => decideApplication(e, actorId: 'org', userId: 'zz', approve: true),
        throwsA(isA<CommunityRuleException>()),
      );
      e = decideApplication(e, actorId: 'org', userId: 'a', approve: false);
      expect(
        promoteFromWaitlist(e).applicationOf('b')!.status,
        ApplicationStatus.pending,
      );
      expect(
        promoteFromWaitlist(e).applicationOf('c')!.status,
        ApplicationStatus.waitlisted,
      );
      expect(rejectionNotice(e), isNot(contains('çünkü')));
      expect(
        promoteFromWaitlist(
          event(
            capacity: 1,
            applications: [app('a', ApplicationStatus.approved)],
          ),
        ).applications,
        hasLength(1),
      );
      expect(promoteFromWaitlist(event()).applications, isEmpty);
    });

    test('adres görünürlüğü ve silinmesi (EVT-005, NFR-046)', () {
      final e = event(
        applications: [
          app('a', ApplicationStatus.approved),
          app('b', ApplicationStatus.pending),
        ],
      );
      expect(canSeeAddress(e, 'a', now), isTrue);
      expect(canSeeAddress(e, 'org', now), isTrue);
      expect(canSeeAddress(e, 'b', now), isFalse);
      expect(canSeeAddress(e, 'x', now), isFalse);
      final after24 = e.endsAt.add(const Duration(hours: 24, minutes: 1));
      expect(canSeeAddress(e, 'a', after24), isFalse);
      expect(canSeeAddress(e.copyWith(cancelled: true), 'a', now), isFalse);
      expect(
        shouldPurgeAddress(e, e.endsAt.add(const Duration(days: 30))),
        isFalse,
      );
      expect(
        shouldPurgeAddress(
          e,
          e.endsAt.add(const Duration(days: 30, minutes: 1)),
        ),
        isTrue,
      );
    });

    test('bildirim, duyuru ve sorun bildirimi (EVT-010, EVT-011, EVT-013)', () {
      final e = event(
        applications: [
          app('a', ApplicationStatus.approved),
          app('b', ApplicationStatus.waitlisted),
          app('c', ApplicationStatus.rejected),
        ],
      );
      expect(changeRecipients(e), {'a', 'b'});
      expect(announcementRecipients(e, 'org'), {'a'});
      expect(
        () => announcementRecipients(e, 'a'),
        throwsA(isA<CommunityRuleException>()),
      );
      expect(canReportProblem(e, 'a', e.endsAt), isTrue);
      expect(canReportProblem(e, 'c', e.endsAt), isFalse);
      expect(canReportProblem(e, 'a', now), isFalse);
      expect(const CommunityRuleException('x').toString(), contains('x'));
    });

    test('etkinlik tadımı anonim, sonuç bitişte (EVT-009)', () {
      final e = event(
        applications: [
          app('a', ApplicationStatus.approved),
          app('b', ApplicationStatus.approved),
        ],
      );
      final board = TastingBoard(e, ['Etiyopya V60', 'Kolombiya AeroPress']);
      final during = e.startsAt.add(const Duration(minutes: 30));
      board.rate('a', 0, 5, during);
      board.rate('b', 0, 3, during);
      board.rate('a', 0, 4, during);
      expect(
        () => board.rate('x', 0, 5, during),
        throwsA(isA<CommunityRuleException>()),
      );
      expect(
        () => board.rate('a', 0, 5, now),
        throwsA(isA<CommunityRuleException>()),
      );
      expect(
        () => board.rate('a', 0, 6, during),
        throwsA(isA<CommunityRuleException>()),
      );
      expect(
        () => board.rate('a', 9, 3, during),
        throwsA(isA<CommunityRuleException>()),
      );
      expect(board.results(during), isNull);
      final res = board.results(e.endsAt)!;
      expect(res.first.average, 3.5);
      expect(res.first.count, 2);
      expect(res.last.average, isNull);
      expect(res.toString(), isNot(contains('a,')));
    });
  });

  group('paylaşılan tarif oyları (KHV-FR-SOC-012 - SOC-014)', () {
    SharedRecipeVotes r0() =>
        SharedRecipeVotes(recipeId: 'r', authorId: 'yazar', sharedAt: now);
    test('yalnız deneyen, bir kez, kendi tarifine değil', () {
      var r = voteOnRecipe(
        r0(),
        userId: 'a',
        score: 5,
        hasBrewLogWithRecipe: true,
      );
      expect(r.count, 1);
      expect(
        () =>
            voteOnRecipe(r, userId: 'a', score: 4, hasBrewLogWithRecipe: true),
        throwsA(isA<CommunityRuleException>()),
      );
      expect(
        () =>
            voteOnRecipe(r, userId: 'b', score: 4, hasBrewLogWithRecipe: false),
        throwsA(isA<CommunityRuleException>()),
      );
      expect(
        () => voteOnRecipe(
          r,
          userId: 'yazar',
          score: 5,
          hasBrewLogWithRecipe: true,
        ),
        throwsA(isA<CommunityRuleException>()),
      );
      expect(
        () =>
            voteOnRecipe(r, userId: 'c', score: 0, hasBrewLogWithRecipe: true),
        throwsA(isA<CommunityRuleException>()),
      );
      r = removeShared(r, 'yazar');
      expect(
        () =>
            voteOnRecipe(r, userId: 'c', score: 3, hasBrewLogWithRecipe: true),
        throwsA(isA<CommunityRuleException>()),
      );
      expect(
        () => removeShared(r0(), 'a'),
        throwsA(isA<CommunityRuleException>()),
      );
    });

    test("5'ten az oy 'yeni'; sıralama ortalama, sonra oy sayısı", () {
      SharedRecipeVotes withVotes(String id, List<int> scores, [int day = 0]) {
        var r = SharedRecipeVotes(
          recipeId: id,
          authorId: 'y',
          sharedAt: now.add(Duration(days: day)),
        );
        for (var i = 0; i < scores.length; i++) {
          r = voteOnRecipe(
            r,
            userId: 'u$i',
            score: scores[i],
            hasBrewLogWithRecipe: true,
          );
        }
        return r;
      }

      final a = withVotes('a', [5, 5, 4, 4, 4]);
      final b = withVotes('b', [5, 5, 5, 5, 5, 5]);
      final c = withVotes('c', [5, 5, 5]);
      final d = withVotes('d', [4, 4, 4, 4, 5, 5, 5, 4, 4, 4]);
      final e = withVotes('e', [], 3);
      final f = removeShared(withVotes('f', [5, 5, 5, 5, 5, 5, 5]), 'y');
      expect(c.isNew, isTrue);
      expect(c.label, 'yeni');
      expect(a.label, '4,4 (5 oy)');
      expect(e.average, isNull);
      expect(rankSharedRecipes([a, b, c, d, e, f]).map((r) => r.recipeId), [
        'b',
        'a',
        'd',
        'c',
        'e',
      ]);
    });
  });
}
