import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../theme/palette.dart';

/// Reusable circular avatar for children.
/// Shows [photoUrl] if valid, falls back to first letter of [name].
/// Handles network errors and loading state consistently.
class ChildAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;

  /// Radius of the circle (default 24 → diameter 48)
  final double radius;

  /// Font size for the fallback initial letter
  final double fontSize;

  const ChildAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.radius = 24,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final url = (photoUrl ?? '').trim();
    final diameter = radius * 2;

    return CircleAvatar(
      radius: radius,
      backgroundColor: Palette.sky.withValues(alpha: 0.10),
      child: ClipOval(
        child: url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                width: diameter,
                height: diameter,
                errorBuilder: (_, __, ___) => _fallback(diameter),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : _loading(diameter),
              )
            : _fallback(diameter),
      ),
    );
  }

  Widget _fallback(double size) => SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: AppTextStyles.heading(fontSize, color: Palette.sky),
          ),
        ),
      );

  Widget _loading(double size) => SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Palette.sky),
        ),
      );
}
