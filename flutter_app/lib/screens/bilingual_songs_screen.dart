import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/bilingual_song_model.dart';
import '../providers/user_provider.dart';
import '../services/bilingual_song_service.dart';
import '../theme/app_text_styles.dart';
import '../theme/palette.dart';
import '../widgets/game_activity_cover.dart';
import 'bilingual_song_player_screen.dart';

class BilingualSongsScreen extends StatefulWidget {
  static const String routeName = '/bilingual-songs';

  const BilingualSongsScreen({super.key});

  @override
  State<BilingualSongsScreen> createState() => _BilingualSongsScreenState();
}

class _BilingualSongsScreenState extends State<BilingualSongsScreen> {
  List<BilingualSongModel> _songs = [];
  BilingualSongModel? _selectedSong;
  bool _isLoading = true;
  List<String> _extraChildIds = [];
  bool _isCreatingOwnSong = false;
  String _customInputType = 'vocabulary';
  String _customMusicStyle = 'เพลงเด็กสนุกสนาน';
  final TextEditingController _customSongPromptController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  @override
  void dispose() {
    _customSongPromptController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    final songs = await BilingualSongService.fetchSongs();
    if (mounted) {
      setState(() {
        _songs = songs;
        _selectedSong = songs.isNotEmpty ? songs.first : null;
        _isLoading = false;
      });
    }
  }

