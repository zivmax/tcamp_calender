import 'package:flutter/material.dart';

/// Application theme configuration for TCamp Calendar.
///
/// Provides a consistent Material 3 theme with custom typography
/// optimized for Chinese character rendering.
abstract final class AppTheme {
  /// The primary seed color for the app's color scheme.
  static const Color seedColor = Colors.indigo;

  /// The default font family used throughout the app.
  static const String fontFamily = 'Noto Sans SC';

  /// Creates the light theme for the application.
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(seedColor: seedColor);
    final baseTheme = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: fontFamily,
    );

    return baseTheme.copyWith(
      textTheme: _buildTextTheme(baseTheme.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        indicatorColor: colorScheme.secondaryContainer,
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    // Apply slightly heavier weight for better Chinese character rendering
    const weight = FontWeight.w700;

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontWeight: weight, fontFamily: fontFamily),
      displayMedium: base.displayMedium?.copyWith(fontWeight: weight, fontFamily: fontFamily),
      displaySmall: base.displaySmall?.copyWith(fontWeight: weight, fontFamily: fontFamily),
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: weight, fontFamily: fontFamily),
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: weight, fontFamily: fontFamily),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: weight, fontFamily: fontFamily),
      titleLarge: base.titleLarge?.copyWith(fontWeight: weight, fontFamily: fontFamily),
      titleMedium: base.titleMedium?.copyWith(fontWeight: weight, fontFamily: fontFamily),
      titleSmall: base.titleSmall?.copyWith(fontWeight: weight, fontFamily: fontFamily),
      bodyLarge: base.bodyLarge?.copyWith(fontWeight: weight, fontFamily: fontFamily),
      bodyMedium: base.bodyMedium?.copyWith(fontWeight: weight, fontFamily: fontFamily),
      bodySmall: base.bodySmall?.copyWith(fontWeight: weight, fontFamily: fontFamily),
      labelLarge: base.labelLarge?.copyWith(fontWeight: weight, fontFamily: fontFamily),
      labelMedium: base.labelMedium?.copyWith(fontWeight: weight, fontFamily: fontFamily),
      labelSmall: base.labelSmall?.copyWith(fontWeight: weight, fontFamily: fontFamily),
    );
  }
}
