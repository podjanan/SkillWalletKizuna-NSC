import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bilingual_song_model.dart';
import '../providers/user_provider.dart';
import '../services/bilingual_song_service.dart';
import '../theme/app_text_styles.dart';
import '../theme/palette.dart';
import '../widgets/child_avatar.dart';
import '../widgets/game_activity_cover.dart';
import 'bilingual_song_player_screen.dart';

class ChildParticipant {
  final String id;
  final String name;
  final String? photoUrl;

  const ChildParticipant({
    required this.id,
    required this.name,
    this.photoUrl,
  });
}

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
  final Set<String> _selectedChildIds = {};
  bool _childrenInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_childrenInitialized) {
      final userProvider = context.read<UserProvider>();
      final currentId = userProvider.currentChildId;
      if (currentId != null) {
        _selectedChildIds.add(currentId);
      }
      _childrenInitialized = true;
    }
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

  List<ChildParticipant> _getAvailableChildren(UserProvider userProvider) {
    final list = <ChildParticipant>[];
    for (final item in userProvider.children) {
      final child = item['child'] as Map<String, dynamic>?;
      if (child != null) {
        final id = child['child_id']?.toString();
        final name = child['name_surname']?.toString();
        final photo = child['photo_url']?.toString();
        if (id != null && name != null) {
          list.add(ChildParticipant(id: id, name: name, photoUrl: photo));
        }
      }
    }
    if (list.isEmpty && userProvider.currentChildId != null) {
      list.add(ChildParticipant(
        id: userProvider.currentChildId!,
        name: userProvider.currentChildName ?? 'Child',
      ));
    }
    return list;
  }

  void _startSong(BilingualSongModel song, UserProvider userProvider) {
    final available = _getAvailableChildren(userProvider);
    var selectedList = available
        .where((c) => _selectedChildIds.contains(c.id))
        .toList();

    if (selectedList.isEmpty && available.isNotEmpty) {
      selectedList = [available.first];
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BilingualSongPlayerScreen(
          song: song,
          participatingChildren: selectedList,
        ),
      ),
    );
  }

  Widget _buildChildSelector(UserProvider userProvider) {
    final available = _getAvailableChildren(userProvider);
    if (available.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_rounded, size: 20, color: Palette.sky),
              const SizedBox(width: 6),
              const Text(
                'Select Participating Children / เลือกเด็กที่จะร้องเต้นด้วยกัน',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: available.map((child) {
              final isSelected = _selectedChildIds.contains(child.id);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      if (_selectedChildIds.length > 1) {
                        _selectedChildIds.remove(child.id);
                      }
                    } else {
                      _selectedChildIds.add(child.id);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Palette.sky.withValues(alpha: 0.15)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Palette.sky : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChildAvatar(
                        name: child.name,
                        photoUrl: child.photoUrl,
                        radius: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        child.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Palette.sky : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                        size: 18,
                        color: isSelected ? Palette.sky : Colors.grey,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCEB),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Palette.sky),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          // Large Banner Cover using Voice Quest cover art
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

                          // Physical Category Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Palette.sky,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.directions_run_rounded,
                                    size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Physical / ร่างกาย',
                                  style: AppTextStyles.label(13,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Heading Text
                          const Text(
                            'Sing & Dance Together!\nร้องเพลงเต้นด้วยกันกับลูก',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Child Selector & Song Selector Dropdown
                          _buildChildSelector(userProvider),

                          if (_songs.isNotEmpty) ...[
                            _buildLabelInput(
                              label: 'Choose Song / เลือกเพลง',
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
                            const SizedBox(height: 24),

                            // Big Start Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_selectedSong != null) {
                                    _startSong(_selectedSong!, userProvider);
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
                                      'START SINGING & DANCING',
                                      style: AppTextStyles.label(15,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
