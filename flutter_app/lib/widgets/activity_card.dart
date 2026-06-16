import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/activity.dart';
import '../providers/user_provider.dart';
import '../routes/app_routes.dart';
import '../services/draft_service.dart';
import '../theme/app_text_styles.dart';
import '../theme/palette.dart';
import '../utils/math_op_detector.dart';
import '../utils/youtube_helper.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
  });

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final category = activity.category.toUpperCase();

    final bool hasTikTokOEmbedData = category == 'ด้านร่างกาย' &&
        activity.videoUrl != null &&
        activity.tiktokHtmlContent != null &&
        activity.thumbnailUrl != null;

    String? youtubeThumbnailUrl;
    if ((category == 'ด้านภาษา' || category == 'LANGUAGE') &&
        activity.videoUrl != null) {
      final videoId = YouTubeHelper.extractVideoId(activity.videoUrl!);
      if (videoId != null) {
        youtubeThumbnailUrl = YouTubeHelper.thumbnailUrl(videoId);
      }
    }
    final bool hasYouTubeVideo = youtubeThumbnailUrl != null;

    final bool shouldGoToVideoDetail =
        category == 'ด้านร่างกาย' && activity.videoUrl != null;

    void showSelectChildDialog() {
      final l10n = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              Text(
                l10n.activityCard_selectChild,
                style: AppTextStyles.heading(20),
              ),
            ],
          ),
          content: Text(
            l10n.activityCard_selectChildMsg,
            style: AppTextStyles.body(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                l10n.common_close,
                style: AppTextStyles.body(14, color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushNamed(context, AppRoutes.childSetting);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.sky,
              ),
              child: Text(
                l10n.activityCard_goSelect,
                style: AppTextStyles.body(14, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    void doNavigate() {
      if (category == 'ด้านภาษา' || category == 'LANGUAGE') {
        Navigator.pushNamed(context, AppRoutes.languageDetail, arguments: activity);
      } else if (shouldGoToVideoDetail) {
        Navigator.pushNamed(context, AppRoutes.videoDetail, arguments: activity);
      } else if (category == 'ด้านคำนวณ') {
        Navigator.pushNamed(context, AppRoutes.calculateActivity, arguments: activity);
      } else {
        Navigator.pushNamed(context, AppRoutes.itemIntro, arguments: activity);
      }
    }

    Future<void> navigate() async {
      final userProvider = context.read<UserProvider>();
      if (userProvider.currentChildId == null) {
        showSelectChildDialog();
        return;
      }

      // Check if there's a saved draft for a DIFFERENT activity
      final childId = userProvider.currentChildId!;
      final draft = await DraftService.loadDraft(childId);
      if (draft != null && draft['activityId'] != activity.id) {
        // There's a draft for a different activity — warn user
        final draftName =
            (draft['activityJson'] as Map<String, dynamic>?)?['name_activity']
                as String? ??
                '—';
        if (!context.mounted) return;
        final l10n = AppLocalizations.of(context)!;
        final choice = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.draft_conflictTitle, style: AppTextStyles.heading(18)),
            content: Text(
              l10n.draft_conflictMsg(draftName),
              style: AppTextStyles.body(14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: Text(l10n.common_cancel, style: AppTextStyles.body(14)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'discard'),
                child: Text(l10n.draft_bannerDiscard,
                    style: AppTextStyles.body(14, color: Palette.pink)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, 'play'),
                style: ElevatedButton.styleFrom(backgroundColor: Palette.sky),
                child: Text(l10n.draft_conflictPlay,
                    style: AppTextStyles.label(14, color: Colors.white)),
              ),
            ],
          ),
        );
        if (!context.mounted) return;
        if (choice == 'cancel') return;
        if (choice == 'discard') {
          await DraftService.clearDraft(childId);
        }
        // 'play' or 'discard' → proceed to navigate
      }

      if (!context.mounted) return;
      doNavigate();
    }

    // Category accent color for info strip & score badge
    final Color accentColor = _categoryAccent(category);

    return GestureDetector(
      onTap: navigate,
      child: Container(
        width: 125,
        height: 145,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: Palette.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: _buildThumbnail(
                  hasTikTokOEmbedData: hasTikTokOEmbedData,
                  hasYouTubeVideo: hasYouTubeVideo,
                  youtubeThumbnailUrl: youtubeThumbnailUrl,
                ),
              ),
            ),
            // Thin category color accent line
            Container(height: 2.5, color: accentColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 3, 6, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: AppTextStyles.heading(11, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 10, color: accentColor),
                      const SizedBox(width: 2),
                      Text(
                        '${activity.maxScore}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _categoryAccent(String category) {
    switch (category) {
      case 'ด้านภาษา':
      case 'LANGUAGE':
        return const Color(0xFFFFB300); // amber
      case 'ด้านร่างกาย':
        return Palette.pink;
      case 'ด้านคำนวณ':
        return Palette.sky;
      default:
        return Palette.teal;
    }
  }

  Widget _buildThumbnail({
    required bool hasTikTokOEmbedData,
    required bool hasYouTubeVideo,
    String? youtubeThumbnailUrl,
  }) {
    if (hasTikTokOEmbedData && activity.thumbnailUrl != null) {
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Image.network(
          activity.thumbnailUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    }

    if (hasYouTubeVideo && youtubeThumbnailUrl != null) {
      // YouTube hqdefault เป็น 4:3 แต่วีดีโอเป็น 16:9 ทำให้มีแถบดำ
      // ขยาย 1.35x เพื่อตัดแถบดำออก
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Transform.scale(
          scale: 1.32,
          child: Image.network(
            youtubeThumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder();
            },
          ),
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    // กำหนดสีและไอคอนตามประเภทกิจกรรม
    final category = activity.category;

    // ด้านคำนวณ = dynamic operator cover
    if (category == 'ด้านคำนวณ') {
      return _buildCalculateCover();
    }

    // ด้านภาษา = ABC with yellow background
    if (category == 'ด้านภาษา' || category.toUpperCase() == 'LANGUAGE') {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Palette.languagePlaceholder,
        alignment: Alignment.center,
        child: const Text(
          'ABC',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      );
    }

    // ด้านร่างกาย = Running icon with pink background
    if (category == 'ด้านร่างกาย') {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Palette.physicalPlaceholder,
        alignment: Alignment.center,
        child: const Icon(
          Icons.directions_run,
          color: Colors.white,
          size: 50,
        ),
      );
    }

    // Default fallback
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Palette.sky,
      alignment: Alignment.center,
      child: Text(
        category.isNotEmpty ? category.substring(0, 1) : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Builds the calculate-activity cover by scanning segment questions
  /// for math operators and showing them as seamless coloured blocks.
  Widget _buildCalculateCover() {
    final ops = MathOpDetector.detect(activity.segments);
    final display = ops.isEmpty
        ? [
            MathOpDetector.plus,
            MathOpDetector.minus,
            MathOpDetector.multiply,
            MathOpDetector.divide,
          ]
        : ops.take(4).toList();

    Color opColor(String op) =>
        Color(MathOpDetector.opColorValue[op] ?? 0xFF0D92F4);

    const symStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      shadows: [Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(1, 2))],
    );

    Widget symTile(String op, Color color) => Expanded(
          child: Container(
            color: color,
            alignment: Alignment.center,
            child: Text(op, style: symStyle.copyWith(fontSize: 30)),
          ),
        );

    // ── 1 operator: full gradient cover ───────────────
    if (display.length == 1) {
      final c = opColor(display[0]);
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(Colors.white, c, 0.55)!,
              c,
              Color.lerp(c, Colors.black, 0.20)!,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          display[0],
          style: symStyle.copyWith(fontSize: 46),
        ),
      );
    }

    // ── 2 operators: left / right halves ──────────────
    if (display.length == 2) {
      return Row(children: display.map((op) => symTile(op, opColor(op))).toList());
    }

    // ── 3 operators: top full + bottom split ──────────
    if (display.length == 3) {
      return Column(children: [
        symTile(display[0], opColor(display[0])),
        Expanded(
          child: Row(children: [
            symTile(display[1], opColor(display[1])),
            symTile(display[2], opColor(display[2])),
          ]),
        ),
      ]);
    }

    // ── 4 operators: 2×2 seamless grid ────────────────
    return Column(children: [
      Expanded(child: Row(children: [
        symTile(display[0], opColor(display[0])),
        symTile(display[1], opColor(display[1])),
      ])),
      Expanded(child: Row(children: [
        symTile(display[2], opColor(display[2])),
        symTile(display[3], opColor(display[3])),
      ])),
    ]);
  }
}
