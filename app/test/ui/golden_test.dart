import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

/// Rehber mod ve tat değerlendirme ekranlarının golden testleri
/// (KHV-NFR-041). Güncellemek için: flutter test --update-goldens
void main() {
  testWidgets('rehber mod', (tester) async {
    await setUpEnv(tester, settings: v60User);
    await tester.tap(find.text('V60 başlangıç'));
    await settle(tester);
    await tester.tap(find.text('Rehberle demle'));
    await settle(tester);
    await tester.tap(find.text('Demlemeyi başlat'));
    await settle(tester, 10);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/rehber_mod.png'),
    );
    await tester.tap(find.byTooltip('Duraklat'));
    await settle(tester, 10);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/rehber_mod_duraklatildi.png'),
    );
  });

  testWidgets('tat değerlendirme', (tester) async {
    await setUpEnv(tester, settings: v60User);
    await tester.tap(find.text('Günlük'));
    await settle(tester);
    await tester.tap(find.text('Elle kaydet'));
    await settle(tester);
    await tester.tap(find.text('Kaydet ve tadı değerlendir'));
    await settle(tester, 10);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Ekşi'));
    await settle(tester, 10);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/tat_degerlendirme.png'),
    );
  });
}
