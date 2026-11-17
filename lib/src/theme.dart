import 'package:flutter/material.dart';

/// The whole "Lemon v2" palette lives here. Warm cream, citrus gold, leaf
/// green - one source of truth for light and dark.
class LemonPalette {
  const LemonPalette._();

  static const citrus = Color(0xFFF7B500);
  static const citrusDeep = Color(0xFFDE8A00);
  static const citrusSoft = Color(0xFFFFE9A8);
  static const rind = Color(0xFFFFD98A);
  static const leaf = Color(0xFF5E9E2F);
  static const leafDeep = Color(0xFF3F7220);
  static const cream = Color(0xFFFFFBF0);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFFFF4D9);
  static const ink = Color(0xFF211F15);
  static const inkSoft = Color(0xFF74725E);
  static const line = Color(0xFFF0E7CB);
  static const danger = Color(0xFFD14343);

  static const night = Color(0xFF101109);
  static const nightSurface = Color(0xFF1C1E14);
  static const nightSurfaceAlt = Color(0xFF26281A);
  static const nightInk = Color(0xFFF5F2E3);
  static const nightInkSoft = Color(0xFFA5A48B);
  static const nightLine = Color(0xFF32351F);
  static const nightCitrus = Color(0xFFFFCA3C);
}

class LemonTheme {
  const LemonTheme._();

  static const double radius = 24;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: isDark ? LemonPalette.nightCitrus : LemonPalette.citrus,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? LemonPalette.nightCitrus : LemonPalette.citrus,
      onPrimary: isDark ? LemonPalette.ink : Colors.white,
      secondary: LemonPalette.leaf,
      onSecondary: Colors.white,
      surface: isDark ? LemonPalette.nightSurface : LemonPalette.surface,
      onSurface: isDark ? LemonPalette.nightInk : LemonPalette.ink,
      error: LemonPalette.danger,
      onError: Colors.white,
    );

    final Color bg = isDark ? LemonPalette.night : LemonPalette.cream;
    final Color onSurface = isDark ? LemonPalette.nightInk : LemonPalette.ink;
    final Color softText = isDark ? LemonPalette.nightInkSoft : LemonPalette.inkSoft;
    final Color line = isDark ? LemonPalette.nightLine : LemonPalette.line;

    final TextTheme base = ThemeData(brightness: brightness).textTheme;
    final TextTheme text = base.copyWith(
      displaySmall: base.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8, color: onSurface),
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6, color: onSurface),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4, color: onSurface),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2, color: onSurface),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: onSurface),
      bodyMedium: base.bodyMedium?.copyWith(color: onSurface),
      bodySmall: base.bodySmall?.copyWith(color: softText),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: onSurface),
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: onSurface, size: 22),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(0, 54),
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          minimumSize: const Size(0, 54),
          side: BorderSide(color: line),
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge?.copyWith(fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? LemonPalette.nightSurfaceAlt : LemonPalette.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: softText, fontWeight: FontWeight.w500),
        labelStyle: TextStyle(color: softText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: LemonPalette.danger),
        ),
      ),
      cardTheme: CardTheme(
        color: isDark ? LemonPalette.nightSurface : LemonPalette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: line),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: isDark ? LemonPalette.nightSurface : LemonPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: softText),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? LemonPalette.nightSurface : LemonPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? LemonPalette.nightSurfaceAlt : LemonPalette.ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        elevation: 0,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: line,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withOpacity(0.12),
        trackHeight: 5,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? scheme.onPrimary : softText,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? scheme.primary : line,
        ),
      ),
    );
  }
}
