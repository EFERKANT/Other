import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../services/platform.dart';
import 'labels.dart';

/// Paylaşım kartı biçimi (KHV-FR-SOC-002).
enum ShareFormat {
  /// Dikey 9:16 (story).
  story(9 / 16, 'Story'),

  /// Kare 1:1 (mesaj).
  message(1, 'Mesaj');

  const ShareFormat(this.aspectRatio, this.label);

  final double aspectRatio;
  final String label;
}

/// Tarif veya demlemenin görsel paylaşım kartı (KHV-FR-SOC-001). Kullanıcı
/// kimliği, cihaz bilgisi ve konum içermez (KHV-FR-SOC-010).
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.recipe,
    required this.format,
    this.beanName,
    this.score,
    this.actualTimeS,
  });

  final Recipe recipe;
  final ShareFormat format;
  final String? beanName;
  final int? score;
  final int? actualTimeS;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final r = recipe;
    final time = actualTimeS ?? r.targetTimeS;
    final rows = <(IconData, String, String)>[
      (Icons.scale, 'Kahve', '${formatNumber(r.coffeeG)} g'),
      (
        Icons.water_drop_outlined,
        r.method.isEspresso ? 'Çıktı' : 'Su',
        '${formatNumber(r.waterG)} g',
      ),
      (Icons.percent, 'Oran', formatRatio(r.ratio)),
      if (r.temperatureC != null)
        (Icons.thermostat, 'Sıcaklık', '${formatNumber(r.temperatureC!)} °C'),
      if (time != null) (Icons.timer_outlined, 'Süre', formatDuration(time)),
      (Icons.grain, 'Öğütme', r.grind.label),
      if (beanName != null) (Icons.eco_outlined, 'Çekirdek', beanName!),
    ];
    return AspectRatio(
      aspectRatio: format.aspectRatio,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      methodIcon(r.method),
                      size: 32,
                      color: scheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        methodName(r.method),
                        style: t.titleMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r.name,
                  style: t.headlineSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                for (final (icon, k, v) in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(icon, size: 20, color: scheme.onPrimaryContainer),
                        const SizedBox(width: 8),
                        Text(
                          k,
                          style: TextStyle(color: scheme.onPrimaryContainer),
                        ),
                        const Spacer(),
                        Text(
                          v,
                          style: t.titleSmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (score != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        Icon(
                          i <= score! ? Icons.star : Icons.star_border,
                          color: scheme.onPrimaryContainer,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Ev Kahvesi ile demlendi',
                  style: t.labelMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paylaşım kartı önizlemesi ve gönderimi (KHV-FR-SOC-001, SOC-002,
/// SOC-003, SOC-010). Kullanıcı kartı paylaşmadan önce görür.
Future<void> showShareSheet(
  BuildContext context, {
  required Recipe recipe,
  required Future<void> Function(Uint8List png, String link) onShare,
  String? beanName,
  int? score,
  int? actualTimeS,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (c) => _ShareSheet(
    recipe: recipe,
    onShare: onShare,
    beanName: beanName,
    score: score,
    actualTimeS: actualTimeS,
  ),
);

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({
    required this.recipe,
    required this.onShare,
    this.beanName,
    this.score,
    this.actualTimeS,
  });

  final Recipe recipe;
  final Future<void> Function(Uint8List png, String link) onShare;
  final String? beanName;
  final int? score;
  final int? actualTimeS;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _boundary = GlobalKey();
  ShareFormat _format = ShareFormat.message;
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final render =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final link = '$shareBaseUrl${encodeSharedRecipe(widget.recipe)}';
      await widget.onShare(data!.buffer.asUint8List(), link);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<ShareFormat>(
            segments: [
              for (final f in ShareFormat.values)
                ButtonSegment(value: f, label: Text(f.label)),
            ],
            selected: {_format},
            onSelectionChanged: (s) => setState(() => _format = s.first),
          ),
          const SizedBox(height: 12),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420, maxWidth: 320),
              child: RepaintBoundary(
                key: _boundary,
                child: ShareCard(
                  recipe: widget.recipe,
                  format: _format,
                  beanName: widget.beanName,
                  score: widget.score,
                  actualTimeS: widget.actualTimeS,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kart ve bağlantı yalnız tarif parametrelerini içerir; adınız, '
            'cihaz bilginiz veya konumunuz eklenmez.',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: _busy ? null : _share,
            icon: const Icon(Icons.ios_share),
            label: const Text('Paylaş'),
          ),
        ],
      ),
    ),
  );
}
