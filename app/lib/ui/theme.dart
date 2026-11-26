import 'package:material_ui/material_ui.dart';

/// "Sohbet" görsel yönü: akşamüstü ışığı, gün batımı renkleri, masada iki
/// fincan (ürün sahibi kararı, KB-026). Widget kodunda doğrudan renk değeri
/// kullanılmaz; yalnız ColorScheme rolleri ve [SceneColors] kullanılır
/// (KHV-HMI-033). Koyu tema saf siyah/beyaz kullanmaz (KHV-HMI-036).
const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFF6A96C),
  onPrimary: Color(0xFF2B1E2F),
  primaryContainer: Color(0xFF6B3A54),
  onPrimaryContainer: Color(0xFFFCE7D6),
  secondary: Color(0xFFE2A0AE),
  onSecondary: Color(0xFF2B1E2F),
  secondaryContainer: Color(0xFF5A2F45),
  onSecondaryContainer: Color(0xFFFCE7D6),
  tertiary: Color(0xFFFBD38D),
  onTertiary: Color(0xFF2B1E2F),
  tertiaryContainer: Color(0xFF5C4A2A),
  onTertiaryContainer: Color(0xFFFCE7D6),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF2B1E2F),
  onSurface: Color(0xFFFCE7D6),
  onSurfaceVariant: Color(0xFFE2CFDA),
  surfaceContainerLowest: Color(0xFF1E1522),
  surfaceContainerLow: Color(0xFF33243A),
  surfaceContainer: Color(0xFF3A2840),
  surfaceContainerHigh: Color(0xFF44304A),
  surfaceContainerHighest: Color(0xFF4E3955),
  outline: Color(0xFFA48DAA),
  outlineVariant: Color(0xFF5B4260),
  inverseSurface: Color(0xFFFCE7D6),
  onInverseSurface: Color(0xFF2B1E2F),
  inversePrimary: Color(0xFF8A4A1F),
  shadow: Color(0xFF120C14),
  scrim: Color(0xFF120C14),
  surfaceTint: Color(0xFFF6A96C),
);

const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF9A4119),
  onPrimary: Color(0xFFFFFBF7),
  primaryContainer: Color(0xFFFFD9C2),
  onPrimaryContainer: Color(0xFF3A1606),
  secondary: Color(0xFF8E3D57),
  onSecondary: Color(0xFFFFFBF7),
  secondaryContainer: Color(0xFFFFD9E2),
  onSecondaryContainer: Color(0xFF3A0A1C),
  tertiary: Color(0xFF6E5A10),
  onTertiary: Color(0xFFFFFBF7),
  tertiaryContainer: Color(0xFFF9E08A),
  onTertiaryContainer: Color(0xFF221B00),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFBF7),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF410002),
  surface: Color(0xFFFFF4EA),
  onSurface: Color(0xFF2B1E2F),
  onSurfaceVariant: Color(0xFF5B4260),
  surfaceContainerLowest: Color(0xFFFFFBF7),
  surfaceContainerLow: Color(0xFFFBEADB),
  surfaceContainer: Color(0xFFF6E0CF),
  surfaceContainerHigh: Color(0xFFF1D6C3),
  surfaceContainerHighest: Color(0xFFEBCCB7),
  outline: Color(0xFF85727F),
  outlineVariant: Color(0xFFD8C2CC),
  inverseSurface: Color(0xFF2B1E2F),
  onInverseSurface: Color(0xFFFCE7D6),
  inversePrimary: Color(0xFFF6A96C),
  shadow: Color(0xFF2B1E2F),
  scrim: Color(0xFF2B1E2F),
  surfaceTint: Color(0xFF9A4119),
);

