import 'package:flutter/material.dart';

class AppTheme {
  // Modern color palette with shades
  static const _primary = Color(0xFF1FA37B);
  static const _primaryDark = Color(0xFF198A66);
  static const _primaryLight = Color(0xFF4DBF99);
  static const _background = Color(0xFFF5F7F6);
  static const _surface = Color(0xFFFFFFFF);
  static const _onSurface = Color(0xFF2D2D2D);
  static const _onSurfaceVariant = Color(0xFF666666);
  static const _outline = Color(0xFFE0E0E0);
  static const _error = Color(0xFFBA1A1A);

  // Gradients
  static final _primaryGradient = LinearGradient(
    colors: [_primary, _primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static final _softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static final _mediumShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
      primary: _primary,
      onPrimary: Colors.white,
      primaryContainer: _primaryLight.withOpacity(0.2),
      secondary: _primaryLight,
      onSecondary: Colors.white,
      background: _background,
      surface: _surface,
      onSurface: _onSurface,
      onSurfaceVariant: _onSurfaceVariant,
      outline: _outline,
      error: _error,
    ),
    scaffoldBackgroundColor: _background,

    // Enhanced App Bar
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: _onSurface,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      surfaceTintColor: Colors.transparent,
      titleTextStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: _onSurface,
      ),
      iconTheme: const IconThemeData(color: _onSurface),
    ),

    // Enhanced Card Theme
    cardTheme: CardThemeData(
      color: _surface,
      shadowColor: Colors.black12,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _outline.withOpacity(0.5), width: 1),
      ),
      surfaceTintColor: Colors.transparent,
    ),

    // Enhanced FAB
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      highlightElevation: 8,
    ),

    // Enhanced Bottom Navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _surface,
      selectedItemColor: _primary,
      unselectedItemColor: _onSurfaceVariant,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
    ),

    // Enhanced Text Theme
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 32,
        color: _onSurface,
        height: 1.2,
      ),
      displayMedium: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 24,
        color: _onSurface,
        height: 1.3,
      ),
      titleLarge: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: _onSurface,
        height: 1.4,
      ),
      titleMedium: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: _onSurface,
        height: 1.4,
      ),
      bodyLarge: const TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: _onSurface,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: _onSurfaceVariant,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: _onSurfaceVariant.withOpacity(0.8),
        height: 1.5,
      ),
      labelLarge: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Colors.white,
        height: 1.4,
      ),
    ),

    // Enhanced Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _outline),
        gapPadding: 0,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _error, width: 2),
      ),
      labelStyle: TextStyle(color: _onSurfaceVariant),
      hintStyle: TextStyle(color: _onSurfaceVariant.withOpacity(0.6)),
      errorStyle: TextStyle(color: _error, fontSize: 12),
    ),

    // Enhanced Button Themes
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primary,
        side: BorderSide(color: _primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Enhanced Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: _surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: _onSurface,
      ),
      contentTextStyle: TextStyle(
        fontSize: 14,
        color: _onSurfaceVariant,
      ),
    ),

    // Bottom Sheet Theme
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: _surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      elevation: 8,
      modalElevation: 16,
    ),

    // Divider Theme
    dividerTheme: DividerThemeData(
      color: _outline,
      thickness: 1,
      space: 0,
    ),

    // Progress Indicator
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: _primary,
      linearTrackColor: _outline,
      circularTrackColor: _outline,
    ),
  );

  // Additional static methods for custom widgets
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _softShadow,
        border: Border.all(color: _outline.withOpacity(0.3)),
      );

  static BoxDecoration get gradientButtonDecoration => BoxDecoration(
        gradient: _primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _mediumShadow,
      );

  static BoxDecoration get floatingCardDecoration => BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _mediumShadow,
      );

  // Text styles for specific use cases
  static TextStyle get headlineStyle => const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 28,
        color: _onSurface,
        height: 1.2,
      );

  static TextStyle get subtitleStyle => TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: _onSurfaceVariant,
        height: 1.4,
      );

  static TextStyle get captionStyle => TextStyle(
        fontSize: 12,
        color: _onSurfaceVariant.withOpacity(0.7),
        height: 1.3,
      );
}