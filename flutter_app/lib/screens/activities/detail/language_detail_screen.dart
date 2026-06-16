import 'package:flutter/material.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../models/activity.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/youtube_helper.dart';
import '../../../widgets/info_badges.dart';
import '../../../utils/activity_l10n.dart';
import '../../../widgets/sticky_bottom_button.dart';

const _kAmber = Color(0xFFFFB300);

class LanguageDetailScreen extends StatefulWidget {
  static const String routeName = '/language_detail';

  final Activity activity;

  const LanguageDetailScreen({
    super.key,
    required this.activity,
  });

  @override
  State<LanguageDetailScreen> createState() => _LanguageDetailScreenState();
}

class _LanguageDetailScreenState extends State<LanguageDetailScreen> {
  YoutubePlayerController? _ytController;
  String _videoId = '';
  bool _descExpanded = false;

  @override
  void initState() {
    super.initState();
    _videoId = YouTubeHelper.extractVideoId(widget.activity.videoUrl) ?? '';

    if (_videoId.isNotEmpty) {
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: _videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          origin: 'https://www.youtube-nocookie.com',
        ),
      );
    }
  }

  @override
  void dispose() {
    _ytController?.close();
    super.dispose();
  }

  Future<void> _openInYouTube() async {
    if (_videoId.isEmpty) return;
    final appUri = Uri.parse('youtube://watch?v=$_videoId');
    final webUri = Uri.parse('https://www.youtube.com/watch?v=$_videoId');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.activity.name;

    return _buildScaffold(
      context,
      name,
      videoWidget: _ytController != null
          ? YoutubePlayer(controller: _ytController!)
          : null,
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    String name, {
    required Widget? videoWidget,
  }) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
            ActivityL10n.localizedActivityType(
                context, widget.activity.category),
            style: AppTextStyles.heading(22, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InfoBadges(activity: widget.activity),

                  const SizedBox(height: 16),

                  // ── YouTube Player ──
                  if (videoWidget != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: videoWidget,
                      ),
                    )
                  else
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: _kAmber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: _kAmber.withValues(alpha: 0.3), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle_outline_rounded,
                              size: 48, color: _kAmber.withValues(alpha: 0.6)),
                          const SizedBox(height: 8),
                          Text('ABC',
                              style: AppTextStyles.heading(40,
                                  color: _kAmber.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),

                  // ── Open in YouTube (TV) banner ──
                  if (_videoId.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: GestureDetector(
                        onTap: _openInYouTube,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: Palette.cardShadow,
                            border: Border.all(
                                color: const Color(0xFFFF0000)
                                    .withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF0000),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.tv_rounded,
                                    color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!
                                          .languagedetail_openInYoutube,
                                      style: AppTextStyles.label(14,
                                          color:
                                              const Color(0xFFFF0000)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .calculate_tvModeBannerSub,
                                      style: AppTextStyles.body(12,
                                          color: Palette.labelGrey),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  color: Color(0xFFFF0000), size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ── Activity Title ──
                  Container(
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
                          Container(width: 4, color: Palette.sky),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.text_fields_rounded,
                                          color: Palette.sky, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppLocalizations.of(context)!
                                            .languagedetail_activityTitleLabel,
                                        style: AppTextStyles.label(13,
                                            color: Palette.sky),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    name,
                                    style: AppTextStyles.heading(18,
                                        color: Palette.text),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Description (collapsible) ──
                  if ((widget.activity.description ?? '').isNotEmpty)
                    StatefulBuilder(
                      builder: (_, setLocal) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                setLocal(() => _descExpanded = !_descExpanded),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: Palette.cardShadow,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded,
                                      color: Palette.sky, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .languagedetail_descriptionLabel,
                                      style: AppTextStyles.heading(16,
                                          color: Palette.sky),
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: _descExpanded ? 0.5 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Palette.sky,
                                        size: 22),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: Palette.cardShadow,
                                border: Border.all(
                                    color: Palette.sky.withValues(alpha: 0.25)),
                              ),
                              child: Text(
                                widget.activity.description!,
                                style: AppTextStyles.body(15),
                              ),
                            ),
                            crossFadeState: _descExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          StickyBottomButton(
            onPressed: () async {
              // Pause YouTube before leaving so audio doesn't bleed into gameplay
              await _ytController?.pauseVideo();
              if (!context.mounted) return;
              Navigator.pushNamed(
                context,
                AppRoutes.itemIntro,
                arguments: widget.activity,
              );
            },
            label: AppLocalizations.of(context)!.languagedetail_startBtn,
          ),
        ],
      ),
    );
  }

}
