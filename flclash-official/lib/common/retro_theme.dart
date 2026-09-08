import 'package:flutter/material.dart';

ThemeData buildRetroTheme({
  required Brightness brightness,
  int? primaryColor,
  bool pureBlack = false,
}) {
  const orange = Color(0xFFFF7901);
  const ink = Color(0xFF24344D);
  const paper = Color(0xFFF4F6FB);
  const green = Color(0xFF3E5D9C);
  const darkGreen = Color(0xFF17243B);
  const darkPanel = Color(0xFF233552);
  final isDark = brightness == Brightness.dark;
  final primary = primaryColor == null ? orange : Color(primaryColor);
  final surface = isDark ? darkGreen : paper;
  final surfaceContainer = isDark ? darkPanel : const Color(0xFFE5EBF6);
  final onSurface = isDark ? const Color(0xFFEDF1F8) : ink;
  final scheme =
      ColorScheme.fromSeed(seedColor: primary, brightness: brightness).copyWith(
        primary: primary,
        onPrimary: isDark ? ink : const Color(0xFFFFF2D6),
        secondary: green,
        onSecondary: const Color(0xFFFFF2D6),
        surface: pureBlack && isDark ? Colors.black : surface,
        onSurface: onSurface,
        surfaceContainerLowest: isDark ? Colors.black : Colors.white,
        surfaceContainerLow: surfaceContainer,
        surfaceContainer: surfaceContainer,
        surfaceContainerHigh: isDark
            ? const Color(0xFF30486D)
            : const Color(0xFFD7E1F2),
        surfaceContainerHighest: isDark
            ? const Color(0xFF415B82)
            : const Color(0xFFC6D5ED),
        outline: isDark ? const Color(0xFF8A9EBE) : const Color(0xFF7789A6),
        error: const Color(0xFFA84D3B),
      );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'JetBrainsMono',
    scaffoldBackgroundColor: scheme.surface,
    canvasColor: scheme.surface,
    dividerTheme: DividerThemeData(
      color: scheme.outline,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: green,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontFamily: 'JetBrainsMono',
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainer,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      margin: EdgeInsets.zero,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: primary.withValues(alpha: 0.28),
      selectedIconTheme: IconThemeData(color: scheme.onSurface, size: 21),
      unselectedIconTheme: IconThemeData(
        color: scheme.onSurface.withValues(alpha: 0.68),
        size: 21,
      ),
      selectedLabelTextStyle: TextStyle(color: scheme.onSurface, fontSize: 11),
      unselectedLabelTextStyle: TextStyle(
        color: scheme.onSurface.withValues(alpha: 0.68),
        fontSize: 11,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: primary.withValues(alpha: 0.28),
      labelTextStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 10)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: green,
        foregroundColor: const Color(0xFFFFF2D6),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        elevation: 2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outline, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: ink,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: primary, width: 2),
      ),
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'JetBrainsMono',
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
  );
}
