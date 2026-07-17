import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import '../../widgets/share_result_helper.dart';
import '../../theme/palette.dart';
import '../../theme/app_text_styles.dart';

class PlayingResultDetailScreen extends StatelessWidget {
  final Map<String, dynamic> record;
  final int sessionNumber;

  const PlayingResultDetailScreen({
    super.key,
    required this.record,
    required this.sessionNumber,
  });

  String _formatDate(String? createdAt) {
    if (createdAt == null) return '--';
    final date = DateTime.tryParse(createdAt);
    if (date == null) return '--';
    return DateFormat('dd MMM yyyy').format(date.toLocal()).toUpperCase();
  }

  String _formatTime(int? seconds) {
    if (seconds == null || seconds == 0) return '--:--:--';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ดึง segment_results จาก record
  List<Map<String, dynamic>> _getSegmentResults() {
    final segmentResults = record['segment_results'];
    if (segmentResults == null) return [];
    if (segmentResults is List) {
      return segmentResults.cast<Map<String, dynamic>>();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    // ดึงข้อมูลจาก record (handle Decimal from Supabase)
    final pointRaw = record['point'];
    int score = 0;
    if (pointRaw is int) {
      score = pointRaw;
    } else if (pointRaw is double) {
      score = pointRaw.toInt();
    } else if (pointRaw != null) {
      score = int.tryParse(pointRaw.toString()) ?? 0;
    }

    final timeRaw = record['time_spent'];
    int timespent = 0;
    if (timeRaw is int) {
      timespent = timeRaw;
    } else if (timeRaw is double) {
      timespent = timeRaw.toInt();
    } else if (timeRaw != null) {
      timespent = int.tryParse(timeRaw.toString()) ?? 0;
    }

    final loc = AppLocalizations.of(context)!;
    final createdAt = record['created_at'] as String?;
    final activityName =
        record['activity']?['name_activity'] as String? ?? loc.playingresult_activity;
    final category = record['activity']?['category'] as String? ?? '';
    final maxScore = record['activity']?['maxscore'];
    int maxScoreInt = 0;
    if (maxScore is int) {
      maxScoreInt = maxScore;
    } else if (maxScore is double) {
      maxScoreInt = maxScore.toInt();
    } else if (maxScore != null) {
      maxScoreInt = int.tryParse(maxScore.toString()) ?? 0;
    }

    // ดึง evidence (อาจเป็น Map หรือ JSON string)
    Map<String, dynamic>? evidence;
    if (record['evidence'] is Map) {
      evidence = record['evidence'] as Map<String, dynamic>;
    }

    final diary = evidence?['description'] as String? ?? '';
    final imagePath = evidence?['imagePathLocal'] as String?;
    final videoPath = evidence?['videoPathLocal'] as String?;

    // ตรวจสอบ category
    final isLanguageCategory = category == 'ด้านภาษา';
    final isAnalysisCategory = category == 'ด้านคำนวณ';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back,
                            size: 35, color: Colors.black87),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.playingresult_title,
                              style: AppTextStyles.body(24,
                                  color: Palette.blueChip,
                                  weight: FontWeight.bold),
                            ),
                            Text(
                              '${_formatDate(createdAt)} | ${loc.playingresult_session(sessionNumber)}',
                              style: AppTextStyles.body(14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ชื่อกิจกรรม
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Palette.blueChip.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Palette.blueChip, width: 2),
                    ),
                    child: Text(
                      activityName,
                      style: AppTextStyles.body(18,
                          color: Palette.blueChip, weight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 1. Medals Section
                  Row(
                    children: [
                      const Icon(Icons.emoji_events,
                          color: Palette.warning, size: 35),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          loc.playingresult_scoreObtained,
                          style: AppTextStyles.body(20,
                              color: Palette.warning, weight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Palette.warning, width: 2),
                        ),
                        child: Text(
                          maxScoreInt > 0 ? '$score/$maxScoreInt' : '$score',
                          style: AppTextStyles.heading(24, color: Colors.black87),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 25),

                  // ==================== Content by Category ====================

                  // สำหรับ Language: แสดง segments แทน diary/evidence
                  if (isLanguageCategory) ...[
                    _buildLanguageSegmentsSection(loc),
                    const SizedBox(height: 25),
                  ]
                  // สำหรับ Physical และอื่นๆ: แสดง diary, image, video ตามปกติ
                  else ...[
                    // 2. Diary Section
                    Text(
                      loc.playingresult_diary,
                      style: AppTextStyles.body(20,
                          color: Palette.error, weight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        diary.isNotEmpty ? diary : loc.playingresult_noNotes,
                        style: AppTextStyles.body(16,
                            color: diary.isNotEmpty
                                ? Colors.black87
                                : Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // 3. Image Section
                    Text(
                      loc.playingresult_image,
                      style: AppTextStyles.body(20,
                          color: Palette.error, weight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _buildImageWidget(imagePath, loc),
                    ),
                    const SizedBox(height: 25),

                    // 4. Video Section (if exists)
                    if (videoPath != null && videoPath.isNotEmpty) ...[
                      Text(
                        loc.playingresult_video,
                        style: AppTextStyles.body(20,
                            color: Palette.error, weight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.videocam,
                                  size: 40, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(
                                loc.playingresult_videoAttached,
                                style: AppTextStyles.body(14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                    ],
                  ],

                  // สำหรับ Analysis: เพิ่มส่วนผลการตอบคำถามท้ายสุด
                  if (isAnalysisCategory) ...[
                    _buildAnalysisQuestionsSection(loc),
                    const SizedBox(height: 25),
                  ],

                  // 5. Time Section
                  Center(
                    child: Column(
                      children: [
                        Text(
                          loc.playingresult_timeSpent,
                          style: AppTextStyles.body(20,
                              color: Palette.error, weight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            _formatTime(timespent),
                            style: AppTextStyles.heading(24,
                                color: Palette.blueChip),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            // Floating share button (top-right, always visible)
            Positioned(
              right: 16,
              top: 12,
              child: GestureDetector(
                onTap: () {
                  showShareBottomSheet(
                    context,
                    ShareResultData(
                      activityName: activityName,
                      score: score,
                      maxScore: maxScoreInt,
                      timeSpentSeconds: timespent,
                      category: category,
                      evidenceImagePath: imagePath,
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: Palette.softShadow,
                  ),
                  child: const Icon(Icons.share, size: 20, color: Palette.sky),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String? imagePath, AppLocalizations loc) {
    // ถ้ามี local path และไฟล์ยังอยู่
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
          ),
        );
      }
    }

    // ถ้าไม่มีรูป
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported,
              size: 50, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            loc.playingresult_noImage,
            style: AppTextStyles.body(14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ==================== Language Category: Segments Display ====================
  Widget _buildLanguageSegmentsSection(AppLocalizations loc) {
    final segments = _getSegmentResults();
    if (segments.isEmpty) {
      return _buildEmptySegmentsState(loc);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.mic, color: Palette.blueChip, size: 28),
            const SizedBox(width: 10),
            Text(
              loc.playingresult_sentencesSpoken,
              style: AppTextStyles.body(20,
                  color: Palette.blueChip, weight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...segments.asMap().entries.map((entry) {
          final index = entry.key;
          final segment = entry.value;
          return _buildLanguageSegmentItem(index + 1, segment, loc);
        }),
      ],
    );
  }

  Widget _buildLanguageSegmentItem(int number, Map<String, dynamic> segment, AppLocalizations loc) {
    final text = segment['text'] as String? ?? '';
    final recognizedText = segment['recognizedText'] as String? ?? '';
    final maxScoreRaw = segment['maxScore'];
    int accuracy = 0;
    if (maxScoreRaw is int) {
      accuracy = maxScoreRaw;
    } else if (maxScoreRaw is double) {
      accuracy = maxScoreRaw.toInt();
    } else if (maxScoreRaw != null) {
      accuracy = int.tryParse(maxScoreRaw.toString()) ?? 0;
    }

    // กำหนดสีตามความแม่นยำ
    Color accuracyColor;
    if (accuracy >= 80) {
      accuracyColor = Palette.success;
    } else if (accuracy >= 50) {
      accuracyColor = Palette.warning;
    } else {
      accuracyColor = Palette.error;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Palette.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ลำดับและคะแนน
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Palette.blueChip,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  loc.playingresult_sentence(number),
                  style: AppTextStyles.body(14,
                      color: Colors.white, weight: FontWeight.bold),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: accuracyColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accuracyColor, width: 1.5),
                ),
                child: Text(
                  '$accuracy%',
                  style: AppTextStyles.heading(16, color: accuracyColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ประโยคที่ต้องพูด
          Text(
            loc.playingresult_sentenceToSpeak,
            style: AppTextStyles.body(13, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            text.isNotEmpty ? text : '-',
            style: AppTextStyles.body(16,
                color: Colors.black87, weight: FontWeight.w500),
          ),
          const SizedBox(height: 10),

          // ประโยคที่พูดได้
          Text(
            loc.playingresult_whatWasSpoken,
            style: AppTextStyles.body(13, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            recognizedText.isNotEmpty ? recognizedText : loc.playingresult_noData,
            style: AppTextStyles.body(16,
                color: recognizedText.isNotEmpty ? Colors.black87 : Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySegmentsState(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.mic_off, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              loc.playingresult_noSpeechData,
              style: AppTextStyles.body(16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Analysis Category: Question Results ====================
  Widget _buildAnalysisQuestionsSection(AppLocalizations loc) {
    final segments = _getSegmentResults();
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.quiz, color: Palette.purple, size: 28),
            const SizedBox(width: 10),
            Text(
              loc.playingresult_answerResults,
              style: AppTextStyles.body(20,
                  color: Palette.purple, weight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...segments.asMap().entries.map((entry) {
          final index = entry.key;
          final segment = entry.value;
          return _buildAnalysisQuestionItem(index + 1, segment, loc);
        }),
      ],
    );
  }

  Widget _buildAnalysisQuestionItem(int number, Map<String, dynamic> segment, AppLocalizations loc) {
    final text = segment['text'] as String? ?? loc.playingresult_questionFallback(number);
    final maxScoreRaw = segment['maxScore'];
    int itemScore = 0;
    if (maxScoreRaw is int) {
      itemScore = maxScoreRaw;
    } else if (maxScoreRaw is double) {
      itemScore = maxScoreRaw.toInt();
    } else if (maxScoreRaw != null) {
      itemScore = int.tryParse(maxScoreRaw.toString()) ?? 0;
    }

    final isCorrect = itemScore > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCorrect
            ? Palette.success.withValues(alpha: 0.1)
            : Palette.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCorrect ? Palette.success : Palette.error,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // ไอคอนถูก/ผิด
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCorrect ? Palette.success : Palette.error,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCorrect ? Icons.check : Icons.close,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // ข้อความคำถาม
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.playingresult_questionLabel(number),
                  style: AppTextStyles.body(13, color: Colors.grey),
                ),
                Text(
                  text,
                  style: AppTextStyles.body(15,
                      color: Colors.black87, weight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // คะแนน
          Text(
            isCorrect ? '+$itemScore' : '0',
            style: AppTextStyles.heading(18,
                color: isCorrect ? Palette.success : Palette.error),
          ),
        ],
      ),
    );
  }
}