/// Gün batımı sahnesi ve yöntem çizimlerinin renkleri (KB-026). Sahne iki
/// temada da aynıdır; çizim olduğu için ColorScheme rollerine bağlanmaz.
@immutable
class SceneColors extends ThemeExtension<SceneColors> {
  /// Varsayılan "Sohbet" sahne renkleri.
  const SceneColors({
    this.sky = const [
      Color(0xFF3B2741),
      Color(0xFF6B3A54),
      Color(0xFFB9566A),
      Color(0xFFE98A6B),
      Color(0xFFF6B27A),
    ],
    this.sun = const Color(0xFFFBD38D),
    this.ridge = const Color(0xFF4A2D47),
    this.sea = const Color(0xFF3A2C48),
    this.glint = const Color(0xFFF6B27A),
    this.table = const Color(0xFF4A3040),
    this.foam = const Color(0xFFFCE7D6),
    this.saucer = const Color(0xFFE2CFDA),
    this.apricot = const Color(0xFFF6A96C),
    this.copper = const Color(0xFFB9566A),
    this.coffee = const Color(0xFF6B3A2E),
    this.crema = const Color(0xFFC9874F),
    this.iced = const Color(0xFF8C5A3C),
    this.glass = const Color(0xFFC9B3C2),
    this.metal = const Color(0xFF8E7896),
    this.text = const Color(0xFFFCE7D6),
  });

  /// Gökyüzü bantları, yukarıdan ufka.
  final List<Color> sky;

  /// Güneş.
  final Color sun;

  /// Uzak tepeler.
  final Color ridge;

  /// Deniz.
  final Color sea;

  /// Denizdeki ışık çizgileri.
  final Color glint;

  /// Masa.
  final Color table;

  /// Köpük, açık fincan, buhar.
  final Color foam;

  /// Fincan tabağı.
  final Color saucer;

  /// Kayısı vurgu (ikinci fincan, damlatıcı).
  final Color apricot;

  /// Bakır (cezve, kapaklar).
  final Color copper;

  /// Demlenmiş kahve.
  final Color coffee;

  /// Espresso kreması.
  final Color crema;

  /// Buzlu kahve.
  final Color iced;

  /// Cam.
  final Color glass;

  /// Metal (makine, piston).
  final Color metal;

  /// Sahne üstündeki yazı.
  final Color text;

  @override
  SceneColors copyWith() => this;

  @override
  SceneColors lerp(SceneColors? other, double t) => this;
}

/// El yazısı notlar için yazı stili ("bir arkadaşın notu", KB-026).
TextStyle handwriting(BuildContext context, {double size = 24, Color? color}) =>
    TextStyle(
      fontFamily: 'Caveat',
      fontWeight: FontWeight.w700,
      fontSize: size,
      height: 1.1,
      color: color ?? Theme.of(context).colorScheme.primary,
    );

ThemeData buildTheme(Brightness brightness) {
  final scheme = brightness == Brightness.dark ? _darkScheme : _lightScheme;
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: 'Figtree',
  );
  final text = base.textTheme;
  const stadium = StadiumBorder();
  return base.copyWith(
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    scaffoldBackgroundColor: scheme.surface,
    extensions: const [SceneColors()],
    // Gövde metni M3 bodyLarge: 16 sp (KHV-HMI-028).
    textTheme: text.copyWith(
      headlineLarge: text.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: scheme.surface,
      titleTextStyle: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    listTileTheme: const ListTileThemeData(minVerticalPadding: 8),
    filledButtonTheme: const FilledButtonThemeData(
      style: ButtonStyle(shape: WidgetStatePropertyAll(stadium)),
    ),
    outlinedButtonTheme: const OutlinedButtonThemeData(
      style: ButtonStyle(shape: WidgetStatePropertyAll(stadium)),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: scheme.outlineVariant),
      selectedColor: scheme.primary,
      checkmarkColor: scheme.onPrimary,
      secondaryLabelStyle: TextStyle(color: scheme.onPrimary),
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainer),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: scheme.primaryContainer,
      surfaceTintColor: scheme.surfaceContainerLowest,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
    ),
    snackBarTheme: SnackBarThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(),
  );
}
