import 'package:flutter/material.dart';

/// Single source of truth for all app colors, gradients, and shadows.
/// Adjust once here → reflects everywhere.
class Palette {
  Palette._(); // prevent instantiation

  // ── Base ──────────────────────────────────────────────
  // Warm paper-like neutrals sampled from the Kizuna presentation artwork.
  static const cream = Color(0xFFFFF3D6);
  static const white = Color(0xFFFFFCF5);
  static const text = Color(0xFF4F3D31);
  static const deepGrey = Color(0xFF735D4D);
  static const surface = Color(0xFFFFFCF5);
  static const surfaceWarm = Color(0xFFFFF7E7);
  static const outlineWarm = Color(0xFFEEDBC7);

  // ── Brand / Primary ──────────────────────────────────
  static const terracotta = Color(0xFFE47751);
  static const terracottaDark = Color(0xFFBF5738);
  static const terracottaLight = Color(0xFFF3A071);
  static const authGrey = Color(0xFF7C695B);

  // Backward-compatible names. Existing screens still use the old "sky" API,
  // but all primary actions now resolve to the Kizuna orange family.
  static const sky = terracotta;
  static const skyDark = terracottaDark;
  static const skyLight = terracottaLight;
  static const deepSky = Color(0xFFE98B63);
  static const blueChip = Color(0xFFEFA17C);
  static const blueBtn = Color(0xFFE98B63);
  static const bluePill = Color(0xFFF0AA85);

  // ── Semantic ─────────────────────────────────────────
  // Fresh, saturated greens used by success states, progress and confirm CTAs.
  static const success = Color(0xFF16A34A);
  static const successAlt = Color(0xFF16A34A);
  static const successDark = Color(0xFF15803D);
  static const error = Color(0xFFFF8A8A);
  static const errorStrong = Color(0xFFE85C5C);
  static const warning = Color(0xFFF09A3E);
  static const warningLight = Color(0xFFF7B968);

  // ── Accents ──────────────────────────────────────────
  static const teal = Color(0xFF10B981);
  static const pink = Color(0xFFE7866F);
  static const purple = Color(0xFFC78B68);
  static const yellow = Color(0xFFF3C96B);
  static const yellowBright = Color(0xFFEFB84E);
  static const yellowLight = Color(0xFFF7D98D);
  static const facebook = Color(0xFF1877F2);

  // ── Surface / Card ───────────────────────────────────
  static const greyCard = Color(0xFFF4ECE3);
  static const divider = Color(0xFFEBDCCF);
  static const labelGrey = Color(0xFF9B8777);
  static const deleteRed = Color(0xFFFF6B6B);
  static const lightBlue = Color(0xFFF4C5AA);

  // ── Progress bars ────────────────────────────────────
  static const progressBg = Color(0xFFF1E5D4);
  static const progressFill = success;

  // ── Category placeholders ────────────────────────────
  static const languagePlaceholder = Color(0xFFF6D883);
  static const physicalPlaceholder = Color(0xFFF1A889);

  // ══════════════════════════════════════════════════════
  // ── Gradients (Line-like: มีแสงเงา ไม่ monotone) ──
  // ══════════════════════════════════════════════════════

  /// Primary button / header — warm Kizuna orange gradient.
  static LinearGradient get skyGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [skyLight, skyDark],
      );

  /// Success / confirm button gradient
  static LinearGradient get successGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4ADE80), successAlt],
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
        colors: [terracottaLight, terracottaDark],
      );

  /// Orange nav bar shadow — upward glow for bottom nav elevation
  static List<BoxShadow> get orangeButtonShadow => [
        BoxShadow(
          color: terracotta.withValues(alpha: 0.35),
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
          Color(0xFFFFFDF7),
          Color(0xFFFFF7E8),
          Color(0xFFFFEACB),
        ],
        stops: [0.0, 0.40, 1.0],
      );

  /// Warm cream header gradient (home/background sections)
  static LinearGradient get creamGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFDF7),
          Color(0xFFFFF7E8),
          Color(0xFFFFEACB),
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

  /// Primary button shadow — warm orange glow.
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
