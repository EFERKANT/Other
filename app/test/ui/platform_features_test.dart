import 'dart:convert';

import 'package:ev_kahvesi/state/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

Future<void> startV60(WidgetTester tester) async {
  await tester.tap(find.text('V60 başlangıç'));
  await settle(tester);
  await tester.tap(find.text('Rehberle demle'));
  await settle(tester);
  await tester.tap(find.text('Demlemeyi başlat'));
  await settle(tester, 6);
}

Future<void> advance(WidgetTester tester, TestEnv env, int seconds) async {
  for (var i = 0; i < seconds; i++) {
    env.clock.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('ön izin ekranı ilk demlemede bir kez (KHV-HMI-037), Türkçe '
      'ses yoksa yardım (KHV-FR-BRW-013)', (tester) async {
    final env = await setUpEnv(
      tester,
      settings: const AppSettings(
        onboardingDone: true,
        equipment: EquipmentProfile(brewers: {BrewMethod.v60}),
      ),
      configure: (e) => e.speaker.available = false,
    );
    await tester.tap(find.text('V60 başlangıç'));
    await settle(tester);
    await tester.tap(find.text('Rehberle demle'));
    await settle(tester);
    await tester.tap(find.text('Demlemeyi başlat'));
    await settle(tester);
    expect(
      find.text('Telefon kilitliyken de haber verelim mi?'),
      findsOneWidget,
    );
    expect(find.text('Şimdi değil'), findsOneWidget);
    await tester.tap(find.text('İzin ver'));
    await settle(tester);
    expect(env.notifications.permissionRequests, 1);
    expect(find.text('Türkçe ses bulunamadı'), findsOneWidget);
    await tester.tap(find.text('Anladım'));
    await settle(tester, 6);
    expect(find.text('Adım 1/6'), findsOneWidget);
    expect(env.speaker.spoken, isEmpty);
    final s = AppSettings.fromJson((await env.db.readJson('settings'))!);
    expect(s.notificationPermissionAsked, isTrue);
    expect(s.ttsHelpShown, isTrue);
  });

  testWidgets('sesli adım komutu (KHV-HMI-007)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    await startV60(tester);
    expect(env.speaker.spoken, ['30 grama kadar dök']);
    await advance(tester, env, 10);
    expect(env.speaker.spoken.last, 'Bekle (bloom)');
    await advance(tester, env, 35);
    expect(env.speaker.spoken.last, '150 grama kadar dök');
  });

  testWidgets('arka planda adım geçişi bildirimleri ve kilit ekranı '
      '(KHV-FR-BRW-005, KHV-HMI-022)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    await startV60(tester);
    await advance(tester, env, 4);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await settle(tester, 4);
    final n = env.notifications;
    // 6 sn sonra bekleme adımı, onay adımına kadar 5 geçiş.
    expect(n.scheduled.length, 5);
    final first = n.scheduled[1000]!;
    expect(first.$2, 'Bekle (bloom)');
    expect(first.$3.difference(env.clock.wall).inSeconds, closeTo(6, 1));
    expect(n.scheduled[1004]!.$2, 'Süzülmeyi bekle');
    expect(n.ongoing[900]!.$1, contains('Adım 1/6'));
    expect(n.ongoing[900]!.$2, isNotNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester, 4);
    expect(n.scheduled, isEmpty);
    expect(n.ongoing, isEmpty);
  });

  testWidgets('uzun demleme bitişi bildirimi (KHV-FR-BRW-009)', (tester) async {
    final env = await setUpEnv(
      tester,
      settings: v60User.copyWith(
        equipment: const EquipmentProfile(brewers: {BrewMethod.coldBrew}),
      ),
    );
    await tester.tap(find.text('Cold brew konsantre'));
    await settle(tester);
    await tester.tap(find.text('Rehberle demle'));
    await settle(tester);
    await tester.tap(find.text('Demlemeyi başlat'));
    await settle(tester, 6);
    await tester.tap(find.textContaining('Adım '));
    await settle(tester, 4);
    await tester.tap(find.text('Arka planda takip et'));
    await settle(tester);
    // Ana ekrana dön (KHV-FR-BRW-010).
    await tester.tap(find.text('Demle'));
    await settle(tester);
    expect(find.textContaining('Bitiş:'), findsOneWidget);
    final n = env.notifications.scheduled.values.single;
    expect(n.$1, 'Cold brew konsantre hazır');
    expect(n.$3.difference(env.clock.wall).inHours, 14);
  });

  testWidgets('uzun demleme bitmeden açılınca kalan süre gösterilir, erken '
      'kayıt olmaz; geri dönülebilir (KB-024, KHV-FR-BRW-009)', (tester) async {
    final env = await setUpEnv(
      tester,
      settings: v60User.copyWith(
        equipment: const EquipmentProfile(brewers: {BrewMethod.coldBrew}),
      ),
    );
    await tester.tap(find.text('Cold brew konsantre'));
    await settle(tester);
    await tester.tap(find.text('Rehberle demle'));
    await settle(tester);
    await tester.tap(find.text('Demlemeyi başlat'));
    await settle(tester, 6);
    await tester.tap(find.textContaining('Adım '));
    await settle(tester, 4);
    await tester.tap(find.text('Arka planda takip et'));
    await settle(tester);
    await tester.tap(find.text('Demle'));
    await settle(tester);
    await tester.tap(find.text('Aç'));
    await settle(tester, 6);
    expect(find.text('Demleniyor'), findsOneWidget);
    expect(find.text('Çift filtrele'), findsNothing);
    // İki dokunuşla erken kayıt olmaz.
    await tester.tap(find.textContaining('Adım '));
    await settle(tester, 4);
    await tester.tap(find.textContaining('Adım '));
    await settle(tester, 4);
    expect(find.text('Tadı nasıldı?'), findsNothing);
    final brews = (await tester.runAsync(() => env.db.watchBrews().first))!;
    expect(brews, isEmpty);
    // Geri dönülür; uzun demleme ve bildirimi sürer.
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.textContaining('Bitiş:'), findsOneWidget);
    expect(env.notifications.scheduled, hasLength(1));
  });

  testWidgets('paylaşım kartı: görsel + bağlantı, kişisel veri yok '
      '(KHV-FR-SOC-001, SOC-002, SOC-010)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    await tester.tap(find.text('V60 başlangıç'));
    await settle(tester);
    await tester.tap(find.byTooltip('Diğer işlemler'));
    await settle(tester);
    await tester.tap(find.text('Paylaş'));
    await settle(tester);
    expect(find.text('Ev Kahvesi ile demlendi'), findsOneWidget);
    await tester.tap(find.text('Story'));
    await settle(tester);
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Paylaş'));
      for (var i = 0; i < 50 && env.sharer.files.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    await settle(tester);
    final (name, bytes, text) = env.sharer.files.single;
    expect(name, endsWith('.png'));
    expect(bytes.sublist(1, 4), utf8.encode('PNG'));
    expect(text, contains('https://evkahvesi.app/r/'));
    final payload = text!.split('/r/').last;
    final decoded = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
    expect(decoded, isNot(contains('notes')));
    expect(decoded, contains('sys-v60'));
  });

  testWidgets('paylaşım bağlantısıyla tarif içe aktarma (KHV-ARC-003, '
      'SOC-003, SOC-004)', (tester) async {
    final source = bundle.recipes.firstWhere((r) => r.id == 'sys-chemex');
    final env = await setUpEnv(
      tester,
      settings: v60User,
      configure: (e) => e.links.first = Uri.parse(
        'evkahvesi://r/${encodeSharedRecipe(source)}',
      ),
    );
    expect(find.text('Paylaşılan tarif'), findsOneWidget);
    expect(find.text('Chemex başlangıç'), findsOneWidget);
    await tester.tap(find.text('Tariflerime ekle'));
    await settle(tester);
    final mine = (await tester.runAsync(
      () => env.db.watchUserRecipes().first,
    ))!;
    expect(mine.single.sourceRecipeId, 'sys-chemex');
    expect(mine.single.owner, RecipeOwner.user);
  });

  testWidgets('bozuk bağlantı nedeniyle reddedilir (KHV-FR-SOC-009)', (
    tester,
  ) async {
    await setUpEnv(
      tester,
      settings: v60User,
      configure: (e) =>
          e.links.first = Uri.parse('https://evkahvesi.app/r/bozuk'),
    );
    expect(find.text('Tarif içe aktarılamadı'), findsOneWidget);
    expect(find.text('Bağlantı bozuk veya eksik.'), findsOneWidget);
  });

  testWidgets('yedeği dışa aktar ve geri yükle (KHV-NFR-030)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    await env.db.setFavorite('sys-v60', favorite: true);
    await tester.tap(find.text('Ayarlar'));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('Verimi dışa aktar'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Verimi dışa aktar'));
    await settle(tester);
    final (name, bytes, _) = env.sharer.files.single;
    expect(name, 'ev-kahvesi-yedek-2026-11-24.json');
    await env.db.setFavorite('sys-v60', favorite: false);
    env.filePick.next = utf8.decode(bytes);
    await tester.tap(find.text('Yedekten geri yükle'));
    await settle(tester);
    await tester.tap(find.text('Geri yükle'));
    await settle(tester);
    expect(find.text('Yedek geri yüklendi.'), findsOneWidget);
    expect(await tester.runAsync(() => env.db.watchFavorites().first), {
      'sys-v60',
    });
  });

  testWidgets('hata bildirimi; cihaz bilgisi yalnız onayla '
      '(KHV-FR-HLP-003)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    await tester.tap(find.text('Ayarlar'));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('Hata bildir veya öneri gönder'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Hata bildir veya öneri gönder'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Zamanlayıcı durdu');
    await tester.tap(find.text('Gönder'));
    await settle(tester);
    expect(env.sharer.texts.single, isNot(contains('Test cihazı')));
    await tester.tap(find.text('Hata bildir veya öneri gönder'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Yine durdu');
    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.text('Gönder'));
    await settle(tester);
    expect(env.sharer.texts.last, contains('Test cihazı'));
    expect(env.sharer.texts.last, startsWith('Ev Kahvesi hata bildirimi|'));
  });

  testWidgets('bakım hatırlatıcıları (KHV-FR-ENG-001, ENG-002)', (
    tester,
  ) async {
    final env = await setUpEnv(
      tester,
      settings: v60User.copyWith(
        equipment: const EquipmentProfile(
          brewers: {BrewMethod.espresso},
          grinder: GrinderType.electricBurr,
        ),
      ),
    );
    await tester.tap(find.text('Ayarlar'));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('Bakım hatırlatıcıları'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Bakım hatırlatıcıları'));
    await settle(tester);
    expect(find.text('Kireç çözme'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Öğütücü temizliği'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.scrollUntilVisible(
      find.text('Kireç çözme'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Bugün yaptım').first);
    await settle(tester);
    await tester.tap(find.text('Bugün yaptım').first);
    await settle(tester);
    final stored = await env.db.readJson('maintenance');
    final items = (stored!['items']! as List).cast<Map<String, Object?>>();
    expect(items.where((i) => i['lastDoneAt'] != null), hasLength(1));
  });
}
