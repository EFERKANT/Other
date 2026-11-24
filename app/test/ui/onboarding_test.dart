import 'package:ev_kahvesi/state/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahve_core/kahve_core.dart';

import '../helpers.dart';

void main() {
  testWidgets('ilk açılış: araç seç, en fazla 3 ekranda rehber moda '
      '(UC-01, KHV-HMI-038)', (tester) async {
    final env = await setUpEnv(tester);
    // Ekran 1: kurulum.
    expect(find.text('Hangi demleme araçlarınız var?'), findsOneWidget);
    await tester.tap(find.text('V60 / Pour over'));
    await settle(tester);
    await tester.tap(find.text('Devam'));
    await settle(tester);
    // Ekran 2: tarif.
    expect(find.text('V60 başlangıç'), findsWidgets);
    expect(find.text('Rehberle demle'), findsOneWidget);
    // HMI-016: terazi ve öğütücü ilk kullanımda sorulur.
    expect(find.text('Teraziniz var mı?'), findsOneWidget);
    final s = AppSettings.fromJson((await env.db.readJson('settings'))!);
    expect(s.onboardingDone, isTrue);
    expect(s.equipment.brewers, {BrewMethod.v60});
    expect(s.profile, UserProfile.beginner);
    // Ekran 3: rehber mod (hazırlık listesi).
    await tester.tap(find.text('Rehberle demle'));
    await settle(tester);
    expect(find.text('Demlemeyi başlat'), findsOneWidget);
  });

  testWidgets('kurulum atlanabilir, P1 atanır (KHV-FR-ONB-005)', (
    tester,
  ) async {
    final env = await setUpEnv(tester);
    await tester.tap(find.text('Şimdilik atla'));
    await settle(tester);
    expect(find.text('Tüm yöntemler'), findsOneWidget);
    final s = AppSettings.fromJson((await env.db.readJson('settings'))!);
    expect(s.profile, UserProfile.beginner);
  });
}
