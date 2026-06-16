import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../theme/palette.dart';

/// Alias kept for backward-compatibility with existing callers.
TextStyle luckiestH(double size, {Color? color}) =>
    AppTextStyles.heading(size, color: color);

// ══════════════════════════════════════════════════════════
// AppCard — white card with Line-like soft shadow
// ══════════════════════════════════════════════════════════
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  final List<BoxShadow>? shadow;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.color,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Palette.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ?? Palette.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// GradientButton — gradient background + shadow (Line-like)
// ══════════════════════════════════════════════════════════
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final LinearGradient gradient;
  final List<BoxShadow>? shadow;
  final double fontSize;
  final EdgeInsets padding;
  final double radius;
  final Widget? icon;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.label,
    required this.gradient,
    this.onTap,
    this.shadow,
    this.fontSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.radius = 16,
    this.icon,
    this.isLoading = false,
  });

  /// Convenience: primary sky-blue button
  factory GradientButton.primary({
    Key? key,
    required String label,
    VoidCallback? onTap,
    double fontSize = 16,
    EdgeInsets? padding,
    double radius = 16,
    Widget? icon,
    bool isLoading = false,
  }) =>
      GradientButton(
        key: key,
        label: label,
        gradient: Palette.skyGradient,
        shadow: Palette.buttonShadow,
        onTap: onTap,
        fontSize: fontSize,
        padding: padding ??
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        radius: radius,
        icon: icon,
        isLoading: isLoading,
      );

  /// Convenience: success green button
  factory GradientButton.success({
    Key? key,
    required String label,
    VoidCallback? onTap,
    double fontSize = 16,
    EdgeInsets? padding,
    double radius = 16,
    Widget? icon,
    bool isLoading = false,
  }) =>
      GradientButton(
        key: key,
        label: label,
        gradient: Palette.successGradient,
        shadow: Palette.successShadow,
        onTap: onTap,
        fontSize: fontSize,
        padding: padding ??
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        radius: radius,
        icon: icon,
        isLoading: isLoading,
      );

  /// Convenience: danger red button
  factory GradientButton.danger({
    Key? key,
    required String label,
    VoidCallback? onTap,
    double fontSize = 16,
    EdgeInsets? padding,
    double radius = 16,
  }) =>
      GradientButton(
        key: key,
        label: label,
        gradient: Palette.dangerGradient,
        onTap: onTap,
        fontSize: fontSize,
        padding: padding ??
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        radius: radius,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: Colors.white24,
          child: Padding(
            padding: padding,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        icon!,
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: AppTextStyles.heading(fontSize,
                            color: Colors.white),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// PillButton — compact rounded button (existing, updated)
// ══════════════════════════════════════════════════════════
class PillButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double radius;
  final double fontSize;
  final List<BoxShadow>? shadow;

  const PillButton({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.radius = 22,
    this.fontSize = 14,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ?? Palette.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: padding,
            child: Text(label, style: luckiestH(fontSize, color: fg)),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// OutlineCard — card with border (existing, updated with shadow)
// ══════════════════════════════════════════════════════════
class OutlineCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const OutlineCard({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Palette.blueChip, width: 1.5),
        boxShadow: Palette.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// TinyProgress — progress bar (existing)
// ══════════════════════════════════════════════════════════
class TinyProgress extends StatelessWidget {
  final double value;

  const TinyProgress({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final double clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Container(height: 14, color: Palette.progressBg),
          FractionallySizedBox(
            widthFactor: clamped,
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                gradient: Palette.successGradient,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// SectionHeader — consistent section title with optional action
// ══════════════════════════════════════════════════════════
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.heading(16, color: Palette.text)),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: AppTextStyles.label(13, color: Palette.sky),
            ),
          ),
      ],
    );
  }
}
