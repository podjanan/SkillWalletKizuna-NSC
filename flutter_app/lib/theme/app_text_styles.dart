import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'palette.dart';

/// Centralized text styles for the app.
/// Use these instead of calling GoogleFonts directly in screens.
class AppTextStyles {
  AppTextStyles._();

  // OLD FONTS (kept for reference):
  //   heading → GoogleFonts.luckiestGuy  (blocky display font)
  //   body    → GoogleFonts.openSans     (no Thai fallback)
  //   label   → GoogleFonts.openSans     (no Thai fallback)
  //   Thai fallback for heading only: GoogleFonts.itim

  // NEW FONTS: all styles use Open Sans (clean, readable) with Itim Thai fallback
  static final String _thaiFallback = GoogleFonts.itim().fontFamily!;

  /// Heading font (Open Sans Bold + Itim fallback for Thai)
  // OLD: GoogleFonts.luckiestGuy
  static TextStyle heading(double size, {Color? color}) {
    return GoogleFonts.openSans(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color ?? Palette.text,
    ).copyWith(
      fontFamilyFallback: [_thaiFallback],
    );
  }

  /// Body font (Open Sans + Itim fallback for Thai)
  // OLD: GoogleFonts.openSans (no Thai fallback)
  static TextStyle body(double size, {Color? color, FontWeight? weight}) {
    return GoogleFonts.openSans(
      fontSize: size,
      color: color ?? Colors.black,
      fontWeight: weight,
    ).copyWith(
      fontFamilyFallback: [_thaiFallback],
    );
  }

  /// Label font (Open Sans SemiBold + Itim fallback for Thai)
  // OLD: GoogleFonts.openSans (no Thai fallback)
  static TextStyle label(double size, {Color? color}) {
    return GoogleFonts.openSans(
      fontSize: size,
      color: color ?? Palette.deepGrey,
      fontWeight: FontWeight.w600,
    ).copyWith(
      fontFamilyFallback: [_thaiFallback],
    );
  }
}
