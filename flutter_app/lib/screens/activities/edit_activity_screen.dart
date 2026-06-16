import 'package:flutter/material.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';

import '../../models/activity.dart';
import '../../services/activity_service.dart';
import '../../theme/palette.dart';
import '../../theme/app_text_styles.dart';

class EditActivityScreen extends StatefulWidget {
  final Activity activity;
  const EditActivityScreen({super.key, required this.activity});

  @override
  State<EditActivityScreen> createState() => _EditActivityScreenState();
}

class _EditActivityScreenState extends State<EditActivityScreen> {
  final ActivityService _activityService = ActivityService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _maxScoreCtrl;
  late final TextEditingController _videoUrlCtrl;
  late String _difficulty;
  late final bool _isPhysical;
  bool _isSubmitting = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    _isPhysical = a.category == 'ด้านร่างกาย';
    _nameCtrl = TextEditingController(text: a.name);
    _descCtrl = TextEditingController(text: a.description ?? '');
    _contentCtrl = TextEditingController(text: a.content);
    _maxScoreCtrl = TextEditingController(text: a.maxScore.toString());
    _videoUrlCtrl = TextEditingController(text: a.videoUrl ?? '');
    _difficulty = a.difficulty;
    for (final c in [_nameCtrl, _descCtrl, _contentCtrl, _maxScoreCtrl, _videoUrlCtrl]) {
      c.addListener(_markDirty);
    }
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _contentCtrl.dispose();
    _maxScoreCtrl.dispose();
    _videoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack(l.createActivity_nameRequired);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _activityService.updateActivity(
        activityId: widget.activity.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        difficulty: _difficulty,
        maxScore: _isPhysical ? int.tryParse(_maxScoreCtrl.text) : null,
        videoUrl: _isPhysical ? _videoUrlCtrl.text.trim() : null,
      );
      if (!mounted) return;
      _showSnack(l.profile_updateSuccess);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

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
      appBar: AppBar(
        backgroundColor: Palette.sky,
        title: Text(l.profile_editActivity,
            style: AppTextStyles.heading(20, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            final nav = Navigator.of(context);
            if (await _confirmDiscard() && mounted) nav.pop();
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isPhysical
                          ? Palette.physicalPlaceholder
                          : Palette.blueChip,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isPhysical
                          ? l.createActivity_physical
                          : l.createActivity_calculate,
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

                  if (_isPhysical) ...[
                    // Max Score
                    _label(l.createActivity_maxScore),
                    _textField(_maxScoreCtrl,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 12),

                    // Video URL
                    _label(l.createActivity_videoUrl),
                    _textField(_videoUrlCtrl),
                    const SizedBox(height: 12),
                  ],

                  // Content / Instructions
                  _label(l.createActivity_content),
                  _textField(_contentCtrl, maxLines: 5),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Save button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.success,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _isSubmitting ? l.createActivity_creating : l.profile_save,
                    style: AppTextStyles.heading(18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ), // PopScope
    );
  }

  Widget _buildDifficultyChips() {
    final l = AppLocalizations.of(context)!;
    final options = ['ง่าย', 'กลาง', 'ยาก'];
    final labels = [
      l.common_difficultyEasy,
      l.common_difficultyMedium,
      l.common_difficultyHard,
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
