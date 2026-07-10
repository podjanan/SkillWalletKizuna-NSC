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
import '../../../models/activity.dart';
import '../../../routes/app_routes.dart';
import '../../../providers/user_provider.dart';
import '../../../services/dynamic_vocabulary_service.dart';
import '../../../services/activity_service.dart';
import '../../../services/child_service.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/palette.dart';
import '../../../widgets/game_activity_cover.dart';
import '../../../widgets/ui.dart';
import '../../../widgets/share_result_helper.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import '../../../utils/activity_l10n.dart';

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
  final ChildService _childService = ChildService();
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
        'animals',
        'Animals',
        '\u{0E2A}\u{0E31}\u{0E15}\u{0E27}\u{0E4C}',
        '\u{1F981}',
        Palette.successAlt),
    _VocabularyCategory(
        'food',
        'Food',
        '\u{0E2D}\u{0E32}\u{0E2B}\u{0E32}\u{0E23}',
        '\u{1F34E}',
        Palette.warning),
    _VocabularyCategory(
        'vehicles',
        'Vehicles',
        '\u{0E22}\u{0E32}\u{0E19}\u{0E1E}\u{0E32}\u{0E2B}\u{0E19}\u{0E30}',
        '\u{1F680}',
        Palette.sky),
    _VocabularyCategory(
        'nature',
        'Nature',
        '\u{0E18}\u{0E23}\u{0E23}\u{0E21}\u{0E0A}\u{0E32}\u{0E15}\u{0E34}',
        '\u{1F308}',
        Palette.teal),
  ];

  // Game States
  bool _isCustomActivity = false;
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
  int _sessionMaxScore = 100;
  int _sessionTimeLimitSeconds = 600;
  int _secondsLeft = 600;
  String _coverImageUrl = 'asset:assets/images/voice_quest_cover.png';
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

  static const Color _languageAccent = Color(0xFFFFB300);

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: Palette.cardShadow,
      );

  bool get _shouldConfirmExit =>
      _words.isNotEmpty &&
      (_screen == _ScreenState.gameplayScreen ||
          _screen == _ScreenState.resultScreen);

  bool _categoriesLoaded = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _loadHighScore();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_categoriesLoaded) {
      _categoriesLoaded = true;
      _loadCategories();
    }
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
      final activity = ModalRoute.of(context)?.settings.arguments as Activity?;
      final bootstrap = await _service.fetchBootstrap();
      final categories = bootstrap.categories;
      final settings = bootstrap.settings;
      
      int? timeLimitMinutes;
      int? maxScore;
      String? difficulty;
      String? wordCategory;
      
      if (activity != null) {
        maxScore = activity.maxScore;
        final diffStr = activity.difficulty.trim().toUpperCase();
        if (diffStr == 'ง่าย' || diffStr == 'EASY') {
          difficulty = 'easy';
        } else if (diffStr == 'กลาง' || diffStr == 'MEDIUM') {
          difficulty = 'medium';
        } else if (diffStr == 'ยาก' || diffStr == 'HARD') {
          difficulty = 'hard';
        }
        
        if (activity.segments is Map) {
          final segmentsMap = activity.segments as Map;
          final timeLimitSec = segmentsMap['timeLimit'];
          if (timeLimitSec != null) {
            timeLimitMinutes = (int.tryParse(timeLimitSec.toString()) ?? 60) ~/ 60;
            if (timeLimitMinutes == 0) timeLimitMinutes = 1;
          }
          final wordCat = segmentsMap['wordCategory'];
          if (wordCat != null) {
            wordCategory = wordCat.toString();
          }
        }
      }

      timeLimitMinutes ??= _positiveInt(settings['timeLimitMinutes']);
      maxScore ??= _positiveInt(settings['maxScore']);
      final coverImageUrl = settings['coverImageUrl']?.toString().trim();
      
      if (!mounted) return;
      setState(() {
        _categories = categories.isEmpty
            ? _fallbackCategories
            : categories
                .map((category) => _VocabularyCategory(
                      category.slug,
                      category.label,
                      category.thaiLabel ?? '',
                      _emojiFromValue(category.icon, category.slug),
                      _colorFromHex(category.color),
                    ))
                .toList();
        if (maxScore != null) _sessionMaxScore = maxScore;
        if (timeLimitMinutes != null) {
          _sessionTimeLimitSeconds = timeLimitMinutes * 60;
          _secondsLeft = _sessionTimeLimitSeconds;
        }
        if (difficulty != null) {
          _difficulty = difficulty;
        }
        if (wordCategory != null) {
          _selectedCategory = wordCategory;
        }
        if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
          _coverImageUrl = coverImageUrl;
        }
        _isCustomActivity = activity != null &&
            activity.id != 'ai-word-game' &&
            activity.content != 'AI Word Game' &&
            activity.content != 'ai-word-game';
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
    final childId = context.read<UserProvider>().currentChildId;
    final prefs = await SharedPreferences.getInstance();
    final localHighScore = prefs.getInt(_highScorePrefsKey(childId)) ??
        prefs.getInt('voiceQuestHighScore') ??
        0;
    var highScore = localHighScore;

    if (childId != null) {
      final historyHighScore =
          await _childService.getVoiceQuestHighScore(childId);
      if (historyHighScore > highScore) highScore = historyHighScore;
      if (highScore > localHighScore) {
        await prefs.setInt(_highScorePrefsKey(childId), highScore);
      }
    }

    if (!mounted) return;
    setState(() {
      _highScore = highScore;
    });
  }

  Future<void> _saveHighScore(int score) async {
    final childId = context.read<UserProvider>().currentChildId;
    final prefs = await SharedPreferences.getInstance();
    final key = _highScorePrefsKey(childId);
    final currentHigh = [
      _highScore,
      prefs.getInt(key) ?? 0,
      prefs.getInt('voiceQuestHighScore') ?? 0,
    ].fold<int>(0, (high, value) => value > high ? value : high);
    if (score > currentHigh) {
      await prefs.setInt(key, score);
      if (!mounted) return;
      setState(() {
        _highScore = score;
      });
    }
  }

  String _highScorePrefsKey(String? childId) =>
      childId == null ? 'voiceQuestHighScore' : 'voiceQuestHighScore_$childId';

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
      final settings = sessionData['settings'] as Map<String, dynamic>? ?? {};

      final activity = ModalRoute.of(context)?.settings.arguments as Activity?;
      int? activityMaxScore;
      int? activityTimeLimitSeconds;
      if (activity != null) {
        activityMaxScore = activity.maxScore;
        if (activity.segments is Map) {
          final segmentsMap = activity.segments as Map;
          final timeLimitSec = segmentsMap['timeLimit'];
          if (timeLimitSec != null) {
            activityTimeLimitSeconds = int.tryParse(timeLimitSec.toString()) ?? 60;
          }
        }
      }

      final sessionMaxScore = activityMaxScore ??
          _positiveInt(sessionData['maxScore']) ??
          _positiveInt(settings['maxScore']) ??
          loadedWords.length * 50;
      final sessionTimeLimitSeconds = activityTimeLimitSeconds ??
          (_positiveInt(settings['timeLimitMinutes']) ?? 10) * 60;
      final coverImageUrl = settings['coverImageUrl']?.toString().trim();

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
        _sessionMaxScore = sessionMaxScore;
        _sessionTimeLimitSeconds = sessionTimeLimitSeconds;
        if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
          _coverImageUrl = coverImageUrl;
        }
        _scoreSaved = false;
        _savedWallet = null;
        _screen = _ScreenState.gameplayScreen;
        _isLoading = false;
        _isSavingScore = false;
        _secondsLeft = sessionTimeLimitSeconds;
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
      
      final hasWord = cleanTranscribed.split(RegExp(r'\s+')).contains(cleanTarget);
      final wordCorrect = cleanTranscribed == cleanTarget || hasWord || similarityScore >= 60.0;
      final wordMaxScore = _wordMaxScore(_currentIndex);
      final wordScore = wordCorrect
          ? (similarityScore >= 80.0
              ? wordMaxScore
              : (similarityScore >= 60.0 ? _partialWordScore(wordMaxScore) : 0))
          : 0;

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

  int get _maxScore =>
      _sessionMaxScore > 0 ? _sessionMaxScore : _words.length * 50;
  int get _timeSpentSeconds => (_sessionTimeLimitSeconds - _secondsLeft)
      .clamp(0, _sessionTimeLimitSeconds);
  int get _currentWordScore =>
      _currentIndex < _wordScores.length ? _wordScores[_currentIndex] : 0;
  String get _timeLimitLabel {
    final minutes = (_sessionTimeLimitSeconds / 60).round();
    return '$minutes Min';
  }

  static int? _positiveInt(dynamic value) {
    if (value is int && value > 0) return value;
    if (value is num && value > 0) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed != null && parsed > 0 ? parsed : null;
  }

  int _wordMaxScore(int index) {
    if (_words.isEmpty || index < 0 || index >= _words.length) return 0;
    final baseScore = _maxScore ~/ _words.length;
    final remainder = _maxScore % _words.length;
    return baseScore + (index < remainder ? 1 : 0);
  }

  int _partialWordScore(int wordMaxScore) {
    return (wordMaxScore * 0.6).round().clamp(0, wordMaxScore).toInt();
  }

  Widget _buildCoverImage() {
    return const GameActivityCover(type: GameCoverType.voiceQuest);
  }

  Widget _buildCoverPlaceholder() {
    return const GameActivityCover(type: GameCoverType.voiceQuest);
  }

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

    _timer?.cancel();
    setState(() {
      _screen = _ScreenState.summaryScreen;
      _isSavingScore = true;
      _errorMessage = null;
    });

    final userProvider = context.read<UserProvider>();
    final childId = userProvider.currentChildId;
    final category = _selectedCategory ?? _categories.first.id;

    await _saveHighScore(_score);

    if (!mounted) return;

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
  static String _emojiFromValue(String? value, String slug) {
    final raw = (value ?? '').trim();
    if (raw.isNotEmpty && !_legacyIconNames.contains(raw)) return raw;
    return _emojiFromSlug(slug);
  }

  static const Set<String> _legacyIconNames = {
    'restaurant',
    'directions_car',
    'vehicle',
    'park',
    'nature',
    'category',
    'pets',
    'folder',
  };

  static String _emojiFromSlug(String slug) {
    final normalized = slug.toLowerCase();
    if (normalized.contains('animal')) return '\u{1F981}';
    if (normalized.contains('food') || normalized.contains('fruit')) {
      return '\u{1F34E}';
    }
    if (normalized.contains('vehicle') ||
        normalized.contains('car') ||
        normalized.contains('transport')) {
      return '\u{1F680}';
    }
    if (normalized.contains('nature') ||
        normalized.contains('park') ||
        normalized.contains('garden')) {
      return '\u{1F308}';
    }
    if (normalized.contains('toy')) return '\u{1F9F8}';
    if (normalized.contains('color')) return '\u{1F3A8}';
    if (normalized.contains('body')) return '\u{1F440}';
    if (normalized.contains('clothing') || normalized.contains('clothes')) {
      return '\u{1F455}';
    }
    return '\u{2728}';
  }

  static Color _colorFromHex(String? value) {
    final raw = (value ?? '').replaceFirst('#', '').trim();
    if (raw.length != 6) return Palette.sky;
    final parsed = int.tryParse('FF$raw', radix: 16);
    return parsed == null ? Palette.sky : Color(parsed);
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
    final activity = ModalRoute.of(context)?.settings.arguments as Activity?;
    final isSummary = _screen == _ScreenState.summaryScreen;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBackPressed();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isSummary ? Icons.close : Icons.arrow_back_ios_new,
              color: Colors.black87,
            ),
            onPressed: _handleBackPressed,
          ),
          centerTitle: true,
          title: Text(
            isSummary
                ? ActivityL10n.localizedActivityType(context, activity?.category ?? 'ด้านภาษา')
                : 'Voice Quest',
            style: AppTextStyles.heading(20, color: Palette.text),
          ),
          actions: [
            if (isSummary)
              IconButton(
                icon: const Icon(Icons.share, color: Palette.sky),
                onPressed: () {
                  showShareBottomSheet(
                    context,
                    ShareResultData(
                      activityName: activity?.name ?? 'Voice Quest',
                      score: _score,
                      maxScore: _maxScore,
                      timeSpentSeconds: 0,
                      category: activity?.category,
                      evidenceImagePath: null,
                    ),
                  );
                },
              ),
          ],
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildScreen(),
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
                _topBadge(Icons.timer_rounded, _timeLimitLabel, Colors.blue),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Hero Card & Preview
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration.copyWith(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _buildCoverImage(),
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
                        color: _languageAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Language',
                            style:
                                AppTextStyles.label(11, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Say the word,\nwin the stars!',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading(24, color: Palette.text),
                    ),
                  ],
                ),
              ),
              if (!_isCustomActivity) ...[
                // Selectors
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory ?? _categories.first.id,
                  decoration: InputDecoration(
                    labelText: 'Choose Category',
                    labelStyle: AppTextStyles.label(14, color: Palette.deepGrey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Palette.sky, width: 2),
                    ),
                  ),
                  items: _categories.map((c) {
                    return DropdownMenuItem<String>(
                      value: c.id,
                      child: Text('${c.icon} ${c.label}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _difficulty,
                  decoration: InputDecoration(
                    labelText: 'Choose Difficulty',
                    labelStyle: AppTextStyles.label(14, color: Palette.deepGrey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Palette.sky, width: 2),
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
              ],

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
                      selectedCat.icon,
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
        _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Palette.sky),
              )
            : GradientButton.success(
                label: 'Start Quest',
                icon: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 24),
                onTap: _startGame,
                padding: const EdgeInsets.symmetric(vertical: 18),
                radius: 20,
                fontSize: 18,
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
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
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
                  color: _languageAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Word ${_currentIndex + 1} of ${_words.length}',
                  style: AppTextStyles.label(12, color: _languageAccent),
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
            height: 14,
            decoration: BoxDecoration(
              color: Palette.progressBg,
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: Palette.successGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Flashcard
          Expanded(
            child: Container(
              decoration: _cardDecoration.copyWith(
                borderRadius: BorderRadius.circular(24),
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
                    'Say the word:',
                    style: AppTextStyles.label(13, color: Palette.sky),
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
                      style: AppTextStyles.body(15, color: Palette.deepGrey),
                    ),
                  const SizedBox(height: 16),

                  // TTS pronouncer button
                  OutlinedButton.icon(
                    onPressed: () => _speakWord(item.word),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Palette.sky,
                      side: const BorderSide(color: Palette.sky, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.volume_up_rounded, size: 22),
                    label: Text(
                      'Listen: ${item.word}',
                      style: AppTextStyles.label(14, color: Palette.sky),
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
                              gradient: _isListening
                                  ? Palette.skyGradient
                                  : Palette.successGradient,
                              shape: BoxShape.circle,
                              boxShadow: Palette.buttonShadow,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.mic_rounded,
                                    color: Colors.white, size: 38),
                                const SizedBox(height: 4),
                                Text(
                                  _isListening ? 'Speaking' : 'Hold to speak',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.label(9,
                                      color: Colors.white),
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
          const Icon(Icons.star_rounded, color: _languageAccent, size: 48),
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
    final currentResult = _currentIndex < _wordResults.length
        ? _wordResults[_currentIndex]
        : null;
    final isCorrect = currentResult?.isCorrect ?? (cleanSpoken == cleanTarget);
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
              gradient: isCorrect
                  ? Palette.successGradient
                  : LinearGradient(
                      colors: [Palette.warningLight, Palette.warning],
                    ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: Palette.cardShadow,
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
            decoration: _cardDecoration.copyWith(
              borderRadius: BorderRadius.circular(24),
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
                      'Listen to your voice',
                      style: AppTextStyles.label(13, color: Palette.sky),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Palette.sky,
                      side: const BorderSide(color: Palette.sky, width: 1.5),
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
          GradientButton.success(
            label: _currentIndex + 1 >= _words.length ? 'Finish' : 'Next word',
            onTap: _nextWord,
            padding: const EdgeInsets.symmetric(vertical: 16),
            radius: 20,
            fontSize: 18,
            icon: _currentIndex + 1 < _words.length
                ? const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 22)
                : null,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryScreen() {
    final l = AppLocalizations.of(context)!;
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
            decoration: _cardDecoration.copyWith(
              borderRadius: BorderRadius.circular(24),
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
                      if (result != null &&
                          (result.audioPath != null ||
                              result.audioBytes != null))
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.play_circle_outline_rounded,
                            color: Palette.sky,
                            size: 24,
                          ),
                          onPressed: () => _playRecordedAudio(result),
                        ),
                      const SizedBox(width: 8),
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
          if (!_scoreSaved && !_isSavingScore) ...[
            GradientButton.success(
              label: 'Retry Save Score',
              icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
              onTap: _finishQuest,
              padding: const EdgeInsets.symmetric(vertical: 14),
              radius: 18,
              fontSize: 15,
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 55,
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
              icon: const Icon(Icons.replay, color: Colors.white, size: 22),
              label: Text(
                l.result_playAgainBtn,
                style: AppTextStyles.heading(18, color: Palette.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.bluePill,
                disabledBackgroundColor:
                    Palette.bluePill.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              ),
              icon: Icon(Icons.home_outlined, color: Palette.sky, size: 22),
              label: Text(
                l.result_backToActivitiesBtn,
                style: AppTextStyles.heading(18, color: Palette.sky),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Palette.sky, width: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
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
  final String icon;
  final Color color;

  const _VocabularyCategory(
    this.id,
    this.label,
    this.thaiLabel,
    this.icon,
    this.color,
  );
}
