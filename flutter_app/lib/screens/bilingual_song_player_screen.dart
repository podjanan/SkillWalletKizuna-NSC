import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../l10n/app_localizations.dart';
import '../models/bilingual_song_model.dart';
import '../services/api_config.dart';
import '../theme/app_text_styles.dart';
import '../theme/palette.dart';
import '../widgets/sticky_bottom_button.dart';
import 'activities/detail/bilingual_song_evaluation_screen.dart';
import 'activities/gameplay/sing_together_camera_screen.dart';

class BilingualSongPlayerScreen extends StatefulWidget {
  final BilingualSongModel song;
  final List<String> extraChildIds;

  const BilingualSongPlayerScreen({
    super.key,
    required this.song,
    this.extraChildIds = const [],
  });

  @override
  State<BilingualSongPlayerScreen> createState() =>
      _BilingualSongPlayerScreenState();
}

class _BilingualSongPlayerScreenState extends State<BilingualSongPlayerScreen>
    with WidgetsBindingObserver {
  late AudioPlayer _audioPlayer;
  late Future<void> _audioInitFuture;
  late final StreamSubscription<PlayerState> _audioStateSubscription;
  late final StreamSubscription<Duration> _audioDurationSubscription;
  late final StreamSubscription<Duration> _audioPositionSubscription;
  late final StreamSubscription<void> _audioCompleteSubscription;
  bool _isPlaying = false;
  bool _isPlaybackBusy = false;
  bool _isCompletingPlayback = false;
  bool _hasCompletedPlayback = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Duration _lastRenderedPosition = Duration.zero;
  final ValueNotifier<Duration> _positionNotifier =
      ValueNotifier<Duration>(Duration.zero);
  VideoPlayerController? _danceVideoController;
  bool _danceVideoReady = false;
  bool _danceVideoFailed = false;
  Future<void>? _danceInitialization;
  Future<void>? _danceRelease;
  int _dancePlayerGeneration = 0;
  bool _showDanceVideo = true;

  // Media Evidence Capture State
  String? _videoPath;
  String? _imagePath;

  // Toggle for Parent Guitar Chords View
  bool _showGuitarChords = true;
  bool _showMediaSection = false;
  bool _showVocabularyBar = true;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTime = DateTime.now();
    _audioPlayer = AudioPlayer();

    _audioStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    _audioDurationSubscription =
        _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() => _duration = newDuration);
      }
    });

    _audioPositionSubscription =
        _audioPlayer.onPositionChanged.listen((newPosition) {
      final shouldRender =
          (newPosition - _lastRenderedPosition).inMilliseconds.abs() >= 250;
      _position = newPosition;
      if (shouldRender) {
        _lastRenderedPosition = newPosition;
        _positionNotifier.value = newPosition;
      }
    });

    _audioCompleteSubscription =
        _audioPlayer.onPlayerComplete.listen((_) => _handlePlaybackComplete());

    _audioInitFuture = _initAudio();
    _initDanceVideo();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _pausePlayback();
    }
  }

  Future<void> _handleMediaSelection({required bool isVideo}) async {
    try {
      if (isVideo) {
        // Open In-App Studio Camera Screen with Live Audio Playback & Karaoke Overlay
        await _audioPlayer.pause();
        // Free the decoder before the camera asks Android for its encoder and
        // preview surface. This is especially important on low-memory devices.
        await _releaseDanceVideo();
        if (!mounted) return;
        final String? videoPath = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => SingTogetherCameraScreen(
              song: widget.song,
              audioPlayer: _audioPlayer,
            ),
          ),
        );

        if (videoPath != null && videoPath.isNotEmpty && mounted) {
          setState(() {
            _videoPath = videoPath;
          });
        }
      } else {
        final ImagePicker picker = ImagePicker();
        final XFile? pickedFile =
            await picker.pickImage(source: ImageSource.camera);

        if (pickedFile != null && mounted) {
          setState(() {
            _imagePath = pickedFile.path;
          });
        }
      }
    } catch (e) {
      debugPrint('Media selection error: $e');
    } finally {
      if (isVideo && mounted && _showDanceVideo) {
        await _initDanceVideo();
      }
    }
  }

  void _handleFinish() {
    _audioPlayer.pause();
    _danceVideoController?.pause();
    final timeSpent = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BilingualSongEvaluationScreen(
          song: widget.song,
          extraChildIds: widget.extraChildIds,
          timeSpentSeconds: timeSpent,
          videoPath: _videoPath,
          imagePath: _imagePath,
        ),
      ),
    );
  }

  String _resolvePlayableUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return '';
    }
    final trimmed = rawUrl.trim();
    return ApiConfig.resolveAssetUrl(trimmed);
  }

  Future<void> _initAudio() async {
    final playUrl = _resolvePlayableUrl(widget.song.audioUrl);
    if (playUrl.isEmpty) return;
    try {
      // Keep the prepared source after completion. Releasing it here forces a
      // second network load on every replay and can leave Android's media
      // decoder in a transient state while the dance video is also seeking.
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setSourceUrl(playUrl);
    } catch (e) {
      debugPrint('Audio load error: $e');
    }
  }

  Future<void> _initDanceVideo() async {
    final pendingRelease = _danceRelease;
    if (pendingRelease != null) await pendingRelease;
    if (!mounted || !_showDanceVideo) return;

    final videoUrl = _resolvePlayableUrl(widget.song.danceVideoUrl);
    if (videoUrl.isEmpty || _danceVideoController != null) return;
    final pendingInitialization = _danceInitialization;
    if (pendingInitialization != null) return pendingInitialization;

    final generation = _dancePlayerGeneration;
    late final Future<void> initialization;
    initialization = _createDanceVideo(videoUrl, generation).whenComplete(() {
      if (identical(_danceInitialization, initialization)) {
        _danceInitialization = null;
      }
    });
    _danceInitialization = initialization;
    return initialization;
  }

  Future<void> _createDanceVideo(String videoUrl, int generation) async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    try {
      await controller.initialize().timeout(const Duration(seconds: 20));
      await controller.setVolume(0);
      await controller.setLooping(true);
      if (!mounted ||
          generation != _dancePlayerGeneration ||
          !_showDanceVideo) {
        await controller.dispose();
        return;
      }
      _danceVideoController = controller;
      controller.addListener(() => _handleDanceVideoError(controller));
      _danceVideoReady = true;
      _danceVideoFailed = false;
      await controller.seekTo(_dancePositionForAudio(_position, controller));
      if (_isPlaying) {
        await controller.play();
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Dance video load error: $e');
      if (identical(_danceVideoController, controller)) {
        _danceVideoController = null;
        _danceVideoReady = false;
      }
      try {
        await controller.dispose();
      } catch (_) {}
      if (mounted && generation == _dancePlayerGeneration) {
        setState(() => _danceVideoFailed = true);
      }
    }
  }

  void _handleDanceVideoError(VideoPlayerController controller) {
    if (!mounted ||
        !identical(_danceVideoController, controller) ||
        _danceVideoFailed ||
        !controller.value.hasError) {
      return;
    }
    debugPrint(
        'Dance video playback error: ${controller.value.errorDescription}');
    setState(() => _danceVideoFailed = true);
  }

  Future<void> _releaseDanceVideo() async {
    final pendingRelease = _danceRelease;
    if (pendingRelease != null) return pendingRelease;

    late final Future<void> release;
    release = _performDanceVideoRelease().whenComplete(() {
      if (identical(_danceRelease, release)) {
        _danceRelease = null;
      }
    });
    _danceRelease = release;
    return release;
  }

  Future<void> _performDanceVideoRelease() async {
    _dancePlayerGeneration++;
    final initialization = _danceInitialization;
    final controller = _danceVideoController;
    _danceVideoController = null;
    _danceVideoReady = false;
    if (mounted) setState(() {});
    // Let an in-flight open observe the invalidated generation and clean up
    // its own player before a replacement player is created.
    if (initialization != null) {
      try {
        await initialization;
      } catch (_) {}
    }
    if (controller != null) {
      try {
        await controller.pause();
      } catch (e) {
        debugPrint('Dance video pause during release error: $e');
      }
      try {
        await controller.dispose();
      } catch (e) {
        debugPrint('Dance video dispose error: $e');
      }
    }
  }

  Future<void> _hideDanceVideo() async {
    _showDanceVideo = false;
    await _releaseDanceVideo();
  }

  Future<void> _showDanceVideoPanel() async {
    if (!mounted) return;
    setState(() {
      _showDanceVideo = true;
      _danceVideoFailed = false;
    });
    await _initDanceVideo();
  }

  Future<void> _openEvidenceVideo() async {
    final videoPath = _videoPath;
    if (videoPath == null || videoPath.isEmpty || _isPlaybackBusy) return;
    _isPlaybackBusy = true;
    try {
      await _pausePlayback();
      // Android devices commonly expose only one reliable hardware decoder.
      // Release the dance video before opening the recorded evidence player.
      await _releaseDanceVideo();
      if (!mounted) return;
      final evidenceRelease = Completer<void>();
      await showDialog<void>(
        context: context,
        builder: (_) => BilingualVideoPlayerDialog(
          videoPath: videoPath,
          releaseCompleter: evidenceRelease,
        ),
      );
      // Do not allocate the dance-video decoder until the evidence video's
      // native surface has been released completely.
      try {
        await evidenceRelease.future.timeout(const Duration(seconds: 22));
      } catch (e) {
        debugPrint('Evidence video release timeout: $e');
      }
    } finally {
      _isPlaybackBusy = false;
      if (mounted && _showDanceVideo) {
        await _initDanceVideo();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioStateSubscription.cancel();
    _audioDurationSubscription.cancel();
    _audioPositionSubscription.cancel();
    _audioCompleteSubscription.cancel();
    _positionNotifier.dispose();
    _audioPlayer.dispose();
    _dancePlayerGeneration++;
    final danceVideoController = _danceVideoController;
    _danceVideoController = null;
    unawaited(danceVideoController?.dispose());
    super.dispose();
  }

  Future<void> _pausePlayback() async {
    try {
      await Future.wait<void>([
        _audioPlayer.pause(),
        if (_danceVideoController != null) _danceVideoController!.pause(),
      ]);
    } catch (e) {
      debugPrint('Pause playback error: $e');
    } finally {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  Future<void> _seekPlayback(Duration position) async {
    final safePosition = position < Duration.zero
        ? Duration.zero
        : (_duration > Duration.zero && position > _duration
            ? _duration
            : position);
    _position = safePosition;
    _lastRenderedPosition = safePosition;
    _positionNotifier.value = safePosition;
    await Future.wait<void>([
      _audioPlayer.seek(safePosition),
      if (_danceVideoReady && _danceVideoController != null)
        _danceVideoController!.seekTo(_dancePositionForAudio(
          safePosition,
          _danceVideoController!,
        )),
    ]);
  }

  Duration _dancePositionForAudio(
    Duration audioPosition,
    VideoPlayerController controller,
  ) {
    final videoDuration = controller.value.duration;
    if (videoDuration <= Duration.zero) return Duration.zero;
    return Duration(
      microseconds: audioPosition.inMicroseconds % videoDuration.inMicroseconds,
    );
  }

  Future<void> _handlePlaybackComplete() async {
    if (_isCompletingPlayback) return;
    _isCompletingPlayback = true;
    try {
      final controller = _danceVideoController;
      if (controller != null) {
        await controller.pause();
        await controller.seekTo(Duration.zero);
      }
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _hasCompletedPlayback = true;
          _position = Duration.zero;
          _lastRenderedPosition = Duration.zero;
        });
        _positionNotifier.value = Duration.zero;
      }
    } catch (e) {
      debugPrint('Playback completion reset error: $e');
    } finally {
      _isCompletingPlayback = false;
    }
  }

  Future<void> _togglePlayPause() async {
    final playUrl = _resolvePlayableUrl(widget.song.audioUrl);
    debugPrint('Toggling audio play/pause for URL: $playUrl');
    if (playUrl.isEmpty || _isPlaybackBusy || _isCompletingPlayback) return;

    _isPlaybackBusy = true;
    try {
      await _audioInitFuture;
      if (_isPlaying) {
        await _pausePlayback();
      } else {
        final isAtEnd = _duration > Duration.zero &&
            _position >= _duration - const Duration(milliseconds: 500);
        if (_hasCompletedPlayback || isAtEnd) {
          await _seekPlayback(Duration.zero);
          _hasCompletedPlayback = false;
        }
        if (mounted) setState(() => _isPlaying = true);

        await Future.wait<void>([
          _audioPlayer.resume(),
          if (_danceVideoReady && _danceVideoController != null)
            _danceVideoController!.play(),
        ]);
      }
    } catch (e) {
      debugPrint('Audio play exception: $e');
      await _danceVideoController?.pause();
      if (mounted) setState(() => _isPlaying = false);
    } finally {
      _isPlaybackBusy = false;
    }
  }

  Widget _buildAudioControls() {
    return ValueListenableBuilder<Duration>(
      valueListenable: _positionNotifier,
      builder: (context, renderedPosition, _) => Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Palette.sky,
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: Colors.amber,
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              min: 0,
              max: _duration.inSeconds.toDouble() > 0
                  ? _duration.inSeconds.toDouble()
                  : 100,
              value: renderedPosition.inSeconds.toDouble().clamp(
                    0,
                    _duration.inSeconds.toDouble() > 0
                        ? _duration.inSeconds.toDouble()
                        : 100,
                  ),
              // Position seeking is intentionally disabled on this screen.
              // Keeping playback linear avoids overlapping native seek
              // commands while the short dance clip is looping on Android.
              onChanged: null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDuration(renderedPosition),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
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
                          color: Colors.amber.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
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
                Expanded(
                  child: Text(
                    _formatDuration(_duration),
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDanceVideoPanel(AppLocalizations l) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.black,
          child: _danceVideoFailed
              ? Center(
                  child: IconButton(
                    tooltip: l.sing_retryVideo,
                    onPressed: () async {
                      setState(() => _danceVideoFailed = false);
                      await _releaseDanceVideo();
                      await _initDanceVideo();
                    },
                    icon: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 32),
                  ),
                )
              : _danceVideoController == null
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        RepaintBoundary(
                          child: VideoPlayer(
                            _danceVideoController!,
                            key: const ValueKey('sing-dance-video'),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton.filledTonal(
                            tooltip: l.sing_hideVideo,
                            visualDensity: VisualDensity.compact,
                            onPressed: _hideDanceVideo,
                            icon: const Icon(Icons.visibility_off_rounded,
                                size: 18),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0x99000000),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l.sing_videoSyncHint,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
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
    final l = AppLocalizations.of(context)!;
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCEB), // Warm Cream Voice Quest Theme
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
                          isThai && widget.song.titleTh.isNotEmpty
                              ? widget.song.titleTh
                              : widget.song.titleEn,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
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
                      size: 24,
                    ),
                    tooltip: _showGuitarChords
                        ? l.sing_hideChords
                        : l.sing_showChords,
                    onPressed: () {
                      setState(() {
                        _showGuitarChords = !_showGuitarChords;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _showGuitarChords
                                ? '🎸 ${l.sing_chordsShown}'
                                : '🙈 ${l.sing_chordsHidden}',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Music Player Control Card Container
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: Palette.cardShadow,
              ),
              child: Column(
                children: [
                  if (widget.song.danceVideoUrl?.trim().isNotEmpty == true) ...[
                    if (_showDanceVideo) _buildDanceVideoPanel(l),
                    if (_showDanceVideo)
                      const SizedBox(height: 10)
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _showDanceVideoPanel,
                          icon: const Icon(Icons.visibility_rounded, size: 18),
                          label: Text(l.sing_showVideo),
                        ),
                      ),
                  ],

                  // Song controls sit below the dance video.
                  _buildAudioControls(),
                  const SizedBox(height: 10),

                  // Toggle Bar for Media Options (Collapsible to maximize Lyrics View)
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showMediaSection = !_showMediaSection),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _showMediaSection
                            ? Palette.sky.withValues(alpha: 0.12)
                            : Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _showMediaSection
                              ? Palette.sky.withValues(alpha: 0.4)
                              : Colors.purple.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.photo_camera_rounded,
                                size: 18,
                                color: _showMediaSection
                                    ? Palette.sky
                                    : Colors.purple,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                (_imagePath != null || _videoPath != null)
                                    ? l.sing_evidenceAttached
                                    : l.sing_captureEvidence,
                                style: AppTextStyles.label(13,
                                    color: _showMediaSection
                                        ? Palette.sky
                                        : Colors.purple.shade800),
                              ),
                              if (_imagePath != null || _videoPath != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Palette.success,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('✓ ${l.sing_attached}',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          Icon(
                            _showMediaSection
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 22,
                            color:
                                _showMediaSection ? Palette.sky : Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Collapsible Media Capture Buttons & Preview Row
                  if (_showMediaSection) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _handleMediaSelection(isVideo: true),
                            icon: const Icon(Icons.videocam_rounded,
                                size: 18, color: Palette.sky),
                            label: Text(l.sing_recordVideo,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Palette.sky)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: Palette.sky.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _handleMediaSelection(isVideo: false),
                            icon: const Icon(Icons.camera_alt_rounded,
                                size: 18, color: Colors.amber),
                            label: Text(l.sing_takePhoto,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: Colors.amber.withValues(alpha: 0.8)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_imagePath != null || _videoPath != null)
                      Row(
                        children: [
                          if (_imagePath != null)
                            Expanded(
                              child: Container(
                                height: 130,
                                margin: EdgeInsets.only(
                                    top: 10,
                                    right: (_videoPath != null) ? 6 : 0),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Palette.sky.withValues(alpha: 0.5),
                                      width: 1.5),
                                  boxShadow: Palette.cardShadow,
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: SizedBox.expand(
                                        child: kIsWeb
                                            ? Image.network(_imagePath!,
                                                fit: BoxFit.cover)
                                            : Image.file(File(_imagePath!),
                                                fit: BoxFit.cover),
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () =>
                                            setState(() => _imagePath = null),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Color(0xB3000000),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close_rounded,
                                              size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_videoPath != null)
                            Expanded(
                              child: Container(
                                height: 130,
                                margin: EdgeInsets.only(
                                    top: 10,
                                    left: (_imagePath != null) ? 6 : 0),
                                decoration: BoxDecoration(
                                  color: const Color(0xDD000000),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Palette.sky.withValues(alpha: 0.5),
                                      width: 1.5),
                                  boxShadow: Palette.cardShadow,
                                ),
                                child: Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: _openEvidenceVideo,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Container(
                                          color: const Color(0xDD000000),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                    Icons
                                                        .play_circle_fill_rounded,
                                                    size: 40,
                                                    color: Palette.sky),
                                                const SizedBox(height: 4),
                                                Text(
                                                  l.sing_openVideo,
                                                  style: AppTextStyles.label(12,
                                                      color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () =>
                                            setState(() => _videoPath = null),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Color(0xB3000000),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close_rounded,
                                              size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Lyrics & Guitar Chords List
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: widget.song.lyrics.length,
                itemBuilder: (context, index) {
                  final line = widget.song.lyrics[index];
                  final isSectionTag = line.lineEn.trim().startsWith('[');
                  final isKeyTag = line.lineEn.toLowerCase().contains('[key');

                  if (isSectionTag) {
                    return Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isKeyTag
                            ? Colors.amber.shade100
                            : Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isKeyTag
                              ? Colors.amber.shade400
                              : Colors.purple.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isKeyTag
                                ? Icons.key_rounded
                                : Icons.library_music_rounded,
                            size: 18,
                            color: isKeyTag ? Colors.brown : Colors.purple,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            line.lineEn,
                            style: TextStyle(
                              fontSize: isKeyTag ? 15 : 14,
                              fontWeight: FontWeight.w900,
                              color: isKeyTag
                                  ? Colors.brown
                                  : Colors.purple.shade800,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: Palette.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Guitar Chord Badge (Toggleable for parents if chord exists)
                        if (_showGuitarChords && line.chord.trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.music_note_rounded,
                                    size: 13, color: Colors.brown),
                                const SizedBox(width: 4),
                                Text(
                                  line.chord,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.brown,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Combined Rhythmic Sung Lyrics Line (e.g. "Sing! Sing! (แปล - ว่า - ร้อง - เพลง!)")
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: line.lineEn,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),
                              if (line.lineTh.isNotEmpty) ...[
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: line.lineTh,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Target Vocabulary Cards Bar (Bottom Sheet style)
            if (widget.song.targetWords.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_rounded,
                                size: 18, color: Colors.amber),
                            const SizedBox(width: 6),
                            Text(
                              l.sing_songVocabulary,
                              style: AppTextStyles.label(13,
                                  color: Colors.black87),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => setState(
                              () => _showVocabularyBar = !_showVocabularyBar),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _showVocabularyBar
                                  ? Icons.keyboard_arrow_down_rounded
                                  : Icons.keyboard_arrow_up_rounded,
                              size: 18,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showVocabularyBar) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.song.targetWords.length,
                          itemBuilder: (context, index) {
                            final word = widget.song.targetWords[index];
                            return GestureDetector(
                              onTap: () {
                                _showWordDialog(context, word);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Palette.sky.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color:
                                          Palette.sky.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        size: 16, color: Palette.sky),
                                    const SizedBox(width: 6),
                                    Text(
                                      word.word,
                                      style: AppTextStyles.label(13,
                                          color: Palette.sky),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: StickyBottomButton(
        label: AppLocalizations.of(context)!.common_finish,
        onPressed: _handleFinish,
        color: Palette.success,
      ),
    );
  }

  void _showWordDialog(BuildContext context, TargetWordModel word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.translate_rounded, color: Palette.sky),
            const SizedBox(width: 8),
            Text(word.word,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (word.phonetic != null && word.phonetic!.isNotEmpty)
              Text(
                AppLocalizations.of(context)!
                    .sing_pronunciation(word.phonetic!),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.sing_translation(word.thaiMeaning),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.common_ok,
                style: const TextStyle(
                    color: Palette.sky, fontWeight: FontWeight.bold)),
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

class BilingualVideoPlayerDialog extends StatefulWidget {
  final String videoPath;
  final Completer<void>? releaseCompleter;

  const BilingualVideoPlayerDialog({
    super.key,
    required this.videoPath,
    this.releaseCompleter,
  });

  @override
  State<BilingualVideoPlayerDialog> createState() =>
      _BilingualVideoPlayerDialogState();
}

class _BilingualVideoPlayerDialogState
    extends State<BilingualVideoPlayerDialog> {
  late final VideoPlayerController _controller;
  late final Future<void> _openFuture;

  @override
  void initState() {
    super.initState();
    _controller = kIsWeb
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoPath))
        : VideoPlayerController.file(File(widget.videoPath));
    _openFuture = _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    await _controller.initialize().timeout(const Duration(seconds: 20));
    if (!mounted) return;
    await _controller.setLooping(false);
    if (!mounted) return;
    await _controller.play();
  }

  Future<void> _toggleVideo() async {
    if (!_controller.value.isInitialized) return;
    if (_controller.value.isPlaying) {
      await _controller.pause();
      return;
    }
    final duration = _controller.value.duration;
    final position = _controller.value.position;
    if (duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 200)) {
      await _controller.seekTo(Duration.zero);
    }
    await _controller.play();
  }

  @override
  void dispose() {
    unawaited(_disposeController());
    super.dispose();
  }

  Future<void> _disposeController() async {
    try {
      await _openFuture;
    } catch (_) {
      // Initialization errors are rendered by FutureBuilder.
    }
    try {
      await _controller.dispose();
    } finally {
      final completer = widget.releaseCompleter;
      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              FutureBuilder<void>(
                future: _openFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: Colors.white70, size: 48),
                    );
                  }
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleVideo,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        VideoPlayer(_controller),
                        ValueListenableBuilder<VideoPlayerValue>(
                          valueListenable: _controller,
                          builder: (context, value, _) => Center(
                            child: AnimatedOpacity(
                              opacity: value.isPlaying ? 0 : 1,
                              duration: const Duration(milliseconds: 150),
                              child: const Icon(
                                Icons.play_circle_fill_rounded,
                                color: Colors.white,
                                size: 58,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: VideoProgressIndicator(
                            _controller,
                            allowScrubbing: false,
                            colors: const VideoProgressColors(
                              playedColor: Palette.sky,
                              bufferedColor: Colors.white54,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xB3000000),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
