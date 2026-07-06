import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';

import '../../providers/user_provider.dart';
import '../../services/activity_service.dart';
import '../../theme/palette.dart';
import '../../theme/app_text_styles.dart';

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final ActivityService _activityService = ActivityService();

  // Selected Activity Type: physical, calculate, voice_quest, space_adventure
  String? _selectedActivityType;

  // Selected Category (for DB category column, e.g. ด้านภาษา, ด้านร่างกาย, ด้านคำนวณ)
  String? _selectedCategory;

  // Selected Word Category (for Voice Quest, e.g. animals, food, vehicles, nature, bedroom, school)
  String _selectedWordCategory = 'animals';

  // Common fields
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _difficulty = 'ง่าย';

  // Physical-specific
  final _maxScoreCtrl = TextEditingController(text: '10');
  final _videoUrlCtrl = TextEditingController();

  // Voice Quest / Space Adventure settings
  final _timeLimitCtrl = TextEditingController(text: '60');
  final _scorePerItemCtrl = TextEditingController(text: '10');

  // Analysis-specific — dynamic question list
  final List<Map<String, TextEditingController>> _questions = [];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _contentCtrl.dispose();
    _maxScoreCtrl.dispose();
    _videoUrlCtrl.dispose();
    _timeLimitCtrl.dispose();
    _scorePerItemCtrl.dispose();
    for (final q in _questions) {
      for (final c in q.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'question': TextEditingController(),
        'answer': TextEditingController(),
        'solution': TextEditingController(),
        'score': TextEditingController(text: '1'),
      });
    });
  }

  void _removeQuestion(int index) {
    final removed = _questions.removeAt(index);
    for (final c in removed.values) {
      c.dispose();
    }
    setState(() {});
  }

  int get _analysisMaxScore {
    int total = 0;
    for (final q in _questions) {
      total += int.tryParse(q['score']!.text) ?? 0;
    }
    return total;
  }

  bool get _isPhysical => _selectedActivityType == 'physical';
  bool get _isCalculate => _selectedActivityType == 'calculate';
  bool get _isVoiceQuest => _selectedActivityType == 'voice_quest';
  bool get _isSpaceAdventure => _selectedActivityType == 'space_adventure';

  bool get _isDirty =>
      _selectedActivityType != null &&
      (_nameCtrl.text.isNotEmpty ||
          _descCtrl.text.isNotEmpty ||
          _contentCtrl.text.isNotEmpty ||
          _videoUrlCtrl.text.isNotEmpty ||
          _questions.isNotEmpty);

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    final l = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(l.common_discardChanges,
                style: AppTextStyles.heading(18)),
            content: Text(l.common_discardMsg,
                style: AppTextStyles.body(15)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.common_keepEditing,
                    style: AppTextStyles.label(14, color: Palette.sky)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.errorStrong),
                child: Text(l.common_discard,
                    style: AppTextStyles.label(14, color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;

    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack(l.createActivity_nameRequired);
      return;
    }

    if (_isPhysical) {
      if (_maxScoreCtrl.text.trim().isEmpty) {
        _showSnack('กรุณากรอกคะแนนเต็ม');
        return;
      }
      if (_contentCtrl.text.trim().isEmpty) {
        _showSnack(l.createActivity_contentRequired);
        return;
      }
    } else if (_isCalculate) {
      if (_questions.isEmpty) {
        _showSnack(l.createActivity_needQuestions);
        return;
      }
    } else if (_isVoiceQuest) {
      if (_maxScoreCtrl.text.trim().isEmpty) {
        _showSnack('กรุณากรอกคะแนนเต็ม');
        return;
      }
      if (_timeLimitCtrl.text.trim().isEmpty) {
        _showSnack('กรุณากรอกระยะเวลาที่กำหนด');
        return;
      }
    } else if (_isSpaceAdventure) {
      if (_scorePerItemCtrl.text.trim().isEmpty) {
        _showSnack('กรุณากรอกคะแนนต่อชิ้น');
        return;
      }
      if (_timeLimitCtrl.text.trim().isEmpty) {
        _showSnack('กรุณากรอกระยะเวลาที่กำหนด');
        return;
      }
    }

    final parentId =
        Provider.of<UserProvider>(context, listen: false).currentParentId;
    if (parentId == null || parentId.isEmpty) {
      _showSnack(l.createActivity_error);
      debugPrint('CreateActivity: parentId is null/empty — cannot create');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      int maxScore;
      dynamic segments;
      String contentStr = '';

      if (_isPhysical) {
        maxScore = int.tryParse(_maxScoreCtrl.text) ?? 10;
        contentStr = _contentCtrl.text.trim();
      } else if (_isCalculate) {
        maxScore = _analysisMaxScore;
        contentStr = _contentCtrl.text.trim();
        segments = _questions.asMap().entries.map((e) {
          final idx = e.key;
          final q = e.value;
          return {
            'id': idx + 1,
            'question': q['question']!.text.trim(),
            'answer': q['answer']!.text.trim(),
            'solution': q['solution']!.text.trim(),
            'score': int.tryParse(q['score']!.text) ?? 1,
          };
        }).toList();
      } else if (_isVoiceQuest) {
        maxScore = int.tryParse(_maxScoreCtrl.text) ?? 100;
        contentStr = 'voice_quest';
        segments = {
          'timeLimit': int.tryParse(_timeLimitCtrl.text) ?? 60,
          'wordCategory': _selectedWordCategory,
        };
      } else {
        // Space Adventure
        maxScore = int.tryParse(_maxScoreCtrl.text) ?? 100;
        contentStr = 'space_adventure';
        segments = {
          'timeLimit': int.tryParse(_timeLimitCtrl.text) ?? 60,
          'scorePerItem': int.tryParse(_scorePerItemCtrl.text) ?? 10,
        };
      }

      await _activityService.createActivity(
        parentId: parentId,
        name: _nameCtrl.text.trim(),
        category: _selectedCategory ?? 'ด้านภาษา',
        content: contentStr,
        difficulty: _difficulty,
        isPublic: false,
        maxScore: maxScore,
        description:
            _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        videoUrl: _isPhysical && _videoUrlCtrl.text.trim().isNotEmpty
            ? _videoUrlCtrl.text.trim()
            : null,
        segments: segments,
      );

      if (!mounted) return;
      _showSnack(l.createActivity_success);
      Navigator.of(context).pop(true); // return true = created
    } catch (e) {
      if (!mounted) return;
      _showSnack('${l.createActivity_error}: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _confirmDiscard() && mounted) nav.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: BoxDecoration(
              color: Palette.sky,
              boxShadow: Palette.buttonShadow,
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: kToolbarHeight,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        if (await _confirmDiscard() && mounted) nav.pop();
                      },
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          _selectedActivityType == null
                              ? l.createActivity_title
                              : (_isPhysical
                                  ? 'สร้างกิจกรรม ด้านร่างกาย'
                                  : (_isCalculate
                                      ? 'สร้างกิจกรรม ด้านคำนวณ'
                                      : (_isVoiceQuest
                                          ? 'สร้างกิจกรรม Voice Quest'
                                          : 'สร้างกิจกรรม Space Adventure'))),
                          style: AppTextStyles.heading(20, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: _selectedActivityType == null ? _buildCategoryPicker(l) : _buildForm(l),
      ),
    );
  }

  // ── Category Picker ────────────────────────────────────

  Widget _buildCategoryPicker(AppLocalizations l) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.createActivity_selectCategory,
                style: AppTextStyles.heading(22)),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _categoryCard(
                  icon: Icons.directions_run,
                  label: l.createActivity_physical,
                  color: Palette.physicalPlaceholder,
                  onTap: () => setState(() {
                    _selectedActivityType = 'physical';
                    _selectedCategory = 'ด้านร่างกาย';
                  }),
                ),
                _categoryCard(
                  icon: Icons.psychology,
                  label: l.createActivity_calculate,
                  color: Palette.blueChip,
                  onTap: () {
                    setState(() {
                      _selectedActivityType = 'calculate';
                      _selectedCategory = 'ด้านคำนวณ';
                    });
                    if (_questions.isEmpty) _addQuestion();
                  },
                ),
                _categoryCard(
                  icon: Icons.mic,
                  label: 'Voice Quest',
                  color: Palette.teal,
                  onTap: () => setState(() {
                    _selectedActivityType = 'voice_quest';
                    _selectedCategory = 'ด้านภาษา';
                    _maxScoreCtrl.text = '100';
                  }),
                ),
                _categoryCard(
                  icon: Icons.auto_awesome,
                  label: 'Space Adventure',
                  color: Palette.sky,
                  onTap: () => setState(() {
                    _selectedActivityType = 'space_adventure';
                    _selectedCategory = 'ด้านภาษา';
                    _maxScoreCtrl.text = '100';
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(label, style: AppTextStyles.label(16, color: color)),
          ],
        ),
      ),
    );
  }

  // ── Form ───────────────────────────────────────────────

  Widget _buildForm(AppLocalizations l) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back to category
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedActivityType = null;
                    _selectedCategory = null;
                  }),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back_ios,
                          size: 14, color: Palette.sky),
                      Text(l.createActivity_selectCategory,
                          style: AppTextStyles.label(13, color: Palette.sky)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Category badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isPhysical
                        ? Palette.physicalPlaceholder
                        : (_isCalculate
                            ? Palette.blueChip
                            : (_isVoiceQuest ? Palette.teal : Palette.sky)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isPhysical
                        ? l.createActivity_physical
                        : (_isCalculate
                            ? l.createActivity_calculate
                            : (_isVoiceQuest ? 'Voice Quest' : 'Space Adventure')),
                    style: AppTextStyles.label(13, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                _label(l.createActivity_name),
                _textField(_nameCtrl),
                const SizedBox(height: 12),

                // Description
                _label(l.createActivity_description),
                _textField(_descCtrl, maxLines: 3),
                const SizedBox(height: 12),

                // Difficulty
                _label(l.createActivity_difficulty),
                _buildDifficultyChips(),
                const SizedBox(height: 12),

                // Category selector for Space Adventure
                if (_isSpaceAdventure) ...[
                  _label('หมวดหมู่กิจกรรม / Category'),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Palette.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Palette.divider),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'ด้านภาษา',
                        child: Text('ด้านภาษา (Language)'),
                      ),
                      DropdownMenuItem(
                        value: 'ด้านร่างกาย',
                        child: Text('ด้านร่างกาย (Physical)'),
                      ),
                      DropdownMenuItem(
                        value: 'ด้านคำนวณ',
                        child: Text('ด้านคำนวณ (Calculate)'),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                  const SizedBox(height: 12),
                ],

                // Word Category selector for Voice Quest
                if (_isVoiceQuest) ...[
                  _label('หมวดหมู่คำศัพท์ / Word Category'),
                  DropdownButtonFormField<String>(
                    value: _selectedWordCategory,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Palette.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Palette.divider),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'animals',
                        child: Text('🦁 สัตว์ (Animals)'),
                      ),
                      DropdownMenuItem(
                        value: 'food',
                        child: Text('🍎 อาหาร (Food)'),
                      ),
                      DropdownMenuItem(
                        value: 'vehicles',
                        child: Text('🚀 ยานพาหนะ (Vehicles)'),
                      ),
                      DropdownMenuItem(
                        value: 'nature',
                        child: Text('🌈 ธรรมชาติ (Nature)'),
                      ),
                      DropdownMenuItem(
                        value: 'bedroom',
                        child: Text('🛏️ ห้องนอน (Bedroom)'),
                      ),
                      DropdownMenuItem(
                        value: 'school',
                        child: Text('🎒 โรงเรียน (School)'),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedWordCategory = val ?? 'animals'),
                  ),
                  const SizedBox(height: 12),
                ],

                // Settings for Voice Quest & Space Adventure
                if (_isVoiceQuest || _isSpaceAdventure) ...[
                  _label('ระยะเวลาที่กำหนด (วินาที) / Time Limit (Seconds)'),
                  _textField(_timeLimitCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                ],

                if (_isVoiceQuest) ...[
                  _label('คะแนนเต็ม / Max Score'),
                  _textField(_maxScoreCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                ],

                if (_isSpaceAdventure) ...[
                  _label('คะแนนต่อวัตถุที่สแกนเจอ / Score Per Item'),
                  _textField(_scorePerItemCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                ],

                if (_isPhysical) ...[
                  // Max Score
                  _label(l.createActivity_maxScore),
                  _textField(_maxScoreCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 12),

                  // Video URL
                  _label(l.createActivity_videoUrl),
                  _textField(_videoUrlCtrl),
                  const SizedBox(height: 12),
                ],

                // Content / Instructions
                if (_isPhysical || _isCalculate) ...[
                  _label(l.createActivity_content),
                  _textField(_contentCtrl, maxLines: 4),
                  const SizedBox(height: 16),
                ],

                if (_isCalculate) ...[
                  // Questions section
                  _label('${l.createActivity_question}  '
                      '(${l.createActivity_maxScore}: $_analysisMaxScore)'),
                  const SizedBox(height: 8),
                  ..._buildQuestionCards(l),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(l.createActivity_addQuestion),
                  ),
                ],

                const SizedBox(height: 80), // space for bottom button
              ],
            ),
          ),
        ),

        // Submit button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.success,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _isSubmitting
                        ? l.createActivity_creating
                        : l.createActivity_submit,
                    style: AppTextStyles.heading(18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Difficulty Chips ───────────────────────────────────

  Widget _buildDifficultyChips() {
    final options = ['ง่าย', 'กลาง', 'ยาก'];
    final labels = [
      AppLocalizations.of(context)!.common_difficultyEasy,
      AppLocalizations.of(context)!.common_difficultyMedium,
      AppLocalizations.of(context)!.common_difficultyHard,
    ];
    return Row(
      children: List.generate(options.length, (i) {
        final selected = _difficulty == options[i];
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(labels[i]),
            selected: selected,
            selectedColor: Palette.warningLight,
            onSelected: (_) => setState(() => _difficulty = options[i]),
          ),
        );
      }),
    );
  }

  // ── Question Cards (Analysis) ──────────────────────────

  List<Widget> _buildQuestionCards(AppLocalizations l) {
    return _questions.asMap().entries.map((entry) {
      final idx = entry.key;
      final q = entry.value;
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.createActivity_questionNo(idx + 1),
                      style: AppTextStyles.label(14)),
                  if (_questions.length > 1)
                    TextButton.icon(
                      onPressed: () => _removeQuestion(idx),
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Palette.deleteRed),
                      label: Text(l.createActivity_removeQuestion,
                          style: const TextStyle(
                              color: Palette.deleteRed, fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _label(l.createActivity_question),
              _textField(q['question']!, maxLines: 2),
              const SizedBox(height: 8),
              _label(l.createActivity_answer),
              _textField(q['answer']!),
              const SizedBox(height: 8),
              _label(l.createActivity_solution),
              _textField(q['solution']!, maxLines: 3),
              const SizedBox(height: 8),
              _label(l.createActivity_score),
              _textField(q['score']!, keyboardType: TextInputType.number),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ── Helpers ────────────────────────────────────────────

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: AppTextStyles.label(13)),
    );
  }

  Widget _textField(
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Palette.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Palette.divider),
        ),
      ),
      style: AppTextStyles.body(14),
    );
  }
}
