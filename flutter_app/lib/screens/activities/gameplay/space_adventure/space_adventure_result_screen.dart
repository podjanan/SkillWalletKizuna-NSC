import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'space_adventure_quest_screen.dart';
import '../../../../providers/user_provider.dart';
import '../../../../services/space_adventure_service.dart';
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
  });

  @override
  State<SpaceAdventureResultScreen> createState() => _SpaceAdventureResultScreenState();
}

class _SpaceAdventureResultScreenState extends State<SpaceAdventureResultScreen> {
  final SpaceAdventureService _spaceService = SpaceAdventureService();
  final TextEditingController _nameController = TextEditingController(text: "Space Adventurer");
  bool _isSaving = false;
  bool _saved = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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
      // Game over! Must submit score
      _showGameOverDialog();
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
        ),
      ),
    );
  }

  Future<void> _submitScoreToLeaderboard(VoidCallback updateDialogState) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your ranger name!'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    if (_saved || _isSaving) return;

    final userProvider = context.read<UserProvider>();
    final childId = userProvider.currentChildId;
    if (childId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Child ID not found. Please choose a child first.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });
    updateDialogState();

    try {
      final maxScore = widget.totalItems * widget.scorePerItem;

      await _spaceService.completeMission(
        childId: childId,
        totalScoreEarned: widget.currentScore,
        maxScore: maxScore,
        detectedObjects: widget.detectedObjects,
        completedItems: widget.completedItemsHistory,
        scorePerItem: widget.scorePerItem,
        timerLimit: widget.timerLimit,
      );
      await _spaceService.submitScore(name, widget.currentScore);
      await userProvider.fetchChildrenData();
      setState(() {
        _saved = true;
      });
      updateDialogState();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Score saved to child history!'),
          backgroundColor: Colors.green,
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      });
    } catch (e) {
      print('Failed to save score: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save score. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        updateDialogState();
      }
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => PopScope(
          canPop: !_isSaving,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            title: Text(
              'Mission completed!',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading(20, color: Colors.black87),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, color: Palette.yellow, size: 64),
                const SizedBox(height: 12),
                Text(
                  'You scanned all items! Awesome work, Space Ranger!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(14, color: Palette.deepGrey),
                ),
                const SizedBox(height: 16),
                Text(
                  'Total score: ${widget.currentScore}',
                  style: AppTextStyles.heading(18, color: Palette.skyDark),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  enabled: !_isSaving,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'RANGER NAME',
                    labelStyle: const TextStyle(color: Palette.skyDark),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Palette.divider, width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Palette.sky, width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              if (_isSaving)
                const CircularProgressIndicator(color: Palette.sky)
              else
                TextButton(
                  onPressed: () => _submitScoreToLeaderboard(() => setStateDialog(() {})),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Palette.successAlt,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      'SUBMIT & EXIT',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
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
                      widget.reasonText,
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
                          ? 'Finish mission'
                          : 'Next quest',
                      onTap: _nextQuest,
                      fontSize: 14,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _showGameOverDialog,
                child: Text(
                  'Finish mission & save score',
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
