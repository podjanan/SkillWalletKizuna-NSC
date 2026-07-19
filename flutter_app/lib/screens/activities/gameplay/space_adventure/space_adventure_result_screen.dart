import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'space_adventure_quest_screen.dart';
import '../../../../models/activity.dart';
import '../../../../providers/user_provider.dart';
import '../../../../services/activity_service.dart';
import '../../../../services/draft_service.dart';
import '../../../../theme/palette.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../widgets/ui.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/activity_l10n.dart';
import '../../../../widgets/share_result_helper.dart';

class SpaceAdventureResultScreen extends StatefulWidget {
  final bool isMatch;
  final String targetObject;
  final Uint8List? imageBytes;
  final String reasonText;
  final int pointsEarned;
  final int currentScore;
  final List<String> detectedObjects;
  final int scorePerItem;
  final int timerLimit;
  final int currentIndex;
  final int totalItems;
  final List<Map<String, dynamic>> completedItemsHistory;
  final Activity? activity;

  const SpaceAdventureResultScreen({
    super.key,
    required this.isMatch,
    required this.targetObject,
    this.imageBytes,
    required this.reasonText,
    required this.pointsEarned,
    required this.currentScore,
    required this.detectedObjects,
    required this.scorePerItem,
    required this.timerLimit,
    required this.currentIndex,
    required this.totalItems,
    this.completedItemsHistory = const [],
    this.activity,
  });

  @override
  State<SpaceAdventureResultScreen> createState() => _SpaceAdventureResultScreenState();
}

class _SpaceAdventureResultScreenState extends State<SpaceAdventureResultScreen> {
  final ActivityService _activityService = ActivityService();
  bool _isFinishing = false;
  bool _showSummary = false;
  bool _scoreSaved = false;
  int? _savedWallet;
  String? _errorMessage;

  String? _imagePath;
  String? _videoPath;
  Uint8List? _videoThumbnail;
  final TextEditingController _descriptionController = TextEditingController();

