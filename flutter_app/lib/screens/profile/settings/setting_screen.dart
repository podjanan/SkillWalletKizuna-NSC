import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import 'package:skill_wallet_kizuna/main.dart';
import 'package:skill_wallet_kizuna/routes/app_routes.dart';

// Import Provider
import '../../../providers/user_provider.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_config.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';

// Import หน้าย่อยต่างๆ
import 'profile_setting_screen.dart'; // หน้าแก้ไขโปรไฟล์
import '../../child/child_setting_screen.dart'; // หน้าจัดการเด็ก

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  // ตัวแปรเก็บค่าภาษาที่เลือก (Default เป็น 'TH')
  String _selectedLanguage = 'th';
  bool _localeInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_localeInitialized) return;
    _selectedLanguage = Localizations.localeOf(context).languageCode;
    _localeInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = context.watch<UserProvider>().parentPhotoUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF8),
      body: SafeArea(
        child: Column(
          children: [
            // --- Scrollable content ---
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- 1. Header (Back & Title) ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 24,
                                    color: Palette.terracotta,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .setting_backBtn,
                                    style: AppTextStyles.heading(
                                      20,
                                      color: Palette.terracotta,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.setting_settingBtn,
                            style: AppTextStyles.heading(
                              22,
                              color: Palette.terracotta,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- 2. Menu: PROFILE ---
                      _buildMenuItem(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ProfileSettingScreen(),
                            ),
                          );
                        },
                        title: AppLocalizations.of(context)!.setting_profileBtn,
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            image: photoUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                        ApiConfig.resolveAssetUrl(photoUrl)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: photoUrl == null
                              ? const Icon(Icons.person,
                                  size: 30, color: Colors.black87)
                              : null,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- Section: Personal Information ---
                      Text(
                        AppLocalizations.of(context)!.setting_personalBtn,
                        style: AppTextStyles.label(
                          13,
                          color: Palette.authGrey,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Menu: CHILD
                      _buildMenuItem(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChildSettingScreen(),
                            ),
                          );
                        },
                        title: AppLocalizations.of(context)!.setting_childBtn,
                        leading: const Icon(Icons.sentiment_satisfied_alt,
                            size: 32, color: Colors.black87),
                      ),

                      const SizedBox(height: 20),

                      // --- Language Buttons ---
                      _buildLanguageButton(
                        code: 'th',
                        label: AppLocalizations.of(context)!.setting_thaiBtn,
                        flagEmoji: '🇹🇭',
                      ),
                      const SizedBox(height: 12),
                      _buildLanguageButton(
                        code: 'en',
                        label: AppLocalizations.of(context)!.setting_englishBtn,
                        flagEmoji: '🇺🇸',
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // --- Sticky Bottom: Logout + Delete Account ---
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  // Log Out Button
                  GestureDetector(
                    onTap: _confirmLogout,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.setting_logoutBtn,
                          style: AppTextStyles.heading(
                            20,
                            color: Palette.terracotta,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.logout_rounded,
                          color: Palette.terracotta,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Delete Account
                  GestureDetector(
                    onTap: _confirmDeleteAccount,
                    child: Text(
                      AppLocalizations.of(context)!.setting_deleteAccountBtn,
                      style:
                          AppTextStyles.body(14, color: Colors.grey).copyWith(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.setting_logoutTitle,
          style: AppTextStyles.body(18, weight: FontWeight.bold),
        ),
        content: Text(
          l10n.setting_logoutMsg,
          style: AppTextStyles.body(14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.common_cancel,
                style: AppTextStyles.body(14, color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Palette.pink),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.setting_logoutConfirm,
                style: AppTextStyles.body(14, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await AuthService().signOut();
    } catch (_) {}

    if (!mounted) return;
    context.read<UserProvider>().clearUserData();

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.welcome,
        (route) => false,
      );
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.setting_deleteTitle,
          style: AppTextStyles.body(18,
              weight: FontWeight.bold, color: Palette.errorStrong),
        ),
        content: Text(
          l10n.setting_deleteMsg,
          style: AppTextStyles.body(14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.common_cancel,
                style: AppTextStyles.body(14, color: Colors.black54)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Palette.errorStrong),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.setting_deleteConfirm,
                style: AppTextStyles.body(14, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _deleteAccount();
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // 1. Call backend to delete parent + children data
      final apiService = ApiService();
      await apiService.delete('/parents/me');

      // 2. Delete Supabase auth user
      try {
        await AuthService().signOut();
      } catch (_) {}

      // 3. Clear local state
      if (!mounted) return;
      context.read<UserProvider>().clearUserData();

      // 4. Navigate to welcome
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.setting_deleteSuccess)),
        );
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.welcome,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.setting_deleteError)),
        );
      }
    }
  }

  // Helper Widget: สร้างแถวเมนู (Profile, Child, Noti)
  Widget _buildMenuItem({
    required String title,
    required Widget leading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0E3DC)),
          boxShadow: Palette.softShadow,
        ),
        child: Row(
          children: [
            // จัดให้ leading (icon/image) อยู่ตรงกลางของความกว้าง 50 เพื่อความเป็นระเบียบ
            SizedBox(
              width: 50,
              child: Center(child: leading),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.heading(17, color: Palette.text),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 26,
              color: Palette.terracotta,
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget: สร้างปุ่มเปลี่ยนภาษา
  Widget _buildLanguageButton({
    required String code,
    required String label,
    required String flagEmoji,
  }) {
    // ตรวจสอบว่าปุ่มนี้ถูกเลือกอยู่หรือไม่
    bool isActive = _selectedLanguage == code;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = code;
        });

        if (code == 'th') {
          SWKApp.of(context)?.setLocale(const Locale('th'));
        } else if (code == 'en') {
          SWKApp.of(context)?.setLocale(const Locale('en'));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), // เอฟเฟกต์เปลี่ยนสีนุ่มๆ
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
        decoration: BoxDecoration(
          // Logic ความสว่าง:
          // ถ้าเลือก (Active) -> สีชัด (Opacity 1.0)
          // ถ้าไม่เลือก -> สีจาง (Opacity 0.4)
          color: isActive
              ? Palette.terracotta.withValues(alpha: .14)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? Palette.terracotta : const Color(0xFFF0E3DC),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flagEmoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTextStyles.heading(18,
                  // ถ้าไม่ Active ให้ตัวหนังสือจางลงด้วยนิดหน่อย เพื่อความสวยงาม
                  color: isActive ? Palette.terracotta : Palette.authGrey),
            ),
          ],
        ),
      ),
    );
  }
}
