import 'package:flutter/material.dart';

/// Single source of truth for all app colors, gradients, and shadows.
/// Adjust once here → reflects everywhere.
class Palette {
  Palette._(); // prevent instantiation

  // ── Base ──────────────────────────────────────────────
  static const cream = Color(0xFFFFF5CD);
  static const white = Colors.white;
  static const text = Colors.black87;
  static const deepGrey = Color(0xFF5D5D5D);

  // ── Brand / Primary ──────────────────────────────────
  static const sky = Color(0xFF0D92F4); // primary blue
  static const skyDark = Color(0xFF0A6FC2); // deep blue (gradient end)
  static const skyLight = Color(0xFF42B4FF); // bright blue (gradient start)
  static const deepSky = Color(0xFF7DBEF1); // lighter blue (home)
  static const blueChip = Color(0xFF59B3FF); // chip/tag blue
  static const blueBtn = Color(0xFF6EC1FF); // play-section blue
  static const bluePill = Color(0xFF78BDF1); // pill badge blue

  // ── Semantic ─────────────────────────────────────────
  static const success = Color(0xFF88C273);
  static const successAlt = Color(0xFF66BB6A);
  static const successDark = Color(0xFF388E3C);
  static const error = Color(0xFFFF8A8A);
  static const errorStrong = Color(0xFFE85C5C);
  static const warning = Color(0xFFFF9800);
  static const warningLight = Color(0xFFFFB74D);

  // ── Accents ──────────────────────────────────────────
  static const teal = Color(0xFF1AAA88);  // suggested / highlight teal
  static const pink = Color(0xFFEA5B6F);
  static const purple = Color(0xFFB67CFF);
  static const yellow = Color(0xFFFFD45E);
  static const yellowBright = Color(0xFFFFCC00);
  static const yellowLight = Color(0xFFFFCB61);
  static const facebook = Color(0xFF1877F2);

  // ── Surface / Card ───────────────────────────────────
  static const greyCard = Color(0xFFE9E9EB);
  static const divider = Color(0xFFE5E5E5);
  static const labelGrey = Color(0xFF9E9E9E);
  static const deleteRed = Color(0xFFFF6B6B);
  static const lightBlue = Color(0xFFA2D2FF);

  // ── Progress bars ────────────────────────────────────
  static const progressBg = Color(0xFFEEE8D5);
  static const progressFill = Color(0xFF8ED081);

  // ── Category placeholders ────────────────────────────
  static const languagePlaceholder = Color(0xFFFFEB3B);
  static const physicalPlaceholder = Color(0xFFFFAB91);

  // ══════════════════════════════════════════════════════
  // ── Gradients (Line-like: มีแสงเงา ไม่ monotone) ──
  // ══════════════════════════════════════════════════════

  /// Primary button / header — sky blue gradient
  static LinearGradient get skyGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [skyLight, skyDark],
      );

  /// Success / confirm button gradient
  static LinearGradient get successGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF98D887), successDark],
      );

  /// Danger / delete button gradient
  static LinearGradient get dangerGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF6B6B), Color(0xFFD32F2F)],
      );

  /// Orange / child nav bar gradient (warm light → deep orange)
  static LinearGradient get orangeGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFB74D), Color(0xFFE65100)],
      );

  /// Orange nav bar shadow — upward glow for bottom nav elevation
  static List<BoxShadow> get orangeButtonShadow => [
        BoxShadow(
          color: Color(0xFFFF9800).withValues(alpha: 0.45),
          blurRadius: 12,
          spreadRadius: 0,
          offset: const Offset(0, -3),
        ),
      ];

  /// Facebook button gradient
  static LinearGradient get facebookGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4267B2), Color(0xFF1877F2)],
      );

  /// Full-app background gradient — warm cream, light from top-left (Line-like)
  static LinearGradient get appBackground => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFF8), // near-white warm (light source)
          Color(0xFFFFF9DE), // soft cream mid
          Color(0xFFFFF0B2), // deeper golden cream
        ],
        stops: [0.0, 0.40, 1.0],
      );

  /// Warm cream header gradient (home/background sections)
  static LinearGradient get creamGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFF8),
          Color(0xFFFFF9DE),
          Color(0xFFFFF0B2),
        ],
        stops: [0.0, 0.40, 1.0],
      );

  /// Card shimmer / highlight overlay (top-edge gloss)
  static LinearGradient get glossOverlay => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.6],
      );

  // ══════════════════════════════════════════════════════
  // ── Shadows (Line-like: soft depth, not harsh) ────────
  // ══════════════════════════════════════════════════════

  /// Standard card shadow — light lift effect
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 12,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
      ];

  /// Primary button shadow — blue tinted glow
  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: sky.withValues(alpha: 0.40),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  /// Success button shadow — green tinted glow
  static List<BoxShadow> get successShadow => [
        BoxShadow(
          color: successAlt.withValues(alpha: 0.40),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  /// Soft shadow for input / small elements
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];

  /// Inset-like subtle shadow (bottom navigation, headers)
  static List<BoxShadow> get headerShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 6,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];
}
