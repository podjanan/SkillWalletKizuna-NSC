// lib/screens/activities/gameplay/sing_together_camera_screen.dart

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/bilingual_song_model.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/palette.dart';

class SingTogetherCameraScreen extends StatefulWidget {
  final BilingualSongModel song;
  final AudioPlayer audioPlayer;

  const SingTogetherCameraScreen({
    super.key,
    required this.song,
    required this.audioPlayer,
  });

  @override
  State<SingTogetherCameraScreen> createState() =>
      _SingTogetherCameraScreenState();
}

class _SingTogetherCameraScreenState extends State<SingTogetherCameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  bool _isRecording = false;
  bool _isMuted = false;
  int _currentLyricIndex = 0;

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    widget.audioPlayer.setVolume(_isMuted ? 0.0 : 1.0);
  }

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // Default to front camera if available
        int frontIdx = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
        _selectedCameraIndex = frontIdx != -1 ? frontIdx : 0;
        await _setupController(_cameras[_selectedCameraIndex]);
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _setupController(CameraDescription cameraDescription) async {
    final prevController = _cameraController;
    final controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: true, // Captures mic audio & singing into the recorded video file
    );

    await prevController?.dispose();

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _cameraController = controller;
        });
      }
    } catch (e) {
      debugPrint('Setup controller error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isRecording) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() => _isInitializing = true);
    await _setupController(_cameras[_selectedCameraIndex]);
    if (mounted) setState(() => _isInitializing = false);
  }

  Future<void> _toggleRecording() async {
    if (_cameraController == null) {
      // Fallback capture for devices without native camera controller
      try {
        final picker = ImagePicker();
        await widget.audioPlayer.seek(Duration.zero);
        await widget.audioPlayer.resume();

        final XFile? file = await picker.pickVideo(source: ImageSource.camera);
        await widget.audioPlayer.pause();

        if (file != null && mounted) {
          Navigator.pop(context, file.path);
        }
      } catch (e) {
        debugPrint('Web camera picker error: $e');
      }
      return;
    }

    if (_isRecording) {
      // Stop recording
      try {
        final file = await _cameraController!.stopVideoRecording();
        await widget.audioPlayer.pause();
        if (mounted) {
          setState(() => _isRecording = false);
          Navigator.pop(context, file.path);
        }
      } catch (e) {
        debugPrint('Stop video recording error: $e');
      }
    } else {
      // Start recording
      try {
        await _cameraController!.startVideoRecording();
        // Set volume according to mute toggle & play from beginning
        await widget.audioPlayer.setVolume(_isMuted ? 0.0 : 1.0);
        await widget.audioPlayer.seek(Duration.zero);
        await widget.audioPlayer.resume();

        if (mounted) {
          setState(() => _isRecording = true);
        }
      } catch (e) {
        debugPrint('Start video recording error: $e');
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLyric = (widget.song.lyrics.isNotEmpty &&
            _currentLyricIndex < widget.song.lyrics.length)
        ? widget.song.lyrics[_currentLyricIndex]
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Camera Live Viewport (Responsive BoxFit.cover to fit full screen without squeezing)
            Positioned.fill(
              child: _isInitializing
                  ? const Center(
                      child: CircularProgressIndicator(color: Palette.sky),
                    )
                  : (_cameraController != null &&
                          _cameraController!.value.isInitialized)
                      ? ClipRect(
                          child: SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _cameraController!.value.previewSize?.height ?? MediaQuery.of(context).size.width,
                                height: _cameraController!.value.previewSize?.width ?? MediaQuery.of(context).size.height,
                                child: CameraPreview(_cameraController!),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.videocam_rounded,
                                  size: 64, color: Colors.white70),
                              const SizedBox(height: 12),
                              Text(
                                'กำลังเตรียมกล้องในแอป...',
                                style: AppTextStyles.body(14,
                                    color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
            ),

            // 2. Top Header Bar (Responsive Layout with 0% Overflow)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Song Title Badge
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.music_note,
                              color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.song.titleEn,
                              style: AppTextStyles.label(12, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // BGM Mute / Unmute Button
                  GestureDetector(
                    onTap: _toggleMute,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isMuted ? Colors.red.shade800 : Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  // Front / Rear Camera Switch Button
                  if (_cameras.length > 1 && !_isRecording) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _switchCamera,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cameraswitch,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 3. Lyrics Karaoke Overlay Banner
            if (currentLyric != null)
              Positioned(
                top: 80,
                left: 20,
                right: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        currentLyric.lineEn,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (currentLyric.lineTh.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          currentLyric.lineTh,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber.shade300,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // 4. Bottom Shutter Record Button & Controls
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  if (_isRecording)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'กำลังอัดวิดีโอพร้อมเพลง...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _isRecording ? Colors.red : Colors.red.shade600,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.5),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.videocam,
                        color: Colors.white,
                        size: 36,
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
