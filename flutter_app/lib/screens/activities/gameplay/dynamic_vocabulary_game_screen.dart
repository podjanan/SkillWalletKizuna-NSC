import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../../../models/dynamic_vocabulary_item.dart';
import '../../../routes/app_routes.dart';
import '../../../providers/user_provider.dart';
import '../../../services/dynamic_vocabulary_service.dart';
import '../../../services/activity_service.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/palette.dart';

enum _ScreenState { startScreen, gameplayScreen, resultScreen, summaryScreen }

class DynamicVocabularyGameScreen extends StatefulWidget {
  const DynamicVocabularyGameScreen({super.key});

  @override
  State<DynamicVocabularyGameScreen> createState() =>
      _DynamicVocabularyGameScreenState();
}

class _DynamicVocabularyGameScreenState
    extends State<DynamicVocabularyGameScreen>
    with SingleTickerProviderStateMixin {
  final DynamicVocabularyService _service = DynamicVocabularyService();
  final ActivityService _activityService = ActivityService();
  final AudioPlayer _ttsPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final FlutterTts _flutterTts = FlutterTts();

  StreamSubscription<List<int>>? _webAudioSub;
  BytesBuilder? _webBytesBuilder;
  Uint8List? _webAudioBytes;
  final List<String> _recordedAudioPaths = [];

  late AnimationController _pulseController;

  static const List<_VocabularyCategory> _fallbackCategories = [
    _VocabularyCategory(
        'animals', 'Animals', 'สัตว์', Icons.pets_rounded, Palette.successAlt),
    _VocabularyCategory(
        'food', 'Food', 'อาหาร', Icons.restaurant_rounded, Palette.warning),
    _VocabularyCategory('vehicles', 'Vehicles', 'ยานพาหนะ',
        Icons.directions_car_rounded, Palette.sky),
    _VocabularyCategory(
        'nature', 'Nature', 'ธรรมชาติ', Icons.park_rounded, Palette.teal),
  ];

  // Game States
  _ScreenState _screen = _ScreenState.startScreen;
  List<_VocabularyCategory> _categories = _fallbackCategories;
  String? _selectedCategory;
  String _difficulty = 'easy';
  List<DynamicVocabularyItem> _words = [];
  List<_VoiceQuestWordResult?> _wordResults = [];
  List<int> _wordScores = [];
  int _currentIndex = 0;
  String _spokenText = '';
  double _confidence = 0.0;
  int _score = 0;
  int _highScore = 0;
  int _secondsLeft = 600;
  Timer? _timer;

  bool _isLoadingCategories = true;
  bool _isLoading = false;
  bool _isListening = false;
  bool _isEvaluating = false;
  bool _isSavingScore = false;
  bool _scoreSaved = false;
  int? _savedWallet;
  String? _errorMessage;
  String _tempFilePath = '';

  bool get _shouldConfirmExit =>
      _words.isNotEmpty &&
      (_screen == _ScreenState.gameplayScreen ||
          _screen == _ScreenState.resultScreen);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _loadCategories();
    _loadHighScore();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _ttsPlayer.dispose();
    _audioRecorder.dispose();
    _webAudioSub?.cancel();
    _flutterTts.stop();
    _cleanupRecordedAudio();
    super.dispose();
  }

  Future<void> _cleanupRecordedAudio() async {
    for (final path in List<String>.from(_recordedAudioPaths)) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    _recordedAudioPaths.clear();
  }

  Future<void> _deleteAudioPath(String? path) async {
    if (path == null || path.isEmpty) return;
    _recordedAudioPaths.remove(path);
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> _clearCurrentRecordedAudio() async {
    if (_currentIndex >= _wordResults.length) return;
    final result = _wordResults[_currentIndex];
    await _deleteAudioPath(result?.audioPath);
  }

  Future<void> _playRecordedAudio(_VoiceQuestWordResult? result) async {
    if (result == null) return;
    try {
      await _flutterTts.stop();
      await _ttsPlayer.stop();
      if (result.audioBytes != null && result.audioBytes!.isNotEmpty) {
        await _ttsPlayer.play(BytesSource(result.audioBytes!));
        return;
      }
      final path = result.audioPath;
      if (path != null && path.isNotEmpty) {
        await _ttsPlayer.play(DeviceFileSource(path));
      }
    } catch (e) {
      debugPrint('Recorded audio playback error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot play this recording.')),
      );
    }
  }

  // Load Categories
  Future<void> _loadCategories() async {
    try {
      final categories = await _service.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories.isEmpty
            ? _fallbackCategories
            : categories
                .map((category) => _VocabularyCategory(
                      category.slug,
                      category.label,
                      category.thaiLabel ?? '',
                      _iconFromName(category.icon),
                      _colorFromHex(category.color),
                    ))
                .toList();
        _isLoadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categories = _fallbackCategories;
        _isLoadingCategories = false;
      });
    }
  }

  // Load / Save High Score
  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _highScore = prefs.getInt('voiceQuestHighScore') ?? 0;
    });
  }

  Future<void> _saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHigh = prefs.getInt('voiceQuestHighScore') ?? 0;
    if (score > currentHigh) {
      await prefs.setInt('voiceQuestHighScore', score);
      if (!mounted) return;
      setState(() {
        _highScore = score;
      });
    }
  }

  // Start the Game
  Future<void> _startGame() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final category = _selectedCategory ?? _categories.first.id;
      final sessionData = await _service.fetchSession(
        category: category,
        difficulty: _difficulty,
      );

      final rawItems = sessionData['items'] as List<dynamic>? ?? [];
      final List<DynamicVocabularyItem> loadedWords = rawItems
          .map((json) =>
              DynamicVocabularyItem.fromJson(json as Map<String, dynamic>))
          .toList();

      if (loadedWords.isEmpty) {
        throw Exception(
            'No fallback words found for this category and difficulty.');
      }

      await _cleanupRecordedAudio();
      if (!mounted) return;

      setState(() {
        _words = loadedWords;
        _wordResults =
            List<_VoiceQuestWordResult?>.filled(loadedWords.length, null);
        _wordScores = List<int>.filled(loadedWords.length, 0);
        _currentIndex = 0;
        _spokenText = '';
        _confidence = 0.0;
        _score = 0;
        _scoreSaved = false;
        _savedWallet = null;
        _screen = _ScreenState.gameplayScreen;
        _isLoading = false;
        _isSavingScore = false;
        _secondsLeft = 600; // 10 minutes total
      });

      _startTimer();
      _speakWord(loadedWords[0].word);
    } catch (e) {
      String msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains('API Error (404):')) {
        msg = msg.replaceFirst('API Error (404):', '').trim();
      }
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
    }
  }

  // Timer Control
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        _timer?.cancel();
        setState(() => _secondsLeft = 0);
        _finishQuest();
      } else {
        setState(() {
          _secondsLeft--;
        });
      }
    });
  }

  // TTS Audio Guide via Native/Web Speech API
  Future<void> _speakWord(String word) async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.4); // Kid-friendly speed
      await _flutterTts.setPitch(1.05); // High pitched for kids
      await _flutterTts.speak(word);
    } catch (e) {
      debugPrint('TTS Error: $e');
    }
  }

  // Start Voice Recording
  Future<void> _startRecording() async {
    if (_isListening || _isEvaluating) return;
    final hasPermission = await _audioRecorder.hasPermission();
    if (!mounted) return;
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Microphone permission denied. Please allow mic access!')),
      );
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
        _webAudioSub = stream.listen((chunk) {
          _webBytesBuilder?.add(chunk);
        });
      } else {
        final tempDir = await getTemporaryDirectory();
        _tempFilePath =
            '${tempDir.path}/voice_quest_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _tempFilePath,
        );
      }

      setState(() {
        _isListening = true;
        _spokenText = '';
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('Start Recording Error: $e');
    }
  }

  // Stop Recording & Evaluate
  Future<void> _stopRecording() async {
    if (!_isListening) return;
    setState(() {
      _isListening = false;
      _isEvaluating = true;
    });

    try {
      await _audioRecorder.stop();

      Map<String, dynamic> result;
      String? recordedAudioPath;
      Uint8List? recordedAudioBytes;
      final currentTarget = _words[_currentIndex].word;

      if (kIsWeb) {
        await _webAudioSub?.cancel();
        _webAudioSub = null;
        final pcm = _webBytesBuilder?.toBytes();
        _webBytesBuilder = null;

        if (pcm == null || pcm.isEmpty) {
          setState(() => _isEvaluating = false);
          return;
        }

        _webAudioBytes = _pcm16ToWav(pcm, sampleRate: 16000, channels: 1);
        if (_webAudioBytes == null || _webAudioBytes!.lengthInBytes < 100) {
          setState(() => _isEvaluating = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('No speech heard. Hold the mic and speak clearly!')),
          );
          return;
        }

        result = await _activityService.evaluateAudioBytes(
          audioBytes: _webAudioBytes!,
          originalText: currentTarget,
          filename: 'recording.wav',
        );
        recordedAudioBytes = _webAudioBytes;
      } else {
        final file = File(_tempFilePath);
        if (!await file.exists() || await file.length() < 100) {
          setState(() => _isEvaluating = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('No speech heard. Hold the mic and speak clearly!')),
          );
          return;
        }

        result = await _activityService.evaluateAudio(
          audioFile: file,
          originalText: currentTarget,
        );
        recordedAudioPath = file.path;
        _recordedAudioPaths.add(file.path);
      }

      final similarityScore = (result['score'] as num?)?.toDouble() ?? 0.0;
      final transcribedText = result['text'] as String? ?? '';

      final cleanTranscribed = transcribedText
          .replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~()]'), '')
          .toLowerCase()
          .trim();
      final cleanTarget = currentTarget
          .replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~()]'), '')
          .toLowerCase()
          .trim();
      final wordCorrect = cleanTranscribed == cleanTarget;
      final wordScore = wordCorrect ? (similarityScore >= 80 ? 50 : 30) : 0;

      await _clearCurrentRecordedAudio();
      if (!mounted) return;

      setState(() {
        _spokenText = transcribedText;
        _confidence = similarityScore / 100.0;
        _wordScores[_currentIndex] = wordScore;
        _wordResults[_currentIndex] = _VoiceQuestWordResult(
          targetWord: currentTarget,
          spokenText: transcribedText,
          confidence: similarityScore / 100.0,
          score: wordScore,
          isCorrect: wordCorrect,
          audioPath: recordedAudioPath,
          audioBytes: recordedAudioBytes,
        );
        _score = _wordScores.fold(0, (total, score) => total + score);
        _isEvaluating = false;
        _screen = _ScreenState.resultScreen;
      });
    } catch (e) {
      if (!kIsWeb) {
        await _deleteAudioPath(_tempFilePath);
      }
      if (!mounted) return;
      setState(() {
        _isEvaluating = false;
        _errorMessage =
            'AI evaluation error: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  // Build simple WAV (RIFF) header for PCM16 LE
  Uint8List _pcm16ToWav(Uint8List pcmData,
      {required int sampleRate, required int channels}) {
    final int byteRate = sampleRate * channels * 2; // 16-bit
    final int blockAlign = channels * 2;
    final int subchunk2Size = pcmData.lengthInBytes;
    final int chunkSize = 36 + subchunk2Size;

    final bytes = BytesBuilder();
    // RIFF header
    bytes.add(_ascii('RIFF'));
    bytes.add(_le32(chunkSize));
    bytes.add(_ascii('WAVE'));
    // fmt chunk
    bytes.add(_ascii('fmt '));
    bytes.add(_le32(16)); // PCM
    bytes.add(_le16(1)); // audio format PCM
    bytes.add(_le16(channels));
    bytes.add(_le32(sampleRate));
    bytes.add(_le32(byteRate));
    bytes.add(_le16(blockAlign));
    bytes.add(_le16(16)); // bits per sample
    // data chunk
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

  int get _maxScore => _words.length * 50;
  int get _timeSpentSeconds => (600 - _secondsLeft).clamp(0, 600);
  int get _currentWordScore =>
      _currentIndex < _wordScores.length ? _wordScores[_currentIndex] : 0;

  Future<void> _retryWord() async {
    if (_words.isEmpty || _isSavingScore) return;
    await _clearCurrentRecordedAudio();
    if (!mounted) return;
    setState(() {
      _wordScores[_currentIndex] = 0;
      _wordResults[_currentIndex] = null;
      _score = _wordScores.fold(0, (total, score) => total + score);
      _spokenText = '';
      _confidence = 0.0;
      _errorMessage = null;
      _screen = _ScreenState.gameplayScreen;
    });
    _speakWord(_words[_currentIndex].word);
  }

  // Next Word
  Future<void> _nextWord() async {
    if (_currentIndex + 1 >= _words.length) {
      await _finishQuest();
    } else {
      setState(() {
        _currentIndex++;
        _spokenText = '';
        _confidence = 0.0;
        _screen = _ScreenState.gameplayScreen;
      });
      _speakWord(_words[_currentIndex].word);
    }
  }

  Future<void> _finishQuest() async {
    if (_words.isEmpty || _isSavingScore) return;

    final userProvider = context.read<UserProvider>();
    final childId = userProvider.currentChildId;
    final category = _selectedCategory ?? _categories.first.id;

    await _saveHighScore(_score);
    _timer?.cancel();

    if (!mounted) return;

    setState(() {
      _screen = _ScreenState.summaryScreen;
      _isSavingScore = true;
      _errorMessage = null;
    });

    if (childId == null) {
      setState(() {
        _isSavingScore = false;
        _scoreSaved = false;
        _errorMessage = 'Child ID not found. Please choose a child first.';
      });
      return;
    }

    final segmentResults = <SegmentResult>[];
    for (var i = 0; i < _words.length; i++) {
      final result = _wordResults[i];
      segmentResults.add(
        SegmentResult(
          id: 'voice_quest_${i + 1}',
          text: _words[i].word,
          maxScore: _wordScores[i],
          status: SegmentStatus.done,
          recognizedText: result?.spokenText ?? '',
        ),
      );
    }

    try {
      final response = await _activityService.completeVoiceQuest(
        childId: childId,
        totalScoreEarned: _score,
        maxScore: _maxScore,
        segmentResults: segmentResults,
        category: category,
        difficulty: _difficulty,
        timeSpent: _timeSpentSeconds,
      );
      await userProvider.fetchChildrenData();
      if (!mounted) return;
      final wallet = response['newWallet'];
      setState(() {
        _isSavingScore = false;
        _scoreSaved = true;
        _savedWallet =
            wallet is int ? wallet : int.tryParse(wallet?.toString() ?? '');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSavingScore = false;
        _scoreSaved = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // Helpers
  static IconData _iconFromName(String? icon) {
    switch ((icon ?? '').trim()) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'directions_car':
      case 'vehicle':
        return Icons.directions_car_rounded;
      case 'park':
      case 'nature':
        return Icons.park_rounded;
      case 'category':
        return Icons.category_rounded;
      case 'pets':
      default:
        return Icons.pets_rounded;
    }
  }

  static Color _colorFromHex(String? value) {
    final raw = (value ?? '').replaceFirst('#', '').trim();
    if (raw.length != 6) return Palette.sky;
    final parsed = int.tryParse('FF$raw', radix: 16);
    return parsed == null ? Palette.sky : Color(parsed);
  }

  String getCategoryEmoji(String slug) {
    final normalized = slug.toLowerCase();
    if (normalized.contains('animal')) return '🦁';
    if (normalized.contains('food') || normalized.contains('fruit')) {
      return '🍎';
    }
    if (normalized.contains('vehicle') ||
        normalized.contains('car') ||
        normalized.contains('transport')) {
      return '🚀';
    }
    if (normalized.contains('nature') ||
        normalized.contains('park') ||
        normalized.contains('garden')) {
      return '🌈';
    }
    if (normalized.contains('toy')) return '🧸';
    if (normalized.contains('color')) return '🎨';
    if (normalized.contains('body')) return '👀';
    if (normalized.contains('clothing') || normalized.contains('clothes')) {
      return '👕';
    }
    return '✨';
  }

  Future<bool> _confirmExitIfNeeded() async {
    if (!_shouldConfirmExit) return true;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Exit Voice Quest?'),
        content: const Text('Your current quest progress will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Playing'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.errorStrong,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return shouldExit == true;
  }

  Future<void> _handleBackPressed() async {
    final shouldExit = await _confirmExitIfNeeded();
    if (shouldExit && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBackPressed();
      },
      child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF0F6FF), Color(0xFFE2EEFF)],
        ),
      ),
        child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
            onPressed: _handleBackPressed,
          ),
          centerTitle: true,
          title: Text(
            'VOICE QUEST',
            style: AppTextStyles.heading(20, color: Palette.text),
          ),
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildScreen(),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildScreen() {
    switch (_screen) {
      case _ScreenState.startScreen:
        return _buildStartScreen();
      case _ScreenState.gameplayScreen:
        return _buildGameplayScreen();
      case _ScreenState.resultScreen:
        return _buildResultScreen();
      case _ScreenState.summaryScreen:
        return _buildSummaryScreen();
    }
  }

  // ----------------------------------------------------
  // Screen 1: Start Screen
  // ----------------------------------------------------
  Widget _buildStartScreen() {
    if (_isLoadingCategories) {
      return const Center(child: CircularProgressIndicator(color: Palette.sky));
    }

    final selectedCat = _categories.firstWhere(
      (c) => c.id == (_selectedCategory ?? _categories.first.id),
      orElse: () => _categories.first,
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      children: [
        // Top Badges
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Palette.sky, width: 2),
                boxShadow: Palette.softShadow,
              ),
              child: Text(
                _difficulty.toUpperCase(),
                style: AppTextStyles.label(13, color: Palette.sky),
              ),
            ),
            Row(
              children: [
                _topBadge(Icons.emoji_events_rounded, 'High: $_highScore',
                    Colors.orange),
                const SizedBox(width: 8),
                _topBadge(Icons.timer_rounded, '10 Min', Colors.blue),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Hero Card & Preview
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Palette.text, width: 3),
            boxShadow: [
              BoxShadow(color: Palette.text, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    'https://images.unsplash.com/photo-1546410531-bb4caa6b424d?auto=format&fit=crop&q=80&w=800',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5DFFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Palette.purple, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'VOICE QUEST',
                            style:
                                AppTextStyles.label(11, color: Palette.purple),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Say the Word,\nWin the Stars! ⭐️',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading(28, color: Palette.text),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Selectors
              DropdownButtonFormField<String>(
                value: _selectedCategory ?? _categories.first.id,
                decoration: InputDecoration(
                  labelText: 'Choose Category',
                  labelStyle: AppTextStyles.label(14, color: Palette.deepGrey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide:
                        const BorderSide(color: Palette.deepGrey, width: 2),
                  ),
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem<String>(
                    value: c.id,
                    child: Text('${getCategoryEmoji(c.id)} ${c.label}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _difficulty,
                decoration: InputDecoration(
                  labelText: 'Choose Difficulty',
                  labelStyle: AppTextStyles.label(14, color: Palette.deepGrey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide:
                        const BorderSide(color: Palette.deepGrey, width: 2),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'easy', child: Text('🟩 Easy (ง่าย)')),
                  DropdownMenuItem(
                      value: 'medium', child: Text('🟨 Medium (ปานกลาง)')),
                  DropdownMenuItem(value: 'hard', child: Text('🟥 Hard (ยาก)')),
                ],
                onChanged: (value) {
                  setState(() => _difficulty = value ?? 'easy');
                },
              ),
              const SizedBox(height: 20),

              // Category card preview banner
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selectedCat.color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: Palette.softShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TODAY\'S CATEGORY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedCat.label,
                            style:
                                AppTextStyles.heading(24, color: Colors.white),
                          ),
                          Text(
                            selectedCat.thaiLabel,
                            style:
                                AppTextStyles.body(14, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      getCategoryEmoji(selectedCat.id),
                      style: const TextStyle(fontSize: 48),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3F3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Palette.errorStrong, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Palette.errorStrong),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.body(13, color: Palette.errorStrong),
                  ),
                ),
              ],
            ),
          ),

        // Start Button
        GestureDetector(
          onTap: _isLoading ? null : _startGame,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Palette.successAlt,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Palette.text, width: 3),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF166534), offset: const Offset(0, 6)),
              ],
            ),
            alignment: Alignment.center,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'START QUEST',
                        style: AppTextStyles.heading(20, color: Colors.white),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _topBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Palette.text, width: 2),
        boxShadow: Palette.softShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.label(12, color: Palette.text),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // Screen 2: Gameplay Screen
  // ----------------------------------------------------
  Widget _buildGameplayScreen() {
    if (_words.isEmpty) return const SizedBox.shrink();
    final item = _words[_currentIndex];
    final progress = (_currentIndex + 1) / _words.length;
    final mm = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final ss = (_secondsLeft % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5DFFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Word ${_currentIndex + 1} of ${_words.length}',
                  style: AppTextStyles.label(12, color: Palette.purple),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3C4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_rounded,
                        color: Color(0xFF7A4A00), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$mm:$ss',
                      style: AppTextStyles.label(12,
                          color: const Color(0xFF7A4A00)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          Container(
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Palette.text, width: 2),
            ),
            padding: const EdgeInsets.all(2),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: Palette.successAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Flashcard
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Palette.text, width: 3),
                boxShadow: [
                  BoxShadow(color: Palette.text, offset: const Offset(0, 8)),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Flexible(
                    flex: 5,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenHeight = MediaQuery.sizeOf(context).height;
                        final imageHeight = constraints.maxHeight
                            .clamp(120.0, screenHeight * 0.34)
                            .toDouble();
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            color: const Color(0xFFF9FAFB),
                            width: double.infinity,
                            height: imageHeight,
                            alignment: Alignment.center,
                            child: item.imageUrl != null &&
                                    item.imageUrl!.isNotEmpty
                                ? Image.network(
                                    item.imageUrl!,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: imageHeight,
                                    errorBuilder: (_, __, ___) =>
                                        _buildImagePlaceholder(item.word),
                                  )
                                : _buildImagePlaceholder(item.word),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'SAY THE WORD:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Palette.successAlt,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.word.toUpperCase(),
                    style: AppTextStyles.heading(42, color: Palette.text),
                  ),
                  if (item.thaiMeaning != null)
                    Text(
                      'Meaning: ${item.thaiMeaning}',
                      style: AppTextStyles.body(18, color: Palette.deepGrey),
                    ),
                  if (item.phonetic != null)
                    Text(
                      '(${item.phonetic})',
                      style: AppTextStyles.body(15, color: Palette.purple),
                    ),
                  const SizedBox(height: 16),

                  // TTS pronouncer button
                  ElevatedButton.icon(
                    onPressed: () => _speakWord(item.word),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Palette.purple,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Palette.purple, width: 3),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.volume_up_rounded, size: 24),
                    label: Text(
                      'Can you say \'${item.word.toUpperCase()}\'?',
                      style: AppTextStyles.label(14, color: Palette.purple),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Hold to Speak mic button with pulse animations
          Center(
            child: _isEvaluating
                ? const Column(
                    children: [
                      CircularProgressIndicator(color: Palette.successAlt),
                      SizedBox(height: 8),
                      Text('Evaluating your voice...'),
                    ],
                  )
                : Column(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isListening
                                  ? Palette.successAlt.withValues(
                                      alpha:
                                          0.15 + 0.25 * _pulseController.value)
                                  : Colors.transparent,
                            ),
                            padding: EdgeInsets.all(_isListening
                                ? (12.0 * _pulseController.value)
                                : 0),
                            child: child,
                          );
                        },
                        child: Listener(
                          onPointerDown: (_) => _startRecording(),
                          onPointerUp: (_) => _stopRecording(),
                          onPointerCancel: (_) => _stopRecording(),
                          child: Container(
                            width: 106,
                            height: 106,
                            decoration: BoxDecoration(
                              color: _isListening
                                  ? const Color(0xFF166534)
                                  : Palette.successAlt,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 6),
                              boxShadow: [
                                BoxShadow(
                                  color: Palette.text.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.mic_rounded,
                                    color: Colors.white, size: 38),
                                const SizedBox(height: 4),
                                Text(
                                  _isListening ? 'SPEAKING' : 'HOLD TO SPEAK',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Press and hold while speaking. Release when done.',
                        style: AppTextStyles.body(11, color: Palette.deepGrey),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(String word) {
    return Container(
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star_rounded, color: Palette.purple, size: 48),
          const SizedBox(height: 8),
          Text(word, style: AppTextStyles.heading(24, color: Palette.text)),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // Screen 3: Result Screen
  // ----------------------------------------------------
  Widget _buildResultScreen() {
    if (_words.isEmpty) return const SizedBox.shrink();
    final item = _words[_currentIndex];
    final cleanSpoken = _spokenText
        .replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~()]'), '')
        .toLowerCase()
        .trim();
    final cleanTarget = item.word
        .replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~()]'), '')
        .toLowerCase()
        .trim();
    final currentResult =
        _currentIndex < _wordResults.length ? _wordResults[_currentIndex] : null;
    final isCorrect = cleanSpoken == cleanTarget;
    final isPerfect = isCorrect && _confidence >= 0.8;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isCorrect ? Palette.successAlt : Palette.warning,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Palette.text, width: 3),
              boxShadow: [
                BoxShadow(
                  color: isCorrect
                      ? const Color(0xFF166534)
                      : const Offset(0, 6).dx == 0
                          ? const Color(0xFFC2410C)
                          : const Color(0xFFC2410C),
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  isCorrect
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: 12),
                Text(
                  isCorrect ? 'Great Job! เก่งมาก!' : 'Nice Try! พยายามอีกนิด!',
                  style: AppTextStyles.heading(26, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Speech matching details card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Palette.text, width: 3),
              boxShadow: [
                BoxShadow(color: Palette.text, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'YOU SAID:',
                  style: AppTextStyles.label(13, color: Palette.deepGrey),
                ),
                const SizedBox(height: 4),
                Text(
                  _spokenText.isNotEmpty ? '"$_spokenText"' : '(Silence)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: isCorrect ? Palette.successAlt : Palette.warning,
                  ),
                ),
                const Divider(height: 24, color: Palette.divider),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Target word: ',
                        style: AppTextStyles.body(14, color: Palette.deepGrey)),
                    Text(
                      item.word.toUpperCase(),
                      style: AppTextStyles.label(16, color: Palette.text),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Rewards Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _rewardBadge(
                      isCorrect ? '+$_currentWordScore Score' : '+0 Score',
                      isCorrect,
                    ),
                    if (isPerfect)
                      _rewardBadge('Perfect! 🏆', true, isGold: true),
                    _rewardBadge(
                        '${(_confidence * 100).round()}% Voice Match 🎙',
                        isCorrect),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: currentResult == null
                        ? null
                        : () => _playRecordedAudio(currentResult),
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: Text(
                      'Listen to Your Voice',
                      style: AppTextStyles.label(13, color: Palette.purple),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Palette.purple,
                      side: const BorderSide(color: Palette.purple, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(12, color: Palette.errorStrong),
              ),
            ),

          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _retryWord,
              icon: const Icon(Icons.refresh_rounded, size: 22),
              label: Text(
                'Speak Again',
                style: AppTextStyles.heading(16, color: Palette.sky),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Palette.sky,
                side: const BorderSide(color: Palette.sky, width: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Next / Finish Button
          GestureDetector(
            onTap: _nextWord,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Palette.successAlt,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Palette.text, width: 3),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF166534),
                      offset: const Offset(0, 6)),
                ],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentIndex + 1 >= _words.length ? 'Finish' : 'Next Word',
                    style: AppTextStyles.heading(18, color: Colors.white),
                  ),
                  if (_currentIndex + 1 < _words.length) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryScreen() {
    final childName =
        context.watch<UserProvider>().currentChildName ?? 'Selected child';
    final savedText = _scoreSaved
        ? 'Saved to $childName${_savedWallet != null ? ' • Wallet: $_savedWallet' : ''}'
        : 'Saving score for $childName...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Palette.text, width: 3),
              boxShadow: [
                BoxShadow(color: Palette.text, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Palette.warning,
                  size: 62,
                ),
                const SizedBox(height: 12),
                Text(
                  'Quest Complete!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading(28, color: Palette.text),
                ),
                const SizedBox(height: 10),
                Text(
                  'Total Score',
                  style: AppTextStyles.label(13, color: Palette.deepGrey),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$_score / $_maxScore',
                    style: AppTextStyles.heading(58, color: Palette.successAlt),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSavingScore)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Palette.sky,
                        ),
                      )
                    else
                      Icon(
                        _scoreSaved
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        color: _scoreSaved
                            ? Palette.successAlt
                            : Palette.errorStrong,
                        size: 20,
                      ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _errorMessage ?? savedText,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(
                          13,
                          color: _errorMessage == null
                              ? Palette.deepGrey
                              : Palette.errorStrong,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              itemCount: _words.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final result = _wordResults[index];
                final score = _wordScores[index];
                final isCorrect = result?.isCorrect ?? false;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Palette.greyCard, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCorrect
                            ? Icons.check_circle_rounded
                            : Icons.info_outline_rounded,
                        color: isCorrect ? Palette.successAlt : Palette.warning,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _words[index].word.toUpperCase(),
                              style: AppTextStyles.heading(15,
                                  color: Palette.text),
                            ),
                            Text(
                              result?.spokenText.isNotEmpty == true
                                  ? 'Said: ${result!.spokenText}'
                                  : 'No speech recorded',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body(12,
                                  color: Palette.deepGrey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '+$score',
                        style: AppTextStyles.heading(
                          16,
                          color:
                              score > 0 ? Palette.successAlt : Palette.deepGrey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.home,
                    (route) => false,
                  ),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Palette.sky,
                    side: const BorderSide(color: Palette.sky, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSavingScore
                      ? null
                      : () => setState(() {
                            _screen = _ScreenState.startScreen;
                            _words = [];
                            _wordResults = [];
                            _wordScores = [];
                            _score = 0;
                          }),
                  icon: const Icon(Icons.replay_rounded, color: Colors.white),
                  label: Text(
                    'Play Again',
                    style: AppTextStyles.heading(15, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.successAlt,
                    disabledBackgroundColor:
                        Palette.successAlt.withValues(alpha: 0.45),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rewardBadge(String label, bool isCorrect, {bool isGold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isGold
            ? const Color(0xFFFEF08A)
            : isCorrect
                ? const Color(0xFFFFEBA6)
                : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGold
              ? const Color(0xFFEAB308)
              : isCorrect
                  ? const Color(0xFFFCD34D)
                  : Palette.greyCard,
          width: 2,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isGold
              ? const Color(0xFF854D0E)
              : isCorrect
                  ? const Color(0xFF8A5A00)
                  : Palette.deepGrey,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _VoiceQuestWordResult {
  final String targetWord;
  final String spokenText;
  final double confidence;
  final int score;
  final bool isCorrect;
  final String? audioPath;
  final Uint8List? audioBytes;

  const _VoiceQuestWordResult({
    required this.targetWord,
    required this.spokenText,
    required this.confidence,
    required this.score,
    required this.isCorrect,
    this.audioPath,
    this.audioBytes,
  });
}

class _VocabularyCategory {
  final String id;
  final String label;
  final String thaiLabel;
  final IconData icon;
  final Color color;

  const _VocabularyCategory(
    this.id,
    this.label,
    this.thaiLabel,
    this.icon,
    this.color,
  );
}
