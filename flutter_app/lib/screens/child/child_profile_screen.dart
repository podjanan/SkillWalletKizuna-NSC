import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import '../../providers/user_provider.dart';
import '../../services/child_service.dart';
import '../../theme/palette.dart';
import '../../theme/app_text_styles.dart';
import 'activity_history_screen.dart';

class ChildProfileScreen extends StatefulWidget {
  final String? childId; // ใช้สำหรับดึงข้อมูลเด็กคนนี้โดยเฉพาะ
  final String? name;
  final String? imageUrl;
  final int? points;

  const ChildProfileScreen({
    super.key,
    this.childId,
    this.name,
    this.imageUrl,
    this.points,
  });

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  // --- Category Constants (Thai names used in database) ---
  static const String _categoryLanguage = 'ด้านภาษา';
  static const String _categoryPhysical = 'ด้านร่างกาย';
  static const String _categoryCalculate = 'ด้านคำนวณ';

  int _selectedTab = 0;
  final bool _isUploading = false;

  // Activity data
  final ChildService _childService = ChildService();
  List<Map<String, dynamic>> _activityHistory = [];
  Map<String, int> _categoryStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivityData();
  }

  Future<void> _loadActivityData() async {
    // ใช้ childId ที่ส่งมา หรือถ้าไม่มีให้ใช้ currentChildId จาก Provider
    final userProvider = context.read<UserProvider>();
    final childId = widget.childId ?? userProvider.currentChildId;

    if (childId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final history = await _childService.getActivityHistory(childId);

      // Count activities by category
      Map<String, int> stats = {
        _categoryLanguage: 0,
        _categoryPhysical: 0,
        _categoryCalculate: 0,
      };

      for (var record in history) {
        final category = _normalizeCategory(
          record['activity']?['category'] as String?,
        );
        if (category != null && stats.containsKey(category)) {
          stats[category] = (stats[category] ?? 0) + 1;
        }
      }

      setState(() {
        _activityHistory = history;
        _categoryStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading activity data: $e');
      setState(() => _isLoading = false);
    }
  }

  String? _normalizeCategory(String? category) {
    final normalized = category?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) return null;
    if (normalized == 'LANGUAGE' || normalized == 'AI WORD GAME') {
      return _categoryLanguage;
    }
    if (normalized == 'PHYSICAL') {
      return _categoryPhysical;
    }
    if (normalized == 'CALCULATION' || normalized == 'CALCULATE') {
      return _categoryCalculate;
    }
    return category;
  }

  @override
  Widget build(BuildContext context) {
    // Get real data from Provider
    final userProvider = context.watch<UserProvider>();
    final l10n = AppLocalizations.of(context)!;
    final childName =
        widget.name ?? userProvider.currentChildName ?? l10n.childprofile_unknownName;
    final childWallet = widget.points ?? userProvider.currentChildWallet;

    // ดึง photo_url ล่าสุดจาก provider (อัปเดตหลัง upload) แทน widget param
    final childId = widget.childId;
    String imageUrl = widget.imageUrl ?? '';
    if (childId != null) {
      final match = userProvider.children.firstWhere(
        (c) => c['child']?['child_id'] == childId,
        orElse: () => {},
      );
      final fresh = match['child']?['photo_url'] as String?;
      if (fresh != null && fresh.isNotEmpty) imageUrl = fresh;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: Palette.orangeGradient,
          boxShadow: Palette.orangeButtonShadow,
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: GestureDetector(
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/', (_) => false),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Palette.yellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Palette.sky))
            : RefreshIndicator(
                onRefresh: _loadActivityData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // --- Back Button ---
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              color: Colors.transparent,
                              child: const Icon(Icons.arrow_back,
                                  size: 30, color: Colors.black87),
                            ),
                          ),
                        ),
                      ),

                      // --- 1. Profile Image ---
                      Center(
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade300,
                          ),
                          child: ClipOval(
                            child: _buildProfileImage(imageUrl),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // --- 2. Name ---
                      Text(
                        childName,
                        style: AppTextStyles.heading(36, color: Palette.text)
                            .copyWith(letterSpacing: 1.2),
                        textAlign: TextAlign.center,
                      ),

                      // --- 3. Points ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/medal.png',
                            width: 50,
                            height: 50,
                            errorBuilder: (_, __, ___) => const Icon(Icons.star,
                                color: Colors.amber, size: 40),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$childWallet',
                            style: AppTextStyles.heading(40,
                                color: Palette.yellow),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // --- 4. Menu Tabs ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTabIcon(
                              index: 0, assetPath: 'assets/icons/gallery.png'),
                          const SizedBox(width: 60),
                          _buildTabIcon(
                              index: 1,
                              assetPath: 'assets/icons/finish-line.png'),
                        ],
                      ),

                      // --- Divider ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Divider(
                          color: Colors.grey.withValues(alpha: 0.4),
                          thickness: 1,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- 5. Content Area ---
                      _selectedTab == 0
                          ? _buildStatsView()
                          : _buildCategoryListView(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProfileImage(String imageUrl) {
    if (_isUploading) {
      return const Center(
        child: CircularProgressIndicator(color: Palette.sky),
      );
    }

    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: 160,
        height: 160,
        errorBuilder: (_, __, ___) => _buildDefaultProfileIcon(),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : Container(color: Colors.grey.shade300),
      );
    }

    return _buildDefaultProfileIcon();
  }

  Widget _buildDefaultProfileIcon() {
    return Container(
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      width: 160,
      height: 160,
      child: Icon(Icons.person, size: 80, color: Colors.grey.shade500),
    );
  }

  Widget _buildTabIcon({required int index, required String assetPath}) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              isSelected ? Colors.white.withValues(alpha: 0.5) : Colors.transparent,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.6),
          colorBlendMode: isSelected ? null : BlendMode.modulate,
          errorBuilder: (_, __, ___) => Icon(
            index == 0 ? Icons.bar_chart : Icons.emoji_events,
            size: 40,
            color: isSelected ? Palette.text : Colors.grey,
          ),
        ),
      ),
    );
  }

  // แสดงสถิติกิจกรรม
  Widget _buildStatsView() {
    final totalActivities = _activityHistory.length;

    if (totalActivities == 0) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.childprofile_noHistory,
              style: AppTextStyles.body(20, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.childprofile_startPlaying,
              style: AppTextStyles.body(16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Total activities card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.childprofile_totalActivities,
                  style: AppTextStyles.body(18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalActivities',
                  style: AppTextStyles.heading(48, color: Palette.sky),
                ),
                Text(
                  AppLocalizations.of(context)!.childprofile_times,
                  style: AppTextStyles.body(16, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Category breakdown
          Row(
            children: [
              _buildStatCard(
                  AppLocalizations.of(context)!.childprofile_language,
                  _categoryStats[_categoryLanguage] ?? 0,
                  const Color(0xFFFFB300),
                  icon: Icons.menu_book_rounded),
              const SizedBox(width: 12),
              _buildStatCard(
                  AppLocalizations.of(context)!.childprofile_physical,
                  _categoryStats[_categoryPhysical] ?? 0,
                  Palette.pink,
                  icon: Icons.directions_run_rounded),
              const SizedBox(width: 12),
              _buildStatCard(
                  AppLocalizations.of(context)!.childprofile_calculation,
                  _categoryStats[_categoryCalculate] ?? 0,
                  Palette.sky,
                  icon: Icons.calculate_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color accent,
      {IconData? icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: Palette.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: icon != null
                  ? Icon(icon, size: 24, color: accent)
                  : Icon(Icons.calculate_rounded, size: 24, color: accent),
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: AppTextStyles.heading(22, color: accent),
            ),
            Text(
              title.replaceAll('ด้าน', ''),
              style: AppTextStyles.label(11, color: Palette.labelGrey),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // แสดงรายการหมวดหมู่กิจกรรม
  Widget _buildCategoryListView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          _buildCategoryButton(
            AppLocalizations.of(context)!.childprofile_language,
            const Color(0xFFFFB300),
            _categoryStats[_categoryLanguage] ?? 0,
            () => _navigateToHistory(_categoryLanguage),
            icon: Icons.menu_book_rounded,
          ),
          const SizedBox(height: 12),
          _buildCategoryButton(
            AppLocalizations.of(context)!.childprofile_physical,
            Palette.pink,
            _categoryStats[_categoryPhysical] ?? 0,
            () => _navigateToHistory(_categoryPhysical),
            icon: Icons.directions_run_rounded,
          ),
          const SizedBox(height: 12),
          _buildCategoryButton(
            AppLocalizations.of(context)!.childprofile_calculation,
            Palette.sky,
            _categoryStats[_categoryCalculate] ?? 0,
            () => _navigateToHistory(_categoryCalculate),
            icon: Icons.calculate_rounded,
          ),
        ],
      ),
    );
  }

  void _navigateToHistory(String category) {
    // ใช้ childId ที่ส่งมา หรือ currentChildId จาก Provider
    final userProvider = context.read<UserProvider>();
    final childId = widget.childId ?? userProvider.currentChildId;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityHistoryScreen(
          gameName: category,
          childId: childId,
        ),
      ),
    );
  }

  Widget _buildCategoryButton(
    String title,
    Color accent,
    int count,
    VoidCallback onTap, {
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: Palette.cardShadow,
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(
          children: [
            // Left accent strip
            Container(width: 4, color: accent),
            const SizedBox(width: 14),
            // Icon circle
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon ?? Icons.star_rounded,
                  color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            // Title
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.heading(16, color: Palette.text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Count badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count ${AppLocalizations.of(context)!.childprofile_times}',
                style: AppTextStyles.label(12, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right_rounded, size: 22, color: accent),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}
