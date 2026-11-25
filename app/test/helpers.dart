import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:ev_kahvesi/app.dart';
import 'package:ev_kahvesi/data/database.dart';
import 'package:ev_kahvesi/services/platform.dart';
import 'package:ev_kahvesi/state/providers.dart';
import 'package:ev_kahvesi/state/settings.dart';
import 'package:flutter/foundation.dart';
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

class FakeNotifications implements AppNotifications {
  final scheduled = <int, (String, String, DateTime)>{};
  final shown = <int, String>{};
  final ongoing = <int, (String, DateTime?)>{};
  var permissionRequests = 0;

  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<void> schedule(int id, String title, String body, DateTime at) async =>
      scheduled[id] = (title, body, at);
  @override
  Future<void> show(int id, String title, String body) async =>
      shown[id] = body;
  @override
  Future<void> showOngoing(
    int id,
    String title,
    String body, {
    DateTime? endsAt,
  }) async => ongoing[id] = (body, endsAt);
  @override
  Future<void> cancel(int id) async {
    scheduled.remove(id);
    ongoing.remove(id);
  }
}

class FakeSpeaker implements Speaker {
  FakeSpeaker({this.available = true});
  bool available;
  final spoken = <String>[];
  @override
  Future<bool> turkishAvailable() async => available;
  @override
  Future<void> speak(String text) async => spoken.add(text);
  @override
  Future<void> stop() async {}
}

class FakeSharer implements Sharer {
  final texts = <String>[];
  final files = <(String, Uint8List, String?)>[];
  @override
  Future<void> shareText(String text, {String? subject}) async =>
      texts.add('$subject|$text');
  @override
  Future<void> shareFile(
    Uint8List bytes, {
    required String name,
    required String mimeType,
    String? text,
  }) async => files.add((name, bytes, text));
}

class FakeFilePick implements FilePick {
  String? next;
  @override
  Future<String?> pickJson() async => next;
}

class FakeDeviceInfo implements DeviceInfo {
  @override
  Future<String> describe() async => 'Uygulama 0.1.0+1 · Test cihazı';
}

class FakeLinks implements IncomingLinks {
  Uri? first;
  final controller = StreamController<Uri>.broadcast();
  @override
  Future<Uri?> initial() async => first;
  @override
  Stream<Uri> get stream => controller.stream;
}

class TestEnv {
  final clock = FakeClock();
  late final AppDatabase db = AppDatabase(
    NativeDatabase.memory(),
    clock: () => clock.wall,
  );
  final notifications = FakeNotifications();
  final speaker = FakeSpeaker();
  final sharer = FakeSharer();
  final filePick = FakeFilePick();
  final links = FakeLinks();

  /// İçerik yüklenemiyormuş gibi davran (KHV-HMI-042).
  bool contentError = false;

  /// Terazi (KHV-ARC-007); verilmezse elle giriş kullanılır.
  Scale Function()? scaleFactory;
  var _id = 0;

  Future<void> seedSettings(AppSettings s) =>
      db.writeJson('settings', s.toJson());

  Widget app() => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      contentProvider.overrideWith(
        (ref) async =>
            contentError ? throw const FormatException('içerik bozuk') : bundle,
      ),
      clockProvider.overrideWithValue(() => clock.wall),
      monotonicMsProvider.overrideWithValue(() => clock.ms),
      idProvider.overrideWithValue(() => 'id-${_id++}'),
      notificationsProvider.overrideWithValue(notifications),
      speakerProvider.overrideWithValue(speaker),
      sharerProvider.overrideWithValue(sharer),
      filePickProvider.overrideWithValue(filePick),
      deviceInfoProvider.overrideWithValue(FakeDeviceInfo()),
      incomingLinksProvider.overrideWithValue(links),
      if (scaleFactory != null)
        scaleFactoryProvider.overrideWithValue(scaleFactory!),
    ],
    child: const EvKahvesiApp(),
  );
}

Future<TestEnv> setUpEnv(
  WidgetTester tester, {
  AppSettings? settings,
  void Function(TestEnv env)? configure,
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await initializeDateFormatting('tr_TR');
  final env = TestEnv();
  configure?.call(env);
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
  notificationPermissionAsked: true,
  ttsHelpShown: true,
  equipment: EquipmentProfile(
    brewers: {BrewMethod.v60, BrewMethod.espresso},
    grinder: GrinderType.handBurr,
    hasScale: true,
    kettle: KettleType.gooseneck,
  ),
);
