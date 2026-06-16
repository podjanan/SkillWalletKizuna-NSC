import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import 'playing_result_detail_screen.dart';
import '../../theme/palette.dart';
import '../../theme/app_text_styles.dart';

class DailyActivityScreen extends StatelessWidget {
  final String date;
  final List<Map<String, dynamic>> records;

  const DailyActivityScreen({
    super.key,
    required this.date,
    required this.records,
  });

  static Color _categoryAccent(String? category) {
    switch (category) {
      case 'ด้านภาษา':
        return const Color(0xFFFFB300);
      case 'ด้านร่างกาย':
        return Palette.pink;
      case 'ด้านคำนวณ':
        return Palette.sky;
      default:
        return Palette.teal;
    }
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null) return '--:--';
    final dateTime = DateTime.tryParse(createdAt);
    if (dateTime == null) return '--:--';
    return DateFormat('HH:mm').format(dateTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final sortedRecords = List<Map<String, dynamic>>.from(records)
      ..sort((a, b) {
        final aTime = a['created_at'] as String? ?? '';
        final bTime = b['created_at'] as String? ?? '';
        return aTime.compareTo(bTime);
      });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                      date,
                      style: AppTextStyles.body(24,
                          color: Palette.blueChip,
                          weight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            Text(
              AppLocalizations.of(context)!.dailyactivity_playingHistory,
              style: AppTextStyles.body(18, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: sortedRecords.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.dailyactivity_noData,
                        style: AppTextStyles.body(18, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: sortedRecords.length,
                      itemBuilder: (context, index) {
                        final record = sortedRecords[index];
                        final pointRaw = record['point'];
                        int score = 0;
                        if (pointRaw is int) {
                          score = pointRaw;
                        } else if (pointRaw is double) {
                          score = pointRaw.toInt();
                        } else if (pointRaw != null) {
                          score =
                              int.tryParse(pointRaw.toString()) ?? 0;
                        }
                        final createdAt =
                            record['created_at'] as String?;
                        final activityName =
                            record['activity']?['name_activity']
                                    as String? ??
                                AppLocalizations.of(context)!
                                    .dailyactivity_activity;

                        final category = record['activity']?['category']
                            as String?;
                        final accent = _categoryAccent(category);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PlayingResultDetailScreen(
                                  record: record,
                                  sessionNumber: index + 1,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: Palette.cardShadow,
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  // Left accent strip
                                  Container(width: 4, color: accent),

                                  // Session number circle
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: accent
                                            .withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${index + 1}',
                                        style: AppTextStyles.heading(18,
                                            color: accent),
                                      ),
                                    ),
                                  ),

                                  // Detail
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            activityName,
                                            style: AppTextStyles.label(15,
                                                color: Palette.text),
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time,
                                                  color: Palette.labelGrey,
                                                  size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatTime(createdAt),
                                                style: AppTextStyles.body(
                                                    13,
                                                    color:
                                                        Palette.labelGrey),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Score badge
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.star_rounded,
                                            color: accent, size: 18),
                                        Text(
                                          '$score',
                                          style: AppTextStyles.heading(16,
                                              color: accent),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
