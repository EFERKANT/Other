import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:ev_kahvesi/data/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../test/helpers.dart';

/// Arayüz stres testleri: rastgele dokunma (monkey) ve büyük listeler.
/// Tohum `STRES_TOHUM` ortam değişkeniyle değiştirilir; başarısız koşu aynı
/// tohumla yeniden üretilir.
void main() {
  final stepText = find.textContaining(RegExp(r'^Adım \d+/\d+$'));
  final seed =
      int.tryParse(Platform.environment['STRES_TOHUM'] ?? '') ?? 20261125;

  testWidgets('rehber modda 400 rastgele dokunuş ve zaman sıçraması: hata '
      'yok, durum tutarlı (KHV-NFR-003, KHV-HMI-009, HMI-006)', (tester) async {
    final r = Random(seed);
    final env = await setUpEnv(tester, settings: v60User);
    await tester.tap(find.text('V60 başlangıç'));
    await settle(tester);
    await tester.tap(find.text('Rehberle demle'));
    await settle(tester);
    await tester.tap(find.text('Demlemeyi başlat'));
    await settle(tester, 6);
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    var restarts = 0;
    for (var i = 0; i < 400; i++) {
      final onBrew = stepText.evaluate().isNotEmpty;
      if (!onBrew) {
        // Akış bitti veya ekrandan çıkıldı: yeni demleme başlat.
        restarts++;
        GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/');
        await settle(tester, 4);
        if (find.text('Rehberle demle').evaluate().isEmpty) {
          if (find.text('Demle').evaluate().isNotEmpty) {
            await tester.tap(find.text('Demle').first);
            await settle(tester, 4);
          }
          if (find.text('V60 başlangıç').evaluate().isEmpty) continue;
          await tester.tap(
            find.text('V60 başlangıç').first,
            warnIfMissed: false,
          );
          await settle(tester, 4);
        }
        await tester.tap(find.text('Rehberle demle'), warnIfMissed: false);
        await settle(tester, 4);
        if (find.text('Demlemeyi başlat').evaluate().isNotEmpty) {
          await tester.tap(find.text('Demlemeyi başlat'));
          await settle(tester, 4);
        }
        continue;
      }
      switch (r.nextInt(6)) {
        case 0:
          env.clock.advance(Duration(seconds: r.nextInt(90)));
        case 1:
          await tester.tapAt(
            Offset(r.nextDouble() * size.width, r.nextDouble() * size.height),
          );
        case 2:
          for (final tip in ['Duraklat', 'Devam et', 'Adımı atla']) {
            if (r.nextBool() && find.byTooltip(tip).evaluate().isNotEmpty) {
              await tester.tap(find.byTooltip(tip).first);
              break;
            }
          }
        case 3:
          if (find.text('Geri al').evaluate().isNotEmpty) {
            await tester.tap(find.text('Geri al').first, warnIfMissed: false);
          }
        case 4:
          await tester.tap(stepText.first, warnIfMissed: false);
        default:
          env.clock.advance(const Duration(milliseconds: 300));
      }
      await settle(tester, 2);
      expect(tester.takeException(), isNull, reason: 'adım $i, tohum $seed');
      final step = stepText;
      if (step.evaluate().isNotEmpty) {
        final text = (step.evaluate().first.widget as Text).data!;
        final m = RegExp(r'Adım (\d+)/(\d+)').firstMatch(text)!;
        expect(
          int.parse(m.group(1)!),
          inInclusiveRange(1, int.parse(m.group(2)!)),
        );
      }
    }
    // Rastgele akış sırasında oluşan kayıtlar geçerli.
    final brews = (await tester.runAsync(() => env.db.watchBrews().first))!;
    for (final b in brews) {
      expect(b.actualTimeS, isNotNull);
      expect(b.actualTimeS, greaterThanOrEqualTo(0));
    }
    // ignore: avoid_print
    print(
      'monkey: ${brews.length} demleme tamamlandı, $restarts yeniden başlatma',
    );
  });

  testWidgets('2.000 kayıtlı günlük: liste kaydırılır, filtre çalışır '
      '(KHV-FR-LOG-002, KHV-NFR-023)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    await env.db.batch((b) {
      for (var i = 0; i < 2000; i++) {
        final recipe = bundle.recipes[i % bundle.recipes.length];
        b.insert(
          env.db.brews,
          BrewsCompanion.insert(
            id: 'b$i',
            brewedAt: DateTime(2026).add(Duration(hours: i)),
            recipeId: recipe.id,
            lineageId: recipe.id,
            methodId: recipe.method.id,
            recipeJson: jsonEncode(recipe.toJson()),
            score: Value(1 + i % 5),
          ),
        );
      }
    });
    await tester.tap(find.text('Günlük'));
    await settle(tester, 10);
    // Önce filtre (liste başındayken), sonra kaydırma yükü.
    await tester.tap(find.widgetWithText(FilterChip, 'Yöntem'));
    await settle(tester);
    await tester.tap(find.widgetWithText(MenuItemButton, 'Espresso'));
    await settle(tester);
    expect(find.text('Espresso 1:2'), findsWidgets);
    expect(find.text('V60 başlangıç'), findsNothing);
    await tester.tap(find.widgetWithText(FilterChip, 'Espresso'));
    await settle(tester);
    await tester.tap(find.widgetWithText(MenuItemButton, 'Tümü'));
    await settle(tester);
    final list = find.byType(ListView).first;
    final sw = Stopwatch()..start();
    for (var i = 0; i < 40; i++) {
      await tester.drag(list, const Offset(0, -3000));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.takeException(), isNull);
    expect(find.text('V60 başlangıç'), findsWidgets);
    // ignore: avoid_print
    print('2000 kayıt: 40 kaydırma ${sw.elapsedMilliseconds} ms (test zamanı)');
    expect(BrewMethod.values, isNotEmpty);
  });
}
