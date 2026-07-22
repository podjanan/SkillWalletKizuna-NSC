// lib/screens/activities/detail/math_simulation_activity_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../models/activity.dart';
import '../../../providers/user_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/activity_service.dart';
import '../../../services/api_config.dart';
import '../../../services/draft_service.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/palette.dart';
import '../../../widgets/info_badges.dart';
import '../../../widgets/sticky_bottom_button.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import '../../../utils/activity_l10n.dart';
import '../../../utils/math_op_detector.dart';
import '../../../widgets/share_result_helper.dart';

enum _Phase { ready, running, scanning, reviewing, summary }

class MathSimulationActivityScreen extends StatefulWidget {
  static const String routeName = '/math_simulation_activity';

  final Activity activity;

  const MathSimulationActivityScreen({
    super.key,
    required this.activity,
  });

  @override
  State<MathSimulationActivityScreen> createState() =>
      _MathSimulationActivityScreenState();
}

class _MathSimulationActivityScreenState
    extends State<MathSimulationActivityScreen>
    with SingleTickerProviderStateMixin {
  final ActivityService _activityService = ActivityService();

  // Phase
  _Phase _phase = _Phase.ready;
  int _currentQuestionIndex = 0;

  // Timer
  Timer? _uiUpdateTimer;
  DateTime? _startTime;
  int _baseElapsedSeconds = 0;

  // Scanning line animation
  late AnimationController _scanAnimationController;

  // Evidence / Notes
  String? _videoPath;
  String? _imagePath;
  Uint8List? _scanImageBytes;
  Uint8List? _videoThumbnail;
  final TextEditingController _descriptionController = TextEditingController();

  // Segment Results
  final List<SegmentResult> _segmentResults = [];
  List<dynamic> _segments = [];
  final Map<int, int> _originalScores = {};
  final Map<int, bool?> _answerStatus = {};
  final Map<int, TextEditingController> _answerControllers = {};

  bool _isSubmitting = false;
  bool _isTvMode = false;
  int _totalScoreEarned = 0;

  @override
  void initState() {
    super.initState();
    _loadSegments();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    _scanAnimationController.dispose();
    if (_isTvMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    for (final controller in _answerControllers.values) {
      controller.dispose();
    }
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _toggleTvMode() async {
    final nextValue = !_isTvMode;
    await SystemChrome.setEnabledSystemUIMode(
      nextValue ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
    if (!mounted) return;
    setState(() => _isTvMode = nextValue);
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
          10;

      _originalScores[i] = scoreFromSegment;
      _answerControllers[i] = TextEditingController();

      _segmentResults.add(SegmentResult(
        id: segment['id']?.toString() ?? '${i + 1}',
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
                _currentQuestionIndex = 0;
                _answerStatus.clear();
                for (final controller in _answerControllers.values) {
                  controller.clear();
                }
                for (int i = 0; i < _segmentResults.length; i++) {
                  _segmentResults[i] = _segmentResults[i]
                      .copyWith(maxScore: 0, recognizedText: '');
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

    _baseElapsedSeconds = data['elapsedSeconds'] as int? ?? 0;
    if (savedStart != null && restoredPhase == _Phase.running) {
      final closedAt = DateTime.parse(savedStart);
      _baseElapsedSeconds += DateTime.now().difference(closedAt).inSeconds;
    }

    if (restoredPhase == _Phase.running) {
      _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }

    setState(() {
      _phase = restoredPhase;
      _currentQuestionIndex = data['currentQuestionIndex'] as int? ?? 0;
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

      final typedAnswers = data['typedAnswers'] as Map<String, dynamic>? ?? {};
      typedAnswers.forEach((k, v) {
        final idx = int.tryParse(k);
        if (idx != null && _answerControllers[idx] != null) {
          _answerControllers[idx]!.text = v?.toString() ?? '';
        }
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
    final typedAnswers = <String, String>{};
    _answerControllers.forEach((k, v) => typedAnswers['$k'] = v.text);

    await DraftService.saveDraft(
      childId: childId,
      type: DraftService.typeCalculate,
      activityId: widget.activity.id,
      activityJson: widget.activity.toJson(),
      data: {
        'phase': _phase.name,
        'currentQuestionIndex': _currentQuestionIndex,
        'elapsedSeconds': _elapsedSeconds,
        'startTime':
            _phase == _Phase.running ? DateTime.now().toIso8601String() : null,
        'description': _descriptionController.text,
        'scores': scores,
        'answerStatus': answers,
        'typedAnswers': typedAnswers,
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

  // ── Handwriting OCR Scanning Pipeline ────────────────────

  Future<void> _scanAnswerSheet() async {
    final picker = ImagePicker();
    try {
      final source = await _showSourceDialog();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (pickedFile == null) return;

      // XFile works on Android, iOS and web. dart:io File does not work in a browser.
      final bytes = await pickedFile.readAsBytes();

      setState(() {
        _imagePath = pickedFile.path;
        _scanImageBytes = bytes;
        _phase = _Phase.scanning;
      });

      _scanAnimationController.repeat(reverse: true);

      // Call API
      final base64Image = base64Encode(bytes);
      final lowerPath = pickedFile.path.toLowerCase();
      final imageMimeType = pickedFile.mimeType ??
          (lowerPath.endsWith('.png')
              ? 'image/png'
              : lowerPath.endsWith('.webp')
                  ? 'image/webp'
                  : 'image/jpeg');

      // Format expected answers list
      final expectedQuestions = _segments.asMap().entries.map((e) {
        final idx = e.key;
        final s = e.value;
        return {
          'id': idx + 1,
          'question': s['question']?.toString() ?? '',
          'answer': s['answer']?.toString() ?? '',
        };
      }).toList();

      final response = await _activityService.verifyHandwriting(
        base64Image: base64Image,
        questions: expectedQuestions,
        mimeType: imageMimeType,
      );

      _scanAnimationController.stop();

      if (response['results'] != null) {
        final list = response['results'] as List;
        setState(() {
          _phase = _Phase.reviewing;
          // Populate OCR results
          for (int i = 0; i < _segmentResults.length; i++) {
            final ocrItem = list.firstWhere(
              (item) => (item['questionIndex'] as num).toInt() == i + 1,
              orElse: () => null,
            );
            if (ocrItem != null) {
              final detectedText = ocrItem['detectedText']?.toString() ?? '';
              final detectedAnswer =
                  ocrItem['detectedAnswer']?.toString() ?? '';
              final isCorrect = ocrItem['isCorrect'] as bool? ?? false;

              _segmentResults[i] = _segmentResults[i].copyWith(
                recognizedText: detectedText,
                maxScore: isCorrect ? (_originalScores[i] ?? 10) : 0,
              );
              _answerStatus[i] = isCorrect;
            } else {
              _segmentResults[i] = _segmentResults[i].copyWith(
                recognizedText: 'ไม่พบคำตอบ (No answer found)',
                maxScore: 0,
              );
              _answerStatus[i] = false;
            }
          }
        });
      } else {
        throw Exception('เซิร์ฟเวอร์ส่งข้อมูลกลับในรูปแบบที่ไม่ถูกต้อง');
      }
    } catch (e) {
      _scanAnimationController.stop();
      setState(() => _phase = _Phase.running);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการสแกน: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Helper to re-evaluate when parent/child edits detected text
  bool _evaluateAnswerLocally(String detected, String expected) {
    final cleanDet = detected.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    final cleanExp = expected.replaceAll(RegExp(r'\s+'), '').toLowerCase();

    if (cleanDet == cleanExp) return true;

    // Check numeric values, including negative and decimal answers.
    final detNum = double.tryParse(cleanDet.replaceAll(',', ''));
    final expNum = double.tryParse(cleanExp.replaceAll(',', ''));
    if (detNum != null &&
        expNum != null &&
        (detNum - expNum).abs() < 0.000001) {
      return true;
    }

    return false;
  }

  void _openManualReview() {
    setState(() {
      for (int i = 0; i < _segments.length; i++) {
        final typed = _answerControllers[i]?.text.trim() ?? '';
        _answerStatus[i] = null;
        _segmentResults[i] = _segmentResults[i].copyWith(
          recognizedText: typed,
          maxScore: 0,
        );
      }
      _phase = _Phase.reviewing;
    });
  }

  void _showEditOcrDialog(int index) {
    final l = AppLocalizations.of(context)!;
    final textCtrl =
        TextEditingController(text: _segmentResults[index].recognizedText);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.math_simulation_editTitle(index + 1),
            style: AppTextStyles.heading(18)),
        content: TextField(
          controller: textCtrl,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: l.math_simulation_editHint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.common_cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = textCtrl.text.trim();
              final expectedAnswer =
                  _segments[index]['answer']?.toString() ?? '';
              final isCorrect = _evaluateAnswerLocally(newText, expectedAnswer);

              setState(() {
                _segmentResults[index] = _segmentResults[index].copyWith(
                  recognizedText: newText,
                  maxScore: isCorrect ? (_originalScores[index] ?? 10) : 0,
                );
                _answerStatus[index] = isCorrect;
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Palette.sky),
            child: Text(l.profile_save,
                style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // ── Media Attachments ──────────────────────────────────

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการแนบสื่อ: $e')),
      );
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

  // ── Submit Score ───────────────────────────────────────

  Future<void> _handleSubmit() async {
    final String? childId = context.read<UserProvider>().currentChildId;
    if (childId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.calculate_childIdNotFound)),
      );
      return;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final timeSpentSeconds = _elapsedSeconds;

    // Calculate total points
    int correctCount = 0;
    for (int i = 0; i < _segmentResults.length; i++) {
      if (_answerStatus[i] == true) {
        correctCount++;
      }
    }

    // Direct mapping to activity max score percentage
    final ratio = correctCount / _segments.length;
    final totalScoreEarned = (widget.activity.maxScore * ratio).floor();

    final evidencePayload = {
      'videoPathLocal': _videoPath,
      'imagePathLocal': _imagePath,
      'status': 'Approved',
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
        parentScore: totalScoreEarned,
      );

      await DraftService.clearDraft(childId);

      setState(() {
        _totalScoreEarned = totalScoreEarned;
        _phase = _Phase.summary;
        _uiUpdateTimer?.cancel();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ส่งคำตอบล้มเหลว: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ── Build Main UI ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final elapsedSeconds = _elapsedSeconds;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_phase == _Phase.summary) {
          Navigator.pop(context);
          return;
        }
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: _isTvMode && _phase == _Phase.running
            ? const Color(0xFF071A34)
            : const Color(0xFFFFFDF6), // warm cream background
        appBar: _phase != _Phase.scanning &&
                !(_isTvMode && _phase == _Phase.running)
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                      _phase == _Phase.summary ? Icons.close : Icons.arrow_back,
                      color: Colors.black,
                      size: 28),
                  onPressed: () async {
                    if (_phase == _Phase.summary) {
                      Navigator.pop(context);
                      return;
                    }
                    final shouldPop = await _onWillPop();
                    if (shouldPop && mounted) Navigator.pop(context);
                  },
                ),
                centerTitle: true,
                title: Text(
                  _phase == _Phase.summary
                      ? ActivityL10n.localizedActivityType(
                          context, widget.activity.category)
                      : _phase == _Phase.reviewing
                          ? 'ผลการสแกนการตรวจคำตอบ'
                          : 'กิจกรรมคณิตศาสตร์ตามสถานการณ์จำลอง',
                  style: AppTextStyles.heading(20, color: Colors.black),
                ),
                actions: [
                  if (_phase == _Phase.ready || _phase == _Phase.running)
                    IconButton(
                      tooltip:
                          _isTvMode ? 'ออกจากโหมด Smart TV' : 'โหมด Smart TV',
                      icon: Icon(
                        _isTvMode
                            ? Icons.fullscreen_exit_rounded
                            : Icons.tv_rounded,
                        color: Palette.sky,
                      ),
                      onPressed: _toggleTvMode,
                    ),
                  if (_phase == _Phase.summary)
                    IconButton(
                      icon: const Icon(Icons.share, color: Palette.sky),
                      onPressed: () {
                        showShareBottomSheet(
                          context,
                          ShareResultData(
                            activityName: widget.activity.name,
                            score: _totalScoreEarned,
                            maxScore: widget.activity.maxScore,
                            timeSpentSeconds: _elapsedSeconds,
                            category: widget.activity.category,
                            evidenceImagePath: _imagePath,
                          ),
                        );
                      },
                    ),
                ],
              )
            : null,
        body: _segments.isEmpty
            ? Center(
                child: Text(AppLocalizations.of(context)!.calculate_noQuestions,
                    style: AppTextStyles.heading(20, color: Colors.grey)),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: _isTvMode ? 1100 : double.infinity,
                  ),
                  child: _buildPhaseContent(elapsedSeconds),
                ),
              ),
      ),
    );
  }

  Widget _buildPhaseContent(int elapsedSeconds) {
    switch (_phase) {
      case _Phase.ready:
        return _buildReadyScreen();
      case _Phase.running:
        return _isTvMode
            ? _buildTvRunningScreen()
            : _buildRunningScreen(elapsedSeconds);
      case _Phase.scanning:
        return _buildScanningScreen();
      case _Phase.reviewing:
        return _buildReviewingScreen();
      case _Phase.summary:
        return _buildSummaryScreen();
    }
  }

  Widget _buildTvRunningScreen() {
    final segment = _segments[_currentQuestionIndex];
    final totalQuestions = _segments.length;
    final imageUrl =
        ApiConfig.resolveAssetUrl(segment['imageUrl']?.toString() ?? '');
    final progress = (_currentQuestionIndex + 1) / totalQuestions;

    return ColoredBox(
      color: const Color(0xFF071A34),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'ออกจากโหมด Smart TV',
                      onPressed: _toggleTvMode,
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 30),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF103357),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.tv_rounded,
                            color: Color(0xFF24AEFF), size: 21),
                        SizedBox(width: 7),
                        Text('TV Mode',
                            style: TextStyle(
                                color: Color(0xFF24AEFF), fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.13),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF1DA9FA)),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_currentQuestionIndex + 1} / $totalQuestions',
                  style:
                      const TextStyle(color: Color(0xFF24AEFF), fontSize: 13),
                ),
              ),
              const Spacer(flex: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF35B8FF), Color(0xFF1689DC)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x5524AEFF),
                        blurRadius: 24,
                        offset: Offset(0, 8)),
                  ],
                ),
                child: Text(
                  'ภาพข้อที่ ${_currentQuestionIndex + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 430),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF163D66), Color(0xFF123557)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFF137FC1)),
                ),
                child: imageUrl.isNotEmpty
                    ? AspectRatio(
                        // Older generated images contain a duplicate question
                        // banner at the top. The wider TV viewport crops that
                        // header and keeps only the visual counting scene.
                        aspectRatio: 2.1,
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          alignment: Alignment.bottomCenter,
                          errorBuilder: (_, __, ___) =>
                              _buildTvImagePlaceholder(),
                        ),
                      )
                    : _buildTvImagePlaceholder(),
              ),
              const SizedBox(height: 24),
              Text(
                'เลื่อนไปดูรูปข้อถัดไป',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.38), fontSize: 14),
              ),
              const Spacer(flex: 3),
              Row(
                children: [
                  _tvNavigationButton(
                    icon: Icons.chevron_left_rounded,
                    label: _currentQuestionIndex == 0
                        ? '0'
                        : '$_currentQuestionIndex',
                    enabled: _currentQuestionIndex > 0,
                    onPressed: () => setState(() => _currentQuestionIndex--),
                  ),
                  const Spacer(),
                  Row(
                    children: List.generate(totalQuestions, (index) {
                      return Container(
                        width: index == _currentQuestionIndex ? 22 : 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: index == _currentQuestionIndex
                              ? const Color(0xFF20AEFF)
                              : Colors.white.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  _tvNavigationButton(
                    icon: _currentQuestionIndex < totalQuestions - 1
                        ? Icons.chevron_right_rounded
                        : Icons.check_rounded,
                    label: _currentQuestionIndex < totalQuestions - 1
                        ? '${_currentQuestionIndex + 2}'
                        : 'จบ',
                    enabled: true,
                    primary: true,
                    iconAfter: true,
                    onPressed: () {
                      if (_currentQuestionIndex < totalQuestions - 1) {
                        setState(() => _currentQuestionIndex++);
                      } else {
                        _toggleTvMode();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTvImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported_outlined,
              color: Colors.white.withValues(alpha: 0.45), size: 54),
          const SizedBox(height: 10),
          Text(
            'ยังไม่มีรูปสำหรับข้อนี้',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _tvNavigationButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
    bool primary = false,
    bool iconAfter = false,
  }) {
    final foreground =
        enabled ? Colors.white : Colors.white.withValues(alpha: 0.28);
    final children = <Widget>[
      Icon(icon, color: foreground, size: 25),
      const SizedBox(width: 5),
      Text(label,
          style: TextStyle(
              color: foreground, fontSize: 15, fontWeight: FontWeight.w600)),
    ];
    return Material(
      color: primary
          ? const Color(0xFF209FEF)
          : Colors.white.withValues(alpha: enabled ? 0.08 : 0.03),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          constraints: const BoxConstraints(minWidth: 76),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: iconAfter ? children.reversed.toList() : children,
          ),
        ),
      ),
    );
  }

  // ── Screen: Ready Phase ────────────────────────────────

  Widget _buildReadyScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoBadges(activity: widget.activity),
          const SizedBox(height: 20),
          Text('รายละเอียดกิจกรรม',
              style: AppTextStyles.heading(18, color: Palette.sky)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: Palette.cardShadow,
              border: Border.all(color: Palette.divider),
            ),
            child: Text(
              widget.activity.content.isNotEmpty
                  ? widget.activity.content
                  : 'ฝึกคิดวิเคราะห์และแก้โจทย์คณิตศาสตร์ผ่านภาพสถานการณ์จริง บันทึกคำตอบลงในกระดาษก่อนกดสแกน',
              style: AppTextStyles.body(15),
            ),
          ),
          const SizedBox(height: 32),
          _buildReadyMessage(),
          const SizedBox(height: 48),
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _startTimer,
                icon: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 28),
                label: Text(AppLocalizations.of(context)!.common_start,
                    style: AppTextStyles.heading(18, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.success,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Palette.sky.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.sky.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.edit_note_rounded, size: 48, color: Palette.sky),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.calculate_pressStart,
              style: AppTextStyles.body(15,
                  color: Palette.sky, weight: FontWeight.w600),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
              'เตรียมกระดาษจริงและดินสอเขียนคำตอบไว้ให้พร้อม\nตัวเลขคำตอบเขียนชัดๆ เพื่อสแกนตรวจคำตอบ',
              style: AppTextStyles.body(13, color: Palette.deepGrey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Screen: Running (Gameplay) Phase ───────────────────

  Widget _buildRunningScreen(int elapsedSeconds) {
    final l = AppLocalizations.of(context)!;
    final segment = _segments[_currentQuestionIndex];
    final totalQuestions = _segments.length;

    final questionText = MathOpDetector.normalizeQuestion(
      segment['question']?.toString() ?? segment['text']?.toString() ?? '',
    );
    final imageUrl =
        ApiConfig.resolveAssetUrl(segment['imageUrl']?.toString() ?? '');
    return Column(
      children: [
        // Top indicators bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: List.generate(totalQuestions, (index) {
              final isActive = index == _currentQuestionIndex;
              final isCompleted = index < _currentQuestionIndex;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Palette.sky
                        : isCompleted
                            ? Palette.success
                            : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ),

        // Timer Pill & Counter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ข้อที่ ${_currentQuestionIndex + 1} จาก $totalQuestions',
                style: AppTextStyles.heading(16, color: Palette.sky),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: Palette.skyGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: Palette.buttonShadow,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(elapsedSeconds),
                      style: AppTextStyles.heading(14, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Situation Image
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                      child: AspectRatio(
                        // Crop the duplicate question banner from images
                        // generated before the banner was removed.
                        aspectRatio: 2.1,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.bottomCenter,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: Colors.grey.shade100,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image,
                                size: 50, color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24)),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.image,
                          size: 60, color: Colors.grey.shade400),
                    ),

                  // Proposition Text box
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'สถานการณ์ปัญหาวิเคราะห์ (PROPOSITION)',
                          style: AppTextStyles.heading(14,
                              color: Colors.amber.shade800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          questionText,
                          style:
                              AppTextStyles.body(17, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Navigation bottom controls
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scan Answer / Manual Check Button (Only on the last question)
                if (_currentQuestionIndex == totalQuestions - 1) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Palette.sky.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.task_alt_rounded,
                            color: Palette.sky, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ทำครบทุกข้อแล้ว เลือกวิธีตรวจคำตอบ',
                            style: AppTextStyles.body(14,
                                color: Palette.sky, weight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _scanAnswerSheet,
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: const Text('สแกนกระดาษคำตอบ',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20), // Dark green
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _openManualReview,
                      icon: Icon(Icons.fact_check_outlined, color: Palette.sky),
                      label: Text(
                        'ตรวจด้วยตนเอง',
                        style: AppTextStyles.heading(15, color: Palette.sky),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Palette.sky, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Prev / Next actions
                Row(
                  children: [
                    if (_currentQuestionIndex > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              setState(() => _currentQuestionIndex--),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Palette.sky, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(l.math_simulation_prevBtn,
                              style: AppTextStyles.heading(14,
                                  color: Palette.sky)),
                        ),
                      ),
                    if (_currentQuestionIndex > 0 &&
                        _currentQuestionIndex < totalQuestions - 1)
                      const SizedBox(width: 12),
                    if (_currentQuestionIndex < totalQuestions - 1)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              setState(() => _currentQuestionIndex++),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Palette.sky,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(l.math_simulation_nextBtn,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Screen: Scanning Phase (Animated green line) ───────

  Widget _buildScanningScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      body: Stack(
        children: [
          // Background photo
          if (_scanImageBytes != null || (_imagePath != null && !kIsWeb))
            Positioned.fill(
              child: Opacity(
                opacity: 0.82,
                child: _scanImageBytes != null
                    ? Image.memory(_scanImageBytes!, fit: BoxFit.contain)
                    : Image.file(File(_imagePath!), fit: BoxFit.contain),
              ),
            ),

          // Green overlay scanner border
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: Palette.success.withValues(alpha: 0.18), width: 12),
              ),
            ),
          ),

          // Animated laser line
          AnimatedBuilder(
            animation: _scanAnimationController,
            builder: (context, child) {
              return Positioned(
                top: MediaQuery.of(context).size.height *
                    _scanAnimationController.value,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Palette.success,
                    boxShadow: [
                      BoxShadow(
                        color: Palette.success.withValues(alpha: 0.55),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Loading message panel
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: Palette.success.withValues(alpha: 0.18)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Palette.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: CircularProgressIndicator(
                        color: Palette.success,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'กำลังอ่านคำตอบจากภาพ',
                    style: AppTextStyles.heading(17, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'กรุณารอสักครู่ ระบบกำลังค้นหาตัวเลขทั้งหมด',
                    style: AppTextStyles.body(13, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Screen: Reviewing Phase ────────────────────────────

  Widget _buildReviewingScreen() {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        // Review header banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Palette.sky.withValues(alpha: 0.12),
                Palette.success.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.fact_check_rounded,
                    color: Palette.sky, size: 23),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ตรวจคำตอบทั้งหมด',
                      style: AppTextStyles.heading(16, color: Colors.black87),
                    ),
                    Text(
                      'ตรวจสอบและแก้ไขผลก่อนกดเสร็จสิ้น',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // List of question cards
                Text('รายการคำตอบ',
                    style: AppTextStyles.heading(16, color: Colors.black87)),
                const SizedBox(height: 10),

                ...List.generate(_segments.length, (index) {
                  final segment = _segments[index];
                  final ocrText = _segmentResults[index].recognizedText ?? '';
                  final status =
                      _answerStatus[index]; // bool? (true, false, null)
                  final isCorrect = status == true;
                  final isIncorrect = status == false;

                  final Color accentColor = status == true
                      ? Palette.success
                      : status == false
                          ? Palette.pink
                          : Palette.sky;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: status != null
                          ? Palette.buttonShadow
                          : Palette.cardShadow,
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left accent strip
                          Container(width: 4, color: accentColor),

                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Number circle
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: accentColor.withValues(
                                              alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: accentColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Text block
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              segment['question']?.toString() ??
                                                  '',
                                              style: AppTextStyles.body(14,
                                                  weight: FontWeight.w600),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'เฉลย: ${segment['answer']?.toString() ?? ''}',
                                              style: AppTextStyles.label(12,
                                                  color: Palette.success),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Edit button
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: Palette.sky, size: 20),
                                        onPressed: () =>
                                            _showEditOcrDialog(index),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Scanned/Typed answer display
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Text('คำตอบ: ',
                                            style: AppTextStyles.body(13,
                                                color: Colors.grey.shade600)),
                                        Expanded(
                                          child: Text(
                                            ocrText.isNotEmpty
                                                ? ocrText
                                                : 'ยังไม่พบคำตอบ',
                                            style: AppTextStyles.body(14,
                                                weight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Correct / Incorrect toggle buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() {
                                            _answerStatus[index] = true;
                                            _segmentResults[index] =
                                                _segmentResults[index].copyWith(
                                                    maxScore: _originalScores[
                                                            index] ??
                                                        10);
                                          }),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            decoration: BoxDecoration(
                                              color: isCorrect
                                                  ? Palette.success
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                  color: Palette.success,
                                                  width: isCorrect ? 0 : 1.5),
                                              boxShadow: isCorrect
                                                  ? [
                                                      BoxShadow(
                                                        color: Palette.success
                                                            .withValues(
                                                                alpha: 0.3),
                                                        blurRadius: 6,
                                                        offset:
                                                            const Offset(0, 2),
                                                      )
                                                    ]
                                                  : [],
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.check_circle_rounded,
                                                    size: 20,
                                                    color: isCorrect
                                                        ? Colors.white
                                                        : Palette.success),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'ถูกต้อง',
                                                  style: AppTextStyles.heading(
                                                      14,
                                                      color: isCorrect
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
                                            duration: const Duration(
                                                milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            decoration: BoxDecoration(
                                              color: isIncorrect
                                                  ? Palette.pink
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                  color: Palette.pink,
                                                  width: isIncorrect ? 0 : 1.5),
                                              boxShadow: isIncorrect
                                                  ? [
                                                      BoxShadow(
                                                        color: Palette.pink
                                                            .withValues(
                                                                alpha: 0.3),
                                                        blurRadius: 6,
                                                        offset:
                                                            const Offset(0, 2),
                                                      )
                                                    ]
                                                  : [],
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.cancel_rounded,
                                                    size: 20,
                                                    color: isIncorrect
                                                        ? Colors.white
                                                        : Palette.pink),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'ไม่ถูกต้อง',
                                                  style: AppTextStyles.heading(
                                                      14,
                                                      color: isIncorrect
                                                          ? Colors.white
                                                          : Palette.pink),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Retake action button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _scanAnswerSheet,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('สแกนใหม่'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Palette.sky, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Evidence Attachments block
                Text(l.common_evidence,
                    style: AppTextStyles.heading(20, color: Palette.error)),
                const SizedBox(height: 15),
                _buildEvidenceSection(),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),

        // Bottom submit all answers button
        StickyBottomButton(
          onPressed: _handleSubmit,
          label: 'เสร็จสิ้น',
          color: Palette.success,
          isLoading: _isSubmitting,
        ),
      ],
    );
  }

  Widget _buildEvidenceSection() {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.calculate_diaryNotes,
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
              hintText: l.calculate_writeNotes,
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
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.common_image,
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
                        const Icon(Icons.add_photo_alternate_outlined,
                            size: 40, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(l.common_addImage,
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
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.common_video,
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
                          child:
                              Image.memory(_videoThumbnail!, fit: BoxFit.cover),
                        )
                      else
                        const Center(
                            child: Icon(Icons.check_circle_outline,
                                color: Colors.green, size: 36)),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          decoration: const BoxDecoration(
                              color: Colors.black54, shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 14),
                            onPressed: _isSubmitting
                                ? null
                                : () => setState(() {
                                      _videoPath = null;
                                      _videoThumbnail = null;
                                    }),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 26, minHeight: 26),
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
                        Text(l.common_addVideo,
                            style: AppTextStyles.body(12, color: Colors.grey)),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Screen: Summary (Well Done) Phase ──────────────────

  Widget _buildSummaryScreen() {
    final l = AppLocalizations.of(context)!;
    int correctCount = 0;
    for (int i = 0; i < _segmentResults.length; i++) {
      if (_answerStatus[i] == true) correctCount++;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Stars icon header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded,
                    size: 54, color: Colors.amber),
              ),
              const SizedBox(height: 12),

              Text(
                'เก่งมากเลย! (Well Done)',
                style:
                    AppTextStyles.heading(28, color: const Color(0xFF1B5E20)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'บันทึกคะแนนสะสมแต้มรางวัลลงระบบเรียบร้อยแล้ว',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // KPI stats cards grid
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryKpiCard(
                      label: 'SCORE',
                      value: '$_totalScoreEarned',
                      icon: Icons.workspace_premium,
                      color: Colors.amber.shade700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSummaryKpiCard(
                      label: 'TIMESpent',
                      value: '${_formatTime(_elapsedSeconds).substring(3)}',
                      icon: Icons.timer_outlined,
                      color: Palette.sky,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSummaryKpiCard(
                      label: 'CORRECT',
                      value: '$correctCount/${_segments.length}',
                      icon: Icons.check_circle_outline,
                      color: Palette.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Detailed summary checklist
              Align(
                alignment: Alignment.centerLeft,
                child: Text('รายละเอียดการทำกิจกรรม',
                    style: AppTextStyles.heading(16, color: Colors.black54)),
              ),
              const SizedBox(height: 10),

              ...List.generate(_segments.length, (index) {
                final segment = _segments[index];
                final ocrVal = _segmentResults[index].recognizedText ?? '';
                final isCorrect = _answerStatus[index] == true;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: Palette.cardShadow,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? Palette.success.withValues(alpha: 0.1)
                              : Palette.pink.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCorrect ? Palette.success : Palette.pink,
                              fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(segment['question']?.toString() ?? '',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(ocrVal,
                                style: AppTextStyles.body(14,
                                    weight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? Palette.success : Palette.pink,
                        size: 22,
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 48),

              // Bottom summary options
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _phase = _Phase.ready;
                      _currentQuestionIndex = 0;
                      _baseElapsedSeconds = 0;
                      _startTime = null;
                      _answerStatus.clear();
                      _imagePath = null;
                      _videoPath = null;
                      _videoThumbnail = null;
                      _descriptionController.clear();
                      for (final controller in _answerControllers.values) {
                        controller.clear();
                      }
                      for (int i = 0; i < _segmentResults.length; i++) {
                        _segmentResults[i] = _segmentResults[i]
                            .copyWith(maxScore: 0, recognizedText: '');
                      }
                    });
                  },
                  icon: const Icon(Icons.replay, color: Colors.white, size: 22),
                  label: Text(
                    l.result_playAgainBtn,
                    style: AppTextStyles.heading(18, color: Palette.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.bluePill,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.home_outlined, color: Palette.sky, size: 22),
                  label: Text(
                    l.result_backToActivitiesBtn,
                    style: AppTextStyles.heading(18, color: Palette.sky),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Palette.sky, width: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: Palette.cardShadow,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
