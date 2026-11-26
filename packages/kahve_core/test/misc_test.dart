import 'dart:convert';
import 'dart:io';

import 'package:kahve_core/kahve_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('çekirdek (KHV-FR-LOG-004, ENG-003 - ENG-005)', () {
    test('kavurma tarihinden geçen gün', () {
      expect(
        daysSinceRoast(DateTime(2026, 11, 1), DateTime(2026, 11, 24, 23)),
        23,
      );
      expect(daysSinceRoast(DateTime(2026, 12, 1), DateTime(2026, 11, 24)), 0);
    });
    test('tazelik eşiği varsayılan 30 gün', () {
      expect(
        isPastFreshness(DateTime(2026, 10, 1), DateTime(2026, 10, 31)),
        isFalse,
      );
      expect(
        isPastFreshness(DateTime(2026, 10, 1), DateTime(2026, 11, 1)),
        isTrue,
      );
      expect(
        isPastFreshness(
          DateTime(2026, 10, 1),
          DateTime(2026, 10, 12),
          thresholdDays: 10,
        ),
        isTrue,
      );
    });
    test('stok düşümü', () {
      expect(deductStock(250, 15), 235);
      expect(deductStock(10, 15), 0);
    });
    test('düşük stok: 3 demlemelik altı', () {
      final avg = averageDose([15, 15, 18]);
      expect(avg, 16);
      expect(isLowStock(47, avg), isTrue);
      expect(isLowStock(48, avg), isFalse);
      expect(isLowStock(1, null), isFalse);
      expect(averageDose(const []), isNull);
      expect(brewsLeft(50, 16), 3);
      expect(brewsLeft(50, null), isNull);
    });
  });

  group('metin (KHV-FR-RCP-012, KHV-NFR-031)', () {
    test('Türkçe karakter duyarsız arama', () {
      expect(foldTurkish('  Türk   KAHVESİ '), 'turk kahvesi');
      expect(foldTurkish('ÇĞIİÖŞÜ'), 'cgiiosu');
      expect(matchesQuery('turk kahvesi', ['Türk kahvesi 2 fincan']), isTrue);
      expect(matchesQuery('turk v60', ['Türk kahvesi']), isFalse);
      expect(matchesQuery('', ['x']), isTrue);
      expect(
        matchesQuery('cezve', ['Türk kahvesi', 'Cezve veya makine']),
        isTrue,
      );
    });
    test('sayı biçimi', () {
      expect(formatNumber(18.5), '18,5');
      expect(formatNumber(18.0), '18');
      expect(formatNumber(16.666, decimals: 2), '16,67');
      expect(formatNumber(-0.01), '0');
      expect(formatNumber(double.nan), '-');
      expect(formatNumber(250), '250');
    });
    test('sayı girişi virgül ve nokta kabul eder', () {
      expect(parseNumber('18,5'), 18.5);
      expect(parseNumber('18.5'), 18.5);
      expect(parseNumber(' 20 '), 20);
      expect(parseNumber(''), isNull);
      expect(parseNumber('1,2,3'), isNull);
      expect(parseNumber('abc'), isNull);
    });
    test('süre ve oran', () {
      expect(formatDuration(0), '0:00');
      expect(formatDuration(-5), '0:00');
      expect(formatDuration(185), '3:05');
      expect(formatDuration(50400), '14:00:00');
      expect(formatRatio(16), '1:16');
      expect(formatRatio(16.5), '1:16,5');
    });
  });

  group('profil (KHV-FR-ONB-002, ONB-005)', () {
    test('atlanırsa P1', () {
      expect(
        assignProfile(EquipmentProfile.empty, skipped: true),
        UserProfile.beginner,
      );
    });
    test('espresso makinesi → P3', () {
      expect(
        assignProfile(
          const EquipmentProfile(
            brewers: {BrewMethod.espresso, BrewMethod.v60},
          ),
        ),
        UserProfile.espresso,
      );
    });
    test('yalnız Türk kahvesi → P4', () {
      expect(
        assignProfile(const EquipmentProfile(brewers: {BrewMethod.turkish})),
        UserProfile.turkish,
      );
    });
    test('ekipman yok → P5', () {
      expect(assignProfile(EquipmentProfile.empty), UserProfile.shopper);
    });
    test('terazi + burr → P2, aksi P1', () {
      expect(
        assignProfile(
          const EquipmentProfile(
            brewers: {BrewMethod.v60},
            hasScale: true,
            grinder: GrinderType.handBurr,
          ),
        ),
        UserProfile.enthusiast,
      );
      expect(
        assignProfile(
          const EquipmentProfile(brewers: {BrewMethod.frenchPress}),
        ),
        UserProfile.beginner,
      );
    });
    test('P1 ve P5 ileri parametreleri gizler (KHV-HMI-017)', () {
      expect(UserProfile.beginner.hidesAdvancedParameters, isTrue);
      expect(UserProfile.enthusiast.hidesAdvancedParameters, isFalse);
      expect(UserProfile.espresso.code, 'P3');
    });
  });

  group('sonraki ekipman önerisi (KHV-FR-EQP-004)', () {
    test('öncelik sırası', () {
      var e = const EquipmentProfile(brewers: {BrewMethod.v60});
      expect(nextPurchase(e), PurchaseItem.freshBeans);
      expect(nextPurchase(e, usesFreshBeans: true), PurchaseItem.burrGrinder);
      e = e.copyWith(grinder: GrinderType.handBurr);
      expect(nextPurchase(e, usesFreshBeans: true), PurchaseItem.scale);
      e = e.copyWith(hasScale: true, kettle: KettleType.standard);
      expect(
        nextPurchase(e, usesFreshBeans: true),
        PurchaseItem.gooseneckKettle,
      );
      e = e.copyWith(kettle: KettleType.gooseneck);
      expect(nextPurchase(e, usesFreshBeans: true), PurchaseItem.waterFilter);
      e = e.copyWith(hasWaterFilter: true);
      expect(nextPurchase(e, usesFreshBeans: true), isNull);
    });
    test('espresso için grinder önce', () {
      expect(
        nextPurchase(
          const EquipmentProfile(
            brewers: {BrewMethod.espresso},
            grinder: GrinderType.handBurr,
          ),
        ),
        PurchaseItem.espressoGrinder,
      );
    });
    test('demleme aracı yok', () {
      expect(
        nextPurchase(
          const EquipmentProfile(
            grinder: GrinderType.electricBurr,
            hasScale: true,
          ),
          usesFreshBeans: true,
        ),
        PurchaseItem.brewer,
      );
    });
    test('Türk kahvesi', () {
      const t = EquipmentProfile(brewers: {BrewMethod.turkish});
      expect(nextPurchase(t, usesFreshBeans: true), PurchaseItem.scale);
      expect(
        nextPurchase(t.copyWith(hasScale: true), usesFreshBeans: true),
        PurchaseItem.waterFilter,
      );
      expect(
        nextPurchase(
          t.copyWith(hasScale: true, hasWaterFilter: true),
          usesFreshBeans: true,
        ),
        isNull,
      );
    });
  });

  test('eksik ekipman (KHV-FR-RCP-007)', () {
    const e = EquipmentProfile(
      brewers: {BrewMethod.v60},
      kettle: KettleType.standard,
    );
    expect(missingEquipment(BrewMethod.v60, e), {
      MissingEquipment.gooseneckKettle,
    });
    expect(missingEquipment(BrewMethod.chemex, e), {
      MissingEquipment.brewer,
      MissingEquipment.gooseneckKettle,
    });
    expect(
      missingEquipment(
        BrewMethod.espresso,
        const EquipmentProfile(
          brewers: {BrewMethod.espresso},
          hasScale: false,
          grinder: GrinderType.blade,
        ),
      ),
      {MissingEquipment.scale, MissingEquipment.grinder},
    );
    expect(
      missingEquipment(
        BrewMethod.v60,
        const EquipmentProfile(brewers: {BrewMethod.v60}),
      ),
      isEmpty,
    );
  });

  group(
    'paylaşım ve içe aktarma (KHV-FR-SOC-003, SOC-004, SOC-009, SOC-010)',
    () {
      final v60 = recipeOf(
        loadBundle(),
        BrewMethod.v60,
      ).copyWith(notes: 'gizli not', favorite: true);
      test('gidiş-dönüş; kaynak kimliği ve sürüm, kişisel alan yok '
          '(KHV-ARC-001)', () {
        final payload = encodeSharedRecipe(v60);
        final r = decodeSharedRecipe(payload, newId: 'yeni');
        expect(r.id, 'yeni');
        expect(r.sourceRecipeId, v60.id);
        expect(r.owner, RecipeOwner.user);
        expect(r.notes, isEmpty);
        expect(r.favorite, isFalse);
        expect(r.steps.length, v60.steps.length);
        expect(r.coffeeG, v60.coffeeG);
      });
      test('bozuk bağlantı reddedilir', () {
        expect(
          () => decodeSharedRecipe('%%%', newId: 'x'),
          throwsA(isA<RecipeValidationException>()),
        );
        expect(
          () => decodeSharedRecipe('eyJ2IjoyfQ', newId: 'x'),
          throwsA(isA<RecipeValidationException>()),
        );
        expect(
          () => decodeSharedRecipe('eyJ2IjoxLCJyZWNpcGUiOnt9fQ', newId: 'x'),
          throwsA(isA<RecipeValidationException>()),
        );
      });
      test('aralık dışı tarif reddedilir ve nedeni bildirilir', () {
        final bad = v60.copyWith(coffeeG: 200, name: '');
        try {
          decodeSharedRecipe(encodeSharedRecipe(bad), newId: 'x');
          fail('reddedilmeliydi');
        } on RecipeValidationException catch (e) {
          expect(e.reasons, isNotEmpty);
          expect(e.toString(), contains('Tarif adı'));
        }
      });
      test('doğrulama kuralları', () {
        expect(validateRecipe(v60), isEmpty);
        expect(validateRecipe(v60.copyWith(temperatureC: 120)), isNotEmpty);
        expect(validateRecipe(v60.copyWith(steps: const [])), isNotEmpty);
        expect(
          validateRecipe(
            v60.copyWith(
              steps: const [
                BrewStep(
                  title: 'a',
                  trigger: StepTrigger.weight,
                  targetWaterG: 100,
                ),
                BrewStep(
                  title: '',
                  trigger: StepTrigger.weight,
                  targetWaterG: 50,
                  durationS: -1,
                ),
                BrewStep(
                  title: 'c',
                  trigger: StepTrigger.weight,
                  targetWaterG: 900,
                ),
              ],
            ),
          ),
          hasLength(4),
        );
        expect(validateRecipe(v60.copyWith(coffeeG: 0)), isNotEmpty);
      });
    },
  );

  group('tat soruları (KHV-HMI-015)', () {
    test('en fazla üç soru', () {
      expect(tasteQuestions.length, lessThanOrEqualTo(3));
    });
    test('cevaplardan değerlendirme', () {
      final a = assessmentFromAnswers({
        'finish': 'sharp',
        'body': 'thin',
        'aroma': 'clear',
      }, score: 2);
      expect(a.notes, {TasteNote.sour, TasteNote.watery});
      final b = assessmentFromAnswers({'finish': 'both'}, score: 2);
      expect(b.sourAndBitter, isTrue);
      final c = assessmentFromAnswers({'aroma': 'flat'}, score: 2);
      expect(c.flat, isTrue);
      expect(
        () => assessmentFromAnswers({'finish': 'x'}, score: 2),
        throwsArgumentError,
      );
    });
  });

  group('tat değerlendirmesi', () {
    test('notlar', () {
      expect(TasteAssessment(score: 3).notes, {TasteNote.balanced});
      expect(TasteAssessment(score: 3).isBalanced, isTrue);
      expect(TasteAssessment(score: 3, extraction: 0.5, strength: 0.5).notes, {
        TasteNote.bitter,
        TasteNote.strong,
      });
      expect(TasteAssessment(score: 3, sourAndBitter: true, flat: true).notes, {
        TasteNote.sour,
        TasteNote.bitter,
        TasteNote.flat,
      });
      expect(
        TasteAssessment(
          score: 3,
          observations: {ProcessObservation.burnt},
        ).isBalanced,
        isFalse,
      );
    });
    test('JSON gidiş-dönüş', () {
      final t = TasteAssessment(
        score: 4,
        extraction: -0.3,
        strength: 0.2,
        flat: true,
        sourAndBitter: true,
      ).withObservations({ProcessObservation.noFoam});
      final back = TasteAssessment.fromJson(t.toJson());
      expect(back.toJson(), t.toJson());
    });
  });

  group('modeller', () {
    test('ekipman profili JSON ve eşitlik', () {
      const e = EquipmentProfile(
        brewers: {BrewMethod.v60, BrewMethod.espresso},
        grinder: GrinderType.electricBurr,
        hasScale: true,
        kettle: KettleType.temperatureControlled,
        hasWaterFilter: true,
        items: [
          OwnedEquipment(
            category: EquipmentCategory.brewer,
            method: BrewMethod.v60,
            freeText: 'Seramik dripper',
          ),
          OwnedEquipment(
            category: EquipmentCategory.grinder,
            freeText: 'Benim öğütücüm',
          ),
        ],
      );
      final back = EquipmentProfile.fromJson(e.toJson());
      expect(back, e);
      expect(back.hashCode, e.hashCode);
      expect(back.hasTemperatureKettle, isTrue);
      expect(e == e.copyWith(hasScale: false), isFalse);
      expect(EquipmentProfile.empty.scaleConfirmed, isFalse);
      expect(KettleType.standard.isGooseneck, isFalse);
    });
    test('tarif JSON gidiş-dönüş', () {
      for (final r in loadBundle().recipes) {
        final back = Recipe.fromJson(r.toJson());
        expect(back.toJson(), r.toJson());
        expect(back.steps, r.steps);
        expect(back.grind, r.grind);
        expect(back.grind.hashCode, r.grind.hashCode);
        expect(back.steps.first.hashCode, r.steps.first.hashCode);
      }
    });
    test('tarif yardımcıları', () {
      final v60 = recipeOf(loadBundle(), BrewMethod.v60);
      expect(v60.editable, isFalse);
      expect(v60.copyWith(owner: RecipeOwner.user).editable, isTrue);
      expect(v60.plannedDurationS, 120);
      expect(const GrindSetting('x', offset: 2).adjust(-1).offset, 1);
      expect(const GrindSetting('x', clicks: 5).toJson(), {
        'label': 'x',
        'clicks': 5,
      });
    });
    test('yöntem', () {
      expect(BrewMethod.parse('cold_brew'), BrewMethod.coldBrew);
      expect(BrewMethod.tryParse('yok'), isNull);
      expect(() => BrewMethod.parse('yok'), throwsFormatException);
      expect(BrewMethod.turkish.isCupBased, isTrue);
      expect(BrewMethod.espresso.isEspresso, isTrue);
      expect(BrewMethod.v60.usesPaperFilter, isTrue);
      expect(BrewMethod.frenchPress.usesPaperFilter, isFalse);
    });
  });

  group('içerik paketi (KHV-CNT-001, CNT-002, NFR-026)', () {
    final b = loadBundle();
    test('dokuz yöntem, tarif ve tüm belirtiler için kural var '
        '(KHV-FR-RCP-001, KHV-CNT-002)', () {
      expect(b.validate(), isEmpty);
      expect(b.methods, hasLength(9));
      expect(b.method(BrewMethod.turkish).tips, isNotEmpty);
    });
    test('her tarif geçerli', () {
      for (final r in b.recipes) {
        expect(validateRecipe(r), isEmpty, reason: r.id);
        expect(r.source, isNotEmpty, reason: 'KHV-CNT-003 ${r.id}');
      }
    });
    test('sıcak su/ocak adımlarında emniyet uyarısı (KHV-CNT-006)', () {
      for (final m in [
        BrewMethod.v60,
        BrewMethod.mokaPot,
        BrewMethod.turkish,
      ]) {
        expect(
          recipeOf(b, m).steps.any((s) => s.safety != null),
          isTrue,
          reason: m.id,
        );
      }
    });
    test('katalogdan seçilmiş eski kayıt serbest metin olarak korunur '
        '(KHV-FR-ONB-004, KB-017)', () {
      final e = OwnedEquipment.fromJson({
        'category': 'brewer',
        'method': 'v60',
        'catalogModelId': 'hario-v60-02',
      });
      expect(e.freeText, 'hario-v60-02');
      expect(e.toJson(), isNot(contains('catalogModelId')));
    });
    test('içerikte marka ve model kataloğu yok (KB-017)', () {
      final json = jsonDecode(
        File('../../app/assets/content/bundle.json').readAsStringSync(),
      ) as Map<String, Object?>;
      expect(json.containsKey('catalog'), isFalse);
      // Marka adı yalnız Bluetooth terazi uyumluluk listesinde geçer; bu bir
      // öneri değil, teknik tanımadır (KB-017, KB-028).
      final withoutScales = Map.of(json)..remove('scales');
      expect(jsonEncode(withoutScales), isNot(contains('"brand"')));
    });
    test('geçersiz paket reddedilir', () {
      expect(
        () => ContentBundle.fromJson({'version': 1}),
        throwsFormatException,
      );
      const dup = ContentBundle(
        version: 1,
        methods: [],
        recipes: [],
        rules: [],
        glossary: [],
        guides: [],
      );
      expect(dup.validate(), isNotEmpty);
    });
  });
}
