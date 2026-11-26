import 'package:ev_kahvesi/state/settings.dart';
import 'package:ev_kahvesi/ui/scene.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

void main() {
  testWidgets('tarif: doz değişince su ölçeklenir, terazi yoksa kaşık, '
      'kettle standart ise bekleme; artır/azalt girişi ve Türkçe sayı biçimi '
      '(KHV-FR-RCP-004, RCP-007, RCP-008, RCP-010, KHV-HMI-011, '
      'KHV-NFR-010, NFR-031)', (tester) async {
    await setUpEnv(
      tester,
      settings: const AppSettings(
        onboardingDone: true,
        equipment: EquipmentProfile(
          brewers: {BrewMethod.v60},
          hasScale: false,
          grinder: GrinderType.none,
          kettle: KettleType.standard,
        ),
      ),
    );
    await tester.tap(find.text('V60 başlangıç'));
    await settle(tester);
    expect(find.text('15 g'), findsOneWidget);
    expect(find.text('250 g'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('yemek kaşığı'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // KHV-FR-RCP-007: standart kettle ile pour over.
    expect(find.text('Eksik ekipman'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byTooltip('Kahve artır'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Kahve artır'));
    await settle(tester);
    expect(find.text('15,5 g'), findsOneWidget);
    expect(find.text('258 g'), findsOneWidget);
    // KHV-HMI-017: P1 profilinde sıcaklık gizli.
    expect(find.text('Su sıcaklığı'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Ayrıntılar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Ayrıntılar'));
    await settle(tester);
    expect(find.text('Su sıcaklığı'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('saniye bekletin'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
  });

  testWidgets('kendi tarifim olarak kaydet (KHV-FR-RCP-006)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    await tester.tap(find.text('V60 başlangıç'));
    await settle(tester);
    await tester.tap(find.byTooltip('Diğer işlemler'));
    await settle(tester);
    await tester.tap(find.text('Kendi tarifim olarak kaydet'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Sabah V60');
    await tester.tap(find.text('Kaydet'));
    await settle(tester);
    final mine = (await tester.runAsync(
      () => env.db.watchUserRecipes().first,
    ))!;
    expect(mine.single.name, 'Sabah V60');
    expect(mine.single.sourceRecipeId, 'sys-v60');
    expect(mine.single.owner, RecipeOwner.user);
  });

  testWidgets('arama Türkçe karakterlere duyarsız (KHV-FR-RCP-012)', (
    tester,
  ) async {
    await setUpEnv(tester, settings: v60User);
    await tester.enterText(find.byType(SearchBar), 'turk kahvesi');
    await settle(tester);
    expect(find.text('Türk kahvesi 2 fincan'), findsOneWidget);
    expect(find.text('V60 başlangıç'), findsNothing);
  });

  testWidgets('uyarı kanalları: en az ikisi açık kalır (KHV-HMI-005)', (
    tester,
  ) async {
    final env = await setUpEnv(tester, settings: v60User);
    await tester.tap(find.text('Ayarlar'));
    await settle(tester);
    await tester.tap(find.text('Ses'));
    await settle(tester);
    await tester.tap(find.text('Titreşim'));
    await settle(tester);
    expect(find.textContaining('en az iki kanal'), findsOneWidget);
    final s = AppSettings.fromJson((await env.db.readJson('settings'))!);
    expect(s.alerts, {AlertChannel.visual, AlertChannel.vibration});
    expect(s.analyticsConsent, isFalse, reason: 'KHV-NFR-017');
  });

  testWidgets('ne demliyoruz: yöntem seçimi listeyi süzer, sahnedeki takımı '
      'değiştirir (KHV-FR-RCP-012, KB-026)', (tester) async {
    await setUpEnv(tester, settings: v60User);
    Finder scene(BrewMethod m) =>
        find.byWidgetPredicate((w) => w is CoffeeScene && w.method == m);
    // Seçim yokken sahne ilk aracı (V60) gösterir, tüm tarifler listelenir.
    expect(scene(BrewMethod.v60), findsOneWidget);
    expect(find.text('V60 başlangıç'), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Espresso'));
    await settle(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Espresso'));
    await settle(tester);
    expect(scene(BrewMethod.espresso), findsOneWidget);
    expect(find.text('V60 başlangıç'), findsNothing);
    expect(find.textContaining('Espresso'), findsWidgets);
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Tümü'));
    await settle(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tümü'));
    await settle(tester);
    expect(find.text('V60 başlangıç'), findsOneWidget);
  });

  testWidgets('ekipman rehberi: öneri ve kriterler, marka yok '
      '(KHV-FR-EQP-001, EQP-002, EQP-004, KB-017)', (tester) async {
    await setUpEnv(
      tester,
      settings: const AppSettings(
        onboardingDone: true,
        equipment: EquipmentProfile(brewers: {BrewMethod.v60}),
      ),
    );
    await tester.tap(find.text('Ekipman'));
    await settle(tester);
    expect(find.text('Sıradaki önerimiz'), findsOneWidget);
    expect(find.text('Kavurma tarihi yazılı taze çekirdek'), findsOneWidget);
    await tester.tap(find.text('Terazi'));
    await settle(tester);
    expect(find.text('0,1 g çözünürlük'), findsOneWidget);
    // Marka ve model önerilmez; bütçe filtresi yok (ürün sahibi kararı).
    for (final brand in [
      'Fellow',
      'Acaia',
      'Hario',
      'Baratza',
      'Tüm bütçeler',
    ]) {
      expect(find.textContaining(brand), findsNothing, reason: brand);
    }
    expect(find.textContaining('TL'), findsNothing, reason: 'KHV-FR-EQP-006');
  });

  testWidgets('günlük boş durumu ve elle kayıt (KHV-HMI-032, KHV-FR-LOG-006)', (
    tester,
  ) async {
    final env = await setUpEnv(tester, settings: v60User);
    await tester.tap(find.text('Günlük'));
    await settle(tester);
    expect(find.text('Henüz demleme yok'), findsOneWidget);
    await tester.tap(find.text('Elle kaydet'));
    await settle(tester);
    await tester.tap(find.text('Kaydet ve tadı değerlendir'));
    await settle(tester);
    expect(find.text('Tadı nasıldı?'), findsOneWidget);
    final brews = (await tester.runAsync(() => env.db.watchBrews().first))!;
    expect(brews.single.manual, isTrue);
  });

  testWidgets('çekirdek ekle; kavurmadan geçen gün (KHV-FR-LOG-004)', (
    tester,
  ) async {
    final env = await setUpEnv(tester, settings: v60User);
    await tester.tap(find.text('Günlük'));
    await settle(tester);
    await tester.tap(find.text('Çekirdekler'));
    await settle(tester);
    await tester.tap(find.text('Çekirdek ekle').last);
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Ad'), 'Etiyopya');
    await tester.tap(find.text('Kaydet'));
    await settle(tester);
    final beans = (await tester.runAsync(() => env.db.watchBeans().first))!;
    expect(beans.single.name, 'Etiyopya');
    expect(beans.single.remainingG, 250);
  });

  testWidgets('yardım: sözlük araması (KHV-FR-HLP-001)', (tester) async {
    await setUpEnv(tester, settings: v60User);
    await tester.tap(find.byTooltip('Yardım ve sözlük'));
    await settle(tester);
    await tester.enterText(find.byType(SearchBar), 'kanal');
    await settle(tester);
    expect(find.text('Channeling'), findsOneWidget);
    expect(find.text('Bloom'), findsNothing);
  });

  testWidgets('hesaplayıcı: kahve ve orandan su (KHV-FR-RCP-002)', (
    tester,
  ) async {
    await setUpEnv(tester, settings: v60User);
    await tester.tap(find.byTooltip('Hesaplayıcı'));
    await settle(tester);
    expect(find.text('240 g su'), findsOneWidget);
  });

  testWidgets('en büyük yazı boyutunda taşma yok (KHV-HMI-028)', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await setUpEnv(tester, settings: v60User);
    await tester.tap(find.text('V60 başlangıç'));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });
}
