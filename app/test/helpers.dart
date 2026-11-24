import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:ev_kahvesi/app.dart';
import 'package:ev_kahvesi/data/database.dart';
import 'package:ev_kahvesi/state/providers.dart';
import 'package:ev_kahvesi/state/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

final bundle = ContentBundle.fromJson(
  (jsonDecode(File('assets/content/bundle.json').readAsStringSync()) as Map)
      .cast<String, Object?>(),
);

/// Testte kontrol edilen monotonik saat.
class FakeClock {
  int ms = 0;
  DateTime wall = DateTime(2026, 11, 24, 8);
  void advance(Duration d) {
    ms += d.inMilliseconds;
    wall = wall.add(d);
  }
}

class TestEnv {
  TestEnv() : db = AppDatabase(NativeDatabase.memory());

  final AppDatabase db;
  final clock = FakeClock();
  var _id = 0;

  Future<void> seedSettings(AppSettings s) =>
      db.writeJson('settings', s.toJson());

  Widget app() => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      contentProvider.overrideWith((ref) async => bundle),
      clockProvider.overrideWithValue(() => clock.wall),
      monotonicMsProvider.overrideWithValue(() => clock.ms),
      idProvider.overrideWithValue(() => 'id-${_id++}'),
    ],
    child: const EvKahvesiApp(),
  );
}

Future<TestEnv> setUpEnv(WidgetTester tester, {AppSettings? settings}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await initializeDateFormatting('tr_TR');
  final env = TestEnv();
  if (settings != null) await env.seedSettings(settings);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(env.db.close);
  });
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(env.app());
  await settle(tester);
  return env;
}

/// Periyodik zamanlayıcılar nedeniyle pumpAndSettle yerine sınırlı pompa.
Future<void> settle(WidgetTester tester, [int frames = 20]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

const v60User = AppSettings(
  onboardingDone: true,
  equipment: EquipmentProfile(
    brewers: {BrewMethod.v60, BrewMethod.espresso},
    grinder: GrinderType.handBurr,
    hasScale: true,
    kettle: KettleType.gooseneck,
  ),
);
