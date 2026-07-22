// lib/screens/activities/detail/calculate_activity_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../models/activity.dart';
import '../../../providers/user_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/activity_service.dart';
import '../../../services/draft_service.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/palette.dart';
import '../../../widgets/info_badges.dart';
import '../../../widgets/sticky_bottom_button.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import '../../../utils/activity_l10n.dart';
import '../../../utils/math_op_detector.dart';

/// Activity phases
enum _Phase { ready, running, answering }

class CalculateActivityScreen extends StatefulWidget {
  static const String routeName = '/calculate_activity';

  final Activity activity;

  const CalculateActivityScreen({
    super.key,
    required this.activity,
  });

  @override
  State<CalculateActivityScreen> createState() =>
      _CalculateActivityScreenState();
}

class _CalculateActivityScreenState extends State<CalculateActivityScreen> {
  final ActivityService _activityService = ActivityService();

  // Phase
  _Phase _phase = _Phase.ready;

  // Timer
  Timer? _uiUpdateTimer;

  // Evidence
  String? _videoPath;
  String? _imagePath;
  Uint8List? _videoThumbnail;
  final TextEditingController _descriptionController = TextEditingController();

  // Segment Results
  final List<SegmentResult> _segmentResults = [];
  List<dynamic> _segments = [];
  final Map<int, int> _originalScores = {};
  final Map<int, bool?> _answerStatus = {};

  bool _isSubmitting = false;
  DateTime? _startTime;
  int _baseElapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadSegments();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadSegments() {
    if (widget.activity.segments != null) {
      if (widget.activity.segments is List) {
        _segments = widget.activity.segments as List;
      } else {
        _segments = [];
      }
    }

    for (int i = 0; i < _segments.length; i++) {
      final segment = _segments[i];
      final int scoreFromSegment = segment['score'] as int? ??
          segment['maxScore'] as int? ??
          segment['point'] as int? ??
          100;

      _originalScores[i] = scoreFromSegment;

      _segmentResults.add(SegmentResult(
        id: segment['id']?.toString() ?? '',
        text: segment['question']?.toString() ??
            segment['text']?.toString() ??
            '',
        maxScore: 0,
      ));
    }
  }

  // ── Timer ──────────────────────────────────────────────

  int get _elapsedSeconds {
    final running = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;
    return _baseElapsedSeconds + running;
  }

