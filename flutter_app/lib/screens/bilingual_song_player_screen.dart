import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/web_video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/bilingual_song_model.dart';
import '../providers/user_provider.dart';
import '../routes/app_routes.dart';
import '../services/activity_service.dart';
import '../services/api_config.dart';
import '../theme/app_text_styles.dart';
import '../theme/palette.dart';
import '../widgets/child_avatar.dart';

import 'bilingual_songs_screen.dart';

class BilingualSongPlayerScreen extends StatefulWidget {
  final BilingualSongModel song;
  final List<ChildParticipant>? participatingChildren;

  const BilingualSongPlayerScreen({
    super.key,
    required this.song,
    this.participatingChildren,
  });

  @override
  State<BilingualSongPlayerScreen> createState() =>
      _BilingualSongPlayerScreenState();
}

class _BilingualSongPlayerScreenState
    extends State<BilingualSongPlayerScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Toggle for Parent Guitar Chords View
  bool _showGuitarChords = true;

  // Toggle for Parent Evaluation Panel Collapse/Expand
  bool _isEvaluationExpanded = true;

  // Media Capture & Score Submission
  final ActivityService _activityService = ActivityService();
  final ImagePicker _picker = ImagePicker();
  String? _capturedImagePath;
  String? _capturedVideoPath;
  final Map<String, int> _childScores = {};
  final Map<String, TextEditingController> _scoreTextControllers = {};
  bool _isSubmitting = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() => _duration = newDuration);
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() => _position = newPosition);
      }
    });

    _initAudio();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      if (widget.participatingChildren != null &&
          widget.participatingChildren!.isNotEmpty) {
        for (final child in widget.participatingChildren!) {
          _childScores[child.id] = 100;
          _scoreTextControllers[child.id] =
              TextEditingController(text: '100');
        }
      } else {
        final childId = context.read<UserProvider>().currentChildId;
        if (childId != null) {
          _childScores[childId] = 100;
          _scoreTextControllers[childId] =
              TextEditingController(text: '100');
        }
      }
    }
  }

  String _resolvePlayableUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return 'https://cdn1.suno.ai/04869079-f4cb-4dc1-9370-aef8294439c0.mp3';
    }
    final trimmed = rawUrl.trim();
    if (trimmed.contains('suno.com')) {
      return 'https://cdn1.suno.ai/04869079-f4cb-4dc1-9370-aef8294439c0.mp3';
    }
    return ApiConfig.resolveAssetUrl(trimmed);
  }

  Future<void> _initAudio() async {
    final playUrl = _resolvePlayableUrl(widget.song.audioUrl);
    try {
      await _audioPlayer.setSourceUrl(playUrl);
    } catch (e) {
      debugPrint('Audio load error: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    for (final controller in _scoreTextControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _togglePlayPause() async {
    final playUrl = _resolvePlayableUrl(widget.song.audioUrl);
    debugPrint('Toggling audio play/pause for URL: $playUrl');

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        if (mounted) setState(() => _isPlaying = false);
      } else {
        if (mounted) setState(() => _isPlaying = true);
        await _audioPlayer.setSourceUrl(playUrl);
        await _audioPlayer.resume();
      }
    } catch (e) {
      debugPrint('Audio play exception: $e');
      try {
        await _audioPlayer.play(UrlSource(
            'https://cdn1.suno.ai/04869079-f4cb-4dc1-9370-aef8294439c0.mp3'));
        if (mounted) setState(() => _isPlaying = true);
      } catch (err) {
        debugPrint('Fallback play failed: $err');
        if (mounted) setState(() => _isPlaying = false);
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (image != null) {
        setState(() {
          _capturedImagePath = image.path;
        });
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  Future<void> _recordVideo() async {
    try {
      final String? videoPath = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => InAppCameraRecorderSheet(
          onStartRecording: () async {
            // Reset song to 00:00 and start playing from beginning!
            final playUrl = _resolvePlayableUrl(widget.song.audioUrl);
            await _audioPlayer.setSourceUrl(playUrl);
            await _audioPlayer.seek(Duration.zero);
            await _audioPlayer.resume();
            if (mounted) setState(() => _isPlaying = true);
          },
          onStopRecording: () async {
            await _audioPlayer.pause();
            if (mounted) setState(() => _isPlaying = false);
          },
        ),
      );

      if (videoPath != null && videoPath.isNotEmpty) {
        setState(() {
          _capturedVideoPath = videoPath;
        });
        return;
      }
    } catch (e) {
      debugPrint('In-app camera fallback error: $e');
    }

    try {
      final XFile? video = await _picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(minutes: 3));
      if (video != null) {
        setState(() {
          _capturedVideoPath = video.path;
        });
      }
    } catch (e) {
      debugPrint('Error recording video fallback: $e');
    }
  }

  Future<void> _submitScoreAndFinish() async {
    if (_isSubmitting) return;

    final userProvider = context.read<UserProvider>();
    final childId = userProvider.currentChildId;
    if (childId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกโปรไฟล์เด็กก่อนบันทึกคะแนน')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await _audioPlayer.pause();

    final primaryScore = _childScores[childId] ?? 100;
    final activityId = widget.song.id;

    final evidence = {
      'type': 'sing_together',
      'songId': widget.song.id,
      'songTitle': widget.song.titleEn,
      'imagePath': _capturedImagePath,
      'videoPath': _capturedVideoPath,
      'childScores': _childScores,
    };

    try {
      final allChildIds = _childScores.keys.toList();

      await Future.wait(
        allChildIds.map(
          (cid) => _activityService.finalizeQuest(
            childId: cid,
            activityId: activityId,
            segmentResults: [],
            activityMaxScore: 100,
            evidence: evidence,
            parentScore: _childScores[cid] ?? 100,
            timeSpent: _position.inSeconds,
          ),
        ),
        eagerError: false,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.result,
        arguments: {
          'activityName': widget.song.titleEn,
          'totalScore': primaryScore,
          'scoreEarned': primaryScore,
          'timeSpend': _position.inSeconds,
          'evidence': evidence,
          'category': 'physical',
          'imagePath': _capturedImagePath,
          'videoPath': _capturedVideoPath,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final activeChildId = userProvider.currentChildId;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCEB), // Warm Cream Theme
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 24, color: Colors.black87),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Sing Together',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '🎵 ${widget.song.titleEn}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Palette.sky,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Guitar Chord Toggle Button
                  IconButton(
                    icon: Icon(
                      Icons.music_note_rounded,
                      color: _showGuitarChords ? Colors.amber : Colors.grey,
                      size: 26,
                    ),
                    tooltip: _showGuitarChords
                        ? 'ซ่อนคอร์ดกีต้าร์'
                        : 'แสดงคอร์ดกีต้าร์ผู้ปกครอง',
                    onPressed: () {
                      setState(() {
                        _showGuitarChords = !_showGuitarChords;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Music Player Control Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: Palette.cardShadow,
              ),
              child: Column(
                children: [
                  // Audio Playback Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Palette.sky,
                      inactiveTrackColor: Colors.grey.shade200,
                      thumbColor: Colors.amber,
                      trackHeight: 6,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 10),
                    ),
                    child: Slider(
                      min: 0,
                      max: _duration.inSeconds.toDouble() > 0
                          ? _duration.inSeconds.toDouble()
                          : 100,
                      value: _position.inSeconds.toDouble().clamp(
                            0,
                            _duration.inSeconds.toDouble() > 0
                                ? _duration.inSeconds.toDouble()
                                : 100,
                          ),
                      onChanged: (value) async {
                        final position = Duration(seconds: value.toInt());
                        await _audioPlayer.seek(position);
                      },
                    ),
                  ),

                  // Duration Labels & Camera Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                        style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.camera_alt_rounded,
                                color: Palette.sky),
                            onPressed: _takePhoto,
                            tooltip: 'ถ่ายรูปกิจกรรมคู่กัน',
                          ),
                          IconButton(
                            icon: const Icon(Icons.videocam_rounded,
                                color: Colors.deepOrange),
                            onPressed: _recordVideo,
                            tooltip: 'ถ่ายวิดีโอเต้นคู่กัน',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Play / Pause Button
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Lyrics List
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                itemCount: widget.song.lyrics.length,
                itemBuilder: (context, index) {
                  final line = widget.song.lyrics[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: Palette.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_showGuitarChords && line.chord.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '🎸 ${line.chord}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.brown,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        Text(
                          line.lineEn,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          line.lineTh,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Parent Evaluation & Score Submission Container (Collapsible)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Collapse / Expand Toggle Bar Header
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isEvaluationExpanded = !_isEvaluationExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Palette.sky.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: Palette.sky,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isEvaluationExpanded
                                      ? 'ประเมินคะแนน & บันทึกผลงาน'
                                      : 'ประเมินคะแนน (แตะเพื่อเปิด)',
                                  style: AppTextStyles.label(14,
                                      color: Colors.black87),
                                ),
                                if (!_isEvaluationExpanded)
                                  const Text(
                                    'แตะที่นี่เมื่อร้องเต้นเสร็จ เพื่อให้คะแนนเด็กๆ',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            _isEvaluationExpanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_up_rounded,
                            color: Palette.sky,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_isEvaluationExpanded) ...[
                    const Divider(height: 16),

                    // Captured Photo/Video Indicator & Preview Card
                    if (_capturedImagePath != null ||
                        _capturedVideoPath != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Palette.successAlt.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Palette.successAlt, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Palette.successAlt,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _capturedVideoPath != null
                                    ? Icons.videocam_rounded
                                    : Icons.photo_camera_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _capturedVideoPath != null
                                        ? 'บันทึกวิดีโอหลักฐานแล้ว 🎥'
                                        : 'บันทึกภาพถ่ายหลักฐานแล้ว 📸',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Palette.successAlt),
                                  ),
                                  const Text(
                                    'แตะเปิดดูตัวอย่างคลิป/รูปภาพ หรือลบใหม่ได้',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                if (_capturedVideoPath != null) {
                                  _previewCapturedMedia(
                                      isVideo: true,
                                      path: _capturedVideoPath!);
                                } else if (_capturedImagePath != null) {
                                  _previewCapturedMedia(
                                      isVideo: false,
                                      path: _capturedImagePath!);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Palette.successAlt),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.visibility_rounded,
                                        size: 14, color: Palette.successAlt),
                                    SizedBox(width: 4),
                                    Text(
                                      'เปิดดู',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Palette.successAlt),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // List of Child Score Rating Cards (Supports Multiple Children)
                    if (widget.participatingChildren != null &&
                        widget.participatingChildren!.isNotEmpty) ...[
                      ...widget.participatingChildren!.map(
                        (child) => _buildChildScoreCard(
                          childId: child.id,
                          childName: child.name,
                          photoUrl: child.photoUrl,
                        ),
                      ),
                    ] else if (activeChildId != null) ...[
                      _buildChildScoreCard(
                        childId: activeChildId,
                        childName: userProvider.currentChildName ?? 'Child',
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Complete Activity Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitScoreAndFinish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.successAlt,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 3,
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.stars_rounded,
                                      color: Colors.white, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'บันทึกคะแนน & ดูสรุปผลงาน (Share)',
                                    style: AppTextStyles.label(15,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _previewCapturedMedia({required bool isVideo, required String path}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isVideo ? '🎥 พรีวิววิดีโอหลักฐาน' : '📸 พรีวิวรูปภาพหลักฐาน',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 320),
                  width: double.infinity,
                  color: Colors.black,
                  child: isVideo
                      ? WebVideoPlayerView(videoUrl: path)
                      : (kIsWeb || path.startsWith('blob:'))
                          ? Image.network(
                              path,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('📸 บันทึกรูปภาพเรียบร้อยแล้ว',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            )
                          : Image.file(
                              File(path),
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('📸 บันทึกรูปภาพเรียบร้อยแล้ว',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        if (isVideo) {
                          _capturedVideoPath = null;
                        } else {
                          _capturedImagePath = null;
                        }
                      });
                    },
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red),
                    label: const Text('ลบหลักฐานนี้',
                        style: TextStyle(color: Colors.red)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.sky,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('ตกลง',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildScoreCard({
    required String childId,
    required String childName,
    String? photoUrl,
  }) {
    final currentScore = _childScores[childId] ?? 100;
    final controller = _scoreTextControllers.putIfAbsent(
      childId,
      () => TextEditingController(text: '$currentScore'),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ChildAvatar(
                name: childName,
                photoUrl: photoUrl,
                radius: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  childName,
                  style: AppTextStyles.label(14, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // Editable Score Input Field (Type number manually, e.g. 52)
              Container(
                width: 88,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Palette.sky, width: 1.5),
                  boxShadow: Palette.softShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Palette.sky,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val.trim());
                          if (parsed != null) {
                            final clamped = parsed.clamp(0, 100);
                            setState(() {
                              _childScores[childId] = clamped;
                            });
                          }
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Text(
                        'คะแนน',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Slider synchronized with currentScore
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Palette.sky,
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: Palette.sky,
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: currentScore.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (val) {
                final intVal = val.toInt();
                setState(() {
                  _childScores[childId] = intVal;
                  controller.text = '$intVal';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class InAppCameraRecorderSheet extends StatefulWidget {
  final Future<void> Function()? onStartRecording;
  final Future<void> Function()? onStopRecording;

  const InAppCameraRecorderSheet({
    super.key,
    this.onStartRecording,
    this.onStopRecording,
  });

  @override
  State<InAppCameraRecorderSheet> createState() =>
      _InAppCameraRecorderSheetState();
}

class _InAppCameraRecorderSheetState
    extends State<InAppCameraRecorderSheet> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final frontIdx = _cameras.indexWhere(
            (c) => c.lensDirection == CameraLensDirection.front);
        _selectedCameraIndex = frontIdx != -1 ? frontIdx : 0;
        await _setupController(_cameras[_selectedCameraIndex]);
      }
    } catch (e) {
      debugPrint('InAppCamera init error: $e');
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _setupController(CameraDescription camera) async {
    await _controller?.dispose();
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: true,
    );
    _controller = controller;
    try {
      await controller.initialize();
    } catch (e) {
      debugPrint('Controller init error: $e');
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleCamera() async {
    if (_isRecording) return;
    if (_cameras.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'อุปกรณ์นี้มีกล้องเพียง 1 ตัว (บนมือถือจะสลับกล้องหน้า-หลังได้ปกติครับ)'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() => _isInitializing = true);
    await _setupController(_cameras[_selectedCameraIndex]);
    if (mounted) setState(() => _isInitializing = false);
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized || _isRecording) return;
    try {
      if (widget.onStartRecording != null) {
        await widget.onStartRecording!();
      }
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordSeconds++);
      });
    } catch (e) {
      debugPrint('Start recording error: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_isRecording) return;
    try {
      _timer?.cancel();
      if (widget.onStopRecording != null) {
        await widget.onStopRecording!();
      }
      final XFile videoFile = await _controller!.stopVideoRecording();
      setState(() => _isRecording = false);
      if (mounted) Navigator.pop(context, videoFile.path);
    } catch (e) {
      debugPrint('Stop recording error: $e');
      if (mounted) Navigator.pop(context, null);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  String _formatTimer(int totalSecs) {
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera Preview Viewfinder
            if (!_isInitializing &&
                _controller != null &&
                _controller!.value.isInitialized)
              Center(child: CameraPreview(_controller!))
            else
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Palette.sky),
                    SizedBox(height: 12),
                    Text(
                      'กำลังเปิดกล้องถ่ายเต้นคู่กัน...',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),

            // Top Control Overlay Bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close Button
                  CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context, null),
                    ),
                  ),

                  // Recording Timer Badge
                  if (_isRecording)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.fiber_manual_record,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'REC ${_formatTimer(_recordSeconds)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Flip Front/Back Camera Button
                  if (!_isRecording)
                    CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        tooltip: 'สลับกล้อง',
                        icon: const Icon(Icons.cameraswitch_rounded,
                            color: Colors.white),
                        onPressed: _toggleCamera,
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),

            // Bottom Shutter Controls
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    _isRecording
                        ? 'กำลังอัดวิดีโอพร้อมเพลง ♪ (แตะเพื่อหยุด)'
                        : 'แตะปุ่มแดงเพื่อเริ่มอัดวิดีโอคู่เพลง ♪',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius:
                              BorderRadius.circular(_isRecording ? 12 : 36),
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
    );
  }
}

class WebVideoPlayerView extends StatelessWidget {
  final String videoUrl;

  const WebVideoPlayerView({super.key, required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    return buildWebVideoPlayer(videoUrl);
  }
}
