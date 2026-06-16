// lib/widgets/draft_banner.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';

import '../models/activity.dart';
import '../providers/user_provider.dart';
import '../routes/app_routes.dart';
import '../services/draft_service.dart';
import '../theme/app_text_styles.dart';
import '../theme/palette.dart';
import '../utils/activity_l10n.dart';

class DraftBanner extends StatefulWidget {
  const DraftBanner({super.key});

  @override
  State<DraftBanner> createState() => _DraftBannerState();
}

class _DraftBannerState extends State<DraftBanner> {
  Map<String, dynamic>? _draft;
  String? _loadedForChildId;

  @override
  void initState() {
    super.initState();
    DraftService.versionNotifier.addListener(_onVersionChange);
  }

  @override
  void dispose() {
    DraftService.versionNotifier.removeListener(_onVersionChange);
    super.dispose();
  }

  void _onVersionChange() {
    // Force reload when draft is saved or cleared
    _loadedForChildId = null;
    _loadDraft();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final childId = context.read<UserProvider>().currentChildId;
    if (childId == _loadedForChildId) return; // already loaded for this child
    _loadedForChildId = childId;
    if (childId == null) {
      if (mounted) setState(() => _draft = null);
      return;
    }
    final draft = await DraftService.loadDraft(childId);
    if (mounted) setState(() => _draft = draft);
  }

  Future<void> _resume() async {
    if (_draft == null) return;
    final type = _draft!['type'] as String;
    final activityJson = _draft!['activityJson'] as Map<String, dynamic>;
    final activity = Activity.fromJson(activityJson);
    final route = switch (type) {
      DraftService.typePhysical => AppRoutes.physicalActivity,
      DraftService.typeCalculate => AppRoutes.calculateActivity,
      _ => AppRoutes.itemIntro,
    };
    if (!mounted) return;
    Navigator.pushNamed(context, route, arguments: activity);
  }

  Future<void> _discard() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.draft_discardTitle, style: AppTextStyles.heading(18)),
        content: Text(l.draft_discardMsg, style: AppTextStyles.body(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.common_cancel, style: AppTextStyles.body(14)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.draft_bannerDiscard,
                style: AppTextStyles.body(14, color: Palette.pink)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final childId = context.read<UserProvider>().currentChildId;
    if (childId != null) await DraftService.clearDraft(childId);
    // clearDraft bumps versionNotifier → _onVersionChange reloads
  }

  static Color _categoryAccent(String category) {
    switch (category) {
      case 'ด้านภาษา':
      case 'LANGUAGE':
        return const Color(0xFFFFB300);
      case 'ด้านร่างกาย':
        return Palette.pink;
      case 'ด้านคำนวณ':
        return Palette.sky;
      default:
        return Palette.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_draft == null) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final activityJson =
        _draft!['activityJson'] as Map<String, dynamic>? ?? {};
    final activityName = activityJson['name_activity'] as String? ?? '—';
    final category = activityJson['category'] as String? ?? '';
    final Color accent = _categoryAccent(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Palette.cardShadow,
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left category accent strip ───────────────
            Container(width: 4, color: accent),

            // ── Main content ─────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Row(
                  children: [
                    // Icon circle
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_circle_rounded,
                        color: accent,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Text info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  l.draft_bannerTitle,
                                  style: AppTextStyles.label(
                                      11, color: Palette.deepGrey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    ActivityL10n.localizedActivityType(
                                        context, category),
                                    style: AppTextStyles.label(10,
                                        color: accent),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            activityName,
                            style:
                                AppTextStyles.heading(14, color: Palette.text),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Resume button with gradient
                    GestureDetector(
                      onTap: _resume,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.lerp(Colors.white, accent, 0.55)!,
                              accent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          l.draft_bannerResume,
                          style:
                              AppTextStyles.label(13, color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Discard X
                    GestureDetector(
                      onTap: _discard,
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