  void _startTimer() {
    _startTime = DateTime.now();
    setState(() => _phase = _Phase.running);
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _finishTimer() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.calculate_confirmFinishTitle,
            style: AppTextStyles.heading(18)),
        content: Text(AppLocalizations.of(context)!.calculate_confirmFinishMsg,
            style: AppTextStyles.body(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.common_cancel,
                style: AppTextStyles.body(14)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _uiUpdateTimer?.cancel();
              _baseElapsedSeconds = _elapsedSeconds;
              _startTime = null;
              setState(() => _phase = _Phase.answering);
            },
            child: Text(AppLocalizations.of(context)!.common_finish,
                style: AppTextStyles.body(14, color: Palette.pink)),
          ),
        ],
      ),
    );
  }

  void _resetTimer() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.calculate_restartTitle,
            style: AppTextStyles.heading(18)),
        content: Text(AppLocalizations.of(context)!.calculate_restartMsg,
            style: AppTextStyles.body(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.common_cancel,
                style: AppTextStyles.body(14)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _uiUpdateTimer?.cancel();
              _startTime = null;
              _baseElapsedSeconds = 0;
              setState(() {
                _phase = _Phase.ready;
                _answerStatus.clear();
                for (int i = 0; i < _segmentResults.length; i++) {
                  _segmentResults[i] = _segmentResults[i].copyWith(maxScore: 0);
                }
              });
            },
            child: Text(AppLocalizations.of(context)!.calculate_restartBtn,
                style: AppTextStyles.body(14, color: Palette.pink)),
          ),
        ],
      ),
    );
  }

  // ── Draft ──────────────────────────────────────────────

  Future<void> _restoreDraft() async {
    final childId = context.read<UserProvider>().currentChildId;
    if (childId == null) return;
    final draft = await DraftService.loadDraft(childId);
    if (draft == null ||
        draft['type'] != DraftService.typeCalculate ||
        draft['activityId'] != widget.activity.id) {
      return;
    }
    final data = draft['data'] as Map<String, dynamic>? ?? {};
    if (!mounted) return;
    final savedStart = data['startTime'] as String?;
    final phaseStr = data['phase'] as String? ?? 'ready';
    final restoredPhase = _Phase.values
        .firstWhere((p) => p.name == phaseStr, orElse: () => _Phase.ready);
    // Restore accumulated seconds
    _baseElapsedSeconds = data['elapsedSeconds'] as int? ?? 0;
    if (savedStart != null && restoredPhase == _Phase.running) {
      // Add time elapsed while app was closed
      final closedAt = DateTime.parse(savedStart);
      _baseElapsedSeconds += DateTime.now().difference(closedAt).inSeconds;
    }
    // Always restore as paused — user presses start to continue
    if (restoredPhase == _Phase.running) {
      _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
    setState(() {
      _phase = restoredPhase;
      _descriptionController.text = data['description'] as String? ?? '';
      final scores = data['scores'] as Map<String, dynamic>? ?? {};
      scores.forEach((k, v) {
        final idx = int.tryParse(k);
        if (idx != null) {
          _segmentResults[idx] =
              _segmentResults[idx].copyWith(maxScore: (v as num).toInt());
        }
      });
      final answers = data['answerStatus'] as Map<String, dynamic>? ?? {};
      answers.forEach((k, v) {
        final idx = int.tryParse(k);
        if (idx != null) _answerStatus[idx] = v as bool?;
      });
    });
  }

  Future<void> _saveDraft() async {
    final childId = context.read<UserProvider>().currentChildId;
    if (childId == null) return;
    final scores = <String, int>{};
    for (int i = 0; i < _segmentResults.length; i++) {
      scores['$i'] = _segmentResults[i].maxScore;
    }
    final answers = <String, bool?>{};
    _answerStatus.forEach((k, v) => answers['$k'] = v);
    await DraftService.saveDraft(
      childId: childId,
      type: DraftService.typeCalculate,
      activityId: widget.activity.id,
      activityJson: widget.activity.toJson(),
      data: {
        'phase': _phase.name,
        'elapsedSeconds': _elapsedSeconds,
        'startTime':
            _phase == _Phase.running ? DateTime.now().toIso8601String() : null,
        'description': _descriptionController.text,
        'scores': scores,
        'answerStatus': answers,
      },
    );
  }

  Future<bool> _onWillPop() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.draft_leaveTitle, style: AppTextStyles.heading(18)),
        content: Text(l.draft_leaveMsg, style: AppTextStyles.body(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.common_cancel, style: AppTextStyles.body(14)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.draft_leaveBtn,
                style: AppTextStyles.body(14, color: Palette.sky)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _saveDraft();
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    }
    return false;
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  // ── Media ──────────────────────────────────────────────

  Future<void> _handleMediaSelection({required bool isVideo}) async {
    try {
      final ImageSource source = await _showSourceDialog();
      final ImagePicker picker = ImagePicker();
      XFile? pickedFile;

      if (isVideo) {
        pickedFile = await picker.pickVideo(source: source);
      } else {
        pickedFile = await picker.pickImage(source: source);
      }

      if (pickedFile != null) {
        if (isVideo && !kIsWeb) {
          final videoPath = pickedFile.path;
          if (mounted) setState(() => _videoPath = videoPath);
          try {
            final thumb = await VideoThumbnail.thumbnailData(
              video: videoPath,
              imageFormat: ImageFormat.JPEG,
              maxWidth: 400,
              quality: 70,
            );
            if (mounted) setState(() => _videoThumbnail = thumb);
          } catch (e) {
            debugPrint('Video thumbnail generation failed: $e');
          }
        } else {
          setState(() {
            if (isVideo) {
              _videoPath = pickedFile!.path;
            } else {
              _imagePath = pickedFile!.path;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .calculate_failedPickFile(e.toString()))),
        );
      }
    }
  }

  Future<ImageSource> _showSourceDialog() async {
    return await showDialog<ImageSource>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.common_selectSource,
                style: AppTextStyles.heading(18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt, color: Palette.success),
                  title: Text(AppLocalizations.of(context)!.common_camera,
                      style: AppTextStyles.body(14)),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: Palette.lightBlue),
                  title: Text(AppLocalizations.of(context)!.common_gallery,
                      style: AppTextStyles.body(14)),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ) ??
        ImageSource.gallery;
  }

  // ── Submit ─────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    final String? childId = context.read<UserProvider>().currentChildId;

    if (childId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.calculate_childIdNotFound)),
        );
      }
      return;
    }

    if (_isSubmitting) return;

    final timeSpentSeconds = _elapsedSeconds;
    setState(() => _isSubmitting = true);

    final evidencePayload = {
      'videoPathLocal': _videoPath,
      'imagePathLocal': _imagePath,
      'status': 'Pending Approval',
      'description': _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
    };

    try {
      final response = await _activityService.finalizeQuest(
        childId: childId,
        activityId: widget.activity.id,
        segmentResults: _segmentResults,
        activityMaxScore: widget.activity.maxScore,
        evidence: evidencePayload,
        timeSpent: timeSpentSeconds,
        useDirectScore: true,
      );

      await DraftService.clearDraft(childId);

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.result,
          arguments: {
            'activityName': widget.activity.name,
            'totalScore': response['calculatedScore'] as int? ?? 0,
            'scoreEarned': response['scoreEarned'] as int? ?? 0,
            'timeSpend': timeSpentSeconds,
            'activityObject': widget.activity,
            'evidenceImagePath': _imagePath,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .calculate_errorCompleting(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final elapsedSeconds = _elapsedSeconds;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) Navigator.pop(context);
            },
          ),
          centerTitle: true,
          title: Text(
            ActivityL10n.localizedActivityType(
                context, widget.activity.category),
            style: AppTextStyles.heading(24, color: Colors.black),
          ),
          actions: const [],
        ),
        body: _segments.isEmpty
            ? Center(
                child: Text(AppLocalizations.of(context)!.calculate_noQuestions,
                    style: AppTextStyles.heading(20, color: Colors.grey)),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InfoBadges(activity: widget.activity),
                          const SizedBox(height: 16),

                          // ── Content / Instructions ──
                          if (widget.activity.content.isNotEmpty) ...[
                            Text(
                                AppLocalizations.of(context)!
                                    .calculate_descriptionLabel,
                                style: AppTextStyles.heading(18,
                                    color: Palette.sky)),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: Palette.cardShadow,
                              ),
                              child: Text(widget.activity.content,
                                  style: AppTextStyles.body(14)),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── Timer card ──
                          _buildTimerCard(elapsedSeconds),
                          const SizedBox(height: 14),

                          // ── Timer controls ──
                          _buildTimerControls(),
                          const SizedBox(height: 20),

                          // ── Questions (visible during running & answering) ──
                          if (_phase == _Phase.running ||
                              _phase == _Phase.answering) ...[
                            // TV Mode banner
                            _buildTvModeBanner(),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                const Icon(Icons.quiz_rounded,
                                    color: Palette.sky, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                    AppLocalizations.of(context)!
                                        .common_questions,
                                    style: AppTextStyles.heading(22,
                                        color: Palette.sky)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Palette.sky.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_segments.length} ${AppLocalizations.of(context)!.calculate_questionsCount}',
                                    style: AppTextStyles.label(13,
                                        color: Palette.sky),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._buildQuestionCards(),
                            const SizedBox(height: 30),
                          ],

                          // ── Evidence (only in answering phase) ──
                          if (_phase == _Phase.answering) ...[
                            Text(AppLocalizations.of(context)!.common_evidence,
                                style: AppTextStyles.heading(20,
                                    color: Palette.error)),
                            const SizedBox(height: 15),
                            _buildEvidenceSection(),
                            const SizedBox(height: 20),
                          ],

                          // ── Ready phase message ──
                          if (_phase == _Phase.ready) _buildReadyMessage(),
                        ],
                      ),
                    ),
                  ),
                  // FINISH button (only in answering phase)
                  if (_phase == _Phase.answering)
                    StickyBottomButton(
                      onPressed: _handleSubmit,
                      label: AppLocalizations.of(context)!.common_finish,
                      color: Palette.success,
                      isLoading: _isSubmitting,
                    ),
                ],
              ),
      ), // Scaffold
    ); // PopScope
  }

  // ── Timer controls by phase ───────────────────────────

  Widget _buildTimerControls() {
    switch (_phase) {
      case _Phase.ready:
        return Center(
          child: ElevatedButton.icon(
            onPressed: _startTimer,
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: Text(AppLocalizations.of(context)!.common_start,
                style: AppTextStyles.heading(20, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.success,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
        );

      case _Phase.running:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _resetTimer,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(AppLocalizations.of(context)!.common_restart,
                  style: AppTextStyles.heading(16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.warning,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _finishTimer,
              icon: const Icon(Icons.stop, color: Colors.white),
              label: Text(AppLocalizations.of(context)!.common_finish,
                  style: AppTextStyles.heading(16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.pink,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        );

      case _Phase.answering:
        return const SizedBox.shrink();
    }
  }

  // ── Timer card ───────────────────────────────────────

  Widget _buildTimerCard(int elapsedSeconds) {
    final isRunning = _phase == _Phase.running;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
        decoration: BoxDecoration(
          gradient: isRunning ? Palette.skyGradient : null,
          color: isRunning ? null : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: isRunning ? Palette.buttonShadow : Palette.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRunning ? Icons.timer : Icons.timer_outlined,
              color: isRunning ? Colors.white : Palette.sky,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              _formatTime(elapsedSeconds),
              style: AppTextStyles.heading(30,
                  color: isRunning ? Colors.white : Palette.sky),
            ),
          ],
        ),
      ),
    );
  }

  // ── TV Mode banner ────────────────────────────────────

  Widget _buildTvModeBanner() {
    final l = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _TvModeScreen(segments: _segments),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: Palette.cardShadow,
          border:
              Border.all(color: Palette.sky.withValues(alpha: 0.25), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: Palette.skyGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: Palette.buttonShadow,
              ),
              alignment: Alignment.center,
              child:
                  const Icon(Icons.tv_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.calculate_tvModeBannerTitle,
                      style: AppTextStyles.label(15, color: Palette.sky)),
                  const SizedBox(height: 2),
                  Text(l.calculate_tvModeBannerSub,
                      style: AppTextStyles.body(12, color: Palette.labelGrey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Palette.sky, size: 16),
          ],
        ),
      ),
    );
  }

  // ── Phase messages ────────────────────────────────────

  Widget _buildReadyMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Palette.sky.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.sky.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.play_circle_outline, size: 48, color: Palette.sky),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.calculate_pressStart,
              style: AppTextStyles.body(16, color: Palette.sky),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(AppLocalizations.of(context)!.calculate_questionsAfterTimer,
              style: AppTextStyles.body(13, color: Palette.deepGrey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Question cards ────────────────────────────────────

  List<Widget> _buildQuestionCards() {
    return List.generate(_segments.length, (index) {
      final segment = _segments[index];
      final question = MathOpDetector.normalizeQuestion(
        segment['question']?.toString() ??
            segment['text']?.toString() ??
            AppLocalizations.of(context)!.calculate_solutionTitle(index + 1),
      );
      final answer = segment['answer']?.toString() ?? '';
      final solution = segment['solution']?.toString() ?? '';
      final status = _answerStatus[index];

      final Color accentColor = status == true
          ? Palette.success
          : status == false
              ? Palette.pink
              : Palette.sky;

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: status != null ? Palette.buttonShadow : Palette.cardShadow,
        ),
        clipBehavior: Clip.hardEdge,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent strip
              Container(width: 4, color: accentColor),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header row ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style:
                                  AppTextStyles.heading(15, color: accentColor),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!
                                  .calculate_solutionTitle(index + 1),
                              style:
                                  AppTextStyles.label(14, color: accentColor),
                            ),
                          ),
                          if (status != null)
                            Icon(
                              status == true
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: accentColor,
                              size: 20,
                            ),
                        ],
                      ),
                    ),

                    // ── Question text ──
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: accentColor.withValues(alpha: 0.18)),
                      ),
                      child: Text(question,
                          style: AppTextStyles.body(17,
                              color: Colors.black87, weight: FontWeight.w600)),
                    ),

                    // ── Answering phase content ──
                    if (_phase == _Phase.answering) ...[
                      if (answer.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Palette.success.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      Palette.success.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check_circle,
                                    color: Palette.success, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          AppLocalizations.of(context)!
                                              .calculate_answerLabel,
                                          style: AppTextStyles.label(11,
                                              color: Palette.success)),
                                      const SizedBox(height: 2),
                                      Text(answer,
                                          style: AppTextStyles.body(15,
                                              weight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (solution.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.lightbulb_rounded,
                                    color: Colors.amber, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          AppLocalizations.of(context)!
                                              .calculate_solutionLabel,
                                          style: AppTextStyles.label(11,
                                              color: Colors.amber.shade700)),
                                      const SizedBox(height: 2),
                                      Text(solution,
                                          style: AppTextStyles.body(14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Correct / Incorrect buttons
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _answerStatus[index] = true;
                                  _segmentResults[index] =
                                      _segmentResults[index].copyWith(
                                          maxScore:
                                              _originalScores[index] ?? 100);
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: status == true
                                        ? Palette.success
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: Palette.success,
                                        width: status == true ? 0 : 1.5),
                                    boxShadow: status == true
                                        ? [
                                            BoxShadow(
                                              color: Palette.success
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_rounded,
                                          size: 20,
                                          color: status == true
                                              ? Colors.white
                                              : Palette.success),
                                      const SizedBox(width: 6),
                                      Text(
                                        AppLocalizations.of(context)!
                                            .calculate_correct,
                                        style: AppTextStyles.heading(14,
                                            color: status == true
                                                ? Colors.white
                                                : Palette.success),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _answerStatus[index] = false;
                                  _segmentResults[index] =
                                      _segmentResults[index]
                                          .copyWith(maxScore: 0);
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: status == false
                                        ? Palette.pink
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: Palette.pink,
                                        width: status == false ? 0 : 1.5),
                                    boxShadow: status == false
                                        ? [
                                            BoxShadow(
                                              color: Palette.pink
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.cancel_rounded,
                                          size: 20,
                                          color: status == false
                                              ? Colors.white
                                              : Palette.pink),
                                      const SizedBox(width: 6),
                                      Text(
                                        AppLocalizations.of(context)!
                                            .calculate_incorrect,
                                        style: AppTextStyles.heading(14,
                                            color: status == false
                                                ? Colors.white
                                                : Palette.pink),
                                      ),
                                    ], // inner Row children
                                  ), // inner Row
                                ), // AnimatedContainer
                              ), // GestureDetector (incorrect)
                            ), // Expanded (incorrect)
                          ], // Row children [correct,SizedBox,incorrect]
                        ), // Row (buttons)
                      ), // Padding (buttons)
                    ], // if answering spread
                  ], // Column children
                ), // Column
              ), // Expanded
            ], // Row children [strip, Expanded]
          ), // Row
        ), // IntrinsicHeight
      ); // Container
    });
  }

  // ── Evidence section ──────────────────────────────────

  Widget _buildEvidenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.calculate_diaryNotes,
            style: AppTextStyles.heading(18, color: Colors.black54)),
        const SizedBox(height: 5),
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _descriptionController,
            enabled: !_isSubmitting,
            maxLines: null,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              hintText: AppLocalizations.of(context)!.calculate_writeNotes,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildImagePicker()),
            const SizedBox(width: 10),
            Expanded(child: _buildVideoPicker()),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.common_image,
            style: AppTextStyles.heading(18, color: Colors.black54)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: _isSubmitting
              ? null
              : () => _handleMediaSelection(isVideo: false),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    _imagePath != null ? Palette.success : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: _imagePath != null && !kIsWeb
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child:
                              Image.file(File(_imagePath!), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          decoration: const BoxDecoration(
                              color: Colors.black54, shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                            onPressed: _isSubmitting
                                ? null
                                : () => setState(() => _imagePath = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_photo_alternate,
                            size: 40, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context)!.common_addImage,
                            style: AppTextStyles.body(12, color: Colors.grey)),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.common_video,
            style: AppTextStyles.heading(18, color: Colors.black54)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap:
              _isSubmitting ? null : () => _handleMediaSelection(isVideo: true),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    _videoPath != null ? Palette.success : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: _videoPath != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_videoThumbnail != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.memory(
                            _videoThumbnail!,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.videocam,
                                  size: 50, color: Palette.success),
                              const SizedBox(height: 8),
                              Text(
                                  AppLocalizations.of(context)!
                                      .common_videoAdded,
                                  style: AppTextStyles.label(12,
                                      color: Palette.success)),
                            ],
                          ),
                        ),
                      Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 26),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          decoration: const BoxDecoration(
                              color: Colors.black54, shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                            onPressed: _isSubmitting
                                ? null
                                : () => setState(() {
                                      _videoPath = null;
                                      _videoThumbnail = null;
                                    }),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_circle_outline,
                            size: 40, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context)!.common_addVideo,
                            style: AppTextStyles.body(12, color: Colors.grey)),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ── TV Mode Screen ─────────────────────────────────────────────────────────

