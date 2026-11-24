import 'package:material_ui/material_ui.dart';

/// Material 3 HCT tabanlı palet; widget kodunda doğrudan renk değeri
/// kullanılmaz, yalnız ColorScheme rolleri kullanılır (KHV-HMI-033,
/// KHV-HMI-036).
const _seed = Color(0xFF6F4E37);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    // Gövde metni M3 bodyLarge: 16 sp (KHV-HMI-028).
    listTileTheme: const ListTileThemeData(minVerticalPadding: 8),
    pageTransitionsTheme: const PageTransitionsTheme(),
  );
}
