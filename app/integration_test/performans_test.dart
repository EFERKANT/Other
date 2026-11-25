import 'package:drift_flutter/drift_flutter.dart';
import 'package:ev_kahvesi/app.dart';
import 'package:ev_kahvesi/data/database.dart';
import 'package:ev_kahvesi/state/providers.dart';
import 'package:ev_kahvesi/state/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

/// Fiziksel cihazda performans ölçümü (KHV-NFR-001, NFR-023, NFR-024).
///
/// Emülatörde veya debug derlemede çalıştırılmaz:
///   flutter drive --profile \
///     --driver=test_driver/performans_driver.dart \
///     --target=integration_test/performans_test.dart -d CIHAZ_KIMLIGI
/// Sonuç build/ altında *.timeline_summary.json olarak yazılır.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rehber mod ve günlük kare süreleri (KHV-NFR-023)', (
    tester,
  ) async {
    await initializeDateFormatting('tr_TR');
    final db = AppDatabase(
      driftDatabase(name: 'perf_${DateTime.now().millisecondsSinceEpoch}'),
    );
    await db.writeJson(
      'settings',
      const AppSettings(
        onboardingDone: true,
        notificationPermissionAsked: true,
        ttsHelpShown: true,
        equipment: EquipmentProfile(brewers: {BrewMethod.v60}),
      ).toJson(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const EvKahvesiApp(),
      ),
    );
    await tester.pumpAndSettle();

    await binding.traceAction(() async {
      await tester.tap(find.text('V60 başlangıç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rehberle demle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Demlemeyi başlat'));
      // Rehber modda 15 sn gerçek zaman: geri sayım ve geçiş animasyonları.
      for (var i = 0; i < 150; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }, reportKey: 'rehber_mod');

    await binding.traceAction(() async {
      // Demlemeyi basılı tutarak bitir (KHV-HMI-009).
      final hold = await tester.startGesture(
        tester.getCenter(find.text('Bitir (basılı tut)')),
      );
      await tester.pump(const Duration(seconds: 1));
      await hold.up();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Günlük'));
      await tester.pumpAndSettle();
      final list = find.byType(Scrollable).first;
      for (var i = 0; i < 10; i++) {
        await tester.fling(list, const Offset(0, -800), 3000);
        await tester.pumpAndSettle();
      }
    }, reportKey: 'gunluk_kaydirma');
  });
}