class _TvModeScreen extends StatefulWidget {
  final List<dynamic> segments;

  const _TvModeScreen({required this.segments});

  @override
  State<_TvModeScreen> createState() => _TvModeScreenState();
}

class _TvModeScreenState extends State<_TvModeScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.segments.length;
    final l = AppLocalizations.of(context)!;
    final progress = ((_currentPage + 1) / total).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF0F2240), Color(0xFF0A1628)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 22),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: Palette.skyGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.tv_rounded,
                              color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(l.calculate_tvMode,
                            style: AppTextStyles.label(15, color: Palette.sky)),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Progress bar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(Palette.sky),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_currentPage + 1} / $total',
                      style: AppTextStyles.body(13, color: Palette.sky),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── PageView ──
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: total,
                  itemBuilder: (context, index) {
                    final segment = widget.segments[index];
                    final question = MathOpDetector.normalizeQuestion(
                      segment['question']?.toString() ??
                          segment['text']?.toString() ??
                          '',
                    );

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Number badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: Palette.skyGradient,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Palette.sky.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              '${l.calculate_questionsCount} ${index + 1}',
                              style: AppTextStyles.heading(18,
                                  color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Question card with sky glow
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                  color: Palette.sky.withValues(alpha: 0.35),
                                  width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Palette.sky.withValues(alpha: 0.12),
                                  blurRadius: 32,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              question,
                              style: AppTextStyles.body(36,
                                  color: Colors.white, weight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 28),
                          Text(
                            l.calculate_tvModeHint,
                            style: AppTextStyles.body(13,
                                color: Colors.white.withValues(alpha: 0.35)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Navigation ──
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Row(
                  children: [
                    // Prev
                    GestureDetector(
                      onTap: _currentPage > 0
                          ? () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                      child: AnimatedOpacity(
                        opacity: _currentPage > 0 ? 1.0 : 0.25,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_back_ios_new,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text('$_currentPage',
                                  style: AppTextStyles.label(14,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Dots
                    Expanded(
                      child: Center(
                        child: Wrap(
                          spacing: 6,
                          children: List.generate(
                            total,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: i == _currentPage ? 22 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: i == _currentPage
                                    ? Palette.sky
                                    : Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Next
                    GestureDetector(
                      onTap: _currentPage < total - 1
                          ? () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                      child: AnimatedOpacity(
                        opacity: _currentPage < total - 1 ? 1.0 : 0.25,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: _currentPage < total - 1
                                ? Palette.skyGradient
                                : null,
                            color: _currentPage < total - 1
                                ? null
                                : Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _currentPage < total - 1
                                ? Palette.buttonShadow
                                : [],
                          ),
                          child: Row(
                            children: [
                              Text('${_currentPage + 2}',
                                  style: AppTextStyles.label(14,
                                      color: Colors.white)),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_ios,
                                  color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
