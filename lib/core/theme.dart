import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light(TextTheme base) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: base.apply(bodyColor: colorScheme.onSurface),
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.all(12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
    );
  }

  static ThemeData dark(TextTheme base) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: base.apply(bodyColor: colorScheme.onSurface),
      scaffoldBackgroundColor: _elevated(colorScheme.surface, 3),
      appBarTheme: AppBarTheme(
        backgroundColor: _elevated(colorScheme.surface, 2),
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        margin: const EdgeInsets.all(12),
        elevation: 0,
        color: _elevated(colorScheme.surface, 2),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _elevated(colorScheme.surface, 2),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );
  }

  static Color _elevated(Color c, int level) {
    return Color.alphaBlend(Colors.white.withValues(alpha: 0.02 * level), c);
  }
}
