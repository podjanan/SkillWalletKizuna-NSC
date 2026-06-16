import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import '../../theme/palette.dart';
import '../../theme/app_text_styles.dart';

import '../../providers/user_provider.dart';
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
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentName = widget.name;
    _currentImageUrl = widget.imageUrl;
  }

  // --- Functions ---

  Future<void> _pickImage() async {
    if (widget.childId == null) return;
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (!mounted) return;

      setState(() => _isUploading = true);

      final userProvider = context.read<UserProvider>();
      final success =
          await userProvider.uploadChildPhoto(widget.childId!, bytes);

      if (!mounted) return;
      setState(() => _isUploading = false);

      if (success) {
        // Pull the new URL from the updated local children list
        final children = userProvider.children;
        final childData = children.firstWhere(
          (c) => c['child']?['child_id'] == widget.childId,
          orElse: () => {},
        );
        setState(() {
          _currentImageUrl = childData['child']?['photo_url'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) setState(() => _isUploading = false);
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
              onPressed: () {
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
        _currentImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person, size: 80, color: Colors.grey),
      );
    } else {
      profileImageWidget =
          const Icon(Icons.person, size: 80, color: Colors.grey);
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
        child: Column(
          children: [
            // --- Header ---
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context, {'newName': _currentName});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.transparent,
                      child: const Icon(Icons.arrow_back,
                          size: 30, color: Colors.black87),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppLocalizations.of(context)!.managechild_manageprofileBtn,
                    style: AppTextStyles.heading(24, color: Palette.sky),
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
                      width: 140,
                      height: 140,
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
                            color: Palette.yellow,
                            shape: BoxShape.circle,
                            border: Border.all(color: Palette.cream, width: 3)),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.black87, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // --- Menu Items ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. NAME
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _navigateToEditName,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                    const Divider(color: Colors.black12),

                    // 2. MEDALS & REDEMPTION
                    Material(
                      color: Colors.transparent,
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
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events,
                                  color: Palette.yellow, size: 30),
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
            ),

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
    );
  }
}
