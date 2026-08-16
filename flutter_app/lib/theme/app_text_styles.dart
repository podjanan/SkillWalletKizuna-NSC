import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'palette.dart';

/// Centralized text styles for the app.
/// Use these instead of calling GoogleFonts directly in screens.
class AppTextStyles {
  AppTextStyles._();

  static final String _thaiFallback = GoogleFonts.itim().fontFamily!;

  /// Brand mark using the same Nunito family as the rest of the app.
  static TextStyle brand(double size, {Color? color}) {
    return GoogleFonts.nunito(
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: color ?? Palette.terracotta,
    ).copyWith(
      fontFamilyFallback: [_thaiFallback],
    );
  }

  /// Section headings (Welcome Back, New to the family?, etc.)
  static TextStyle heading(double size, {Color? color}) {
    return GoogleFonts.nunito(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: color ?? Palette.text,
    ).copyWith(
      fontFamilyFallback: [_thaiFallback],
    );
  }

  /// Body font (Nunito + Itim fallback for Thai)
  static TextStyle body(double size, {Color? color, FontWeight? weight}) {
    return GoogleFonts.nunito(
      fontSize: size,
      color: color ?? Palette.text,
      fontWeight: weight,
    ).copyWith(
      fontFamilyFallback: [_thaiFallback],
    );
  }

  /// Label font (Nunito SemiBold + Itim fallback for Thai)
  static TextStyle label(double size, {Color? color}) {
    return GoogleFonts.nunito(
      fontSize: size,
      color: color ?? Palette.deepGrey,
      fontWeight: FontWeight.w600,
    ).copyWith(
      fontFamilyFallback: [_thaiFallback],
    );
  }
}
