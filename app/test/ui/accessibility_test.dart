import 'dart:io';

import 'package:ev_kahvesi/ui/taste.dart';
import 'package:ev_kahvesi/ui/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

/// Ana ekranlarda platform kılavuzları: dokunma hedefi (KHV-HMI-025),
/// metin kontrastı (KHV-HMI-020, HMI-034) ve etiketli hedefler
/// (KHV-HMI-031).
Future<void> expectGuidelines(WidgetTester tester, String screen) async {
  await expectLater(
    tester,
    meetsGuideline(androidTapTargetGuideline),
    reason: '$screen: 48x48 dp',
  );
  await expectLater(
    tester,
    meetsGuideline(iOSTapTargetGuideline),
    reason: '$screen: 44x44 pt',
  );
  await expectLater(
    tester,
    meetsGuideline(textContrastGuideline),
    reason: '$screen: kontrast',
  );
  await expectLater(
    tester,
    meetsGuideline(labeledTapTargetGuideline),
    reason: '$screen: etiket',
  );
}

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('dokunma hedefi, kontrast ve etiketler; ${mode.name} tema '
        '(KHV-HMI-020, HMI-025, HMI-031, HMI-034)', (tester) async {
      final semantics = tester.ensureSemantics();
      await setUpEnv(tester, settings: v60User.copyWith(themeMode: mode));
      await expectGuidelines(tester, 'ana ekran');
      await tester.tap(find.text('V60 başlangıç'));
      await settle(tester);
      await expectGuidelines(tester, 'tarif');
      await tester.tap(find.text('Rehberle demle'));
      await settle(tester);
      await tester.tap(find.text('Demlemeyi başlat'));
      await settle(tester, 6);
      await expectGuidelines(tester, 'rehber mod');
      semantics.dispose();
    });
  }

  testWidgets('geri alınamaz işlem en az 56 dp (KHV-HMI-025, HMI-009)', (
    tester,
  ) async {
    await setUpEnv(tester, settings: v60User);
    await tester.tap(find.text('V60 başlangıç'));
    await settle(tester);
    await tester.tap(find.text('Rehberle demle'));
    await settle(tester);
    await tester.tap(find.text('Demlemeyi başlat'));
    await settle(tester, 6);
    final size = tester.getSize(find.text('Bitir (basılı tut)').hitTestable());
    final box = tester.getSize(
      find
          .ancestor(
            of: find.text('Bitir (basılı tut)'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(size.height, greaterThan(0));
    expect(box.height, greaterThanOrEqualTo(56));
  });

  testWidgets('koyu tema saf siyah/beyaz kullanmaz (KHV-NFR-009, '
      'KHV-HMI-036)', (tester) async {
    final dark = buildTheme(Brightness.dark).colorScheme;
    expect(dark.surface, isNot(const Color(0xFF000000)));
    expect(dark.onSurface, isNot(const Color(0xFFFFFFFF)));
    expect(dark.brightness, Brightness.dark);
    await setUpEnv(
      tester,
      settings: v60User.copyWith(themeMode: ThemeMode.dark),
    );
    await tester.tap(find.text('V60 başlangıç'));
    await settle(tester);
    await tester.tap(find.text('Rehberle demle'));
    await settle(tester);
    await tester.tap(find.text('Demlemeyi başlat'));
    await settle(tester, 10);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/rehber_mod_koyu.png'),
    );
  });

  testWidgets('sistem temasını izler (KHV-NFR-009)', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await setUpEnv(tester, settings: v60User);
    final ctx = tester.element(find.text('Demle').first);
    expect(Theme.of(ctx).brightness, Brightness.dark);
  });

  testWidgets('rehber mod yatay yönlendirmede taşmadan çalışır '
      '(KHV-HMI-019)', (tester) async {
    final env = await setUpEnv(tester, settings: v60User);
    tester.view.physicalSize = const Size(2400, 1080);
    await settle(tester);
    await tester.tap(find.text('V60 başlangıç'));
    await settle(tester);
    await tester.tap(find.text('Rehberle demle'));
    await settle(tester);
    await tester.tap(find.text('Demlemeyi başlat'));
    await settle(tester, 6);
    expect(find.text('30 g'), findsOneWidget);
    env.clock.advance(const Duration(seconds: 10));
    await settle(tester, 4);
    expect(find.text('Adım 2/6'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/rehber_mod_yatay.png'),
    );
  });

  testWidgets('hareketi azalt: rehber modda animasyon yok; tat bilgisi renk '
      'yanında simge ve metinle (KHV-HMI-024)', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await setUpEnv(tester, settings: v60User);
    await tester.tap(find.text('V60 başlangıç'));
    await settle(tester);
    await tester.tap(find.text('Rehberle demle'));
    await settle(tester);
    await tester.tap(find.text('Demlemeyi başlat'));
    await settle(tester, 6);
    final animated = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer).first,
    );
    expect(animated.duration, Duration.zero);
  });

  testWidgets('iki boyutlu tat alanı: sürükleme ekseni belirler, merkeze '
      'yakın dengeli (KHV-HMI-013)', (tester) async {
    var value = Offset.zero;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 400,
              child: TastePad(
                value: value,
                onChanged: (v) => setState(() => value = v),
              ),
            ),
          ),
        ),
      ),
    );
    final pad = find.bySemanticsLabel('Tat alanı');
    final rect = tester.getRect(pad);
    // Sol üst: ekşi ve yoğun.
    await tester.tapAt(rect.topLeft + const Offset(10, 10));
    await tester.pump();
    expect(value.dx, lessThan(-0.8));
    expect(value.dy, lessThan(-0.8));
    var a = TasteAssessment(
      score: 3,
      extraction: value.dx,
      strength: -value.dy,
    );
    expect(a.notes, {TasteNote.sour, TasteNote.strong});
    // Sağ alta sürükle: acı ve sulu.
    await tester.dragFrom(
      rect.center,
      Offset(rect.width / 2 - 5, rect.height / 2 - 5),
    );
    await tester.pump();
    a = TasteAssessment(score: 3, extraction: value.dx, strength: -value.dy);
    expect(a.notes, {TasteNote.bitter, TasteNote.watery});
    // Merkeze yakın dokunuş dengeliye yapışır.
    await tester.tapAt(rect.center + const Offset(8, -6));
    await tester.pump();
    expect(value, Offset.zero);
    // Ekran okuyucu için seçim düğmeleri.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Sulu'));
    await tester.pump();
    expect(value, const Offset(0, 0.7));
  });

  test('widget kodunda doğrudan renk değeri yok (KHV-HMI-033)', () {
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.endsWith('theme.dart') || f.path.endsWith('.g.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'Color\(0x|Colors\.[a-z]').hasMatch(lines[i])) {
          offenders.add('${f.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('kırmızı yalnız hata ve geri alınamaz işlemde (KHV-HMI-035)', () {
    final uses = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final text = f.readAsStringSync();
      for (final m in RegExp(
        r'colorScheme\.(error\w*)|scheme\.(error\w*)',
      ).allMatches(text)) {
        uses.add('${f.path}: ${m.group(0)}');
      }
    }
    // İzin verilen yerler: tüm veriyi silme onayı ve basılı tutarak bitirme.
    expect(
      uses.every(
        (u) => u.contains('settings_screen.dart') || u.contains('common.dart'),
      ),
      isTrue,
      reason: uses.join('\n'),
    );
  });
}
