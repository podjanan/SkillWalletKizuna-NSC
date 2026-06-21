import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'space_adventure_quest_screen.dart';
import '../../../../services/space_adventure_service.dart';
import '../../../../theme/palette.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../widgets/ui.dart';

class SpaceAdventureScanScreen extends StatefulWidget {
  const SpaceAdventureScanScreen({super.key});

  @override
  State<SpaceAdventureScanScreen> createState() => _SpaceAdventureScanScreenState();
}

class _SpaceAdventureScanScreenState extends State<SpaceAdventureScanScreen>
    with SingleTickerProviderStateMixin {
  final SpaceAdventureService _spaceService = SpaceAdventureService();
  late AnimationController _scanAnimationController;
  Uint8List? _roomImageBytes;
  bool _isScanning = false;
  List<String> _detectedObjects = [];
  Map<String, dynamic> _gameSettings = {'scorePerItem': 10, 'timerLimit': 60};

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _spaceService.getSettings();
    if (mounted) {
      setState(() {
        _gameSettings = settings;
      });
    }
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    super.dispose();
  }

  Future<void> _captureRoom() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 65,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();

    setState(() {
      _roomImageBytes = bytes;
      _isScanning = true;
      _detectedObjects = [];
    });

    _scanAnimationController.repeat(reverse: true);

    try {
      final base64String = base64Encode(bytes);
      final objects = await _spaceService.scanRoom(base64String);
      
      if (mounted) {
        setState(() {
          _detectedObjects = objects;
        });
      }
    } catch (e) {
      print('Scan failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _scanAnimationController.stop();
        });
      }
    }
  }

  void _finishScanAndStartQuest() {
    if (_detectedObjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please scan your room to find adventure objects first!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Select random object from scanned list
    _detectedObjects.shuffle();
    final targetObject = _detectedObjects.first;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpaceAdventureQuestScreen(
          targetObject: targetObject,
          timerLimit: _gameSettings['timerLimit'] ?? 60,
          scorePerItem: _gameSettings['scorePerItem'] ?? 10,
          detectedObjects: _detectedObjects,
          currentScore: 0,
          currentIndex: 1,
          totalItems: _detectedObjects.length,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SPACE SCANNER',
          style: luckiestH(22, color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Intro banner - light card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Palette.divider,
                    width: 2,
                  ),
                  boxShadow: Palette.cardShadow,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.rocket_launch_rounded,
                      color: Palette.sky,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PHASE 1: INITIAL ROOM SCAN',
                            style: AppTextStyles.label(13, color: Palette.sky),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Take a photo of your room to detect target quest items hidden in space!',
                            style: AppTextStyles.body(12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Viewfinder / Room image container
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: _isScanning ? Palette.sky : Palette.divider,
                      width: 3,
                    ),
                    boxShadow: Palette.cardShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_roomImageBytes == null) ...[
                        // Scanner HUD default
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Palette.sky.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: Palette.sky, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: Palette.sky,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'MAP SCAN COORDINATES',
                              style: luckiestH(18, color: Colors.black87),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap button below to snap room photo',
                              style: AppTextStyles.body(13, color: Colors.black54),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Captured image
                        Image.memory(
                          _roomImageBytes!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),

                        // Scanning overlay
                        if (_isScanning) ...[
                          Container(
                            color: Palette.sky.withOpacity(0.15),
                          ),
                          AnimatedBuilder(
                            animation: _scanAnimationController,
                            builder: (context, child) {
                              return Positioned(
                                top: _scanAnimationController.value * 350,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Palette.sky,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Palette.sky.withOpacity(0.8),
                                        blurRadius: 12,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          // Spinning loading indicator
                          Positioned(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Palette.sky.withOpacity(0.5)),
                                boxShadow: Palette.cardShadow,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Palette.sky,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'SCANNING FOR ITEMS...',
                                    style: AppTextStyles.label(13, color: Palette.sky),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Scanned items output tag view
              if (_detectedObjects.isNotEmpty && !_isScanning) ...[
                Text(
                  'ITEMS DETECTED IN YOUR ROOM:',
                  style: AppTextStyles.label(12, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _detectedObjects.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Palette.sky.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Palette.sky.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Palette.sky, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              _detectedObjects[index].toUpperCase(),
                              style: AppTextStyles.label(12, color: Palette.skyDark),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: _roomImageBytes == null ? 'SCAN ROOM' : 'RE-SCAN',
                      bg: Palette.sky,
                      fg: Colors.white,
                      onTap: _isScanning ? null : _captureRoom,
                    ),
                  ),
                  if (_roomImageBytes != null && _detectedObjects.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: PillButton(
                        label: 'FINISH SCAN',
                        bg: Palette.successAlt,
                        fg: Colors.white,
                        onTap: _isScanning ? null : _finishScanAndStartQuest,
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
