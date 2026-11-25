import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:ev_kahvesi/data/database.dart';
import 'package:ev_kahvesi/state/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

Future<void> scrollTo(WidgetTester tester, Finder f, {double by = 300}) =>
    tester.scrollUntilVisible(f, by, scrollable: find.byType(Scrollable).first);

Future<void> seedBrews(TestEnv env) async {
  final v60 = bundle.recipes.firstWhere((r) => r.id == 'sys-v60');
  final esp = bundle.recipes.firstWhere((r) => r.id == 'sys-espresso');
  await env.db.saveBean(
    BeansCompanion.insert(
      id: 'k1',
      name: 'Kenya',
      createdAt: DateTime(2026),
      remainingG: const Value(200),
    ),
  );
  for (final (id, r, score, bean) in [
    ('b1', v60, 5, 'k1'),
    ('b2', esp, 2, null),
    ('b3', v60, 3, null),
  ]) {
    await env.db.insertBrew(
      BrewsCompanion.insert(
        id: id,
        brewedAt: DateTime(2026, 11, int.parse(id.substring(1))),
        recipeId: r.id,
        lineageId: r.id,
        methodId: r.method.id,
        recipeJson: jsonEncode(r.toJson()),
        beanId: Value(bean),
        score: Value(score),
        assessmentJson: Value(
          jsonEncode(TasteAssessment(score: score).toJson()),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('ekipman profili ayarlardan düzenlenir, profil değişir '
      '(KHV-FR-ONB-003)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    await tester.tap(find.text('Ayarlar'));
    await settle(tester);
    expect(find.textContaining('P2 Meraklı'), findsNothing);
    await tester.tap(find.text('Demleme araçları'));
    await settle(tester);
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Espresso'));
    await settle(tester);
    final s = AppSettings.fromJson((await env.db.readJson('settings'))!);
    expect(s.equipment.brewers, {BrewMethod.v60});
    expect(s.profile, UserProfile.enthusiast);
    await tester.tap(find.widgetWithText(CheckboxListTile, 'V60 / Pour over'));
    await settle(tester);
    final empty = AppSettings.fromJson((await env.db.readJson('settings'))!);
    expect(empty.equipment.brewers, isEmpty);
    // Bölüm 2: ekipmanı olmayan kullanıcı P5 (bkz. kalite bulgusu KB-001).
    expect(empty.profile, UserProfile.shopper);
  });

  testWidgets('araç adı serbest metinle girilir, marka listesi yok '
      '(KHV-FR-ONB-004, KB-017)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    await tester.tap(find.text('Ayarlar'));
    await settle(tester);
    await tester.tap(find.text('Demleme araçları'));
    await settle(tester);
    await scrollTo(tester, find.text('V60 / Pour over modeli'));
    await tester.tap(find.text('V60 / Pour over modeli'));
    await settle(tester);
    expect(find.text('Hario V60 02'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Seramik dripper');
    await tester.tap(find.text('Kaydet'));
    await settle(tester);
    await scrollTo(tester, find.text('Öğütücü modeli'));
    await tester.tap(find.text('Öğütücü modeli'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Dedemin değirmeni');
    await tester.tap(find.text('Kaydet'));
    await settle(tester);
    final s = AppSettings.fromJson((await env.db.readJson('settings'))!);
    expect(
      s.equipment.items.map((i) => i.freeText),
      containsAll(['Seramik dripper', 'Dedemin değirmeni']),
    );
    // Yazılan ad araç satırında görünür.
    await scrollTo(tester, find.text('Seramik dripper'), by: -300);
    expect(find.text('Seramik dripper'), findsOneWidget);
  });

  testWidgets('yıldız, miktar değiştirildikten sonra da favoriye ekler ve '
      'çıkarır (KB-016, KHV-FR-RCP-011)', (tester) async {
    await setUpEnv(tester, settings: v60User);
    await tester.tap(find.text('V60 başlangıç'));
    await settle(tester);
    // Miktar değişince ekran düzenlenen kopyayı gösterir.
    await tester.tap(find.byIcon(Icons.add).first);
    await settle(tester);
    await tester.tap(find.byTooltip('Favorilere ekle'));
    await settle(tester);
    expect(find.byTooltip('Favorilerden çıkar'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
    await tester.tap(find.byTooltip('Favorilerden çıkar'));
    await settle(tester);
    expect(find.byTooltip('Favorilere ekle'), findsOneWidget);
  });

  testWidgets('favori ana ekranda, tek dokunuşla başlar (KHV-FR-RCP-011, '
      'UC-07)', (tester) async {
    await setUpEnv(tester, settings: v60User);
    expect(find.text('Favoriler'), findsNothing);
    await tester.tap(find.text('V60 başlangıç'));
    await settle(tester);
    await tester.tap(find.byTooltip('Favorilere ekle'));
    await settle(tester);
    await tester.tap(find.text('Demle'));
    await settle(tester);
    expect(find.text('Favoriler'), findsOneWidget);
    await tester.tap(find.byTooltip('V60 başlangıç hemen başlat'));
    await settle(tester, 6);
    expect(find.text('Adım 1/6'), findsOneWidget, reason: 'hazırlık atlandı');
  });

  testWidgets('kendi tarifi yeniden adlandırılır ve silinir; sistem tarifi '
      'düzenlenemez (KHV-FR-RCP-013)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    await tester.tap(find.text('V60 başlangıç'));
    await settle(tester);
    await tester.tap(find.byTooltip('Diğer işlemler'));
    await settle(tester);
    expect(find.text('Sil'), findsNothing);
    expect(find.text('Yeniden adlandır'), findsNothing);
    await tester.tap(find.text('Kendi tarifim olarak kaydet'));
    await settle(tester);
    await tester.tap(find.text('Kaydet'));
    await settle(tester);
    await tester.tap(find.byTooltip('Diğer işlemler'));
    await settle(tester);
    await tester.tap(find.text('Yeniden adlandır'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Akşam V60');
    await tester.tap(find.text('Kaydet'));
    await settle(tester);
    expect(
      (await tester.runAsync(() => env.db.watchUserRecipes().first))!
          .single
          .name,
      'Akşam V60',
    );
    await tester.tap(find.byTooltip('Diğer işlemler'));
    await settle(tester);
    await tester.tap(find.text('Sil'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Sil'));
    await settle(tester);
    expect(
      await tester.runAsync(() => env.db.watchUserRecipes().first),
      isEmpty,
    );
  });

  testWidgets('günlük yönteme, çekirdeğe ve puana göre süzülür '
      '(KHV-FR-LOG-002)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    await seedBrews(env);
    await tester.tap(find.text('Günlük'));
    await settle(tester);
    expect(find.text('5/5'), findsOneWidget);
    expect(find.text('2/5'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Yöntem'));
    await settle(tester);
    await tester.tap(find.widgetWithText(MenuItemButton, 'Espresso'));
    await settle(tester);
    expect(find.text('2/5'), findsOneWidget);
    expect(find.text('5/5'), findsNothing);
    await tester.tap(find.widgetWithText(FilterChip, 'Espresso'));
    await settle(tester);
    await tester.tap(find.widgetWithText(MenuItemButton, 'Tümü'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Puan'));
    await settle(tester);
    await tester.tap(find.widgetWithText(MenuItemButton, '3 ve üzeri'));
    await settle(tester);
    expect(find.text('2/5'), findsNothing);
    expect(find.text('3/5'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Çekirdek'));
    await settle(tester);
    await tester.tap(find.widgetWithText(MenuItemButton, 'Kenya'));
    await settle(tester);
    expect(find.text('5/5'), findsOneWidget);
    expect(find.text('3/5'), findsNothing);
  });

  testWidgets('kayıttan aynı parametrelerle demleme; kayıt silinir ve 5 sn '
      'içinde geri alınır (KHV-FR-LOG-003, LOG-007)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    await seedBrews(env);
    await tester.tap(find.text('Günlük'));
    await settle(tester);
    await tester.tap(find.text('5/5'));
    await settle(tester);
    await tester.tap(find.byTooltip('Kaydı sil'));
    await settle(tester);
    expect(find.text('5/5'), findsNothing);
    await tester.tap(find.text('Geri al'));
    await settle(tester);
    expect(find.text('5/5'), findsOneWidget);
    await tester.tap(find.text('5/5'));
    await settle(tester);
    await scrollTo(tester, find.text('Aynı parametrelerle demle'));
    await tester.tap(find.text('Aynı parametrelerle demle'));
    await settle(tester);
    expect(find.text('Hazırlık · V60 başlangıç'), findsOneWidget);
  });

  testWidgets('bitmiş çekirdek arşivlenir, yeni demlemede listelenmez '
      '(KHV-FR-LOG-008)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    await seedBrews(env);
    await tester.tap(find.text('Günlük'));
    await settle(tester);
    await tester.tap(find.text('Çekirdekler'));
    await settle(tester);
    await tester.tap(find.text('Kenya'));
    await settle(tester);
    await scrollTo(tester, find.text('Bitti, arşivle'));
    await tester.tap(find.text('Bitti, arşivle'));
    await tester.tap(find.text('Kaydet'));
    await settle(tester);
    expect(find.text('Kenya (arşiv)'), findsOneWidget);
    await tester.tap(find.text('Demle'));
    await settle(tester);
    await tester.tap(find.text('V60 başlangıç'));
    await settle(tester);
    await tester.tap(find.text('Rehberle demle'));
    await settle(tester);
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await settle(tester);
    expect(find.text('Kenya'), findsNothing);
  });

  testWidgets('tek ayarlar ekranı ve elle profil seçimi (KHV-FR-SET-001, '
      'SET-002, KHV-NFR-036)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    await tester.tap(find.text('Ayarlar'));
    await settle(tester);
    for (final section in [
      'Ekipman profili',
      'Görünüm',
      'Demleme uyarıları',
      'Bildirimler',
      'Çekirdek',
      'Gizlilik',
      'Veri',
      'Hakkında',
    ]) {
      await scrollTo(tester, find.text(section));
      expect(find.text(section), findsWidgets, reason: section);
    }
    await scrollTo(tester, find.text('Açık kaynak lisansları'));
    expect(find.text('Açık kaynak lisansları'), findsOneWidget);
    await scrollTo(tester, find.text('Profil seviyesi'), by: -300);
    await tester.ensureVisible(find.text('Profil seviyesi'));
    await settle(tester);
    await tester.tap(find.text('Profil seviyesi'));
    await settle(tester);
    await tester.tap(find.text('P3 Espresso kullanıcısı'));
    await settle(tester);
    final s = AppSettings.fromJson((await env.db.readJson('settings'))!);
    expect(s.profileOverride, UserProfile.espresso);
    expect(find.text('P3 Espresso kullanıcısı'), findsOneWidget);
  });

  testWidgets('yardım: SSS ve terim açıklaması (KHV-FR-HLP-002, '
      'KHV-HMI-018)', (tester) async {
    await setUpEnv(tester, settings: v60User);
    await tester.tap(find.byTooltip('Yardım ve sözlük'));
    await settle(tester);
    await tester.tap(find.text('Ekşi ile acıyı nasıl ayırırım?'));
    await settle(tester);
    expect(find.textContaining('limon gibi keskin'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await settle(tester);
    await tester.tap(find.text('V60 başlangıç'));
    await settle(tester);
    await scrollTo(tester, find.widgetWithText(ActionChip, 'Bloom'));
    await tester.tap(find.widgetWithText(ActionChip, 'Bloom'));
    await settle(tester);
    expect(find.textContaining('gazının (CO₂)'), findsOneWidget);
  });

  testWidgets('içerik açılamazsa sade dille hata (KHV-HMI-042)', (
    tester,
  ) async {
    await setUpEnv(
      tester,
      settings: v60User,
      configure: (e) => e.contentError = true,
    );
    expect(find.text('İçerik açılamadı'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.textContaining('yeniden başlatın'), findsOneWidget);
  });
}
