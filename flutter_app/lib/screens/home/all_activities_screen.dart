import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';

import '../../models/activity.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/activity_service.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/palette.dart';
import '../../utils/youtube_helper.dart';
import '../../widgets/game_activity_cover.dart';

enum ActivityListType { popular, newActivity }

class AllActivitiesScreen extends StatefulWidget {
  final ActivityListType type;

  const AllActivitiesScreen({super.key, required this.type});

  @override
  State<AllActivitiesScreen> createState() => _AllActivitiesScreenState();
}

class _AllActivitiesScreenState extends State<AllActivitiesScreen> {
  final _activityService = ActivityService();
  List<Activity> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    final userProvider = context.read<UserProvider>();
    final childId = userProvider.currentChildId ?? '';
    final parentId = userProvider.currentParentId;

    try {
      final activities = widget.type == ActivityListType.popular
          ? await _activityService.fetchPopularActivities(
              childId,
              parentId: parentId,
            )
          : await _activityService.fetchNewActivities(
              childId,
              parentId: parentId,
            );

      if (mounted) {
        setState(() {
          _activities = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.type == ActivityListType.popular
        ? l10n.home_popularactivityBtn
        : l10n.home_newactivityBtn;
    final emptyMsg = widget.type == ActivityListType.popular
        ? l10n.home_cannotBtn
        : l10n.home_nonewBtn;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back,
                        size: 35, color: Colors.black87),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.heading(22, color: Palette.sky),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Grid
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Palette.sky))
                  : _activities.isEmpty
                      ? Center(
                          child: Text(emptyMsg,
                              style: AppTextStyles.body(16,
                                  color: Colors.grey.shade500)))
                      : RefreshIndicator(
                          onRefresh: _loadActivities,
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 12,
                              childAspectRatio: 125 / 148,
                            ),
                            itemCount: _activities.length,
                            itemBuilder: (context, index) {
                              return _ActivityGridCard(
                                  activity: _activities[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// Grid card ที่ responsive ตาม cell ของ GridView
class _ActivityGridCard extends StatelessWidget {
  final Activity activity;

  const _ActivityGridCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final category = activity.category.toUpperCase();

    final bool hasTikTok = category == 'ด้านร่างกาย' &&
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

    final bool shouldGoToVideoDetail =
        category == 'ด้านร่างกาย' && activity.videoUrl != null;

    void showSelectChildDialog() {
      final l10n = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.activityCard_selectChild,
              style: AppTextStyles.heading(18)),
          content: Text(l10n.activityCard_selectChildMsg,
              style: AppTextStyles.body(14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.common_close,
                  style: AppTextStyles.body(14, color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.childSetting);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Palette.sky),
              child: Text(l10n.activityCard_goSelect,
                  style: AppTextStyles.body(14, color: Colors.white)),
            ),
          ],
        ),
      );
    }

    void navigate() {
      if (activity.isAiWordGame) {
        Navigator.pushNamed(context, AppRoutes.dynamicVocabularyGame, arguments: activity);
        return;
      }

      final userProvider = context.read<UserProvider>();
      if (userProvider.currentChildId == null) {
        showSelectChildDialog();
        return;
      }

      if (activity.id == 'space-adventure' ||
          activity.content == 'Space Adventure' ||
          activity.content == 'space_adventure' ||
          activity.content == 'space-adventure') {
        Navigator.pushNamed(context, AppRoutes.spaceAdventure, arguments: activity);
        return;
      }

      if (category == 'ด้านภาษา' || category == 'LANGUAGE') {
        Navigator.pushNamed(context, AppRoutes.languageDetail,
            arguments: activity);
      } else if (shouldGoToVideoDetail) {
        Navigator.pushNamed(context, AppRoutes.videoDetail,
            arguments: activity);
      } else if (category == 'ด้านคำนวณ') {
        Navigator.pushNamed(context, AppRoutes.calculateActivity,
            arguments: activity);
      } else {
        Navigator.pushNamed(context, AppRoutes.itemIntro, arguments: activity);
      }
    }

    return GestureDetector(
      onTap: navigate,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: _buildThumbnail(
                    hasTikTok: hasTikTok,
                    youtubeThumbnailUrl: youtubeThumbnailUrl),
              ),
            ),
            // Name + Score
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: AppTextStyles.heading(10, color: Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${AppLocalizations.of(context)!.common_score}: ${activity.maxScore}',
                    style: AppTextStyles.body(9, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(
      {required bool hasTikTok, String? youtubeThumbnailUrl}) {
    if (activity.id == 'space-adventure' ||
        activity.content == 'Space Adventure' ||
        activity.content == 'space_adventure' ||
        activity.content == 'space-adventure') {
      return const GameActivityCover(
        type: GameCoverType.spaceAdventure,
        compact: true,
      );
    }

    if (activity.isAiWordGame) {
      return const GameActivityCover(
        type: GameCoverType.voiceQuest,
        compact: true,
      );
    }

    if (activity.thumbnailUrl?.startsWith('asset:') ?? false) {
      return Image.asset(
        activity.thumbnailUrl!.replaceFirst('asset:', ''),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    final category = activity.category;

    if (hasTikTok && activity.thumbnailUrl != null) {
      return Image.network(activity.thumbnailUrl!,
          fit: BoxFit.cover, width: double.infinity, height: double.infinity,
          errorBuilder: (_, __, ___) => _placeholder(category));
    }

    if (youtubeThumbnailUrl != null) {
      return Transform.scale(
        scale: 1.32,
        child: Image.network(youtubeThumbnailUrl,
            fit: BoxFit.cover, width: double.infinity, height: double.infinity,
            errorBuilder: (_, __, ___) => _placeholder(category)),
      );
    }

    if (category == 'ด้านคำนวณ') return _buildCalculateCover(activity);

    return _placeholder(category);
  }

  Widget _buildCalculateCover(Activity activity) {
    return Image.asset(
      _calculateCoverAsset(activity.difficulty),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    );
  }

  String _calculateCoverAsset(String difficulty) {
    final normalized = difficulty.trim().toLowerCase();
    if (normalized == 'ยาก' || normalized == 'hard') {
      return 'assets/images/calculate_hard.png';
    }
    if (normalized == 'กลาง' ||
        normalized == 'ปานกลาง' ||
        normalized == 'medium') {
      return 'assets/images/calculate_medium.png';
    }
    return 'assets/images/calculate_easy.png';
  }

  Widget _placeholder(String category) {
    if (category == 'ด้านคำนวณ') {
      return Container(color: Palette.sky); // fallback ถ้าไม่มี activity object
    }
    if (category == 'ด้านภาษา' ||
        category.toUpperCase() == 'LANGUAGE') {
      return Container(
        color: Palette.languagePlaceholder,
        alignment: Alignment.center,
        child: Text('ABC',
            style: AppTextStyles.body(24,
                color: Colors.black87, weight: FontWeight.bold)),
      );
    }
    if (category == 'ด้านร่างกาย') {
      return Container(
        color: Palette.physicalPlaceholder,
        alignment: Alignment.center,
        child: const Icon(Icons.directions_run, color: Colors.white, size: 36),
      );
    }
    return Container(
      color: Palette.sky,
      alignment: Alignment.center,
      child: Text(
        category.isNotEmpty ? category.substring(0, 1) : '?',
        style: AppTextStyles.body(30, color: Colors.white, weight: FontWeight.bold),
      ),
    );
  }
}
