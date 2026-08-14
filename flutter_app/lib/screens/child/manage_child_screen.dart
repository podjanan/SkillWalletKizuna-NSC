import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import '../../theme/palette.dart';
import '../../theme/app_text_styles.dart';

import '../../providers/user_provider.dart';
import '../../services/api_config.dart';
import '../../routes/app_routes.dart';
import 'child_name_setting_screen.dart';
import 'medals_redemption_screen.dart';

class ManageChildScreen extends StatefulWidget {
  final String? childId;
  final String name;
  final String? imageUrl;
  final int score;

  const ManageChildScreen({
    super.key,
    this.childId,
    required this.name,
    this.imageUrl,
    required this.score,
  });

  @override
  State<ManageChildScreen> createState() => _ManageChildScreenState();
}

class _ManageChildScreenState extends State<ManageChildScreen> {
  late String _currentName;
  String? _currentImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _currentName = widget.name;
    _currentImageUrl = widget.imageUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _isUploading = true;
    });

    final bytes = await image.readAsBytes();
    final success = await context
        .read<UserProvider>()
        .uploadChildPhoto(widget.childId ?? '', bytes);

    if (success && mounted) {
      final updatedChild = context
          .read<UserProvider>()
          .children
          .firstWhere((c) => c['child']?['child_id'] == widget.childId);
      setState(() {
        _currentImageUrl = updatedChild['child']?['photo_url'] as String?;
      });
    }

    if (mounted) {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _navigateToEditName() async {
    final newName = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChildNameSettingScreen(currentName: _currentName),
      ),
    );

    if (newName != null && newName is String) {
      setState(() {
        _currentName = newName;
      });
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            AppLocalizations.of(context)!.dialog_deleteTitle,
            style: AppTextStyles.heading(18),
          ),
          content: Text(
            AppLocalizations.of(context)!.dialog_deleteContent,
            style: AppTextStyles.body(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)!.dialog_cancel,
                style: AppTextStyles.body(14, color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                await context
                    .read<UserProvider>()
                    .deleteChild(widget.childId ?? '');
                if (!mounted) return;
                Navigator.of(context).pop();
                Navigator.of(context).pop(true);
              },
              child: Text(
                AppLocalizations.of(context)!.dialog_confirmDelete,
                style: AppTextStyles.body(14, color: Palette.deleteRed),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logic แสดงรูปภาพ
    Widget profileImageWidget;
    if (_isUploading) {
      profileImageWidget = const Center(child: CircularProgressIndicator());
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      profileImageWidget = Image.network(
        ApiConfig.resolveAssetUrl(_currentImageUrl!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person, size: 80, color: Colors.grey),
      );
    } else {
      profileImageWidget =
          const Icon(Icons.person, size: 80, color: Colors.grey);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF8),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.authenticatedHome,
              (_) => false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.terracotta,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.home_rounded),
            label: Text(
              AppLocalizations.of(context)!.common_home,
              style: AppTextStyles.heading(16, color: Colors.white),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // --- Header ---
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context, {'newName': _currentName});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF0E3DC)),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 24,
                          color: Palette.terracotta,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      AppLocalizations.of(context)!
                          .managechild_manageprofileBtn,
                      style: AppTextStyles.heading(
                        21,
                        color: Palette.terracotta,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 46),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // --- Profile Image ---
              Center(
                child: GestureDetector(
                  onTap: _isUploading ? null : _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 124,
                        height: 124,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade300),
                        child: ClipOval(child: profileImageWidget),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Palette.terracotta,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 3)),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // --- Menu Items ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. NAME
                    Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFF0E3DC)),
                      ),
                      child: InkWell(
                        onTap: _navigateToEditName,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .managechild_nameBtn,
                                style: AppTextStyles.body(16,
                                    color: Palette.labelGrey),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _currentName,
                                    style: AppTextStyles.heading(24,
                                        color: Colors.black87),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      size: 32, color: Colors.black87),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. MEDALS & REDEMPTION
                    Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFF0E3DC)),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MedalsRedemptionScreen(
                                childId: widget.childId,
                                childName: _currentName,
                                score: widget.score,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.emoji_events_rounded,
                                color: Palette.terracotta,
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .managechild_medalsandredemptionBtn,
                                  style: AppTextStyles.heading(20,
                                      color: Colors.black87),
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  size: 32, color: Colors.black87),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- Delete Button ---
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: TextButton(
                  onPressed: _showDeleteConfirmationDialog,
                  child: Text(
                    AppLocalizations.of(context)!.managechild_deleteprofileBtn,
                    style: AppTextStyles.heading(20, color: Palette.deleteRed),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
