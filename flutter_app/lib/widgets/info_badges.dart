import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/activity.dart';
import '../theme/palette.dart';
import '../utils/activity_l10n.dart';

/// Shared info badges row showing Category, Difficulty, Max Score.
/// Used on language detail, physical video detail, and analysis activity screens.
class InfoBadges extends StatelessWidget {
  final Activity activity;

  const InfoBadges({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localizedCategory =
        ActivityL10n.localizedCategory(context, activity.category);
    final localizedDifficulty =
        ActivityL10n.localizedDifficulty(context, activity.difficulty);

    return Row(
      children: [
        _Badge(
          icon: Icons.category_outlined,
          label: l10n.common_categoryLabel,
          value: localizedCategory,
          color: Palette.sky,
        ),
        const SizedBox(width: 8),
        _Badge(
          icon: Icons.speed_outlined,
          label: l10n.common_difficultyLabel,
          value: localizedDifficulty,
          color: Palette.warning,
        ),
        const SizedBox(width: 8),
        _Badge(
          icon: Icons.star_outline,
          label: l10n.common_maxScoreLabel,
          value: '${activity.maxScore}',
          color: Palette.successAlt,
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _Badge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.openSans(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.openSans(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
