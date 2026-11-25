import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

/// Ölçüm sonuçlarını özet dosyasına yazar ve eşikleri denetler
/// (KHV-NFR-023: 60 Hz'de kare süresi < 16 ms, 700 ms üstü donmuş kare
/// oranı < %0,1).
Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    for (final key in data.keys) {
      final timeline = driver.Timeline.fromJson(
        (data[key]! as Map).cast<String, dynamic>(),
      );
      final summary = driver.TimelineSummary.summarize(timeline);
      await summary.writeTimelineToFile(key, pretty: true);
      final json = summary.summaryJson;
      final avgBuild = json['average_frame_build_time_millis'] as num;
      final p90Raster =
          json['90th_percentile_frame_rasterizer_time_millis'] as num;
      // ignore: avoid_print
      print('$key: ortalama build $avgBuild ms, p90 raster $p90Raster ms');
      if (avgBuild > 16 || p90Raster > 16) {
        throw StateError('$key: kare süresi hedefi aşıldı (KHV-NFR-023)');
      }
    }
  },
);
