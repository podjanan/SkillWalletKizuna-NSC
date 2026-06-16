// lib/screens/activities/detail/physical_detail_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../models/activity.dart';
import '../../../providers/user_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/activity_service.dart';
import '../../../services/draft_service.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/palette.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/activity_l10n.dart';
import '../../../widgets/sticky_bottom_button.dart';
import '../../../widgets/child_avatar.dart';

class PhysicalDetailScreen extends StatefulWidget {
  final Activity activity;
  final List<String> extraChildIds;
  const PhysicalDetailScreen({
    super.key,
    required this.activity,
    this.extraChildIds = const [],
  });

  @override
  State<PhysicalDetailScreen> createState() => _PhysicalDetailScreenState();
}

class _PhysicalDetailScreenState extends State<PhysicalDetailScreen> {
  // ----------------------------------------------------
  // 1. STATE & SERVICES
  // ----------------------------------------------------

  final ActivityService _activityService = ActivityService();

  String? _videoPath;
  String? _imagePath;
  Uint8List? _videoThumbnail;

  // ⏱️ เปลี่ยนจาก Timer เป็น Stopwatch (แม่นยำกว่า)
  Timer? _uiUpdateTimer; // Timer สำหรับอัพเดท UI เท่านั้น
  bool _isPlaying = false;

  final Map<String, int> _childScores = {};
  bool _isSubmitting = false;
  bool _initialized = false;
  final TextEditingController _descriptionController = TextEditingController();

