import 'dart:convert';

import 'package:ev_kahvesi/state/brew_state.dart';
import 'package:ev_kahvesi/state/providers.dart';
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
      'uygulama (UC-02, UC-03, KHV-FR-DIA-005)', (tester) async {
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
    await tester.tapAt(const Offset(200, 500));
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
    await tester.tapAt(const Offset(200, 500));
    await settle(tester, 2);
    expect(find.text('36 g'), findsOneWidget);
    await advance(tester, env, 18);
    await tester.tapAt(const Offset(200, 500));
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
