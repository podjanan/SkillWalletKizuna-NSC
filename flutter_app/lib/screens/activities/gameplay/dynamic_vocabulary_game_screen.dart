import 'package:flutter/material.dart';

import '../../../models/dynamic_vocabulary_item.dart';
import '../../../routes/app_routes.dart';
import '../../../services/dynamic_vocabulary_service.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/palette.dart';

class DynamicVocabularyGameScreen extends StatefulWidget {
  const DynamicVocabularyGameScreen({super.key});

  @override
  State<DynamicVocabularyGameScreen> createState() =>
      _DynamicVocabularyGameScreenState();
}

class _DynamicVocabularyGameScreenState
    extends State<DynamicVocabularyGameScreen> {
  final DynamicVocabularyService _service = DynamicVocabularyService();

  static const List<_VocabularyCategory> _fallbackCategories = [
    _VocabularyCategory('animals', 'Animals', 'สัตว์', Icons.pets_rounded,
        Palette.successAlt),
    _VocabularyCategory('food', 'Food', 'อาหาร', Icons.restaurant_rounded,
        Palette.warning),
    _VocabularyCategory('vehicles', 'Vehicles', 'ยานพาหนะ',
        Icons.directions_car_rounded, Palette.sky),
    _VocabularyCategory('nature', 'Nature', 'ธรรมชาติ', Icons.park_rounded,
        Palette.teal),
  ];

  List<_VocabularyCategory> _categories = _fallbackCategories;
  String? _selectedCategory;
  DynamicVocabularyItem? _item;
  Map<String, dynamic>? _practiceResult;
  bool _isLoadingCategories = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

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

  Future<void> _generate(String category) async {
    setState(() {
      _selectedCategory = category;
      _item = null;
      _practiceResult = null;
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final item = await _service.generate(category: category);
      if (!mounted) return;
      setState(() {
        _item = item;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Cannot generate vocabulary right now. $e';
        _isLoading = false;
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        centerTitle: true,
        title: Text(
          'AI WORD GAME',
          style: AppTextStyles.heading(20, color: Palette.sky),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildCategoryGrid(),
            const SizedBox(height: 18),
            if (_isLoading) _buildLoadingWorkflow(),
            if (_errorMessage != null) _buildErrorCard(),
            if (_item != null) _buildResultCard(_item!),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: Palette.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Palette.sky.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Palette.sky, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a category',
                  style: AppTextStyles.heading(17, color: Palette.text),
                ),
                const SizedBox(height: 3),
                Text(
                  'Gemini Flash picks one word, then the app finds a kid-friendly image.',
                  style: AppTextStyles.body(12, color: Palette.deepGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    if (_isLoadingCategories) {
      return const SizedBox(
        height: 110,
        child: Center(
          child: CircularProgressIndicator(color: Palette.sky),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.55,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final category = _categories[index];
        final selected = _selectedCategory == category.id;
        return InkWell(
          onTap: _isLoading ? null : () => _generate(category.id),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? category.color : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? category.color : Colors.grey.shade200,
                width: 1.5,
              ),
              boxShadow: selected ? Palette.buttonShadow : Palette.softShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.2)
                        : category.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category.icon,
                    color: selected ? Colors.white : category.color,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        style: AppTextStyles.heading(
                          14,
                          color: selected ? Colors.white : Palette.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        category.thaiLabel,
                        style: AppTextStyles.body(
                          12,
                          color: selected
                              ? Colors.white.withValues(alpha: 0.85)
                              : Palette.deepGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingWorkflow() {
    const steps = [
      ('Category selected', Icons.touch_app_rounded),
      ('Gemini Flash picks a word', Icons.auto_awesome_rounded),
      ('Image API searches illustration', Icons.image_search_rounded),
      ('Preparing word card', Icons.dashboard_customize_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: Palette.cardShadow,
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Palette.sky,
            ),
          ),
          const SizedBox(height: 14),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(step.$2, size: 18, color: Palette.sky),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      step.$1,
                      style: AppTextStyles.label(13, color: Palette.deepGrey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: Palette.cardShadow,
        border: Border.all(color: Palette.errorStrong.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Palette.errorStrong, size: 36),
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(13, color: Palette.deepGrey),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _selectedCategory == null
                ? null
                : () => _generate(_selectedCategory!),
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.sky,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(DynamicVocabularyItem item) {
    final meaning = item.thaiMeaning?.trim();
    final phonetic = item.phonetic?.trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: Palette.cardShadow,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: item.imageUrl == null || item.imageUrl!.isEmpty
                ? _buildImageFallback(item.word)
                : Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildImageFallback(item.word),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Palette.sky),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              children: [
                Text(
                  item.word.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading(34, color: Palette.text),
                ),
                if (phonetic != null && phonetic.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    phonetic,
                    style: AppTextStyles.label(14, color: Palette.sky),
                  ),
                ],
                if (meaning != null && meaning.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    meaning,
                    style: AppTextStyles.body(18, color: Palette.deepGrey),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        icon: Icons.refresh_rounded,
                        label: 'New Word',
                        color: Palette.sky,
                        onTap: _selectedCategory == null
                            ? null
                            : () => _generate(_selectedCategory!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionButton(
                        icon: Icons.mic_rounded,
                        label: 'Practice',
                        color: Palette.successAlt,
                        onTap: () => _openPractice(item.word),
                      ),
                    ),
                  ],
                ),
                if (_practiceResult != null) ...[
                  const SizedBox(height: 14),
                  _buildPracticeResult(),
                ],
                if (item.query.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    item.query,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(11, color: Palette.labelGrey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFallback(String word) {
    return Container(
      color: Palette.sky.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_rounded, color: Palette.sky, size: 54),
          const SizedBox(height: 8),
          Text(
            word,
            style: AppTextStyles.heading(20, color: Palette.sky),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: onTap == null ? color.withValues(alpha: 0.5) : color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: onTap == null ? null : Palette.softShadow,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.label(14, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeResult() {
    final score = _practiceResult?['score'] as int? ?? 0;
    final recognizedText =
        _practiceResult?['recognizedText']?.toString().trim() ?? '';
    final passed = score >= 70;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (passed ? Palette.successAlt : Palette.warning)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (passed ? Palette.successAlt : Palette.warning)
              .withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.replay_rounded,
            color: passed ? Palette.successAlt : Palette.warning,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pronunciation score: $score%',
                  style: AppTextStyles.label(13, color: Palette.text),
                ),
                if (recognizedText.isNotEmpty)
                  Text(
                    'Heard: $recognizedText',
                    style: AppTextStyles.body(12, color: Palette.deepGrey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPractice(String word) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.record,
      arguments: {'originalText': word},
    );
    if (!mounted || result is! Map) return;
    setState(() {
      _practiceResult = Map<String, dynamic>.from(result);
    });
  }
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