  // Timer: use _startTime + _baseElapsed so pause/restore keeps correct value
  DateTime? _startTime;
  int _baseElapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('⏱️ Physical Activity initialized');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final childId = context.read<UserProvider>().currentChildId;
      if (childId != null) _childScores[childId] = 0;
      for (final id in widget.extraChildIds) {
        _childScores.putIfAbsent(id, () => 0);
      }
      _restoreDraft(childId);
    }
  }

  Future<void> _restoreDraft(String? childId) async {
    if (childId == null) return;
    final draft = await DraftService.loadDraft(childId);
    if (draft == null ||
        draft['type'] != DraftService.typePhysical ||
        draft['activityId'] != widget.activity.id) {
      return;
    }
    final data = draft['data'] as Map<String, dynamic>? ?? {};
    if (!mounted) return;
    // Restore accumulated seconds first
    _baseElapsedSeconds = data['elapsedSeconds'] as int? ?? 0;
    final savedStart = data['startTime'] as String?;
    final wasPlaying = data['isPlaying'] as bool? ?? false;
    if (wasPlaying && savedStart != null) {
      // Add time that passed while app was closed
      final closedAt = DateTime.parse(savedStart);
      _baseElapsedSeconds += DateTime.now().difference(closedAt).inSeconds;
    }
    setState(() {
      _isPlaying = false; // always resume as paused — user decides to restart
      _descriptionController.text = data['description'] as String? ?? '';
      final scores = data['childScores'] as Map<String, dynamic>? ?? {};
      scores.forEach((k, v) => _childScores[k] = (v as num).toInt());
    });
  }

  Future<void> _saveDraft() async {
    final childId = context.read<UserProvider>().currentChildId;
    if (childId == null) return;
    await DraftService.saveDraft(
      childId: childId,
      type: DraftService.typePhysical,
      activityId: widget.activity.id,
      activityJson: widget.activity.toJson(),
      data: {
        'elapsedSeconds': _elapsedSeconds, // snapshot current total
        'startTime': _isPlaying ? DateTime.now().toIso8601String() : null,
        'isPlaying': _isPlaying,
        'description': _descriptionController.text,
        'childScores': _childScores,
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
    return false; // always return false — we handle pop manually
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    _descriptionController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // 2. LOGIC HANDLERS
  // ----------------------------------------------------

  void _handleStart() {
    if (_isPlaying) return;
    _startTime = DateTime.now();
    setState(() => _isPlaying = true);
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _handleFinish() {
    _uiUpdateTimer?.cancel();
    _baseElapsedSeconds = _elapsedSeconds; // snapshot before clearing startTime
    _startTime = null;
    setState(() => _isPlaying = false);
  }

  int get _elapsedSeconds {
    final running = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;
    return _baseElapsedSeconds + running;
  }

  // 🆕 Logic: เลือก Video/Image จาก Camera หรือ Gallery
  Future<void> _handleMediaSelection(
      {required bool isVideo, ImageSource? source}) async {
    try {
      // ถ้าไม่ระบุ source ให้เลือก
      ImageSource selectedSource = source ?? await _showSourceDialog();

      final ImagePicker picker = ImagePicker();
      XFile? pickedFile;

      if (isVideo) {
        // เลือก/ถ่าย Video
        pickedFile = await picker.pickVideo(source: selectedSource);
      } else {
        // เลือก/ถ่าย Image
        pickedFile = await picker.pickImage(source: selectedSource);
      }

      if (pickedFile != null) {
        final String path = pickedFile.path;

        if (isVideo && !kIsWeb) {
          final thumb = await VideoThumbnail.thumbnailData(
            video: path,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 400,
            quality: 70,
          );
          if (mounted)
            setState(() {
              _videoPath = path;
              _videoThumbnail = thumb;
            });
        } else {
          setState(() {
            if (isVideo) {
              _videoPath = path;
            } else {
              _imagePath = path;
            }
          });
        }
        debugPrint('📸 ${isVideo ? 'Video' : 'Image'} selected: $path');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!
                .calculate_failedPickFile(e.toString()))));
      }
    }
  }

  // 🆕 Dialog เลือก Camera หรือ Gallery
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
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: Text(AppLocalizations.of(context)!.common_gallery,
                      style: AppTextStyles.body(14)),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ) ??
        ImageSource.gallery; // default
  }

  // 🆕 Logic: การส่งหลักฐานและคะแนน
  Future<void> _handleSubmit() async {
    final String? childId = context.read<UserProvider>().currentChildId;

    final bool isEvidenceAttached = _videoPath != null || _imagePath != null;

    if (!isEvidenceAttached) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(AppLocalizations.of(context)!.physical_snackNoEvidence)));
      }
      return;
    }
    final allChildIds = <String>{childId!, ...widget.extraChildIds}.toList();
    final bool allScoresValid = allChildIds.every((cid) {
      final s = _childScores[cid] ?? 0;
      return s > 0 && s <= widget.activity.maxScore;
    });
    if (!allScoresValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!
                .physical_snackInvalidScore(widget.activity.maxScore))));
      }
      return;
    }

    // หยุดจับเวลา
    final timeSpentSeconds = _elapsedSeconds;
    _handleFinish();
    debugPrint('⏱️ Physical activity completed in ${timeSpentSeconds}s');

    setState(() => _isSubmitting = true);

    // 1. ดึงค่า description
    final String description = _descriptionController.text.trim();

    // 2. Payload สำหรับ ActivityRecord (ส่ง Local Path + Description แยก)
    final evidencePayload = {
      'videoPathLocal': _videoPath,
      'imagePathLocal': _imagePath,
      'status': 'Pending Approval',
      'description':
          description.isNotEmpty ? description : null, // ✅ ส่ง description
    };

    try {
      debugPrint(
          '📊 Sending to ${allChildIds.length} children, timeSpent: $timeSpentSeconds');

      final results = await Future.wait(
        allChildIds.map((cid) => _activityService.finalizeQuest(
              childId: cid,
              activityId: widget.activity.id,
              segmentResults: [],
              activityMaxScore: widget.activity.maxScore,
              evidence: evidencePayload,
              parentScore: _childScores[cid] ?? 0,
              timeSpent: timeSpentSeconds,
            )),
        eagerError: false,
      );

      debugPrint('✅ Submitted for ${results.length} children');

      // Clear draft on successful submit
      await DraftService.clearDraft(childId);

      if (mounted) {
        final currentScore = _childScores[childId] ?? 0;
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.result,
          arguments: {
            'activityName': widget.activity.name,
            'totalScore':
                ((currentScore / widget.activity.maxScore) * 100).round(),
            'scoreEarned': currentScore,
            'timeSpend': timeSpentSeconds,
            'activityObject': widget.activity,
            'evidenceImagePath': _imagePath,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!
                .physical_snackSubmitError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _removeBtn(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 14),
      ),
    );
  }

  Widget _mediaPlaceholder(IconData icon, String label, bool attached) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon,
            size: 36, color: attached ? Palette.success : Colors.grey.shade400),
        const SizedBox(height: 6),
        Text(label,
            style: AppTextStyles.body(12,
                color: attached ? Palette.success : Colors.grey)),
      ],
    );
  }

  // ── Score Section: แสดงคะแนนแยกต่อเด็กแต่ละคน ──
  Widget _buildScoreSection() {
    final userProvider = context.read<UserProvider>();
    final currentChildId = userProvider.currentChildId ?? '';
    final allIds = <String>{currentChildId, ...widget.extraChildIds}
        .where((id) => id.isNotEmpty)
        .toList();

    return Column(
      children: allIds.map((childId) {
        final name = _getChildName(userProvider.children, childId);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildChildScoreRow(childId, name),
        );
      }).toList(),
    );
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

  Widget _buildChildScoreRow(String childId, String childName) {
    final score = _childScores[childId] ?? 0;
    final pct =
        widget.activity.maxScore > 0 ? score / widget.activity.maxScore : 0.0;
    final barColor = _scoreColor(pct);
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    ChildAvatar(
                      photoUrl: _getChildPhoto(
                          context.read<UserProvider>().children, childId),
                      name: childName,
                      radius: 16,
                      fontSize: 14,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(childName,
                              style:
                                  AppTextStyles.label(14, color: Palette.text)),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct.toDouble(),
                              backgroundColor:
                                  Colors.grey.withValues(alpha: 0.15),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(barColor),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Minus
                    GestureDetector(
                      onTap: () => setState(() {
                        _childScores[childId] = (score > 0) ? score - 1 : 0;
                      }),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Palette.sky.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Palette.sky.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.remove,
                            color: Palette.sky, size: 16),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Score display
                    GestureDetector(
                      onTap: () => _showChildScoreDialog(childId, childName),
                      child: SizedBox(
                        width: 44,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$score',
                            style: AppTextStyles.heading(18, color: barColor),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Plus
                    GestureDetector(
                      onTap: () => setState(() {
                        _childScores[childId] =
                            (score < widget.activity.maxScore)
                                ? score + 1
                                : widget.activity.maxScore;
                      }),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Palette.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Palette.success.withValues(alpha: 0.4)),
                        ),
                        child:
                            Icon(Icons.add, color: Palette.success, size: 16),
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

  void _showChildScoreDialog(String childId, String childName) {
    final tempController = TextEditingController(
      text: (_childScores[childId] ?? 0).toString(),
    );
    tempController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: tempController.text.length,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(childName, style: AppTextStyles.heading(16)),
        content: TextField(
          controller: tempController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!
                .physical_dialogEnterScoreHint(widget.activity.maxScore),
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            _updateChildScore(childId, value);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.common_cancel,
                style: AppTextStyles.body(14, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              _updateChildScore(childId, tempController.text);
              Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(context)!.common_ok,
                style: AppTextStyles.heading(16, color: Palette.success)),
          ),
        ],
      ),
    ).then((_) {
      // Delay dispose until after the dialog dismiss animation completes
      Future.delayed(const Duration(milliseconds: 400), tempController.dispose);
    });
  }

  void _updateChildScore(String childId, String value) {
    final score = int.tryParse(value);
    if (score != null && score >= 0 && score <= widget.activity.maxScore) {
      setState(() => _childScores[childId] = score);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!
              .physical_snackInvalidInput(widget.activity.maxScore))));
    }
  }

  String _getChildName(List<Map<String, dynamic>> children, String childId) {
    for (final item in children) {
      final child = item['child'] as Map<String, dynamic>?;
      if (child != null && child['child_id']?.toString() == childId) {
        return child['name_surname']?.toString() ?? '?';
      }
    }
    return '?';
  }

  String? _getChildPhoto(List<Map<String, dynamic>> children, String childId) {
    for (final item in children) {
      final child = item['child'] as Map<String, dynamic>?;
      if (child != null && child['child_id']?.toString() == childId) {
        return child['photo_url'] as String?;
      }
    }
    return null;
  }

  // ----------------------------------------------------
  // 3. BUILD METHOD (UI)
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final int elapsedSeconds = _elapsedSeconds;
    final mm = two(elapsedSeconds ~/ 60), ss = two(elapsedSeconds % 60);
    final bool isEvidenceAttached = _videoPath != null || _imagePath != null;

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
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) Navigator.pop(context);
            },
          ),
          title: Text(
              ActivityL10n.localizedActivityType(
                  context, widget.activity.category),
              style: AppTextStyles.heading(20, color: Colors.black)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Timer card ──
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: _isPlaying
                              ? const LinearGradient(
                                  colors: [Palette.sky, Color(0xFF0DA8F4)])
                              : null,
                          color: _isPlaying ? null : Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: _isPlaying
                              ? Palette.buttonShadow
                              : Palette.cardShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isPlaying ? Icons.timer : Icons.timer_outlined,
                              color: _isPlaying ? Colors.white : Palette.sky,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$mm:$ss',
                              style: AppTextStyles.heading(30,
                                  color:
                                      _isPlaying ? Colors.white : Palette.sky),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Start / Stop button ──
                    Center(
                      child: GestureDetector(
                        onTap: _isSubmitting
                            ? null
                            : (_isPlaying ? _handleFinish : _handleStart),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 48, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: _isPlaying
                                ? null
                                : const LinearGradient(
                                    colors: [Palette.sky, Color(0xFF0DA8F4)]),
                            color: _isPlaying
                                ? Palette.sky.withValues(alpha: 0.1)
                                : null,
                            borderRadius: BorderRadius.circular(24),
                            border: _isPlaying
                                ? Border.all(color: Palette.sky, width: 2)
                                : null,
                            boxShadow: _isPlaying ? [] : Palette.buttonShadow,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isPlaying
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded,
                                color: _isPlaying ? Palette.sky : Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _isPlaying
                                      ? AppLocalizations.of(context)!
                                          .physical_stopBtn
                                      : AppLocalizations.of(context)!
                                          .physical_startBtn,
                                  style: AppTextStyles.heading(20,
                                      color: _isPlaying
                                          ? Palette.sky
                                          : Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Score section ──
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Palette.sky, size: 20),
                        const SizedBox(width: 8),
                        Text(
                            AppLocalizations.of(context)!
                                .physical_medalsScoreLabel,
                            style:
                                AppTextStyles.heading(18, color: Palette.sky)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Palette.sky.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Palette.sky.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'Max: ${widget.activity.maxScore}',
                            style: AppTextStyles.label(13, color: Palette.sky),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildScoreSection(),
                    const SizedBox(height: 20),

                    // ── Diary ──
                    Row(
                      children: [
                        const Icon(Icons.edit_note_rounded,
                            color: Palette.sky, size: 20),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.physical_diaryLabel,
                            style:
                                AppTextStyles.heading(18, color: Palette.sky)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: Palette.cardShadow,
                        border: Border.all(
                            color: Palette.sky.withValues(alpha: 0.2)),
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!
                                .physical_diaryHint,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12)),
                        maxLines: null,
                        expands: true,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Evidence (image + video) ──
                    Row(
                      children: [
                        const Icon(Icons.photo_library_rounded,
                            color: Palette.sky, size: 20),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.common_evidence,
                            style:
                                AppTextStyles.heading(18, color: Palette.sky)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Image picker
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _handleMediaSelection(isVideo: false),
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: Palette.cardShadow,
                                border: Border.all(
                                  color: _imagePath != null
                                      ? Palette.success
                                      : Colors.grey.shade200,
                                  width: _imagePath != null ? 2 : 1,
                                ),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: _imagePath != null && !kIsWeb
                                  ? Stack(children: [
                                      SizedBox.expand(
                                        child: Image.file(File(_imagePath!),
                                            fit: BoxFit.cover),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: _removeBtn(() =>
                                            setState(() => _imagePath = null)),
                                      ),
                                    ])
                                  : _mediaPlaceholder(
                                      Icons.add_photo_alternate_rounded,
                                      AppLocalizations.of(context)!
                                          .common_addImage,
                                      _imagePath != null,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Video picker
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _handleMediaSelection(isVideo: true),
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: Palette.cardShadow,
                                border: Border.all(
                                  color: _videoPath != null
                                      ? Palette.success
                                      : Colors.grey.shade200,
                                  width: _videoPath != null ? 2 : 1,
                                ),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: _videoPath != null
                                  ? Stack(fit: StackFit.expand, children: [
                                      if (_videoThumbnail != null)
                                        Image.memory(
                                          _videoThumbnail!,
                                          fit: BoxFit.cover,
                                        )
                                      else
                                        Center(
                                          child: _mediaPlaceholder(
                                              Icons.videocam_rounded,
                                              AppLocalizations.of(context)!
                                                  .common_videoAdded,
                                              true),
                                        ),
                                      // Play icon overlay
                                      Center(
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.45),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                              Icons.play_arrow_rounded,
                                              color: Colors.white,
                                              size: 26),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: _removeBtn(() => setState(() {
                                              _videoPath = null;
                                              _videoThumbnail = null;
                                            })),
                                      ),
                                    ])
                                  : _mediaPlaceholder(
                                      Icons.video_call_rounded,
                                      AppLocalizations.of(context)!
                                          .common_addVideo,
                                      false,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            // 7. FINISH BUTTON (sticky bottom)
            StickyBottomButton(
              onPressed: isEvidenceAttached &&
                      !_isSubmitting &&
                      _elapsedSeconds > 0 &&
                      !_isPlaying
                  ? _handleSubmit
                  : null,
              label: _isSubmitting
                  ? AppLocalizations.of(context)!.common_submitting
                  : AppLocalizations.of(context)!.common_finish,
              color: Palette.success,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ), // Scaffold
    ); // PopScope
  }
}
