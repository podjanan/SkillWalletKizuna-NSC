import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import 'package:skill_wallet_kizuna/services/storage_service.dart';

import '../../models/activity.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/activity_service.dart';
import '../../theme/palette.dart';
import '../../theme/app_text_styles.dart';
import '../activities/edit_activity_screen.dart';
import 'settings/setting_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onActivityChanged;

  const ProfileScreen({super.key, this.onActivityChanged});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final ActivityService _activityService = ActivityService();
  List<Activity> _myActivities = [];
  bool _loading = true;
  bool _isEditMode = false;
  bool _uploading = false;
  UserProvider? _userProvider;
  String? _lastParentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userProvider = context.read<UserProvider>();
      _lastParentId = _userProvider?.currentParentId;
      _userProvider!.addListener(_onProviderChanged);
      _loadActivities();
    });
  }

  void _onProviderChanged() {
    final parentId = _userProvider?.currentParentId;
    // Only reload when parentId actually changes (account switch)
    if (parentId != _lastParentId) {
      _lastParentId = parentId;
      if (mounted) {
        setState(() {
          _myActivities = [];
          _loading = parentId != null && parentId.isNotEmpty;
        });
      }
      if (parentId != null && parentId.isNotEmpty) {
        _loadActivities();
      }
    }
  }

  @override
  void dispose() {
    _userProvider?.removeListener(_onProviderChanged);
    super.dispose();
  }

  /// Public method so HomeScreen can trigger a reload.
  void reloadActivities() => _loadActivities();

  // ── Photo picker (parent) ──────────────────────────────

  Future<void> _showPhotoOptions() async {
    final oauthPhotoUrl = await StorageService().getOAuthPhotoUrl();
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.common_pickFromGallery),
              onTap: () { Navigator.pop(ctx); _pickFromGallery(); },
            ),
            if (oauthPhotoUrl != null)
              ListTile(
                leading: const Icon(Icons.account_circle_outlined, size: 28),
                title: Text(l.common_useOriginalPhoto),
                onTap: () { Navigator.pop(ctx); _useOAuthPhoto('oauth'); },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    final ok = await context.read<UserProvider>().uploadAndSetPhoto(bytes);
    if (mounted) {
      setState(() => _uploading = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.common_uploadPhotoFailed),
        ));
      }
    }
  }

  Future<void> _useOAuthPhoto(String provider) async {
    setState(() => _uploading = true);
    final ok = await context.read<UserProvider>().setPhotoFromOAuth(provider);
    if (mounted) setState(() => _uploading = false);
    if (mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            AppLocalizations.of(context)!.common_photoNotFound(provider)),
      ));
    }
  }

  Future<void> _loadActivities() async {
    final parentId =
        Provider.of<UserProvider>(context, listen: false).currentParentId;
    if (parentId == null || parentId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    final activities = await _activityService.fetchMyActivities(parentId);
    if (mounted) {
      setState(() {
        _myActivities = activities;
        _loading = false;
      });
    }
  }

  /// Translate raw difficulty value to localized string
  String _translateDifficulty(String raw, AppLocalizations l) {
    switch (raw) {
      case 'ง่าย':
        return l.common_difficultyEasy;
      case 'กลาง':
        return l.common_difficultyMedium;
      case 'ยาก':
        return l.common_difficultyHard;
      default:
        return raw;
    }
  }

  // ── Play activity ───────────────────────────────────────

  void _playActivity(Activity activity) {
    final category = activity.category;
    String routeName;

    if (category == 'ด้านภาษา' || category == 'LANGUAGE') {
      routeName = AppRoutes.languageDetail;
    } else if (category == 'ด้านร่างกาย' && activity.videoUrl != null) {
      routeName = AppRoutes.videoDetail;
    } else if (category == 'ด้านคำนวณ') {
      routeName = AppRoutes.calculateActivity;
    } else {
      routeName = AppRoutes.itemIntro;
    }

    Navigator.pushNamed(context, routeName, arguments: activity);
  }

  // ── Navigate to edit ───────────────────────────────────

  void _openEdit(Activity activity) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditActivityScreen(activity: activity),
      ),
    );
    if (result == true) {
      _loadActivities();
      widget.onActivityChanged?.call();
    }
  }

  // ── Delete ─────────────────────────────────────────────

  void _showDeleteDialog(Activity activity) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.profile_deleteActivity, style: AppTextStyles.heading(18)),
        content: Text(l.profile_deleteConfirm(activity.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.dialog_cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _activityService.deleteActivity(activity.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.profile_deleteSuccess)),
                  );
                  _loadActivities();
                  widget.onActivityChanged?.call();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(l.dialog_confirmDelete,
                style: const TextStyle(color: Palette.deleteRed)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final parentName = userProvider.currentParentName ?? 'PARENT';
    final photoUrl = userProvider.parentPhotoUrl;
    final l = AppLocalizations.of(context)!;

    return SafeArea(
      top: true,
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            const SizedBox(height: 16),
            // ── Header ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _showPhotoOptions,
                          child: Stack(
                            children: [
                              Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade300,
                                  image: photoUrl != null && !_uploading
                                      ? DecorationImage(
                                          image: NetworkImage(photoUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _uploading
                                    ? const CircularProgressIndicator(
                                        color: Palette.sky)
                                    : photoUrl == null
                                        ? const Icon(Icons.person,
                                            size: 80, color: Colors.grey)
                                        : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Palette.yellow,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Palette.cream, width: 3),
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      size: 24, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(parentName, style: AppTextStyles.heading(24)),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.settings, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Section header ───────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sports_esports, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(l.profile_myActivities,
                            style: AppTextStyles.heading(18)),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isEditMode = !_isEditMode),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isEditMode ? Palette.warning : Palette.sky,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            l.profile_manage,
                            style: AppTextStyles.label(12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(thickness: 1),
                ],
              ),
            ),

            // ── Activity list ────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _myActivities.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.sports_esports_outlined,
                                  size: 48, color: Palette.labelGrey),
                              const SizedBox(height: 8),
                              Text(l.profile_noActivities,
                                  style: AppTextStyles.body(16,
                                      color: Palette.labelGrey)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadActivities,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: _myActivities.length,
                            itemBuilder: (context, index) =>
                                _buildActivityCard(_myActivities[index], l),
                          ),
                        ),
            ),
          ],
        ),
      );
  }

  // ── Category helpers ───────────────────────────────────

  static Color _categoryAccent(String category) {
    switch (category) {
      case 'ด้านภาษา':
        return const Color(0xFFFFB300);
      case 'ด้านร่างกาย':
        return Palette.pink;
      case 'ด้านคำนวณ':
        return Palette.sky;
      default:
        return Palette.teal;
    }
  }

  static IconData _categoryIcon(String category) {
    switch (category) {
      case 'ด้านภาษา':
        return Icons.menu_book_rounded;
      case 'ด้านร่างกาย':
        return Icons.directions_run_rounded;
      case 'ด้านคำนวณ':
        return Icons.calculate_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  static String _categoryLabel(String category, AppLocalizations l) {
    switch (category) {
      case 'ด้านภาษา':
        return l.home_languageBtn;
      case 'ด้านร่างกาย':
        return l.home_physicalBtn;
      case 'ด้านคำนวณ':
        return l.home_calculationBtn;
      default:
        return category;
    }
  }

  // ── Activity Card ──────────────────────────────────────

  Widget _buildActivityCard(Activity activity, AppLocalizations l) {
    final accent = _categoryAccent(activity.category);
    final icon = _categoryIcon(activity.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: Palette.cardShadow,
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent strip
            Container(width: 4, color: accent),

            // Content
            Expanded(
              child: InkWell(
                onTap: _isEditMode
                    ? () => _openEdit(activity)
                    : () => _playActivity(activity),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                  child: Row(
                    children: [
                      // Category icon circle
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: accent, size: 22),
                      ),
                      const SizedBox(width: 12),

                      // Name + chips
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(activity.name,
                                style: AppTextStyles.label(14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 5,
                              runSpacing: 4,
                              children: [
                                _chipLabel(
                                    _categoryLabel(activity.category, l),
                                    accent),
                                _chipLabel(
                                    _translateDifficulty(
                                        activity.difficulty, l),
                                    Palette.warning),
                                _chipLabel(
                                    '★ ${activity.maxScore}',
                                    Palette.successAlt),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Edit/delete
                      if (_isEditMode) ...[
                        IconButton(
                          icon: const Icon(Icons.edit_rounded,
                              size: 20, color: Palette.sky),
                          onPressed: () => _openEdit(activity),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 36, minHeight: 36),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 20, color: Palette.deleteRed),
                          onPressed: () => _showDeleteDialog(activity),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 36, minHeight: 36),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: AppTextStyles.label(10, color: color)),
    );
  }
}
