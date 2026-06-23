import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'space_adventure_result_screen.dart';
import '../../../../services/space_adventure_service.dart';
import '../../../../theme/palette.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../widgets/ui.dart';

class SpaceAdventureQuestScreen extends StatefulWidget {
  final String targetObject;
  final int timerLimit;
  final int scorePerItem;
  final List<String> detectedObjects;
  final int currentScore;
  final int currentIndex;
  final int totalItems;

  const SpaceAdventureQuestScreen({
    super.key,
    required this.targetObject,
    required this.timerLimit,
    required this.scorePerItem,
    required this.detectedObjects,
    required this.currentScore,
    required this.currentIndex,
    required this.totalItems,
  });

  @override
  State<SpaceAdventureQuestScreen> createState() => _SpaceAdventureQuestScreenState();
}

class _SpaceAdventureQuestScreenState extends State<SpaceAdventureQuestScreen> {
  final SpaceAdventureService _spaceService = SpaceAdventureService();
  Uint8List? _capturedImageBytes;
  bool _isEvaluating = false;
  late int _timeLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.timerLimit;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Space time warp! Time ran out!"),
        backgroundColor: Colors.redAccent,
      ),
    );
    _navigateToResult(false, "Time ran out before verification!", 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _captureItem() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 65,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();

    setState(() {
      _capturedImageBytes = bytes;
    });
  }

  Future<void> _verifyMatch() async {
    if (_capturedImageBytes == null) return;

    setState(() {
      _isEvaluating = true;
    });
    _timer?.cancel(); // Pause timer while evaluating

    try {
      final base64String = base64Encode(_capturedImageBytes!);

      final result = await _spaceService.verifyObject(base64String, widget.targetObject);
      final bool isMatch = result['match'] ?? false;
      final String reason = result['reason'] ?? (isMatch ? 'Match!' : 'Not a match.');
      final int points = isMatch ? widget.scorePerItem : 0;

      _navigateToResult(isMatch, reason, points);
    } catch (e) {
      print('Verification error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification error, please try again!')),
      );
      _startTimer(); // Restart timer
      setState(() {
        _isEvaluating = false;
      });
    }
  }

  void _navigateToResult(bool isMatch, String reason, int pointsEarned) {
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SpaceAdventureResultScreen(
          isMatch: isMatch,
          targetObject: widget.targetObject,
          imageBytes: _capturedImageBytes,
          reasonText: reason,
          pointsEarned: pointsEarned,
          currentScore: widget.currentScore + pointsEarned,
          detectedObjects: widget.detectedObjects,
          scorePerItem: widget.scorePerItem,
          timerLimit: widget.timerLimit,
          currentIndex: widget.currentIndex,
          totalItems: widget.totalItems,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double progress = _timeLeft / widget.timerLimit;
    final Color timerColor = _timeLeft < 15 ? Palette.errorStrong : Palette.warning;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Object Hunter',
          style: AppTextStyles.heading(20, color: Colors.black87),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Palette.sky.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Palette.sky.withOpacity(0.3)),
                ),
                child: Text(
                  'Score: ${widget.currentScore}',
                  style: AppTextStyles.label(13, color: Palette.skyDark),
                ),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Digital clock timer & Quest text
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: Palette.cardShadow,
                ),
                child: Column(
                  children: [
                    // Digital Timer countdown layout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.alarm, color: timerColor, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          '00:${_timeLeft.toString().padLeft(2, '0')}',
                          style: AppTextStyles.heading(28, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Linear progress timer indicator
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Palette.progressBg,
                        valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Quest ${widget.currentIndex} / ${widget.totalItems}',
                      style: AppTextStyles.label(12, color: Palette.sky),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Find: ${widget.targetObject}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading(22, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

               // Viewfinder / Captured item image
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: _capturedImageBytes != null ? Palette.sky : Palette.divider,
                      width: 3,
                    ),
                    boxShadow: Palette.cardShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_capturedImageBytes == null) ...[
                        // Viewfinder guidelines/target
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Opacity(
                              opacity: 0.3,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black38, width: 2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: Icon(Icons.add, color: Colors.black38, size: 40),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Take target photo',
                              style: AppTextStyles.label(14, color: Colors.black54),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Display preview of shot
                        Image.memory(
                          _capturedImageBytes!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),

                        if (_isEvaluating) ...[
                          Container(
                            color: Colors.white.withOpacity(0.9),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(color: Palette.sky),
                              const SizedBox(height: 18),
                              Text(
                                'Verifying match...',
                                style: AppTextStyles.label(14, color: Palette.skyDark),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Shutter action button
              Row(
                children: [
                  Expanded(
                    child: GradientButton.primary(
                      label: _capturedImageBytes == null ? 'Capture' : 'Re-take',
                      onTap: _isEvaluating ? null : _captureItem,
                      fontSize: 14,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  if (_capturedImageBytes != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton.success(
                        label: 'Verify match',
                        onTap: _isEvaluating ? null : _verifyMatch,
                        fontSize: 14,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
