import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import '../state/settings.dart';
import 'common.dart';

/// Oran hesaplayıcısı: herhangi iki değerden üçüncüsü (KHV-FR-RCP-002),
/// fincan sayısından miktar (KHV-FR-RCP-003).
class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  CalcTarget _target = CalcTarget.water;
  double _coffee = 15;
  double _water = 250;
  double _ratio = 16;
  double _cups = 2;
  double? _cupMl;

  BrewAmounts? get _result {
    try {
      return switch (_target) {
        CalcTarget.water => BrewCalculator.solve(
          coffeeG: _coffee,
          ratio: _ratio,
        ),
        CalcTarget.coffee => BrewCalculator.solve(
          waterG: _water,
          ratio: _ratio,
        ),
        CalcTarget.ratio => BrewCalculator.solve(
          coffeeG: _coffee,
          waterG: _water,
        ),
      };
    } on CalculatorException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final cupMl = _cupMl ?? settings.cupMl;
    final r = _result;
    final cupsResult = BrewCalculator.forCups(
      cups: _cups.round(),
      cupMl: cupMl,
      ratio: _ratio,
    );
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Hesaplayıcı')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Hangisini hesaplayalım?'),
          const SizedBox(height: 8),
          SegmentedButton<CalcTarget>(
            segments: const [
              ButtonSegment(value: CalcTarget.coffee, label: Text('Kahve')),
              ButtonSegment(value: CalcTarget.water, label: Text('Su')),
              ButtonSegment(value: CalcTarget.ratio, label: Text('Oran')),
            ],
            selected: {_target},
            onSelectionChanged: (s) => setState(() => _target = s.first),
          ),
          const SizedBox(height: 8),
          if (_target != CalcTarget.coffee)
            NumberStepper(
              label: 'Kahve',
              value: _coffee,
              unit: 'g',
              step: 0.5,
              min: 1,
              max: 200,
              onChanged: (v) => setState(() => _coffee = v),
            ),
          if (_target != CalcTarget.water)
            NumberStepper(
              label: 'Su',
              value: _water,
              unit: 'g',
              step: 10,
              min: 10,
              max: 3000,
              decimals: 0,
              onChanged: (v) => setState(() => _water = v),
            ),
          if (_target != CalcTarget.ratio)
            NumberStepper(
              label: 'Oran',
              prefix: '1:',
              value: _ratio,
              unit: '',
              step: 0.5,
              min: 1,
              max: 25,
              onChanged: (v) => setState(() => _ratio = v),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  r == null
                      ? 'Değerleri kontrol edin.'
                      : switch (_target) {
                          CalcTarget.water => '${formatNumber(r.waterG)} g su',
                          CalcTarget.coffee =>
                            '${formatNumber(r.coffeeG)} g kahve',
                          CalcTarget.ratio => formatRatio(r.ratio),
                        },
                  style: t.headlineMedium,
                ),
              ),
            ),
          ),
          const SectionTitle('Fincan sayısından'),
          NumberStepper(
            label: 'Fincan',
            value: _cups,
            unit: 'fincan',
            min: 1,
            max: 12,
            decimals: 0,
            showSlider: false,
            onChanged: (v) => setState(() => _cups = v),
          ),
          NumberStepper(
            label: 'Fincan hacmi',
            value: cupMl,
            unit: 'ml',
            step: 10,
            min: 30,
            max: 500,
            decimals: 0,
            showSlider: false,
            onChanged: (v) => setState(() => _cupMl = v),
          ),
          Text(
            '${formatNumber(cupsResult.coffeeG)} g kahve · '
            '${formatNumber(cupsResult.waterG)} g su (${formatRatio(_ratio)})',
            style: t.titleMedium,
          ),
        ],
      ),
    );
  }
}
