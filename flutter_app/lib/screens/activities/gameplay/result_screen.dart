// lib/screens/result_screen.dart

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../models/activity.dart';
import '../../../utils/activity_l10n.dart';
import '../../../widgets/share_result_helper.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // 🌀 Animation สำหรับขยายคะแนนตอนเปิดหน้า
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?) ??
            {};

    final String activityName = (args['activityName'] as String?) ??
        AppLocalizations.of(context)!.result_activityCompletedDefault;
    final int timeSpentSeconds = (args['timeSpend'] as int?) ?? 0;
    final Duration time = Duration(seconds: timeSpentSeconds);

    // 🆕 รับ Activity Object ที่ ItemIntroScreen ส่งมา
    final Activity? activityToReplay = args['activityObject'] as Activity?;

    // 🆕 รับคะแนนดิบจาก backend (scoreEarned)
    final int scoreEarned = (args['scoreEarned'] as int?) ?? 0;
    final int maxScore = activityToReplay?.maxScore ?? 100;

    // รับ evidence image path (จากกิจกรรมร่างกาย/คำนวณ)
    final String? evidenceImagePath = args['evidenceImagePath'] as String?;

    String two(int n) => n.toString().padLeft(2, '0');
    final mm = two(time.inMinutes % 60), ss = two(time.inSeconds % 60);

    final double pct = maxScore > 0
        ? (scoreEarned / maxScore).clamp(0.0, 1.0)
        : 0.0;
    final Color scoreColor = pct <= 0.5
        ? Color.lerp(const Color(0xFFE53935), const Color(0xFFFDD835), pct * 2)!
        : Color.lerp(const Color(0xFFFDD835), const Color(0xFF43A047), (pct - 0.5) * 2)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          ),
        ),
        elevation: 0,
        title: Text(
          activityToReplay != null
              ? ActivityL10n.localizedActivityType(
                  context, activityToReplay.category)
              : AppLocalizations.of(context)!.result_resultTitle,
          style: AppTextStyles.heading(18, color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Palette.sky),
            onPressed: () {
              showShareBottomSheet(
                context,
                ShareResultData(
                  activityName: activityName,
                  score: scoreEarned,
                  maxScore: maxScore,
                  timeSpentSeconds: timeSpentSeconds,
                  category: activityToReplay?.category,
                  evidenceImagePath: evidenceImagePath,
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. ชื่อกิจกรรม
            Text(
              activityName.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.heading(16, color: Palette.deepGrey),
            ),
            const SizedBox(height: 20),

            // 2. การ์ดคะแนน (มี animation)
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scoreColor, width: 3),
                ),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.result_totalScoreTitle,
                      style: AppTextStyles.heading(18, color: Palette.deepGrey),
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$scoreEarned / $maxScore',
                        style: AppTextStyles.heading(72, color: scoreColor),
                      ),
                    ),
                    Text(
                      scoreEarned >= (maxScore / 2)
                          ? AppLocalizations.of(context)!.result_greatJobTitle
                          : AppLocalizations.of(context)!
                              .result_keepTryingTitle,
                      style: AppTextStyles.heading(24, color: scoreColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. เวลา
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.result_timeSpentPrefix,
                  style: AppTextStyles.body(16, weight: FontWeight.w700),
                ),
                Text(
                  '$mm:$ss',
                  style: AppTextStyles.body(18, weight: FontWeight.w900),
                ),
              ],
            ),

            const Spacer(),

            // 4. ปุ่มต่าง ๆ
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ▶ ปุ่ม 1: เล่นกิจกรรมนี้อีกครั้ง (PLAY AGAIN)
                SizedBox(
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: activityToReplay != null
                        ? () {
                            final category =
                                activityToReplay.category.toUpperCase();
                            if (category == 'ด้านภาษา' ||
                                category == 'LANGUAGE') {
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.itemIntro,
                                arguments: activityToReplay,
                              );
                            } else if (category == 'ด้านร่างกาย' &&
                                activityToReplay.videoUrl != null) {
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.videoDetail,
                                arguments: activityToReplay,
                              );
                            } else if (category == 'ด้านคำนวณ') {
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.calculateActivity,
                                arguments: activityToReplay,
                              );
                            } else {
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.itemIntro,
                                arguments: activityToReplay,
                              );
                            }
                          }
                        : null,
                    icon: const Icon(Icons.replay, color: Colors.white, size: 22),
                    label: Text(
                      AppLocalizations.of(context)!.result_playAgainBtn,
                      style: AppTextStyles.heading(18, color: Palette.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.bluePill,
                      disabledBackgroundColor:
                          Palette.bluePill.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 🏠 ปุ่ม 2: กลับหน้าหลัก (outlined)
                SizedBox(
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (route) => false,
                    ),
                    icon: Icon(Icons.home_outlined, color: Palette.sky, size: 22),
                    label: Text(
                      AppLocalizations.of(context)!.result_backToActivitiesBtn,
                      style: AppTextStyles.heading(18, color: Palette.sky),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Palette.sky, width: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
