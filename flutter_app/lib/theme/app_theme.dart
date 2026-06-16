// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'palette.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light();

    // OLD Thai fallback font: GoogleFonts.itim
    final String thaiFallback = GoogleFonts.itim().fontFamily!;

    // OLD base TextTheme: GoogleFonts.luckiestGuyTextTheme
    // NEW: Open Sans for all text — matches AppTextStyles.heading/body/label
    TextTheme tt = GoogleFonts.openSansTextTheme(base.textTheme).apply(
      bodyColor: Colors.black87,
      displayColor: Colors.black87,
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
        seedColor: Palette.yellowBright,
        surface: Palette.cream,
      ),
      textTheme: tt,
      primaryTextTheme: tt,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.sky,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Palette.sky.withValues(alpha: 0.45),
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
          foregroundColor: Palette.pink,
          textStyle: withThaiFallback(
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: withThaiFallback(
          const TextStyle(color: Colors.black54),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.black.withValues(alpha: .08),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: true,
        // OLD appBar title: GoogleFonts.luckiestGuy(fontSize: 22, fontWeight: FontWeight.w900)
        titleTextStyle: withThaiFallback(
          GoogleFonts.openSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
