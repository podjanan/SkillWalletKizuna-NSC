import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import 'package:skill_wallet_kizuna/services/storage_service.dart';

import '../../../providers/user_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';
import 'name_setting_screen.dart';

class ProfileSettingScreen extends StatefulWidget {
  const ProfileSettingScreen({super.key});

  @override
  State<ProfileSettingScreen> createState() => _ProfileSettingScreenState();
}

class _ProfileSettingScreenState extends State<ProfileSettingScreen> {
  bool _uploading = false;

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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.common_pickFromGallery),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery();
              },
            ),
            if (oauthPhotoUrl != null)
              ListTile(
                leading: const Icon(Icons.account_circle_outlined, size: 28),
                title: Text(l.common_useOriginalPhoto),
                onTap: () {
                  Navigator.pop(ctx);
                  _useOAuthPhoto('oauth');
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    final ok = await context.read<UserProvider>().uploadAndSetPhoto(bytes);
    if (mounted) {
      setState(() => _uploading = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.common_uploadPhotoFailed)),
        );
      }
    }
  }

  Future<void> _useOAuthPhoto(String provider) async {
    setState(() => _uploading = true);
    final ok = await context.read<UserProvider>().setPhotoFromOAuth(provider);
    if (mounted) {
      setState(() => _uploading = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .common_photoNotFound(provider))),
        );
      }
    }
  }

  // --- ฟังก์ชันแสดง Popup ยืนยันการลบบัญชี ---
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppLocalizations.of(context)!.profileSet_deleteDialogTitle,
              style: AppTextStyles.heading(22, color: Palette.pink),
              textAlign: TextAlign.center,
            ),
          ),
          content: Text(
            AppLocalizations.of(context)!.profilesetting_areusureBtn,
            style: AppTextStyles.heading(16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            // ปุ่ม CANCEL
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppLocalizations.of(context)!.profilesetting_cancelBtn,
                style: AppTextStyles.heading(18, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 10),
            // ปุ่ม DELETE
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // ปิด Dialog ก่อน
                _performDeleteAccount(); // เรียกฟังก์ชันลบ
              },
              child: Text(
                AppLocalizations.of(context)!.profilesetting_deleteBtn,
                style: AppTextStyles.heading(18, color: Palette.pink),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- ฟังก์ชันทำงานเมื่อยืนยันการลบ ---
  Future<void> _performDeleteAccount() async {
    setState(() => _uploading = true);
    final ok = await context.read<UserProvider>().deleteAccount();
    if (!mounted) return;
    setState(() => _uploading = false);
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.welcome,
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)!.common_errorGeneric('delete failed')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final photoUrl = userProvider.parentPhotoUrl;
    final parentName = userProvider.currentParentName ?? 'SWK';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back,
                  size: 32,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 24),

              // --- Profile Image ---
              Center(
                child: GestureDetector(
                  onTap: _showPhotoOptions,
                  child: Stack(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade300,
                          image: photoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(photoUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _uploading
                            ? const CircularProgressIndicator()
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
                            border: Border.all(color: Palette.cream, width: 3),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 24,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // --- Name Label ---
              Text(
                AppLocalizations.of(context)!.profilesetting_nameBtn,
                style: AppTextStyles.heading(20, color: Palette.labelGrey),
              ),

              const SizedBox(height: 12),

              // --- Name Value (Click to Edit) ---
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NameSettingScreen(),
                    ),
                  );
                },
                child: Container(
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        parentName,
                        style: AppTextStyles.heading(24, color: Colors.black87),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 32,
                        color: Colors.black87,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // --- Delete Account Button ---
              GestureDetector(
                onTap: _uploading
                    ? null
                    : () => _showDeleteConfirmation(context),
                child: Text(
                  AppLocalizations.of(context)!.profilesetting_deleteaccoutBtn,
                  style: AppTextStyles.heading(20, color: Palette.pink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
