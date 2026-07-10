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
import '../../../../theme/palette.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../widgets/ui.dart';

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

  void _nextQuest() {
    // Remove the current target object from the list of available items
    final remainingObjects = List<String>.from(widget.detectedObjects)
      ..remove(widget.targetObject);

    if (remainingObjects.isEmpty) {
      _finishMission();
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
      await _showCompletionDialog();
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

    try {
      await _activityService.finalizeQuest(
        childId: childId,
        activityId: activity?.id ?? 'space-adventure',
        segmentResults: results,
        activityMaxScore: (activity?.maxScore ?? 0) > 0
            ? activity!.maxScore
            : widget.totalItems * widget.scorePerItem,
        parentScore: widget.currentScore,
        useDirectScore: true,
        evidence: {
          'type': 'space_adventure',
          'completedItems': results.length,
          'totalItems': widget.totalItems,
        },
      );
      if (mounted) {
        await context.read<UserProvider>().fetchChildrenData();
      }
      if (mounted) {
        setState(() => _isFinishing = false);
        await _showCompletionDialog();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isFinishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your score. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _showCompletionDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          title: Text(
            'Mission completed!',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading(20, color: Colors.black87),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: Palette.yellow, size: 64),
              const SizedBox(height: 12),
              Text(
                widget.currentScore > 0
                    ? 'Your score has been saved.'
                    : 'Mission finished. Keep exploring next time!',
                textAlign: TextAlign.center,
                style: AppTextStyles.body(14, color: Palette.deepGrey),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Palette.sky.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'YOU EARNED',
                      style: AppTextStyles.label(12, color: Palette.deepGrey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.currentScore} POINTS',
                      style: AppTextStyles.heading(28, color: Palette.skyDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.successAlt,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Scan results',
          style: AppTextStyles.heading(20, color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
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
                          widget.isMatch ? Icons.stars : Icons.error_outline,
                          color: widget.isMatch ? Palette.successAlt : Palette.errorStrong,
                          size: 32,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.isMatch ? 'Match!' : 'Try again',
                          style: AppTextStyles.heading(26,
                              color: widget.isMatch ? Palette.successAlt : Palette.errorStrong),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Encouragement/AI feedback
                    Text(
                      widget.isMatch ? 'Great job!' : 'Almost there!',
                      style: AppTextStyles.heading(16, color: Palette.teal),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isMatch
                          ? 'You found the correct item: ${widget.targetObject}!'
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
                  if (widget.imageBytes != null) ...[
                    Expanded(
                      child: GradientButton.primary(
                        label: 'Share photo',
                        onTap: _sharePhoto,
                        fontSize: 14,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: GradientButton.success(
                      label: (widget.detectedObjects.length <= 1)
                          ? (_isFinishing ? 'Saving score...' : 'Finish mission')
                          : 'Next quest',
                      onTap: _isFinishing ? null : _nextQuest,
                      fontSize: 14,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _isFinishing ? null : _finishMission,
                child: Text(
                  _isFinishing ? 'Saving score...' : 'Finish mission',
                  style: AppTextStyles.label(12, color: Palette.deepGrey),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
