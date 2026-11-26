import 'dart:async';
import 'dart:typed_data';

import 'package:kahve_core/kahve_core.dart';
import 'package:universal_ble/universal_ble.dart';

/// Bluetooth'un kullanılabilirliği (KHV-FR-SCL-007).
enum BleState {
  /// Açık ve izinli.
  ready,

  /// Telefonda Bluetooth kapalı.
  off,

  /// İzin verilmedi.
  unauthorized,

  /// Cihaz Bluetooth LE desteklemiyor (ör. simülatör).
  unsupported,
}

/// Taramada bulunan cihaz.
class FoundDevice {
  /// Bir tarama sonucu oluşturur.
  const FoundDevice(this.deviceId, this.advertisement);

  /// Platformun cihaz kimliği.
  final String deviceId;

  /// Reklam bilgisi (ad, servisler, üretici kimlikleri).
  final BleAdvertisement advertisement;
}

/// Bluetooth tarama ve bağlantı servisi; platform eklentisinin arkasındaki
/// arayüz, testte sahtesiyle değiştirilir (KHV-ARC-007, KB-028).
abstract interface class BleCentral {
  /// Güncel durum.
  Future<BleState> state();

  /// İzin ister; verildiyse `true`. Yalnız kullanıcı açıklamayı gördükten
  /// sonra çağrılır (KHV-FR-SCL-007).
  Future<bool> requestPermission();

  /// Dinlendiği sürece tarar; abonelik iptal edilince tarama durur.
  Stream<FoundDevice> scan();

  /// Cihazla bağlantı nesnesi.
  BleLink link(String deviceId);
}

/// [BleCentral]'ın universal_ble (BSD-3) gerçekleştirimi.
class UniversalBleCentral implements BleCentral {
  @override
  Future<BleState> state() async {
    try {
      return switch (await UniversalBle.getBluetoothAvailabilityState()) {
        AvailabilityState.poweredOn => BleState.ready,
        AvailabilityState.poweredOff ||
        AvailabilityState.resetting => BleState.off,
        AvailabilityState.unauthorized => BleState.unauthorized,
        AvailabilityState.unsupported => BleState.unsupported,
        AvailabilityState.unknown =>
          await UniversalBle.hasPermissions()
              ? BleState.ready
              : BleState.unauthorized,
      };
    } on Object {
      return BleState.unsupported;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      // Konum izni istenmez; tarama konum için kullanılmaz.
      await UniversalBle.requestPermissions();
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Stream<FoundDevice> scan() {
    late final StreamController<FoundDevice> out;
    StreamSubscription<BleDevice>? sub;
    out = StreamController<FoundDevice>(
      onListen: () async {
        sub = UniversalBle.scanStream.listen((d) {
          final name = d.name ?? d.rawName ?? '';
          if (name.isEmpty) return;
          out.add(
            FoundDevice(
              d.deviceId,
              BleAdvertisement(
                name: name,
                serviceUuids: d.services,
                manufacturerIds: [
                  for (final m in d.manufacturerDataList) m.companyId,
                ],
              ),
            ),
          );
        });
        try {
          await UniversalBle.startScan();
        } on Object catch (e) {
          out.addError(e);
        }
      },
      onCancel: () async {
        await sub?.cancel();
        try {
          await UniversalBle.stopScan();
        } on Object {
          // Tarama zaten durmuş olabilir.
        }
      },
    );
    return out.stream;
  }

  @override
  BleLink link(String deviceId) => _UniversalBleLink(deviceId);
}

class _UniversalBleLink implements BleLink {
  _UniversalBleLink(this.deviceId);

  final String deviceId;

  @override
  Stream<bool> get connected => UniversalBle.connectionStream(deviceId);

  @override
  Future<void> connect() async {
    await UniversalBle.connect(deviceId, timeout: const Duration(seconds: 15));
    await UniversalBle.discoverServices(deviceId);
  }

  @override
  Stream<List<int>> notifications(String service, String characteristic) {
    late final StreamController<List<int>> out;
    StreamSubscription<Uint8List>? sub;
    out = StreamController<List<int>>(
      onListen: () async {
        sub = UniversalBle.characteristicValueStream(
          deviceId,
          characteristic,
          serviceId: service,
        ).listen(out.add);
        try {
          await UniversalBle.subscribeNotifications(
            deviceId,
            service,
            characteristic,
          );
        } on Object catch (e) {
          // Cihazda bu servis yoksa (dinleme modunda başka protokol) hata.
          out.addError(e);
        }
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }

  @override
  Future<void> write(String service, String characteristic, List<int> value) =>
      UniversalBle.write(
        deviceId,
        service,
        characteristic,
        Uint8List.fromList(value),
      );

  @override
  Future<void> disconnect() => UniversalBle.disconnect(deviceId);
}