  void _sharePhoto() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sharing is supported on mobile devices. Right-click the image to save on Web!'),
          backgroundColor: Colors.blueAccent,
        ),
      );
      return;
    }
    if (widget.imageBytes == null) return;
    try {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/space_ranger_match.jpg');
      await tempFile.writeAsBytes(widget.imageBytes!);

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Look at my Space Adventure scavenger match: ${widget.targetObject}! I scored ${widget.currentScore} points!',
      );
    } catch (e) {
      print('Share failed: $e');
    }
  }

  void _retryQuest() {
    final history = List<Map<String, dynamic>>.from(widget.completedItemsHistory);
    if (history.isNotEmpty) {
      history.removeLast();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SpaceAdventureQuestScreen(
          targetObject: widget.targetObject,
          timerLimit: widget.timerLimit,
          scorePerItem: widget.scorePerItem,
          detectedObjects: widget.detectedObjects,
          currentScore: widget.currentScore,
          currentIndex: widget.currentIndex,
          totalItems: widget.totalItems,
          completedItemsHistory: history,
          activity: widget.activity,
        ),
      ),
    );
  }

  void _nextQuest() {
    // Remove the current target object from the list of available items
    final remainingObjects = List<String>.from(widget.detectedObjects)
      ..remove(widget.targetObject);

    if (remainingObjects.isEmpty) {
      setState(() {
        _showSummary = true;
        _scoreSaved = false;
        _isFinishing = false;
        _errorMessage = null;
      });
      return;
    }

    // Pick next random object
    remainingObjects.shuffle();
    final nextTarget = remainingObjects.first;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SpaceAdventureQuestScreen(
          targetObject: nextTarget,
          timerLimit: widget.timerLimit,
          scorePerItem: widget.scorePerItem,
          detectedObjects: remainingObjects,
          currentScore: widget.currentScore,
          currentIndex: widget.currentIndex + 1,
          totalItems: widget.totalItems,
          completedItemsHistory: widget.completedItemsHistory,
          activity: widget.activity,
        ),
      ),
    );
  }

  Future<void> _finishMission() async {
    if (_isFinishing) return;

    if (widget.currentScore <= 0) {
      setState(() {
        _showSummary = true;
        _scoreSaved = true;
      });
      return;
    }

    final childId = context.read<UserProvider>().currentChildId;
    final activity = widget.activity;
    if (childId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a child profile before saving the score.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isFinishing = true);
    final results = widget.completedItemsHistory
        .map(
          (item) => SegmentResult(
            id: item['id']?.toString() ?? '',
            text: item['text']?.toString() ?? '',
            maxScore: (item['scoreEarned'] as num?)?.toInt() ?? 0,
            status: SegmentStatus.done,
            recognizedText: item['recognizedText']?.toString(),
          ),
        )
        .toList();

    final evidencePayload = {
      'type': 'space_adventure',
      'completedItems': results.length,
      'totalItems': widget.totalItems,
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
        activityId: activity?.id ?? 'space-adventure',
        segmentResults: results,
        activityMaxScore: (activity?.maxScore ?? 0) > 0
            ? activity!.maxScore
            : widget.totalItems * widget.scorePerItem,
        parentScore: widget.currentScore,
        useDirectScore: true,
        evidence: evidencePayload,
      );
      await DraftService.clearDraft(childId);
      if (mounted) {
        await context.read<UserProvider>().fetchChildrenData();
      }
      final wallet = response['newWallet'];
      if (mounted) {
        setState(() {
          _isFinishing = false;
          _showSummary = true;
          _scoreSaved = true;
          _savedWallet = wallet is int ? wallet : int.tryParse(wallet?.toString() ?? '');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFinishing = false;
        _scoreSaved = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _showSummary = true;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final isSummary = _showSummary;
    final activity = widget.activity;

    return Scaffold(
      backgroundColor: isSummary ? const Color(0xFFFFF9DE) : Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: !isSummary
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.black87),
                onPressed: () {
                  setState(() {
                    _showSummary = true;
                    _scoreSaved = false;
                    _isFinishing = false;
                    _errorMessage = null;
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.close, color: Colors.black87),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
        title: Text(
          isSummary
              ? ActivityL10n.localizedActivityType(context, activity?.category ?? 'PHYSICAL')
              : 'Scan results',
          style: AppTextStyles.heading(20, color: Colors.black87),
        ),
        centerTitle: true,
        actions: [
          if (isSummary)
            IconButton(
              icon: const Icon(Icons.share, color: Palette.sky),
              onPressed: () {
                showShareBottomSheet(
                  context,
                  ShareResultData(
                    activityName: activity?.name ?? 'Space Adventure',
                    score: widget.currentScore,
                    maxScore: widget.totalItems * widget.scorePerItem,
                    timeSpentSeconds: 0,
                    category: activity?.category,
                    evidenceImagePath: _imagePath,
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isSummary ? _buildSummaryScreen() : _buildResultView(),
        ),
      ),
    );
  }

  Widget _buildResultView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image result display
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: widget.isMatch ? Palette.successAlt : Palette.errorStrong,
                  width: 3,
                ),
                boxShadow: Palette.cardShadow,
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.imageBytes != null
                  ? Image.memory(
                      widget.imageBytes!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : const Center(
                      child: Icon(Icons.broken_image, color: Colors.black26, size: 64),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Match verification details card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Palette.divider,
                width: 2,
              ),
              boxShadow: Palette.cardShadow,
            ),
            child: Column(
              children: [
                // Match Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.isMatch ? Icons.stars_rounded : Icons.info_outline_rounded,
                      color: widget.isMatch ? Palette.successAlt : Palette.errorStrong,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isMatch ? 'CORRECT MATCH' : 'MISMATCH DETECTED',
                      style: AppTextStyles.heading(
                        14,
                        color: widget.isMatch ? Palette.successAlt : Palette.errorStrong,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.isMatch
                      ? 'Vision AI verified your target: ${widget.targetObject}'
                      : 'This photo does not match ${widget.targetObject} yet. Please try again.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(13, color: Colors.black87),
                ),
                const SizedBox(height: 14),
                // Points details
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Palette.sky.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    widget.isMatch
                        ? 'Scored +${widget.pointsEarned} Points! Current Total: ${widget.currentScore}'
                        : 'Current Total: ${widget.currentScore} Points',
                    style: AppTextStyles.label(13, color: Palette.skyDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sharing and next action buttons
          Row(
            children: [
              if (widget.isMatch && widget.imageBytes != null) ...[
                Expanded(
                  child: GradientButton.primary(
                    label: 'Share photo',
                    onTap: _sharePhoto,
                    fontSize: 14,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(width: 12),
              ] else if (!widget.isMatch) ...[
                Expanded(
                  child: GradientButton.primary(
                    label: 'Recapture',
                    onTap: _isFinishing ? null : _retryQuest,
                    fontSize: 14,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: GradientButton.success(
                  label: (widget.detectedObjects.length <= 1)
                      ? (_isFinishing ? 'Saving score...' : 'Done')
                      : 'Next quest',
                  onTap: _isFinishing ? null : _nextQuest,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildSummaryScreen() {
    final l = AppLocalizations.of(context)!;
    final childName =
        context.watch<UserProvider>().currentChildName ?? 'Selected child';
    final savedText = _scoreSaved
        ? 'Saved to $childName${_savedWallet != null ? ' • Wallet: $_savedWallet' : ''}'
        : 'Please enter evidence and save score';

    final maxScore = widget.totalItems * widget.scorePerItem;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: Palette.softShadow,
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Palette.warning,
                  size: 62,
                ),
                const SizedBox(height: 12),
                Text(
                  'Quest Complete!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading(28, color: Palette.text),
                ),
                const SizedBox(height: 10),
                Text(
                  'Total Score',
                  style: AppTextStyles.label(13, color: Palette.deepGrey),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${widget.currentScore} / $maxScore',
                    style: AppTextStyles.heading(58, color: Palette.successAlt),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isFinishing)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Palette.sky,
                        ),
                      )
                    else
                      Icon(
                        _scoreSaved
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        color: _scoreSaved
                            ? Palette.successAlt
                            : Palette.errorStrong,
                        size: 20,
                      ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _errorMessage ?? savedText,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(
                          13,
                          color: _errorMessage == null
                              ? Palette.deepGrey
                              : Palette.errorStrong,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          
          // Quest items list
          ...List.generate(widget.completedItemsHistory.length, (index) {
            final result = widget.completedItemsHistory[index];
            final name = result['text']?.toString() ?? '';
            final isCorrect = result['match'] as bool? ?? false;
            final score = (result['scoreEarned'] as num?)?.toInt() ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Palette.greyCard, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(
                    isCorrect
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    color: isCorrect ? Palette.successAlt : Palette.warning,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.toUpperCase(),
                          style: AppTextStyles.heading(15, color: Palette.text),
                        ),
                        Text(
                          isCorrect ? 'Found: $name' : 'Not found',
                          style: AppTextStyles.body(12, color: Palette.deepGrey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+$score',
                    style: AppTextStyles.heading(
                      16,
                      color: score > 0 ? Palette.successAlt : Palette.deepGrey,
                    ),
                  ),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 20),
          _buildEvidenceSection(),
          const SizedBox(height: 30),
          
          // Action Buttons
          if (!_scoreSaved) ...[
            GradientButton.success(
              label: 'Done',
              onTap: _finishMission,
              isLoading: _isFinishing,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                icon: const Icon(Icons.replay, color: Colors.white, size: 22),
                label: Text(
                  l.result_playAgainBtn,
                  style: AppTextStyles.heading(18, color: Palette.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.bluePill,
                  disabledBackgroundColor: Palette.bluePill.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (route) => false,
                ),
                icon: const Icon(Icons.home_outlined, color: Palette.sky, size: 22),
                label: Text(
                  l.result_backToActivitiesBtn,
                  style: AppTextStyles.heading(18, color: Palette.sky),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Palette.sky, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEvidenceSection() {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.common_evidence.toUpperCase(),
          style: AppTextStyles.heading(14, color: Palette.pink),
        ),
        const SizedBox(height: 10),
        Text(
          l.calculate_diaryNotes.toUpperCase(),
          style: AppTextStyles.label(12, color: Palette.deepGrey),
        ),
        const SizedBox(height: 6),
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Palette.divider, width: 1.5),
          ),
          child: TextField(
            controller: _descriptionController,
            enabled: !_isFinishing && !_scoreSaved,
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
        Text(
          l.common_image.toUpperCase(),
          style: AppTextStyles.label(12, color: Palette.deepGrey),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: (_isFinishing || _scoreSaved)
              ? null
              : () => _handleMediaSelection(isVideo: false),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _imagePath != null ? Palette.successAlt : Palette.divider,
                width: 1.5,
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
                          child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 16),
                            onPressed: (_isFinishing || _scoreSaved)
                                ? null
                                : () => setState(() => _imagePath = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.grey),
                        const SizedBox(height: 6),
                        Text(
                          l.common_addImage,
                          style: AppTextStyles.body(11, color: Colors.grey),
                        ),
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
        Text(
          l.common_video.toUpperCase(),
          style: AppTextStyles.label(12, color: Palette.deepGrey),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: (_isFinishing || _scoreSaved)
              ? null
              : () => _handleMediaSelection(isVideo: true),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _videoPath != null ? Palette.successAlt : Palette.divider,
                width: 1.5,
              ),
            ),
            child: _videoPath != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_videoThumbnail != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.memory(_videoThumbnail!, fit: BoxFit.cover),
                        )
                      else
                        const Center(
                          child: Icon(Icons.check_circle_outline, color: Colors.green, size: 36),
                        ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 14),
                            onPressed: (_isFinishing || _scoreSaved)
                                ? null
                                : () => setState(() {
                                      _videoPath = null;
                                      _videoThumbnail = null;
                                    }),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_circle_outline, size: 36, color: Colors.grey),
                        const SizedBox(height: 6),
                        Text(
                          l.common_addVideo,
                          style: AppTextStyles.body(11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

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
          final thumb = await VideoThumbnail.thumbnailData(
            video: pickedFile.path,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 400,
            quality: 70,
          );
          if (mounted) {
            setState(() {
              _videoPath = pickedFile!.path;
              _videoThumbnail = thumb;
            });
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
            title: Text(
              AppLocalizations.of(context)!.common_selectSource,
              style: AppTextStyles.heading(18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt, color: Palette.successAlt),
                  title: Text(
                    AppLocalizations.of(context)!.common_camera,
                    style: AppTextStyles.body(14),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: Palette.sky),
                  title: Text(
                    AppLocalizations.of(context)!.common_gallery,
                    style: AppTextStyles.body(14),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ) ??
        ImageSource.gallery;
  }
}
