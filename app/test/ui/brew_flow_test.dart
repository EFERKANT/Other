import 'dart:convert';

import 'package:ev_kahvesi/state/brew_state.dart';
import 'package:ev_kahvesi/state/providers.dart';
import 'package:ev_kahvesi/ui/scene.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

Future<void> advance(WidgetTester tester, TestEnv env, int seconds) async {
  for (var i = 0; i < seconds; i++) {
    env.clock.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> openV60(WidgetTester tester) async {
  await tester.tap(find.text('V60 başlangıç'));
  await settle(tester);
  await tester.tap(find.text('Rehberle demle'));
  await settle(tester);
}

void main() {
  testWidgets('tam döngü: rehberli demleme → tat → tek düzeltme → tarife '
      'uygulama (UC-02, UC-03, KHV-FR-BRW-001, BRW-002, BRW-007, DIA-001, '
      'DIA-005, LOG-001)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    await openV60(tester);
    // KHV-FR-BRW-001 hazırlık listesi.
    expect(
      find.text('Kağıt filtreyi sıcak suyla durula, suyu dök'),
      findsOneWidget,
    );
    await tester.tap(find.text('Demlemeyi başlat'));
    await settle(tester, 4);

    // KHV-HMI-001: birincil bilgi hedef kümülatif ağırlık.
    expect(find.text('30 g'), findsOneWidget);
    expect(find.text('Adım 1/6'), findsOneWidget);
    // KHV-HMI-021: emniyet uyarısı adım ekranında.
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    // Aktif demleme kalıcı (KHV-NFR-003).
    expect(await env.db.readJson(activeBrewKey), isNotNull);

    await advance(tester, env, 10);
    expect(find.text('Adım 2/6'), findsOneWidget);
    await advance(tester, env, 110);
    // KHV-HMI-003: onay adımı kendiliğinden geçmez.
    expect(find.text('Adım 6/6'), findsOneWidget);
    await advance(tester, env, 30);
    expect(find.text('Adım 6/6'), findsOneWidget);
    // KHV-HMI-006: ekranın herhangi bir yerine dokunarak ilerle.
    await tester.tap(find.textContaining('Adım '));
    await settle(tester);

    // KHV-FR-BRW-007: tat ekranı açılır, aktif demleme temizlenir.
    expect(find.text('Tadı nasıldı?'), findsOneWidget);
    expect(await env.db.readJson(activeBrewKey), isNull);
    final brews = (await tester.runAsync(() => env.db.watchBrews().first))!;
    expect(brews, hasLength(1));
    expect(brews.single.actualTimeS, 150);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Ekşi'));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('Öneriyi göster'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Öneriyi göster'));
    await settle(tester);
    expect(find.text('Öğütmeyi bir kademe incelt'), findsOneWidget);
    expect(find.textContaining('Neden:'), findsOneWidget);

    await tester.ensureVisible(find.text('Öneriyi tarife uygula'));
    await settle(tester);
    await tester.tap(find.text('Öneriyi tarife uygula'));
    await settle(tester);

    final saved = await env.db.brewById(brews.single.id);
    expect(saved!.correctionAccepted, isTrue);
    expect(saved.score, 3);
    final mine = (await tester.runAsync(
      () => env.db.watchUserRecipes().first,
    ))!;
    expect(mine.single.name, 'V60 başlangıç (ayarım)');
    expect(mine.single.grind.offset, -1);
    expect(mine.single.sourceRecipeId, 'sys-v60');
    expect(find.text('V60 başlangıç (ayarım)'), findsWidgets);
    await tester.scrollUntilVisible(
      find.textContaining('1 kademe daha ince'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('1 kademe daha ince'), findsOneWidget);
  });

  testWidgets('duraklat, adım atla ve geri al (KHV-HMI-009, HMI-010)', (
    tester,
  ) async {
    final env = await setUpEnv(tester, settings: v60User);
    await openV60(tester);
    await tester.tap(find.text('Demlemeyi başlat'));
    await settle(tester, 4);
    await tester.tap(find.byTooltip('Duraklat'));
    await settle(tester, 2);
    expect(find.text('DURAKLATILDI'), findsOneWidget);
    await advance(tester, env, 20);
    expect(find.text('Adım 1/6'), findsOneWidget);
    await tester.tap(find.byTooltip('Devam et'));
    await settle(tester, 2);
    await tester.tap(find.byTooltip('Adımı atla'));
    await settle(tester, 10);
    expect(find.text('Adım 2/6'), findsOneWidget);
    await tester.tap(find.text('Geri al'));
    await settle(tester, 2);
    expect(find.text('Adım 1/6'), findsOneWidget);
  });

  testWidgets('adım atlandı bildirimi duraklat ve bitir düğmelerini örtmez '
      '(KB-012, KHV-HMI-009)', (tester) async {
    await setUpEnv(tester, settings: v60User);
    await openV60(tester);
    await tester.tap(find.text('Demlemeyi başlat'));
    await settle(tester, 4);
    await tester.tap(find.byTooltip('Adımı atla'));
    await settle(tester, 10);
    // Görünen bildirim kutusu (kenar boşluğu hariç).
    final snack = tester.getRect(
      find
          .ancestor(
            of: find.text('Adım atlandı'),
            matching: find.byType(Material),
          )
          .first,
    );
    for (final control in [
      find.byTooltip('Duraklat'),
      find.byTooltip('Adımı atla'),
      find.textContaining('Bitir'),
    ]) {
      expect(snack.overlaps(tester.getRect(control)), isFalse);
    }
    // Bildirim ekrandayken duraklatma çalışır.
    await tester.tap(find.byTooltip('Duraklat'));
    await settle(tester, 2);
    expect(find.text('DURAKLATILDI'), findsOneWidget);
  });

  testWidgets('son adım atlanınca demleme biter, Geri al bildirimi tat '
      'ekranına taşınmaz (KB-020, KHV-HMI-009)', (tester) async {
    await setUpEnv(tester, settings: v60User);
    await openV60(tester);
    await tester.tap(find.text('Demlemeyi başlat'));
    await settle(tester, 4);
    for (
      var i = 0;
      i < 6 && find.text('Tadı nasıldı?').evaluate().isEmpty;
      i++
    ) {
      await tester.tap(find.byTooltip('Adımı atla'));
      await settle(tester, 10);
    }
    expect(find.text('Tadı nasıldı?'), findsOneWidget);
    // Kapanmakta olan bildirimin çıkış animasyonu biter.
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
    expect(find.text('Geri al'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demleme sürerken geri tuşu demlemeyi kapatmaz, Bitir\'e '
      'yönlendirir (KB-021, KHV-HMI-009)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    await openV60(tester);
    await tester.tap(find.text('Demlemeyi başlat'));
    await settle(tester, 4);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.text('Adım 1/6'), findsOneWidget);
    expect(find.textContaining('basılı tutun'), findsOneWidget);
    expect(await env.db.readJson(activeBrewKey), isNotNull);
  });

  testWidgets('demlemede yöntemin canlı çizimi: dökmede oynar, duraklatınca '
      've hareketi azaltta durur (KB-027, KHV-HMI-024)', (tester) async {
    BrewAnimation anim() =>
        tester.widget<BrewAnimation>(find.byType(BrewAnimation));
    await setUpEnv(tester, settings: v60User);
    await openV60(tester);
    await tester.tap(find.text('Demlemeyi başlat'));
    await settle(tester, 4);
    // V60 ilk adım: 30 g'a kadar dök.
    expect(anim().method, BrewMethod.v60);
    expect(anim().motion, BrewMotion.pour);
    expect(anim().animate, isTrue);
    await tester.tap(find.byTooltip('Duraklat'));
    await settle(tester, 2);
    expect(anim().animate, isFalse);
    await tester.tap(find.byTooltip('Devam et'));
    await settle(tester, 2);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await settle(tester, 2);
    expect(anim().animate, isFalse);
  });

  testWidgets('kayıtlı çekirdek yoksa hazırlıktan eklenir ve seçilebilir '
      '(KB-014, KHV-FR-LOG-004)', (tester) async {
    await setUpEnv(tester, settings: v60User);
    await openV60(tester);
    // Hazırlık ekranının üstünde yöntem çizimi var; çekirdek alanına kaydır.
    await tester.scrollUntilVisible(
      find.text('Kayıtlı çekirdek yok.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Kayıtlı çekirdek yok.'), findsOneWidget);
    await tester.ensureVisible(find.text('Çekirdek ekle'));
    await tester.tap(find.text('Çekirdek ekle'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Ad'), 'Etiyopya');
    await tester.tap(find.text('Kaydet'));
    await settle(tester);
    // Hazırlığa dönülür, yeni çekirdek listede.
    expect(find.text('Hazırlık · V60 başlangıç'), findsOneWidget);
    expect(find.text('Kayıtlı çekirdek yok.'), findsNothing);
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await settle(tester);
    expect(find.text('Etiyopya'), findsOneWidget);
  });

  testWidgets('kesinti sonrası aktif demlemeye dönülür (KHV-HMI-023)', (
    tester,
  ) async {
    final recipe = bundle.recipes.firstWhere((r) => r.id == 'sys-v60');
    final timer = BrewTimer(recipe.steps)..start(0);
    timer.tick(15000);
    final clock = FakeClock();
    final json = jsonEncode(
      ActiveBrew(
        recipe: recipe,
        snapshot: timer.snapshot(15000),
        savedAt: clock.wall.subtract(const Duration(seconds: 5)),
      ).toJson(),
    );
    final env2 = await setUpEnv(tester, settings: v60User);
    await env2.db.writeJson(
      activeBrewKey,
      (jsonDecode(json) as Map).cast<String, Object?>(),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(env2.app());
    await settle(tester);
    expect(find.text('Adım 2/6'), findsOneWidget);
    // 15 sn + 5 sn kesinti = 20 sn; 2. adımın 10. saniyesi.
    expect(find.text('0:25'), findsOneWidget);
  });

  testWidgets('espresso shot analizi (UC-04, KHV-FR-BRW-008)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    await tester.tap(find.text('Espresso 1:2'));
    await settle(tester);
    await tester.tap(find.text('Rehberle demle'));
    await settle(tester);
    await tester.tap(find.text('Demlemeyi başlat'));
    await settle(tester, 4);
    await tester.tap(find.textContaining('Adım '));
    await settle(tester, 2);
    expect(find.text('36 g'), findsOneWidget);
    await advance(tester, env, 18);
    await tester.tap(find.textContaining('Adım '));
    await settle(tester);
    expect(find.text('Tadı nasıldı?'), findsOneWidget);
    expect(find.textContaining('sn hızlı'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Öneriyi göster'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Öneriyi göster'));
    await settle(tester);
    expect(find.text('Öğütmeyi incelt'), findsOneWidget);
    expect(find.text('Shot çok hızlı'), findsOneWidget);
  });

  test('recipeById yardımcıları', () {
    expect(brewRecipe, isNotNull);
  });
}
