import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../../../models/activity.dart';
import '../../../services/activity_service.dart';
import '../../../services/audio_evaluation_queue.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';

/// Summary page shown before final submission.
///
/// Navigation contract with [ItemIntroScreen]:
///   pop result = null              → user just went back normally
///   pop result = {'playSection': N} → jump to segment N (0-indexed) and play
class ActivitySummaryScreen extends StatefulWidget {
  const ActivitySummaryScreen({
    super.key,
    required this.resultsNotifier,
    required this.activity,
    required this.rawSegments,
    required this.onComplete,
    required this.isSubmitting,
  });

  final ValueNotifier<List<SegmentResult>> resultsNotifier;
  final Activity activity;
  final List<dynamic> rawSegments;
  final VoidCallback onComplete;
  final ValueNotifier<bool> isSubmitting;

  @override
  State<ActivitySummaryScreen> createState() => _ActivitySummaryScreenState();
}

class _ActivitySummaryScreenState extends State<ActivitySummaryScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioEvaluationQueue _evaluationQueue = AudioEvaluationQueue();
  final ActivityService _activityService = ActivityService();
  final List<String> _tempAudioFiles = [];
  final ap.AudioPlayer _playbackPlayer = ap.AudioPlayer();

  int? _recordingIndex;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  String _recordedFilePath = '';
  BytesBuilder? _webBytesBuilder;
  StreamSubscription<List<int>>? _webAudioSub;
  String? _playingAudioKey;

  @override
  void initState() {
    super.initState();
    _playbackPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingAudioKey = null);
    });
  }

  Future<void> _playAudio(SegmentResult result, int index) async {
    final path = result.audioUrl;
    final bytes = result.audioBytes;
    final hasPath = path != null && path.isNotEmpty;
    final hasBytes = bytes != null && bytes.isNotEmpty;
    if (!hasPath && !hasBytes) return;

    final key = hasBytes ? 'web-$index' : path!;
    if (_playingAudioKey == key) {
      await _playbackPlayer.pause();
      setState(() => _playingAudioKey = null);
      return;
    }
    try {
      if (hasBytes) {
        await _playbackPlayer.play(ap.BytesSource(bytes!));
      } else {
        await _playbackPlayer.play(ap.DeviceFileSource(path!));
      }
      setState(() => _playingAudioKey = key);
    } catch (e) {
      debugPrint('Playback error: $e');
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _playbackPlayer.dispose();
    _recordingTimer?.cancel();
    _webAudioSub?.cancel();
    for (final path in _tempAudioFiles) {
      try {
        File(path).deleteSync();
      } catch (_) {}
    }
    super.dispose();
  }

  // ── Recording logic ────────────────────────────────────────────────────────

  Future<void> _handleRecord(int index) async {
    if (_isRecording) {
      if (_recordingIndex == index) {
        await _stopRecording(index);
      }
      return;
    }
    await _startRecording(index);
  }

  Future<void> _startRecording(int index) async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.itemintro_micPermission),
        ));
      }
      return;
    }

    try {
      if (kIsWeb) {
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
        _webAudioSub = stream.listen((chunk) => _webBytesBuilder?.add(chunk));
      } else {
        final tempDir = await getTemporaryDirectory();
        _recordedFilePath =
            '${tempDir.path}/summary_rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _recordedFilePath,
        );
        _tempAudioFiles.add(_recordedFilePath);
      }

      setState(() {
        _isRecording = true;
        _recordingIndex = index;
        _recordingDuration = Duration.zero;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordingDuration += const Duration(seconds: 1));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              AppLocalizations.of(context)!.itemintro_recordStartError(e.toString())),
        ));
      }
    }
  }

  Future<void> _stopRecording(int index) async {
    _recordingTimer?.cancel();
    await _audioRecorder.stop();
    setState(() => _isRecording = false);

    if (_recordingDuration.inSeconds < 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.itemintro_recordTooShort),
        ));
      }
      return;
    }

    Uint8List? webBytes;
    String mobilePath = '';

    if (kIsWeb) {
      await _webAudioSub?.cancel();
      _webAudioSub = null;
      final pcm = _webBytesBuilder?.toBytes();
      _webBytesBuilder = null;
      if (pcm == null || pcm.isEmpty || pcm.length < 8000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.audio_tooShort)),
          );
        }
        return;
      }
      webBytes = _pcm16ToWav(pcm, sampleRate: 16000, channels: 1);
    } else {
      mobilePath = _recordedFilePath;
      final f = File(mobilePath);
      if (!await f.exists() || await f.length() < 1000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.audio_notFound)),
          );
        }
        return;
      }
    }

    final segMap = widget.rawSegments[index] as Map<String, dynamic>;
    final segText = segMap['text'] as String? ?? '';
    final segId = widget.resultsNotifier.value[index].id;

    // Mark processing
    final processing = List<SegmentResult>.from(widget.resultsNotifier.value);
    processing[index] = processing[index].copyWith(
      status: SegmentStatus.processing,
      audioUrl: kIsWeb ? '' : mobilePath,
      audioBytes: kIsWeb ? webBytes : null,
    );
    widget.resultsNotifier.value = processing;

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
      final updated = List<SegmentResult>.from(widget.resultsNotifier.value);
      updated[index] = SegmentResult(
        id: segId,
        text: segText,
        maxScore: score,
        status: SegmentStatus.done,
        recognizedText: recognized,
        audioUrl: kIsWeb ? '' : mobilePath,
        audioBytes: kIsWeb ? webBytes : null,
      );
      widget.resultsNotifier.value = updated;
    }).catchError((e) {
      if (!mounted) return;
      final errList = List<SegmentResult>.from(widget.resultsNotifier.value);
      errList[index] = errList[index].copyWith(status: SegmentStatus.error);
      widget.resultsNotifier.value = errList;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.audio_analyseFailed),
        backgroundColor: Palette.errorStrong,
      ));
    });
  }

  // ── WAV helpers (Web only) ─────────────────────────────────────────────────

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
  Uint8List _le16(int v) => Uint8List.fromList([v & 0xFF, (v >> 8) & 0xFF]);
  Uint8List _le32(int v) => Uint8List.fromList([
        v & 0xFF,
        (v >> 8) & 0xFF,
        (v >> 16) & 0xFF,
        (v >> 24) & 0xFF,
      ]);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
          l10n.summary_title,
          style: AppTextStyles.heading(20, color: Palette.sky),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<List<SegmentResult>>(
              valueListenable: widget.resultsNotifier,
              builder: (context, results, _) {
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final thisRecording = _isRecording && _recordingIndex == i;
                    final otherRecording = _isRecording && _recordingIndex != i;
                    final result = results[i];
                    final audioPath = result.audioUrl;
                    final hasPath = audioPath != null && audioPath.isNotEmpty;
                    final hasBytes =
                        result.audioBytes != null && result.audioBytes!.isNotEmpty;
                    final audioKey = hasBytes ? 'web-$i' : audioPath;
                    return _SegmentCard(
                      index: i,
                      result: result,
                      isRecording: thisRecording,
                      recordingDuration: _recordingDuration,
                      onToggleRecord: otherRecording ? null : () => _handleRecord(i),
                      onPlaySection: _isRecording ? null : () =>
                          Navigator.pop(context, {'playSection': i}),
                      onPlayAudio: (hasPath || hasBytes)
                          ? () => _playAudio(result, i)
                          : null,
                      isPlayingAudio: _playingAudioKey == audioKey && audioKey != null,
                    );
                  },
                );
              },
            ),
          ),

          // ── Sticky Complete Activity button ──────────────────────────
          ValueListenableBuilder<List<SegmentResult>>(
            valueListenable: widget.resultsNotifier,
            builder: (context, results, _) {
              final pendingCount = results
                  .where((r) => r.status == SegmentStatus.processing)
                  .length;

              return ValueListenableBuilder<bool>(
                valueListenable: widget.isSubmitting,
                builder: (context, submitting, _) {
                  return Container(
                    color: Palette.cream,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                        child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (pendingCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Palette.sky),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.summary_pendingAnalysis(pendingCount),
                                    style: AppTextStyles.body(13,
                                        color: Palette.deepGrey),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: (submitting || pendingCount > 0 || _isRecording)
                                  ? null
                                  : widget.onComplete,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Palette.successAlt,
                                disabledBackgroundColor:
                                    Palette.successAlt.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: submitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      l10n.summary_completeActivity,
                                      style: AppTextStyles.heading(17,
                                          color: Colors.white),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Per-segment card ──────────────────────────────────────────────────────────

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({
    required this.index,
    required this.result,
    required this.isRecording,
    required this.recordingDuration,
    required this.onToggleRecord,
    required this.onPlaySection,
    required this.onPlayAudio,
    required this.isPlayingAudio,
  });

  final int index;
  final SegmentResult result;
  final bool isRecording;
  final Duration recordingDuration;
  final VoidCallback? onToggleRecord;
  final VoidCallback? onPlaySection;
  final VoidCallback? onPlayAudio;
  final bool isPlayingAudio;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _statusColor(result.status, result.maxScore);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Palette.cardShadow,
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left accent strip ──────────────────────────────────
            Container(width: 4, color: statusColor),
            // ── Card content ───────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Icon(Icons.record_voice_over_rounded,
                            color: Palette.sky, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          l10n.summary_segmentLabel(index + 1),
                          style: AppTextStyles.label(13, color: Palette.sky),
                        ),
                        const Spacer(),
                        _StatusBadge(
                            status: result.status, score: result.maxScore),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Target text
                    Text(
                      '${l10n.itemintro_speak.toUpperCase()}: ${result.text}',
                      style: AppTextStyles.body(14,
                          color: Palette.deepGrey, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),

                    // Recognised text / status message
                    _buildResultRow(context, l10n),
                    const SizedBox(height: 10),

                    // Score bar (only when done)
                    if (result.status == SegmentStatus.done) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: result.maxScore / 100,
                          backgroundColor: Palette.progressBg,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(statusColor),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Action buttons
                    Row(
                      children: [
                        _RecordBtn(
                          isRecording: isRecording,
                          duration: recordingDuration,
                          status: result.status,
                          onTap: onToggleRecord,
                        ),
                        const SizedBox(width: 8),
                        _ActionBtn(
                          icon: Icons.play_circle_outline,
                          label: l10n.itemintro_playsection,
                          color: Palette.bluePill,
                          onTap: onPlaySection,
                        ),
                      ],
                    ),
                    if (onPlayAudio != null) ...[
                      const SizedBox(height: 8),
                      _ActionBtn(
                        icon: isPlayingAudio
                            ? Icons.pause_circle_rounded
                            : Icons.headphones_rounded,
                        label: isPlayingAudio
                            ? l10n.itemintro_pausePlayback
                            : l10n.itemintro_listenRecording,
                        color: Palette.sky,
                        onTap: onPlayAudio,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(BuildContext context, AppLocalizations l10n) {
    switch (result.status) {
      case SegmentStatus.idle:
        return Text(
          l10n.summary_notRecorded,
          style: AppTextStyles.body(13, color: Palette.labelGrey),
        );
      case SegmentStatus.processing:
        return Row(
          children: [
            const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Palette.sky)),
            const SizedBox(width: 8),
            Text(l10n.summary_analyzing,
                style: AppTextStyles.body(13, color: Palette.sky)),
          ],
        );
      case SegmentStatus.error:
        return Text(
          l10n.summary_analysisFailed,
          style: AppTextStyles.body(13, color: Palette.errorStrong),
        );
      case SegmentStatus.done:
        return Text(
          '${l10n.summary_youSaid}: "${result.recognizedText ?? ''}"',
          style: AppTextStyles.body(13, color: Colors.black87),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
    }
  }

  Color _statusColor(SegmentStatus status, int score) {
    if (status != SegmentStatus.done) return Palette.labelGrey;
    if (score >= 70) return Palette.successAlt;
    if (score >= 40) return Palette.warning;
    return Palette.errorStrong;
  }
}

// ── Record button (inline in summary) ────────────────────────────────────────

class _RecordBtn extends StatelessWidget {
  const _RecordBtn({
    required this.isRecording,
    required this.duration,
    required this.status,
    required this.onTap,
  });

  final bool isRecording;
  final Duration duration;
  final SegmentStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool disabled = onTap == null;
    final Color fg = isRecording
        ? Colors.white
        : disabled
            ? Palette.labelGrey
            : Palette.sky;
    final Color bg = isRecording
        ? Palette.errorStrong
        : disabled
            ? Palette.labelGrey.withValues(alpha: 0.08)
            : Palette.sky.withValues(alpha: 0.12);
    final String label = isRecording
        ? '${l10n.summary_stopRecord}  '
            '${duration.inMinutes.toString().padLeft(2, '0')}:'
            '${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
        : (status == SegmentStatus.done
            ? l10n.summary_reRecord
            : l10n.itemintro_record);
    final IconData icon = isRecording ? Icons.stop : Icons.mic;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 38,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 5),
              Text(label, style: AppTextStyles.label(12, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.score});
  final SegmentStatus status;
  final int score;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case SegmentStatus.idle:
        return _badge(l10n.summary_notRecordedShort, Palette.labelGrey);
      case SegmentStatus.processing:
        return _badge(l10n.summary_analyzing, Palette.sky);
      case SegmentStatus.error:
        return _badge(l10n.summary_error, Palette.errorStrong);
      case SegmentStatus.done:
        final color = score >= 70
            ? Palette.successAlt
            : score >= 40
                ? Palette.warning
                : Palette.errorStrong;
        return _badge('$score%', color);
    }
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: AppTextStyles.label(12, color: color)),
      );
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null;
    final Color fg = disabled ? Palette.labelGrey : color;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: disabled
                ? Palette.labelGrey.withValues(alpha: 0.08)
                : color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 5),
              Text(label, style: AppTextStyles.label(12, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