  void _startSong(BilingualSongModel song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BilingualSongPlayerScreen(
          song: song,
          extraChildIds: _extraChildIds,
        ),
      ),
    );
  }

  void _showAddChildrenSheet() {
    final userProvider = context.read<UserProvider>();
    final children = userProvider.children;
    final currentChildId = userProvider.currentChildId;
    final l = AppLocalizations.of(context)!;

    final tempSelected = Set<String>.from(_extraChildIds);

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Palette.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.physical_addChildren,
                      style: AppTextStyles.heading(20, color: Palette.sky)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(l.physical_addChildrenDesc,
                  style: AppTextStyles.body(14, color: Colors.black54)),
              const SizedBox(height: 16),
              ...children.map((childData) {
                final info = childData['child'] as Map<String, dynamic>?;
                if (info == null) return const SizedBox.shrink();
                final childId = info['child_id'] as String;
                final childName = info['name_surname'] as String? ?? '';
                final isCurrent = childId == currentChildId;
                final isSelected = isCurrent || tempSelected.contains(childId);

                return GestureDetector(
                  onTap: isCurrent
                      ? null
                      : () {
                          setModalState(() {
                            if (tempSelected.contains(childId)) {
                              tempSelected.remove(childId);
                            } else {
                              tempSelected.add(childId);
                            }
                          });
                        },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Palette.sky.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? Palette.sky : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected ? Palette.sky : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Palette.sky.withValues(alpha: 0.2),
                          child: Text(
                            childName.isNotEmpty
                                ? childName[0].toUpperCase()
                                : '?',
                            style:
                                AppTextStyles.heading(16, color: Palette.sky),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(childName,
                              style: AppTextStyles.label(16,
                                  color: Colors.black87)),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Palette.sky,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(l.physical_currentChild,
                                style: AppTextStyles.label(11,
                                    color: Colors.white)),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _extraChildIds = tempSelected.toList();
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.sky,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(l.physical_confirm,
                      style: AppTextStyles.heading(18, color: Colors.white)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCEB),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Palette.sky),
              )
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    // Top Bar (Back Button + Title)
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 24, color: Colors.black87),
                        ),
                        const Expanded(
                          child: Text(
                            'Sing Together',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Top Status Row (EASY, High Score, Timer)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // EASY badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Palette.sky, width: 2),
                          ),
                          child: Text(
                            'EASY',
                            style: AppTextStyles.label(12, color: Palette.sky),
                          ),
                        ),

                        Row(
                          children: [
                            // High Score
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: Palette.softShadow,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.emoji_events_rounded,
                                      size: 16, color: Colors.amber),
                                  const SizedBox(width: 6),
                                  Text(
                                    'High: 100',
                                    style: AppTextStyles.label(12,
                                        color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Timer
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: Palette.softShadow,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.timer_rounded,
                                      size: 16, color: Palette.sky),
                                  const SizedBox(width: 6),
                                  Text(
                                    '10 Min',
                                    style: AppTextStyles.label(12,
                                        color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Main Activity Card (White Container with Voice Quest Style)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: Palette.cardShadow,
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Large Banner Cover
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: const SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: GameActivityCover(
                                type: GameCoverType.singTogether,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Language Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Language',
                                  style: AppTextStyles.label(13,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Heading Text
                          const Text(
                            'Sing the song,\nwin the stars!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Song source selector
                          Row(
                            children: [
                              Expanded(
                                child: _buildSongSourceCard(
                                  title: 'เลือกเพลงจากเรา',
                                  subtitle: 'เพลงพร้อมเล่น',
                                  icon: Icons.library_music_rounded,
                                  selected: !_isCreatingOwnSong,
                                  onTap: () => setState(
                                      () => _isCreatingOwnSong = false),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildSongSourceCard(
                                  title: 'สร้างเพลงเอง',
                                  subtitle: 'คำศัพท์ / ประโยค',
                                  icon: Icons.auto_awesome_rounded,
                                  selected: _isCreatingOwnSong,
                                  onTap: () =>
                                      setState(() => _isCreatingOwnSong = true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Song Selector Dropdown
                          if (!_isCreatingOwnSong && _songs.isNotEmpty) ...[
                            _buildLabelInput(
                              label: 'Choose Song',
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<BilingualSongModel>(
                                  value: _selectedSong ?? _songs.first,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down,
                                      color: Colors.grey),
                                  items: _songs.map((song) {
                                    return DropdownMenuItem<BilingualSongModel>(
                                      value: song,
                                      child: Text(
                                        '🎵 ${song.titleEn} (${song.titleTh})',
                                        style: AppTextStyles.body(14,
                                            color: Colors.black87),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedSong = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Multi-Child Selection Card
                            GestureDetector(
                              onTap: _showAddChildrenSheet,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color:
                                          Palette.sky.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            Palette.sky.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.group_add_rounded,
                                          color: Palette.sky, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'เด็กที่จะร้องเพลงด้วยกัน (${_extraChildIds.length + 1} คน)',
                                            style: AppTextStyles.label(13,
                                                color: Palette.text),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _extraChildIds.isEmpty
                                                ? 'แตะที่นี่เพื่อเลือกเด็กเพิ่ม'
                                                : '+ เพิ่มเด็กเรียบร้อยแล้ว ${_extraChildIds.length} คน',
                                            style: AppTextStyles.body(11,
                                                color: _extraChildIds.isEmpty
                                                    ? Colors.grey
                                                    : Palette.sky),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded,
                                        size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Big Start Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_selectedSong != null) {
                                    _startSong(_selectedSong!);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Palette.successAlt,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.music_note_rounded,
                                        size: 24, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      'START SINGING',
                                      style: AppTextStyles.label(15,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (!_isCreatingOwnSong && _songs.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Text(
                                'ยังไม่มีเพลงจากระบบในขณะนี้',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          if (_isCreatingOwnSong) _buildCustomSongComposer(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSongSourceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? Palette.sky.withValues(alpha: 0.12)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Palette.sky : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: selected ? Palette.sky : Colors.grey),
            const SizedBox(height: 7),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.label(
                13,
                color: selected ? Palette.sky : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSongComposer() {
    final isVocabulary = _customInputType == 'vocabulary';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.orange, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สร้างเพลงฝึกจำของครอบครัว',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'ใส่เนื้อหาที่อยากให้เด็กจดจำ แล้วนำไปแต่งเป็นเพลง',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'อยากฝึกแบบไหน?',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  selected: isVocabulary,
                  showCheckmark: false,
                  avatar: Icon(Icons.abc_rounded,
                      size: 20,
                      color: isVocabulary ? Colors.white : Palette.sky),
                  label: const Text('คำศัพท์'),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isVocabulary ? Colors.white : Colors.black87,
                  ),
                  selectedColor: Palette.sky,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                      color: isVocabulary ? Palette.sky : Colors.grey.shade300),
                  onSelected: (_) =>
                      setState(() => _customInputType = 'vocabulary'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  selected: !isVocabulary,
                  showCheckmark: false,
                  avatar: Icon(Icons.short_text_rounded,
                      size: 20,
                      color: !isVocabulary ? Colors.white : Palette.sky),
                  label: const Text('รูปประโยค'),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: !isVocabulary ? Colors.white : Colors.black87,
                  ),
                  selectedColor: Palette.sky,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                      color:
                          !isVocabulary ? Palette.sky : Colors.grey.shade300),
                  onSelected: (_) =>
                      setState(() => _customInputType = 'sentence'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isVocabulary
                ? 'คำศัพท์ที่อยากให้เด็กฝึกจำ'
                : 'รูปประโยคที่อยากให้เด็กฝึกจำ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _customSongPromptController,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: isVocabulary
                  ? 'เช่น apple, banana, orange, happy'
                  : 'เช่น I brush my teeth every morning.\nฉันแปรงฟันทุกเช้า',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Palette.sky, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildLabelInput(
            label: 'แนวเพลง',
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _customMusicStyle,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                items: const [
                  'เพลงเด็กสนุกสนาน',
                  'ป๊อปเต้นตามได้',
                  'เพลงช้าอบอุ่น',
                  'ฮิปฮอปสำหรับเด็ก',
                ]
                    .map((style) => DropdownMenuItem(
                          value: style,
                          child: Text(style),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _customMusicStyle = value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'UI พร้อมแล้ว — ระบบสร้างเพลงจะเชื่อมต่อในขั้นตอนถัดไป'),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
              label: Text(
                'สร้างเพลงจากเนื้อหานี้',
                style: AppTextStyles.label(15, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelInput({required String label, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          child,
        ],
      ),
    );
  }
}
