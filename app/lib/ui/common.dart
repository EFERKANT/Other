import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../state/providers.dart';
import 'labels.dart';

/// Artır/azalt ve kaydırıcı ile sayısal giriş; klavye ikincil yöntemdir
/// (KHV-HMI-011). Birim değerin yanında gösterilir.
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.onChanged,
    this.step = 1,
    this.min = 0,
    this.max = 1000,
    this.decimals = 1,
    this.warning,
    this.prefix = '',
    this.showSlider = true,
  });

  final String label;
  final double value;
  final String unit;
  final String prefix;
  final double step;
  final double min;
  final double max;
  final int decimals;
  final ValueChanged<double> onChanged;

  /// Aralık dışı uyarısı (KHV-HMI-012); engellemez.
  final String? warning;
  final bool showSlider;

  double _clamp(double v) => ((v.clamp(min, max) * 10).roundToDouble()) / 10;

  Future<void> _keyboard(BuildContext context) async {
    final controller = TextEditingController(
      text: formatNumber(value, decimals: decimals),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(suffixText: unit),
          onSubmitted: (t) => Navigator.pop(c, parseNumber(t)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, parseNumber(controller.text)),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
    if (result != null) onChanged(_clamp(result));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = '$prefix${formatNumber(value, decimals: decimals)} $unit';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: theme.textTheme.titleSmall),
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: '$label azalt',
                onPressed: value <= min
                    ? null
                    : () => onChanged(_clamp(value - step)),
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Semantics(
                  label: label,
                  value: text,
                  hint: 'Değeri klavyeyle girmek için dokunun',
                  button: true,
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => _keyboard(context),
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Center(
                        child: Text(
                          text,
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: '$label artır',
                onPressed: value >= max
                    ? null
                    : () => onChanged(_clamp(value + step)),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (showSlider)
            ExcludeSemantics(
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: (v) => onChanged(_clamp((v / step).round() * step)),
              ),
            ),
          if (warning != null)
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    warning!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Dokunulduğunda sözlük açıklaması gösteren terim (KHV-HMI-018,
/// KHV-FR-HLP-001).
class TermChip extends ConsumerWidget {
  const TermChip(this.term, {super.key});

  final String term;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glossary = ref.watch(contentProvider).value?.glossary ?? const [];
    final def = glossary
        .where((g) => foldTurkish(g.term) == foldTurkish(term))
        .firstOrNull;
    return ActionChip(
      avatar: const Icon(Icons.help_outline, size: 18),
      label: Text(term),
      tooltip: '$term nedir?',
      onPressed: def == null
          ? null
          : () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (c) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(def.term, style: Theme.of(c).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(def.definition),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// Emniyet uyarısı; tüm yöntemlerde aynı simge ve konumda (KHV-HMI-021).
class SafetyBanner extends StatelessWidget {
  const SafetyBanner(this.warning, {super.key});

  final SafetyWarning warning;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: 'Emniyet uyarısı',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: scheme.onTertiaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                safetyText(warning),
                style: TextStyle(color: scheme.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Boş liste görünümü: açıklama ve önerilen ilk adım (KHV-HMI-032).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(title, style: t.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bölüm başlığı.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}

/// İçerik yüklenirken veya hata durumunda sade mesaj (KHV-HMI-042).
class ContentGate extends ConsumerWidget {
  const ContentGate({super.key, required this.builder});

  final Widget Function(BuildContext context, ContentBundle content) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(contentProvider)
        .when(
          data: (c) => builder(context, c),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const EmptyState(
            icon: Icons.error_outline,
            title: 'İçerik açılamadı',
            message:
                'Tarifler yüklenemedi. Uygulamayı yeniden başlatın; sorun '
                'sürerse Yardım ekranından bize bildirin.',
          ),
        );
  }
}

/// Basılı tutarak onaylanan buton; geri alınamaz işlemler için
/// (KHV-HMI-009, KHV-HMI-025: en az 56 dp).
class HoldButton extends StatefulWidget {
  const HoldButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.icon = Icons.stop,
  });

  final String label;
  final IconData icon;
  final VoidCallback onConfirmed;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          _c.reset();
          widget.onConfirmed();
        }
      });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '${widget.label}, basılı tutun',
      onTap: widget.onConfirmed,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => _c.forward(),
        onTapUp: (_) => _c.reverse(),
        onTapCancel: () => _c.reverse(),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Container(
            constraints: const BoxConstraints(minHeight: 56, minWidth: 56),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [scheme.errorContainer, scheme.surfaceContainerHighest],
                stops: [_c.value, _c.value],
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: scheme.onSurface),
                const SizedBox(width: 8),
                Text('${widget.label} (basılı tut)'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
