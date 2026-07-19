import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'space_adventure_quest_screen.dart';
import '../../../../models/activity.dart';
import '../../../../services/space_adventure_service.dart';
import '../../../../services/draft_service.dart';
import '../../../../providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../../../../services/api_config.dart';
import '../../../../theme/palette.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../widgets/ui.dart';
import '../../../../widgets/game_activity_cover.dart';

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
  bool _isLoadingAreas = true;
  bool _usePresetMode = true;
  List<String> _detectedObjects = [];
  List<SpaceAdventureArea> _areas = [];
  String? _scanError;
  Map<String, dynamic> _gameSettings = {'scorePerItem': 10, 'timerLimit': 60, 'maxItems': 5};
  Activity? _activity;

  bool _settingsLoaded = false;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _loadAreas();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_settingsLoaded) return;
    final activity = ModalRoute.of(context)?.settings.arguments as Activity?;
    if (activity != null) {
      _activity = activity;
      _settingsLoaded = true;
      int timerLimit = 60;
      int scorePerItem = 10;
      int maxItems = 5;
      if (activity.segments is Map) {
        final map = activity.segments as Map;
        timerLimit = int.tryParse(map['timeLimit']?.toString() ?? '60') ?? 60;
        scorePerItem = int.tryParse(map['scorePerItem']?.toString() ?? '10') ?? 10;
        maxItems = int.tryParse(map['maxItems']?.toString() ?? '5') ?? 5;
      }
      if (mounted) {
        setState(() {
          _gameSettings = {
            'timerLimit': timerLimit,
            'scorePerItem': scorePerItem,
            'maxItems': maxItems,
          };
        });
      }
      await _checkAndRestoreDraft();
      return;
    }

    final settings = await _spaceService.getSettings();
    _settingsLoaded = true;
    if (mounted) {
      setState(() {
        _gameSettings = settings;
      });
    }
    await _checkAndRestoreDraft();
  }

  Future<void> _checkAndRestoreDraft() async {
    final childId = context.read<UserProvider>().currentChildId;
    if (childId == null) return;
    final draft = await DraftService.loadDraft(childId);
    final expectedActivityId = _activity?.id ?? 'space-adventure';
    if (draft != null &&
        draft['type'] == DraftService.typeSpaceAdventure &&
        draft['activityId'] == expectedActivityId) {
      final data = draft['data'] as Map<String, dynamic>? ?? {};
      final detectedObjects = List<String>.from(data['detectedObjects'] as List<dynamic>? ?? []);
      final completedItemsHistory = (data['completedItemsHistory'] as List<dynamic>? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (mounted && detectedObjects.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SpaceAdventureQuestScreen(
              targetObject: data['targetObject'] as String? ?? detectedObjects.first,
              timerLimit: data['timerLimit'] as int? ?? 60,
              scorePerItem: data['scorePerItem'] as int? ?? 10,
              detectedObjects: detectedObjects,
              currentScore: data['currentScore'] as int? ?? 0,
              currentIndex: data['currentIndex'] as int? ?? 1,
              totalItems: data['totalItems'] as int? ?? detectedObjects.length,
              completedItemsHistory: completedItemsHistory,
              activity: _activity,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    super.dispose();
  }

  Future<void> _captureRoom() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    Uint8List bytes;
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 65,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (image == null) return;

      bytes = await image.readAsBytes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open image picker: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _roomImageBytes = bytes;
      _isScanning = true;
      _detectedObjects = [];
      _scanError = null;
    });

    _scanAnimationController.repeat(reverse: true);

    try {
      final base64String = base64Encode(bytes);
      final result = await _spaceService.scanRoom(base64String);
      
      if (mounted) {
        setState(() {
          _detectedObjects = result.success ? result.objects : [];
          _scanError = result.success
              ? null
              : '${result.error ?? 'Scan failed.'}${(result.reason ?? '').isNotEmpty ? '\nReason: ${result.reason}' : ''}';
        });
        if (!result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_scanError ?? 'Scan failed.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
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

  Future<void> _loadAreas() async {
    final areas = await _spaceService.getAreas();
    if (mounted) {
      setState(() {
        _areas = areas;
        _isLoadingAreas = false;
      });
    }
  }

  Future<ImageSource?> _showImageSourceDialog() {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select image source',
          style: AppTextStyles.heading(18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Palette.success),
              title: Text(
                'Camera',
                style: AppTextStyles.body(14),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Palette.sky),
              title: Text(
                'Gallery',
                style: AppTextStyles.body(14),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
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

    _startQuestWithObjects(_detectedObjects);
  }

  Future<bool?> _showDeleteConfirmDialog(String item) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete Item?',
          style: AppTextStyles.heading(18),
        ),
        content: Text(
          'Are you sure you want to remove "${item.toUpperCase()}" from this quest?',
          style: AppTextStyles.body(14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.body(14, color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: AppTextStyles.body(14, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _startQuestWithObjects(List<String> objects) {
    final availableObjects = objects
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();

    if (availableObjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This area does not have any target items yet.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    availableObjects.shuffle();
    final maxLimit = _gameSettings['maxItems'] ?? 5;
    final limitedObjects = availableObjects.take(maxLimit).toList();
    final targetObject = limitedObjects.first;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpaceAdventureQuestScreen(
          targetObject: targetObject,
          timerLimit: _gameSettings['timerLimit'] ?? 60,
          scorePerItem: _gameSettings['scorePerItem'] ?? 10,
          detectedObjects: limitedObjects,
          currentScore: 0,
          currentIndex: 1,
          totalItems: limitedObjects.length,
          activity: _activity,
        ),
      ),
    );
  }

  Widget _areaPlaceholder() {
    return Container(
      width: 76,
      height: 76,
      color: Palette.sky.withOpacity(0.12),
      child: const Icon(Icons.meeting_room_outlined, color: Palette.sky, size: 34),
    );
  }

  Widget _modeButton({
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _isScanning ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? Palette.sky.withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? Palette.sky : Palette.divider,
              width: selected ? 2 : 1.5,
            ),
            boxShadow: selected ? Palette.softShadow : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? Palette.sky : Colors.black45, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label(
                        12,
                        color: selected ? Palette.skyDark : Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(10, color: Colors.black54),
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

  Widget _buildPresetAreaPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Palette.divider, width: 2),
        boxShadow: Palette.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose preset area',
            style: AppTextStyles.heading(18, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            'Use target items managed in Space Adventure CMS.',
            style: AppTextStyles.body(12, color: Colors.black54),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _isLoadingAreas
                ? const Center(child: CircularProgressIndicator(color: Palette.sky))
                : _areas.isEmpty
                    ? Center(
                        child: Text(
                          'No preset areas are available yet.\nPlease add one in Space Adventure CMS.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body(14, color: Palette.deepGrey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _areas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final area = _areas[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _startQuestWithObjects(area.items),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Palette.sky.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Palette.sky.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: area.imageUrl.isNotEmpty
                                        ? Image.network(
                                            ApiConfig.resolveAssetUrl(area.imageUrl),
                                            width: 76,
                                            height: 76,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _areaPlaceholder(),
                                          )
                                        : _areaPlaceholder(),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          area.name.toUpperCase(),
                                          style: AppTextStyles.label(14, color: Colors.black87),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          area.items.join(', '),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.body(12, color: Palette.deepGrey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.play_arrow_rounded, size: 24, color: Palette.sky),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
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
          'Space Adventure',
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
              // Intro banner - light card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: Palette.cardShadow,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GameActivityCover(
                          type: GameCoverType.spaceAdventure,
                          compact: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phase 1: Room scan',
                            style: AppTextStyles.label(13, color: Palette.sky),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Take a photo of your room to find quest items.',
                            style: AppTextStyles.body(12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  _modeButton(
                    selected: _usePresetMode,
                    icon: Icons.list_alt_rounded,
                    title: 'Use preset',
                    subtitle: 'CMS item list',
                    onTap: () => setState(() => _usePresetMode = true),
                  ),
                  const SizedBox(width: 12),
                  _modeButton(
                    selected: !_usePresetMode,
                    icon: Icons.center_focus_strong_rounded,
                    title: 'Scan room',
                    subtitle: 'Find items in photo',
                    onTap: () => setState(() => _usePresetMode = false),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Viewfinder / Room image container
              Expanded(
                child: _usePresetMode
                    ? _buildPresetAreaPanel()
                    : Container(
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
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
                                  'Scan your room',
                                  style: AppTextStyles.heading(18, color: Colors.black87),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tap below to take a photo',
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
                                    top: _scanAnimationController.value * constraints.maxHeight,
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
                                        'Scanning for items...',
                                        style: AppTextStyles.label(13, color: Palette.sky),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (!_usePresetMode && _scanError != null && !_isScanning) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _scanError!,
                          style: AppTextStyles.body(12, color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Scanned items output tag view
              if (!_usePresetMode && _detectedObjects.isNotEmpty && !_isScanning) ...[
                Text(
                  'Items detected:',
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline, color: Palette.sky, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              _detectedObjects[index].toUpperCase(),
                              style: AppTextStyles.label(12, color: Palette.skyDark),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () async {
                                final confirm = await _showDeleteConfirmDialog(_detectedObjects[index]);
                                if (confirm == true) {
                                  setState(() {
                                    _detectedObjects.removeAt(index);
                                  });
                                }
                              },
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (!_usePresetMode)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_roomImageBytes != null && _detectedObjects.isNotEmpty) ...[
                      GradientButton.success(
                        label: 'Start quest',
                        onTap: _isScanning ? null : _finishScanAndStartQuest,
                        fontSize: 15,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      const SizedBox(height: 12),
                    ],
                    GradientButton.primary(
                      label: _roomImageBytes == null ? 'Scan room' : 'Re-scan',
                      onTap: _isScanning ? null : _captureRoom,
                      fontSize: 14,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
