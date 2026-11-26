import 'dart:async';
import 'dart:io' show Platform;
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Yerel bildirimler (KHV-FR-BRW-005, BRW-009, ENG-001..008, KHV-HMI-022).
abstract interface class AppNotifications {
  Future<void> init();

  /// İzni ister; verilirse `true` (KHV-HMI-037).
  Future<bool> requestPermission();

  /// [at] anında bildirim planlar.
  Future<void> schedule(int id, String title, String body, DateTime at);

  /// Hemen bildirim gösterir.
  Future<void> show(int id, String title, String body);

  /// Demleme sürerken kilit ekranında kalan süreyi gösteren kalıcı bildirim
  /// (Android). [endsAt] verilirse geri sayım kronometresi kullanılır.
  Future<void> showOngoing(
    int id,
    String title,
    String body, {
    DateTime? endsAt,
  });

  Future<void> cancel(int id);
}

/// Sesli adım komutu (KHV-HMI-007, KHV-FR-BRW-013).
abstract interface class Speaker {
  /// Cihazda Türkçe ses varsa `true`.
  Future<bool> turkishAvailable();
  Future<void> speak(String text);
  Future<void> stop();
}

/// Sistem paylaşım menüsü (KHV-FR-SOC-002).
abstract interface class Sharer {
  Future<void> shareText(String text, {String? subject});
  Future<void> shareFile(
    Uint8List bytes, {
    required String name,
    required String mimeType,
    String? text,
  });
}

/// Dosya seçici (KHV-NFR-030).
abstract interface class FilePick {
  /// Kullanıcının seçtiği JSON dosyasının içeriği; vazgeçerse `null`.
  Future<String?> pickJson();
}

/// Uygulama ve cihaz bilgisi (KHV-FR-HLP-003).
abstract interface class DeviceInfo {
  Future<String> describe();
}

/// Gelen paylaşım bağlantıları (KHV-ARC-003).
abstract interface class IncomingLinks {
  Future<Uri?> initial();
  Stream<Uri> get stream;
}

// --- Gerçek uygulamalar ---

class LocalNotifications implements AppNotifications {
  final _plugin = FlutterLocalNotificationsPlugin();
  var _ready = false;

  static const _channel = AndroidNotificationDetails(
    'brew',
    'Demleme',
    channelDescription: 'Demleme adımları ve hatırlatıcılar',
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _details = NotificationDetails(
    android: _channel,
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // İzin ilk açılışta istenmez (KHV-HMI-037).
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<void> schedule(int id, String title, String body, DateTime at) async {
    await init();
    final when = tz.TZDateTime.from(at.toUtc(), tz.UTC);
    try {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: title,
        body: body,
      );
    } on Object {
      // Kesin alarm izni yoksa yaklaşık zamanlı gönder.
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
      );
    }
  }

  @override
  Future<void> show(int id, String title, String body) async {
    await init();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }

  @override
  Future<void> showOngoing(
    int id,
    String title,
    String body, {
    DateTime? endsAt,
  }) async {
    await init();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'brew_ongoing',
          'Devam eden demleme',
          channelDescription: 'Kilit ekranında kalan süre',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          category: AndroidNotificationCategory.stopwatch,
          when: endsAt?.millisecondsSinceEpoch,
          usesChronometer: endsAt != null,
          chronometerCountDown: endsAt != null,
        ),
        iOS: const DarwinNotificationDetails(presentSound: false),
      ),
    );
  }

  @override
  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }
}

class TtsSpeaker implements Speaker {
  final _tts = FlutterTts();
  bool? _available;

  @override
  Future<bool> turkishAvailable() async {
    if (_available != null) return _available!;
    try {
      final ok = await _tts.isLanguageAvailable('tr-TR');
      _available = ok == true || ok == 1;
      if (_available!) await _tts.setLanguage('tr-TR');
    } on Object {
      _available = false;
    }
    return _available!;
  }

  @override
  Future<void> speak(String text) async {
    if (!await turkishAvailable()) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}

class SystemSharer implements Sharer {
  @override
  Future<void> shareText(String text, {String? subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  @override
  Future<void> shareFile(
    Uint8List bytes, {
    required String name,
    required String mimeType,
    String? text,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        files: [XFile.fromData(bytes, mimeType: mimeType, name: name)],
        fileNameOverrides: [name],
      ),
    );
  }
}

class SystemFilePick implements FilePick {
  @override
  Future<String?> pickJson() async {
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (f == null) return null;
    final bytes = await f.readAsBytes();
    return bytes.isEmpty ? null : utf8.decode(bytes);
  }
}

class PlatformDeviceInfo implements DeviceInfo {
  @override
  Future<String> describe() async {
    final p = await PackageInfo.fromPlatform();
    final d = DeviceInfoPlugin();
    var device = defaultTargetPlatform.name;
    if (Platform.isAndroid) {
      final a = await d.androidInfo;
      device = 'Android ${a.version.release} · ${a.manufacturer} ${a.model}';
    } else if (Platform.isIOS) {
      final i = await d.iosInfo;
      device = 'iOS ${i.systemVersion} · ${i.utsname.machine}';
    }
    return 'Uygulama ${p.version}+${p.buildNumber} · $device';
  }
}

class SystemIncomingLinks implements IncomingLinks {
  final _links = AppLinks();

  @override
  Future<Uri?> initial() => _links.getInitialLink();

  @override
  Stream<Uri> get stream => _links.uriLinkStream;
}

// --- Sağlayıcılar (testlerde sahteleriyle değiştirilir) ---

final notificationsProvider = Provider<AppNotifications>(
  (ref) => LocalNotifications(),
);
final speakerProvider = Provider<Speaker>((ref) => TtsSpeaker());
final sharerProvider = Provider<Sharer>((ref) => SystemSharer());
final filePickProvider = Provider<FilePick>((ref) => SystemFilePick());
final deviceInfoProvider = Provider<DeviceInfo>((ref) => PlatformDeviceInfo());
final incomingLinksProvider = Provider<IncomingLinks>(
  (ref) => SystemIncomingLinks(),
);

/// Paylaşım bağlantısı tabanı (KHV-FR-SOC-003). Alan adı yayın öncesi
/// kesinleşmeli; uygulama yüklü değilse bu sayfa mağazaya yönlendirir.
const shareBaseUrl = 'https://evkahvesi.app/r/';

/// Gelen bağlantıdan tarif yükünü çıkarır; tanınmayan bağlantıda `null`.
String? sharePayloadFromUri(Uri uri) {
  if (uri.scheme == 'evkahvesi' && uri.host == 'r') {
    final seg = uri.pathSegments.where((s) => s.isNotEmpty);
    return seg.isEmpty ? null : seg.first;
  }
  if (uri.scheme == 'https' &&
      uri.host == 'evkahvesi.app' &&
      uri.pathSegments.length >= 2 &&
      uri.pathSegments.first == 'r') {
    return uri.pathSegments[1];
  }
  return null;
}
