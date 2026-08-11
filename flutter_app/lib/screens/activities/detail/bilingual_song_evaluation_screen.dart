// lib/screens/activities/detail/bilingual_song_evaluation_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/bilingual_song_model.dart';
import '../../../providers/user_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/activity_service.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/palette.dart';
import '../../../widgets/child_avatar.dart';
import '../../../widgets/sticky_bottom_button.dart';

class BilingualSongEvaluationScreen extends StatefulWidget {
  final BilingualSongModel song;
  final List<String> extraChildIds;
  final int timeSpentSeconds;

  const BilingualSongEvaluationScreen({
    super.key,
    required this.song,
    this.extraChildIds = const [],
    required this.timeSpentSeconds,
  });

  @override
  State<BilingualSongEvaluationScreen> createState() =>
      _BilingualSongEvaluationScreenState();
}

class _BilingualSongEvaluationScreenState
    extends State<BilingualSongEvaluationScreen> {
  final ActivityService _activityService = ActivityService();
  final Map<String, int> _childScores = {};
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final childId = context.read<UserProvider>().currentChildId;
      if (childId != null) _childScores[childId] = 100;
      for (final id in widget.extraChildIds) {
        _childScores.putIfAbsent(id, () => 100);
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _getChildName(List<Map<String, dynamic>> children, String childId) {
    try {
      final item = children.firstWhere(
        (c) => (c['child'] as Map<String, dynamic>?)?['child_id'] == childId,
      );
      return (item['child'] as Map<String, dynamic>?)?['name_surname'] ??
          'น้อง';
    } catch (_) {
      return 'น้อง';
    }
  }

  String? _getChildPhoto(List<Map<String, dynamic>> children, String childId) {
    try {
      final item = children.firstWhere(
        (c) => (c['child'] as Map<String, dynamic>?)?['child_id'] == childId,
      );
      return (item['child'] as Map<String, dynamic>?)?['photo_url'];
    } catch (_) {
      return null;
    }
  }

  Color _scoreColor(double pct) {
    final t = pct.clamp(0.0, 1.0);
    if (t <= 0.5) {
      return Color.lerp(
          const Color(0xFFE53935), const Color(0xFFFDD835), t * 2)!;
    } else {
      return Color.lerp(
          const Color(0xFFFDD835), const Color(0xFF43A047), (t - 0.5) * 2)!;
    }
  }

  Future<void> _handleSubmit() async {
    final String? childId = context.read<UserProvider>().currentChildId;
    if (childId == null || _isSubmitting) return;

    final allChildIds = <String>{childId, ...widget.extraChildIds}.toList();
    setState(() => _isSubmitting = true);

    final String notes = _notesController.text.trim();
    final evidencePayload = {
      'status': 'Completed',
      'description': notes.isNotEmpty ? notes : 'Sing Together Completed',
      'songTitle': widget.song.titleEn,
    };

    try {
      final results = await Future.wait(
        allChildIds.map((cid) => _activityService.finalizeQuest(
              childId: cid,
              activityId: 'bilingual-songs',
              segmentResults: [],
              activityMaxScore: 100,
              evidence: evidencePayload,
              parentScore: _childScores[cid] ?? 100,
              timeSpent: widget.timeSpentSeconds,
            )),
        eagerError: false,
      );

      debugPrint('✅ Sing Together score saved for ${results.length} children');

      if (mounted) {
        final currentScore = _childScores[childId] ?? 100;
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.result,
          arguments: {
            'activityName': 'Sing Together - ${widget.song.titleEn}',
            'totalScore': currentScore,
            'scoreEarned': currentScore,
            'timeSpend': widget.timeSpentSeconds,
          },
        );
      }
    } catch (e) {
      debugPrint('❌ Submit score failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกคะแนน: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showChildScoreDialog(String childId, String childName) {
    final tempController = TextEditingController(
      text: (_childScores[childId] ?? 100).toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ให้คะแนน $childName', style: AppTextStyles.heading(18)),
        content: TextField(
          controller: tempController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'คะแนน (0 - 100)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ยกเลิก', style: AppTextStyles.body(14)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(tempController.text);
              if (val != null && val >= 0 && val <= 100) {
                setState(() => _childScores[childId] = val);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Palette.sky),
            child: const Text('ตกลง', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildChildScoreRow(String childId, String childName) {
    final score = _childScores[childId] ?? 100;
    final pct = score / 100.0;
    final barColor = _scoreColor(pct);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            Container(width: 5, color: Palette.sky),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    ChildAvatar(
                      photoUrl: _getChildPhoto(
                          context.read<UserProvider>().children, childId),
                      name: childName,
                      radius: 18,
                      fontSize: 14,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(childName,
                              style: AppTextStyles.label(15, color: Palette.text)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct.toDouble(),
                              backgroundColor: Colors.grey.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(barColor),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Minus button
                    GestureDetector(
                      onTap: () => setState(() {
                        _childScores[childId] = (score > 0) ? score - 5 : 0;
                      }),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Palette.sky.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Palette.sky.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.remove,
                            color: Palette.sky, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Score text
                    GestureDetector(
                      onTap: () => _showChildScoreDialog(childId, childName),
                      child: SizedBox(
                        width: 48,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$score',
                            style: AppTextStyles.heading(20, color: barColor),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Plus button
                    GestureDetector(
                      onTap: () => setState(() {
                        _childScores[childId] =
                            (score < 100) ? score + 5 : 100;
                      }),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Palette.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Palette.success.withValues(alpha: 0.4)),
                        ),
                        child: Icon(Icons.add,
                            color: Palette.success, size: 18),
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

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final currentChildId = userProvider.currentChildId ?? '';
    final allIds = <String>{currentChildId, ...widget.extraChildIds}
        .where((id) => id.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCEB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ให้คะแนนร้องเพลง Sing Together',
          style: AppTextStyles.heading(18, color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Info Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: Palette.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Palette.sky.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.music_note_rounded,
                                size: 32, color: Palette.sky),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.song.titleEn,
                                  style: AppTextStyles.heading(18,
                                      color: Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'เวลาที่ใช้ร้อง: ${widget.timeSpentSeconds ~/ 60} นาที ${widget.timeSpentSeconds % 60} วินาที',
                                  style: AppTextStyles.body(13,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section Title
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded,
                            size: 22, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          'ประเมินคะแนนเด็ก (${allIds.length} คน)',
                          style: AppTextStyles.heading(16, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Children Score Rows
                    ...allIds.map((cid) {
                      final name = _getChildName(userProvider.children, cid);
                      return _buildChildScoreRow(cid, name);
                    }),

                    const SizedBox(height: 20),

                    // Note / Feedback
                    Text(
                      'บันทึกข้อคิดเห็นเพิ่มเติม',
                      style: AppTextStyles.label(14, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'เช่น ร้องเสียงดังฟังชัด, ออกเสียงคำศัพท์ได้ถูกต้อง...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Submit Button
            StickyBottomButton(
              label: _isSubmitting ? 'กำลังบันทึกคะแนน...' : 'บันทึกคะแนนการร้องเพลง',
              onPressed: _isSubmitting ? null : _handleSubmit,
              isLoading: _isSubmitting,
              color: Palette.success,
            ),
          ],
        ),
      ),
    );
  }
}
