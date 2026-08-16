// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'palette.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light();

    final String thaiFallback = GoogleFonts.itim().fontFamily!;

    // Nunito is the single app-wide typeface; Itim supplies missing Thai glyphs.
    TextTheme tt = GoogleFonts.nunitoTextTheme(base.textTheme).apply(
      bodyColor: Palette.text,
      displayColor: Palette.text,
    );

    TextStyle withThaiFallback(TextStyle? s) => (s ?? const TextStyle()).merge(
          TextStyle(fontFamilyFallback: [thaiFallback]),
        );

    tt = tt.copyWith(
      displayLarge: withThaiFallback(tt.displayLarge),
      displayMedium: withThaiFallback(tt.displayMedium),
      displaySmall: withThaiFallback(tt.displaySmall),
      headlineLarge: withThaiFallback(tt.headlineLarge),
      headlineMedium: withThaiFallback(tt.headlineMedium),
      headlineSmall: withThaiFallback(tt.headlineSmall),
      titleLarge: withThaiFallback(tt.titleLarge),
      titleMedium: withThaiFallback(tt.titleMedium),
      titleSmall: withThaiFallback(tt.titleSmall),
      bodyLarge: withThaiFallback(tt.bodyLarge),
      bodyMedium: withThaiFallback(tt.bodyMedium),
      bodySmall: withThaiFallback(tt.bodySmall),
      labelLarge: withThaiFallback(tt.labelLarge),
      labelMedium: withThaiFallback(tt.labelMedium),
      labelSmall: withThaiFallback(tt.labelSmall),
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Palette.terracotta,
        brightness: Brightness.light,
      ).copyWith(
        primary: Palette.terracotta,
        onPrimary: Colors.white,
        secondary: Palette.success,
        onSecondary: Colors.white,
        surface: Palette.surface,
        onSurface: Palette.text,
        outline: Palette.outlineWarm,
        outlineVariant: Palette.divider,
        error: Palette.errorStrong,
      ),
      dividerColor: Palette.divider,
      disabledColor: Palette.labelGrey.withValues(alpha: .55),
      textTheme: tt,
      primaryTextTheme: tt,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.terracotta,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Palette.terracotta.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: withThaiFallback(
            const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Palette.terracottaDark,
          textStyle: withThaiFallback(
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Palette.surface,
        hintStyle: withThaiFallback(
          const TextStyle(color: Palette.labelGrey),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Palette.outlineWarm,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Palette.outlineWarm),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Palette.terracotta, width: 1.8),
        ),
      ),
      cardTheme: CardThemeData(
        color: Palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: Palette.terracotta.withValues(alpha: .12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Palette.outlineWarm),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Palette.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Palette.surface,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Palette.surfaceWarm,
        selectedColor: Palette.terracotta.withValues(alpha: .18),
        side: const BorderSide(color: Palette.outlineWarm),
        labelStyle: const TextStyle(color: Palette.text),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Palette.terracotta,
        linearTrackColor: Palette.progressBg,
        circularTrackColor: Palette.progressBg,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Palette.surface,
        indicatorColor: Palette.terracotta.withValues(alpha: .16),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? Palette.terracotta
                : Palette.labelGrey,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Palette.terracotta,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Palette.deepGrey,
        contentTextStyle: TextStyle(color: Colors.white),
        actionTextColor: Palette.yellowLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Palette.text,
        centerTitle: true,
        titleTextStyle: withThaiFallback(
          GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Palette.text,
          ),
        ),
      ),
    );
  }
}
