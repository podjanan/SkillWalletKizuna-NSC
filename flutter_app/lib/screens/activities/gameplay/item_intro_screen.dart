import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as yp;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../../../providers/user_provider.dart';
import '../../../services/activity_service.dart';
import '../../../services/audio_evaluation_queue.dart';
import '../../../services/draft_service.dart';
import '../../../models/activity.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import '../../../utils/activity_l10n.dart';
import '../../../utils/youtube_helper.dart';
import 'activity_summary_screen.dart';

class ItemIntroScreen extends StatefulWidget {
  final Activity activity;
  const ItemIntroScreen({super.key, required this.activity});

  @override
  State<ItemIntroScreen> createState() => _ItemIntroScreenState();
}

class _ItemIntroScreenState extends State<ItemIntroScreen>
    with SingleTickerProviderStateMixin {
  // ----------------------------------------------------
  // 1. CONSTANTS & STATE
  // ----------------------------------------------------

  static const nextBlue = Color(0xFF1487FF);
  static const prevGrey = Color(0xFFD6D5D3);

  // 🎥 YouTube controller (ใช้ package youtube_player_iframe)
  yp.YoutubePlayerController? _ytController;

  // 🔊 สำหรับเล่นเสียงที่บันทึกเอง
  final ap.AudioPlayer _playbackPlayer = ap.AudioPlayer();

  // 🎙️ สำหรับอัดเสียง
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  String _recordedFilePath = '';
  BytesBuilder? _webBytesBuilder;
  StreamSubscription<List<int>>? _webAudioSub;

  // 🔔 Shake animation for record button (triggered when nav attempted during recording)
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  // ⏱️ Stopwatch สำหรับจับเวลาทำกิจกรรม
  final Stopwatch _activityStopwatch = Stopwatch();
  final List<String> _tempAudioFiles = []; // เก็บรายการไฟล์เสียงที่ต้องลบ

  // 🔄 Background evaluation queue (sequential, non-blocking)
  final AudioEvaluationQueue _evaluationQueue = AudioEvaluationQueue();

  // 📊 Shared notifiers — read by ActivitySummaryScreen via ValueListenable
  late final ValueNotifier<List<SegmentResult>> _resultsNotifier;
  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);

  String _youtubeVideoId = ''; // ID จาก URL

  late List<dynamic> _rawSegments;
  late final int totalSegments;

  String state = 'idle';
  int current = 1;
  int point = 0;

  late List<SegmentResult> _segmentResults;

  final ActivityService _activityService = ActivityService();
  String? _childId;
  bool _isPlayerReady = false;
  bool _isPlaybackPlaying = false; // สถานะ Playback

  @override
  void initState() {
    super.initState();

    // 0. Shake animation init
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);

    // 1. เตรียม Segment Data
    _rawSegments = (widget.activity.segments as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .where((segment) {
          final text = (segment['text'] as String?)?.trim() ?? '';
          return text.isNotEmpty && text != '[Music]';
        }).toList() ??
        [];
    totalSegments = _rawSegments.length;

    // 2. ตั้งค่า Segment Results
    _segmentResults = _rawSegments.asMap().entries.map((entry) {
      final segment = entry.value as Map<String, dynamic>;
      return SegmentResult(
        id: segment['id'] as String? ?? 'seg_${entry.key}',
        text: segment['text'] as String? ?? 'Placeholder',
        maxScore: 0,
      );
    }).toList();
    _resultsNotifier = ValueNotifier(List.from(_segmentResults));

    // 3. กำหนด YouTube Video ID
    if (widget.activity.videoUrl != null) {
      _youtubeVideoId =
          YouTubeHelper.extractVideoId(widget.activity.videoUrl!) ?? '';
    }

    // 4. สร้าง YouTube controller ถ้ามี videoId
    if (_youtubeVideoId.isNotEmpty) {
      _ytController = yp.YoutubePlayerController.fromVideoId(
        videoId: _youtubeVideoId,
        autoPlay: false,
        params: const yp.YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          origin: 'https://www.youtube-nocookie.com',
        ),
      )..listen((event) {
          // เซ็ตเป็น ready เมื่อ player อยู่ในสถานะ cued, playing, หรือ paused
          if (!_isPlayerReady &&
              (event.playerState == yp.PlayerState.cued ||
                  event.playerState == yp.PlayerState.playing ||
                  event.playerState == yp.PlayerState.paused)) {
            if (mounted) {
              setState(() {
                _isPlayerReady = true;
              });
              debugPrint('✅ YouTube Player Ready');
            }
          }
        });

      // เซ็ตเป็น ready ทันทีถ้า controller สร้างเสร็จแล้ว
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_isPlayerReady) {
          setState(() {
            _isPlayerReady = true;
          });
          debugPrint('✅ YouTube Player Ready (timeout)');
        }
      });
    }

    // 5. โหลด childId + restore draft
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _childId = context.read<UserProvider>().currentChildId;
      _restoreDraft();
    });

    // 6. Listener เมื่อไฟล์เสียงเล่นจบ
    _playbackPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() => _isPlaybackPlaying = false);
      }
    });

    // 7. เริ่มจับเวลากิจกรรม
    _activityStopwatch.start();
    debugPrint('⏱️ Activity timer started');
  }

  Future<void> _restoreDraft() async {
    if (_childId == null) return;
    final draft = await DraftService.loadDraft(_childId!);
    if (draft == null ||
        draft['type'] != DraftService.typeLanguage ||
        draft['activityId'] != widget.activity.id) {
      return;
    }
    final data = draft['data'] as Map<String, dynamic>? ?? {};
    if (!mounted) return;
    final savedCurrent = data['current'] as int? ?? 1;
    final savedSegments =
        (data['segmentResults'] as List<dynamic>?)
            ?.map((e) => SegmentResult.fromDraftJson(e as Map<String, dynamic>))
            .map((r) => r.status == SegmentStatus.processing
                ? r.copyWith(status: SegmentStatus.idle)
                : r)
            .toList() ??
        _segmentResults;
    setState(() {
      current = savedCurrent.clamp(1, totalSegments);
      _segmentResults
        ..clear()
        ..addAll(savedSegments);
      _resultsNotifier.value = List.from(_segmentResults);
      final r = _segmentResults[current - 1];
      state = switch (r.status) {
        SegmentStatus.done => 'reviewed',
        _ => 'idle',
      };
      point = r.maxScore;
    });
  }

  Future<void> _saveDraft() async {
    if (_childId == null) return;
    await DraftService.saveDraft(
      childId: _childId!,
      type: DraftService.typeLanguage,
      activityId: widget.activity.id,
      activityJson: widget.activity.toJson(),
      data: {
        'current': current,
        'segmentResults':
            _segmentResults.map((r) => r.toDraftJson()).toList(),
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
    return false;
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _ytController?.close();
    _playbackPlayer.dispose();
    _audioRecorder.dispose();
    _recordingTimer?.cancel();
    _webAudioSub?.cancel();
    _resultsNotifier.dispose();
    _isSubmitting.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.forward(from: 0);
  }

  // ----------------------------------------------------
  // 2. HELPERS (Logic)
  // ----------------------------------------------------

  SegmentResult get _currentSegmentResult {
    if (current > 0 && current <= totalSegments) {
      return _segmentResults[current - 1];
    }
    return SegmentResult(id: '', text: 'Error', maxScore: 0);
  }

  int get completedSegmentsCount =>
      _segmentResults.where((r) => r.status == SegmentStatus.done).length;

  String _getCurrentSegmentText() {
    if (_rawSegments.isEmpty || current > totalSegments) {
      return 'Activity Content Missing.';
    }
    return (_rawSegments[current - 1] as Map<String, dynamic>)['text']
            as String? ??
        'Text not found.';
  }

  Future<void> _openInYouTube() async {
    if (_youtubeVideoId.isEmpty) return;
    final appUri = Uri.parse('youtube://watch?v=$_youtubeVideoId');
    final webUri = Uri.parse('https://www.youtube.com/watch?v=$_youtubeVideoId');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  // 🔊 เล่น Section ด้วย youtube_player_iframe: seekTo + playVideo + pauseVideo
  void _playSection() async {
    if (_ytController == null) {
      debugPrint('❌ Play Section: YouTube controller is null');
      return;
    }

    if (!_isPlayerReady) {
      debugPrint('❌ Play Section: Player not ready yet');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.itemintro_videoLoading)),
      );
      return;
    }

    if (_rawSegments.isEmpty || current > totalSegments) {
      debugPrint('❌ Play Section: No segments or invalid current index');
      return;
    }

    final currentSegment = _rawSegments[current - 1] as Map<String, dynamic>;
    final start = (currentSegment['start'] as num?)?.toDouble();
    final end = (currentSegment['end'] as num?)?.toDouble();

    if (start == null || end == null) {
      debugPrint('❌ Play Section: Missing start/end time in segment data');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.itemintro_timingIncomplete)),
      );
      return;
    }

    debugPrint('▶️ Playing section: ${start}s - ${end}s (+0.7s buffer)');
    final durationMs = ((end - start + 0.7) * 1000)
        .toInt(); // ✅ เพิ่ม 0.7 วินาทีให้เล่นยาวขึ้น

    try {
      await _ytController!.seekTo(seconds: start, allowSeekAhead: true);
      await _ytController!.playVideo();

      Timer(Duration(milliseconds: durationMs), () {
        if (mounted && _ytController != null) {
          _ytController!.pauseVideo();
          debugPrint('⏸️ Section playback ended');
        }
      });
    } catch (e) {
      debugPrint('❌ Play Section Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .itemintro_videoPlayError(e.toString()))),
        );
      }
    }
  }

  // 🔊 Playback เสียงที่บันทึกเอง
  void _playOwnRecording(SegmentResult result) async {
    final audioPath = result.audioUrl;
    final audioBytes = result.audioBytes;
    final hasAudioPath = audioPath != null && audioPath.isNotEmpty;
    final hasAudioBytes = audioBytes != null && audioBytes.isNotEmpty;
    if (!hasAudioPath && !hasAudioBytes) return;

    if (_isPlaybackPlaying) {
      await _playbackPlayer.pause();
      setState(() => _isPlaybackPlaying = false);
      return;
    }

    try {
      if (hasAudioBytes) {
        await _playbackPlayer.play(ap.BytesSource(audioBytes!));
      } else {
        await _playbackPlayer.play(ap.DeviceFileSource(audioPath!));
      }
      setState(() => _isPlaybackPlaying = true);
    } catch (e) {
      debugPrint('Self-Playback Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.itemintro_playbackFailed)),
      );
      setState(() => _isPlaybackPlaying = false);
    }
  }

  // ----------------------------------------------------
  // 3. EVENT HANDLERS
  // ----------------------------------------------------

  Future<void> _handleRecord() async {
    if (_childId == null || _rawSegments.isEmpty) return;

    if (_isRecording) {
      // หยุดการอัด
      await _stopRecording();
    } else {
      // เริ่มการอัด
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    // ขอ permission
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.itemintro_micPermission)),
        );
      }
      return;
    }

    try {
      if (kIsWeb) {
        // Web: ใช้ stream
        _webBytesBuilder = BytesBuilder(copy: false);
        final stream = await _audioRecorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
            echoCancel: true,
            noiseSuppress: true,
          ),
        );
        _webAudioSub = stream.listen((chunk) {
          _webBytesBuilder?.add(chunk);
        });
      } else {
        // Mobile/Desktop: บันทึกเป็นไฟล์ temp (จะลบหลังเสร็จกิจกรรม)
        final tempDir = await getTemporaryDirectory();
        _recordedFilePath =
            '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _recordedFilePath,
        );

        // เก็บ path ไว้ลบภายหลัง
        _tempAudioFiles.add(_recordedFilePath);
        debugPrint('📝 Added temp audio file: $_recordedFilePath');
      }

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      // เริ่ม timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _recordingDuration += const Duration(seconds: 1);
          });
        }
      });

      debugPrint('🎙️ Recording started');
    } catch (e) {
      debugPrint('❌ Recording start error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .itemintro_recordStartError(e.toString()))),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    await _audioRecorder.stop();

    setState(() => _isRecording = false);

    // ตรวจสอบระยะเวลาที่อัด
    if (_recordingDuration.inSeconds < 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(AppLocalizations.of(context)!.itemintro_recordTooShort)));
        setState(() => state = 'idle');
      }
      return;
    }

    // ── ดึง audio data ก่อน enqueue ──────────────────────────────────────
    Uint8List? webBytes;
    String mobilePath = '';

    if (kIsWeb) {
      await _webAudioSub?.cancel();
      _webAudioSub = null;
      final pcm = _webBytesBuilder?.toBytes();
      _webBytesBuilder = null;
      if (pcm == null || pcm.isEmpty || pcm.length < 8000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context)!.audio_tooShort)));
          setState(() => state = 'idle');
        }
        return;
      }
      webBytes = _pcm16ToWav(pcm, sampleRate: 16000, channels: 1);
    } else {
      mobilePath = _recordedFilePath;
      final f = File(mobilePath);
      if (!await f.exists() || await f.length() < 1000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context)!.audio_notFound)));
          setState(() => state = 'idle');
        }
        return;
      }
    }

    // ── อัปเดต segment เป็น "processing" ทันที ──────────────────────────
    final segIdx = current - 1;
    final segText = _getCurrentSegmentText();
    final segId = _currentSegmentResult.id;

    setState(() {
      _segmentResults[segIdx] = _segmentResults[segIdx].copyWith(
        status: SegmentStatus.processing,
        audioUrl: kIsWeb ? '' : mobilePath,
        audioBytes: kIsWeb ? webBytes : null,
      );
      _resultsNotifier.value = List.from(_segmentResults);
      state = 'processing'; // แสดง inline indicator บน segment ปัจจุบัน
    });

    // ── เพิ่มงานเข้า queue — ไม่ await → ผู้ใช้ทำข้อถัดไปได้เลย ─────────
    _evaluationQueue.enqueue(() async {
      if (kIsWeb) {
        return _activityService.evaluateAudioBytes(
          audioBytes: webBytes!,
          originalText: segText,
          filename: 'recording.wav',
        );
      } else {
        return _activityService.evaluateAudio(
          audioFile: File(mobilePath),
          originalText: segText,
        );
      }
    }).then((result) {
      if (!mounted) return;
      final score = result['score'] as int? ?? 0;
      final recognized = result['text'] as String? ?? '';
      setState(() {
        _segmentResults[segIdx] = SegmentResult(
          id: segId,
          text: segText,
          maxScore: score,
          status: SegmentStatus.done,
          recognizedText: recognized,
          audioUrl: kIsWeb ? '' : mobilePath,
          audioBytes: kIsWeb ? webBytes : null,
        );
        _resultsNotifier.value = List.from(_segmentResults);
        // อัปเดต UI ของ segment ปัจจุบันถ้ายังอยู่หน้าเดิม
        if (current - 1 == segIdx) {
          state = 'reviewed';
          point = score;
        }
      });
      debugPrint('✅ Segment ${segIdx + 1}: $score% ("$recognized")');
    }).catchError((e) {
      if (!mounted) return;
      setState(() {
        _segmentResults[segIdx] = _segmentResults[segIdx].copyWith(
          status: SegmentStatus.error,
        );
        _resultsNotifier.value = List.from(_segmentResults);
        if (current - 1 == segIdx) state = 'idle';
      });
      final l = AppLocalizations.of(context)!;
      final msg = e.toString().contains('SocketException')
          ? l.common_noServer
          : l.audio_analyseFailed;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Palette.errorStrong));
    });
  }

  // Helper: Convert PCM16 to WAV format (for Web)
  Uint8List _pcm16ToWav(Uint8List pcmData,
      {required int sampleRate, required int channels}) {
    final int byteRate = sampleRate * channels * 2;
    final int blockAlign = channels * 2;
    final int subchunk2Size = pcmData.lengthInBytes;
    final int chunkSize = 36 + subchunk2Size;

    final bytes = BytesBuilder();
    bytes.add(_ascii('RIFF'));
    bytes.add(_le32(chunkSize));
    bytes.add(_ascii('WAVE'));
    bytes.add(_ascii('fmt '));
    bytes.add(_le32(16));
    bytes.add(_le16(1));
    bytes.add(_le16(channels));
    bytes.add(_le32(sampleRate));
    bytes.add(_le32(byteRate));
    bytes.add(_le16(blockAlign));
    bytes.add(_le16(16));
    bytes.add(_ascii('data'));
    bytes.add(_le32(subchunk2Size));
    bytes.add(pcmData);

    return bytes.toBytes();
  }

  Uint8List _ascii(String s) => Uint8List.fromList(s.codeUnits);
  Uint8List _le16(int value) =>
      Uint8List.fromList([value & 0xFF, (value >> 8) & 0xFF]);
  Uint8List _le32(int value) => Uint8List.fromList([
        value & 0xFF,
        (value >> 8) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 24) & 0xFF,
      ]);

  // ลบไฟล์เสียงชั่วคราวทั้งหมด (เรียกหลังเสร็จกิจกรรม)
  Future<void> _cleanupAudioFiles() async {
    if (kIsWeb) {
      debugPrint('🌐 Web platform - no audio files to cleanup');
      return;
    }

    int deletedCount = 0;
    for (final filePath in _tempAudioFiles) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          deletedCount++;
          debugPrint('🗑️ Deleted temp audio: $filePath');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to delete $filePath: $e');
      }
    }
    _tempAudioFiles.clear();
    debugPrint('✅ Cleanup complete: $deletedCount file(s) deleted');
  }

  Future<void> _handleFinishQuest() async {
    if (_childId == null || _isSubmitting.value) return;
    _isSubmitting.value = true;

    _activityStopwatch.stop();
    final timeSpentSeconds = _activityStopwatch.elapsed.inSeconds;

    try {
      final result = await _activityService.finalizeQuest(
        childId: _childId!,
        activityId: widget.activity.id,
        segmentResults: _resultsNotifier.value,
        activityMaxScore: widget.activity.maxScore,
        timeSpent: timeSpentSeconds,
      );

      await _cleanupAudioFiles();
      if (_childId != null) await DraftService.clearDraft(_childId!);

      if (!mounted) return;
      // Pop summary screen if it's on the stack, then go to result
      Navigator.popUntil(context, (r) => r.isFirst || r.settings.name != null);
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.result,
        arguments: {
          'activityName': widget.activity.name,
          'totalScore': result['calculatedScore'] as int? ?? 0,
          'scoreEarned': result['scoreEarned'] as int? ?? 0,
          'timeSpend': timeSpentSeconds,
          'activityObject': widget.activity,
        },
      );
    } catch (e) {
      _isSubmitting.value = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              AppLocalizations.of(context)!.itemintro_questError(e.toString()))));
    }
  }

  /// Opens the summary screen.  Pop result:
  ///   {'reRecord': N}   → jump to segment N (0-indexed) and re-record
  ///   {'playSection': N} → jump to segment N (0-indexed) and play section
  Future<void> _openSummary() async {
    final pop = await Navigator.push<Map<String, int>?>(
      context,
      MaterialPageRoute(
        builder: (_) => ActivitySummaryScreen(
          resultsNotifier: _resultsNotifier,
          activity: widget.activity,
          rawSegments: _rawSegments,
          isSubmitting: _isSubmitting,
          onComplete: _handleFinishQuest,
        ),
      ),
    );

    if (!mounted) return;

    // Sync local list from the shared notifier (summary may have updated it)
    setState(() {
      _segmentResults
        ..clear()
        ..addAll(_resultsNotifier.value);
      final r = _segmentResults[current - 1];
      state = switch (r.status) {
        SegmentStatus.done => 'reviewed',
        SegmentStatus.processing => 'processing',
        _ => 'idle',
      };
      point = r.maxScore;
    });

    if (pop == null) return;

    final segIdx = pop['reRecord'] ?? pop['playSection'];
    if (segIdx == null) return;

    setState(() {
      current = segIdx + 1;
      final r = _segmentResults[segIdx];
      state = switch (r.status) {
        SegmentStatus.done => 'reviewed',
        SegmentStatus.processing => 'processing',
        _ => 'idle',
      };
      point = r.maxScore;
    });

    // If asked to play the section, trigger it after the frame
    if (pop.containsKey('playSection')) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _playSection());
    }
  }

  // ----------------------------------------------------
  // 4. BUILD METHOD (UI)
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_rawSegments.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'Error: No segments found for ${widget.activity.name}.',
            style: AppTextStyles.heading(20),
          ),
        ),
      );
    }

    final titleStyle = AppTextStyles.heading(22, color: Palette.sky).copyWith(
      height: 1.05,
      letterSpacing: .3,
    );

    final hasVideo = _ytController != null && _youtubeVideoId.isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) Navigator.pop(context);
      },
      child: _buildScaffold(
        context,
        titleStyle: titleStyle,
        videoWidget: hasVideo
            ? yp.YoutubePlayer(controller: _ytController!)
            : Center(
                child: Text(
                  AppLocalizations.of(context)!.itemintro_Videonotavailable,
                  style: AppTextStyles.heading(14, color: Palette.white),
                ),
              ),
      ),
    );
  }

  // แยก Scaffold ออกมาให้เรียกใช้ได้ทั้งกรณีมี/ไม่มี YouTube player
  Widget _buildScaffold(
    BuildContext context, {
    required TextStyle titleStyle,
    required Widget videoWidget,
  }) {
    // ✅ Calculate current values inside this method so they're always fresh
    final currentSegmentResult = _currentSegmentResult;
    final currentText = _getCurrentSegmentText();

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          ActivityL10n.localizedActivityType(context, widget.activity.category),
          style: titleStyle.copyWith(color: Colors.black),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _openSummary,
            child: Text(
              AppLocalizations.of(context)!.summary_reviewShort,
              style: AppTextStyles.body(14, color: Palette.sky),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🎥 Video Player
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        height: 220,
                        color: Colors.black,
                        child: videoWidget,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Open in YouTube (TV) banner
                    if (_youtubeVideoId.isNotEmpty)
                      GestureDetector(
                        onTap: _openInYouTube,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: Palette.cardShadow,
                            border: Border.all(
                                color: const Color(0xFFFF0000)
                                    .withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF0000),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.tv_rounded,
                                    color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .languagedetail_openInYoutube,
                                  style: AppTextStyles.label(13,
                                      color: const Color(0xFFFF0000)),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  color: Color(0xFFFF0000), size: 13),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),

                    // Progress bar + segment counter
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: totalSegments > 0
                                  ? current / totalSegments
                                  : 0,
                              backgroundColor:
                                  Palette.sky.withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Palette.sky),
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppLocalizations.of(context)!
                              .itemintro_segmentOf(current, totalSegments),
                          style: AppTextStyles.label(13,
                              color: Palette.sky),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // การ์ดเนื้อหา (Segment Controls)
                    _contentCard(
                      text: currentText,
                      score: currentSegmentResult.maxScore,
                    ),
                    const SizedBox(height: 10),

                    // การ์ดสถานะ
                    _statusCard(currentSegmentResult),
                  ],
                ),
              ),
            ),
          ),
          // Sticky bottom navigation
          Container(
              color: Palette.cream,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                children: [
                  Expanded(
                    child: _bottomBtn(
                      label: AppLocalizations.of(context)!.itemintro_previous,
                      bg: prevGrey,
                      fg: Palette.deepGrey,
                      onTap: current > 1
                          ? () {
                              if (_isRecording) {
                                _triggerShake();
                                return;
                              }
                              setState(() {
                                current--;
                                final r = _segmentResults[current - 1];
                                state = switch (r.status) {
                                  SegmentStatus.done => 'reviewed',
                                  SegmentStatus.processing => 'processing',
                                  _ => 'idle',
                                };
                                point = r.maxScore;
                              });
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 80,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Palette.sky.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Palette.sky.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$completedSegmentsCount/$totalSegments',
                          style: AppTextStyles.heading(14,
                              color: Palette.sky),
                        ),
                        Text(
                          AppLocalizations.of(context)!.common_done,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Palette.sky,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _bottomBtn(
                      label: current == totalSegments
                          ? AppLocalizations.of(context)!.summary_reviewShort
                          : AppLocalizations.of(context)!.itemintro_next,
                      bg: nextBlue,
                      fg: Colors.white,
                      onTap: () {
                        if (_isRecording) {
                          _triggerShake();
                          return;
                        }
                        if (current < totalSegments) {
                          setState(() {
                            current++;
                            final r = _segmentResults[current - 1];
                            state = switch (r.status) {
                              SegmentStatus.done => 'reviewed',
                              SegmentStatus.processing => 'processing',
                              _ => 'idle',
                            };
                            point = r.maxScore;
                          });
                        } else {
                          _openSummary();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
          ],
        ),
    );
  }

  // ----------------------------------------------------
  // 5. HELPER WIDGETS
  // ----------------------------------------------------

  Widget _pillButton(String text, Color bg,
      {bool textDark = false, VoidCallback? onTap}) {
    final Color actualBg = onTap == null ? bg.withValues(alpha: 0.6) : bg;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: actualBg,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: AppTextStyles.heading(14,
                color: textDark ? Colors.black : Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _recordButton({required bool isReviewed}) {
    final Color bg = _isRecording ? Palette.errorStrong : Palette.success;

    return Expanded(
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) => Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        ),
        child: InkWell(
          onTap: _handleRecord,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isRecording) ...[
                  const Icon(Icons.mic, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${_recordingDuration.inMinutes.toString().padLeft(2, '0')}:${(_recordingDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: AppTextStyles.heading(14, color: Colors.white),
                  ),
                ] else
                  Text(
                    AppLocalizations.of(context)!.itemintro_record,
                    style: AppTextStyles.heading(14, color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contentCard({required String text, int? score}) {
    final isReviewed = score != null && score > 0;
    const accent = Palette.sky;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: Palette.cardShadow,
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Phrase label
                    Row(
                      children: [
                        const Icon(Icons.record_voice_over_rounded,
                            color: accent, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.of(context)!.itemintro_speak,
                          style: AppTextStyles.label(12, color: accent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      text.toUpperCase(),
                      style: AppTextStyles.heading(16, color: Palette.text),
                    ),
                    const SizedBox(height: 12),
                    // Buttons row
                    Row(
                      children: [
                        _pillButton(
                          AppLocalizations.of(context)!.itemintro_playsection,
                          Palette.bluePill,
                          onTap: _isPlayerReady && _rawSegments.isNotEmpty
                              ? _playSection
                              : null,
                        ),
                        const SizedBox(width: 10),
                        _recordButton(isReviewed: isReviewed),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Score row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: accent, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${score ?? 0}%',
                              style: AppTextStyles.label(13, color: accent),
                            ),
                          ],
                        ),
                        Text(
                          '$completedSegmentsCount/$totalSegments ${AppLocalizations.of(context)!.common_done}',
                          style: AppTextStyles.body(12,
                              color: Palette.labelGrey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: isReviewed ? score / 100 : 0,
                        backgroundColor:
                            accent.withValues(alpha: 0.12),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(accent),
                        minHeight: 7,
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

  Widget _statusCard(SegmentResult result) {
    final String recognizedTextDisplay = result.recognizedText?.trim() ?? '';
    const accent = Palette.sky;

    final bool isProcessing = state == 'processing';
    final bool isReviewed = state == 'reviewed';
    final bool isRecordingAvailable =
        (result.audioUrl != null && result.audioUrl!.isNotEmpty) ||
        (result.audioBytes != null && result.audioBytes!.isNotEmpty);

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    if (isProcessing) {
      statusColor = Palette.sky;
      statusIcon = Icons.hourglass_top_rounded;
      statusLabel = AppLocalizations.of(context)!.summary_analyzing;
    } else if (isReviewed) {
      statusColor = Palette.success;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = '${result.maxScore}%';
    } else if (state == 'finished') {
      statusColor = Palette.success;
      statusIcon = Icons.task_alt_rounded;
      statusLabel = AppLocalizations.of(context)!.itemintro_completed;
    } else {
      statusColor = accent;
      statusIcon = Icons.mic_none_rounded;
      statusLabel = _isPlayerReady
          ? AppLocalizations.of(context)!.itemintro_recordToEnable
          : AppLocalizations.of(context)!.itemintro_Videonotavailable;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Palette.cardShadow,
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status row
          Row(
            children: [
              if (isProcessing)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: statusColor),
                )
              else
                Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusLabel,
                  style: AppTextStyles.body(12, color: statusColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // "You said" display when reviewed
          if (isReviewed) ...[
            const SizedBox(height: 6),
            Text(
              '${AppLocalizations.of(context)!.summary_youSaid}: "$recognizedTextDisplay"',
              style: AppTextStyles.body(13, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          // Playback button
          GestureDetector(
            onTap: isRecordingAvailable
                ? () => _playOwnRecording(result)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 42,
              decoration: BoxDecoration(
                color: isRecordingAvailable
                    ? (_isPlaybackPlaying
                        ? accent.withValues(alpha: 0.12)
                        : Colors.grey.shade50)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isRecordingAvailable
                      ? (_isPlaybackPlaying ? accent : Colors.grey.shade300)
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isPlaybackPlaying
                        ? Icons.pause_circle_rounded
                        : Icons.play_circle_rounded,
                    color: isRecordingAvailable ? accent : Colors.grey.shade400,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isRecordingAvailable
                        ? (_isPlaybackPlaying
                            ? AppLocalizations.of(context)!
                                .itemintro_pausePlayback
                            : AppLocalizations.of(context)!
                                .itemintro_listenRecording)
                        : AppLocalizations.of(context)!.itemintro_recordToPlayback,
                    style: AppTextStyles.label(13,
                        color: isRecordingAvailable
                            ? accent
                            : Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBtn({
    required String label,
    required Color bg,
    required Color fg,
    VoidCallback? onTap,
  }) {
    final Color actualBg = onTap == null ? bg.withValues(alpha: 0.6) : bg;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: actualBg,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.heading(15, color: fg),
        ),
      ),
    );
  }
}
