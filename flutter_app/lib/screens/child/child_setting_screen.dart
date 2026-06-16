import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';

import '../../theme/app_text_styles.dart';
import '../../theme/palette.dart';
import 'add_child_screen.dart';
import 'manage_child_screen.dart';
import 'child_profile_screen.dart';
import '../../providers/user_provider.dart';
import '../../widgets/child_avatar.dart';

class ChildSettingScreen extends StatefulWidget {
  const ChildSettingScreen({super.key});

  @override
  State<ChildSettingScreen> createState() => _ChildSettingScreenState();
}

class _ChildSettingScreenState extends State<ChildSettingScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChildren();
    });
  }

  Future<void> _loadChildren() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final userProvider = context.read<UserProvider>();
    await userProvider.fetchChildrenData();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // ฟังก์ชันเพิ่มเด็กใหม่
  Future<void> _addNewChild() async {
    final newChildData = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddChildScreen()),
    );

    if (!mounted) return;

    if (newChildData != null && newChildData is Map<String, dynamic>) {
      final userProvider = context.read<UserProvider>();

      // Parse birthday if exists
      DateTime birthday = DateTime.now();
      if (newChildData['birthday'] != null) {
        birthday = newChildData['birthday'] as DateTime;
      }

      final success = await userProvider.addChild(
        name: newChildData['name'] as String,
        birthday: birthday,
        relationship: newChildData['relation'] as String?,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.childsetting_addSuccess,
              style: AppTextStyles.body(14),
            ),
          ),
        );
      }
    }
  }

  // ✅ ฟังก์ชันจัดการเด็ก
  Future<void> _manageChild(Map<String, dynamic> childData) async {
    final childInfo = childData['child'] as Map<String, dynamic>;
    final childId = childInfo['child_id'] as String;
    final childName = childInfo['name_surname'] as String;
    final childWallet = childInfo['wallet'] as int? ?? 0;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageChildScreen(
          childId: childId,
          name: childName,
          imageUrl: childInfo['photo_url'] as String?,
          score: childWallet,
        ),
      ),
    );

    if (!mounted) return;

    final userProvider = context.read<UserProvider>();

    if (result == true) {
      // กรณีได้รับค่า true กลับมา = ลบ
      final success = await userProvider.deleteChild(childId);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.childsetting_deleteSuccess,
              style: AppTextStyles.body(14),
            ),
          ),
        );
      }
    } else if (result is Map && result['newName'] != null) {
      // กรณีได้รับ Map กลับมา = มีการแก้ไขข้อมูล
      await userProvider.updateChild(
        childId: childId,
        name: result['newName'] as String,
      );
    }

    // Reload after any manage action (delete/edit)
    await _loadChildren();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          l.childsetting_childsettingBtn,
          style: AppTextStyles.heading(22, color: Palette.sky),
        ),
        actions: [
          GestureDetector(
            onTap: _addNewChild,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                gradient: Palette.skyGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: Palette.buttonShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    Localizations.localeOf(context).languageCode == 'th'
                        ? 'เพิ่ม'
                        : 'Add',
                    style: AppTextStyles.label(13, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final children = userProvider.children;
          final currentChildId = userProvider.currentChildId;

          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Palette.sky),
            );
          }

          if (children.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Palette.sky.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.child_care_rounded,
                          size: 56, color: Palette.sky),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l.childsetting_noChildren,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(16, color: Colors.black54),
                    ),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: _addNewChild,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: Palette.skyGradient,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: Palette.buttonShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(l.childsetting_addChild,
                                style: AppTextStyles.label(16,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: children.length,
            itemBuilder: (context, index) {
              final childData = children[index];
              final childInfo = childData['child'] as Map<String, dynamic>;
              final childId = childInfo['child_id'] as String;
              final childName = childInfo['name_surname'] as String;
              final childWallet = childInfo['wallet'] as int? ?? 0;
              final photoUrl = childInfo['photo_url'] as String? ?? '';
              final isSelected = currentChildId == childId;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? Palette.buttonShadow
                      : Palette.cardShadow,
                  border: isSelected
                      ? Border.all(
                          color: Palette.sky.withValues(alpha: 0.35),
                          width: 1.5)
                      : null,
                ),
                child: Column(
                  children: [
                    // ── Profile Row ───────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Row(
                        children: [
                          // Avatar with optional sky ring behind
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isSelected)
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: Palette.skyGradient,
                                  ),
                                ),
                              ChildAvatar(
                                photoUrl: photoUrl,
                                name: childName,
                                radius: 32,
                                fontSize: 26,
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // Name + wallet
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        childName,
                                        style: AppTextStyles.heading(20,
                                            color: Palette.text),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Palette.successAlt,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          l.childsetting_active,
                                          style: AppTextStyles.label(10,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: Color(0xFFFFB300), size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$childWallet ${l.childsetting_scoreBtn}',
                                      style: AppTextStyles.label(14,
                                          color: const Color(0xFFFFB300)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Divider ───────────────────────────────
                    Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade100),

                    // ── Action Buttons ────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Row(
                        children: [
                          // View Profile — filled sky gradient
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChildProfileScreen(
                                    childId: childId,
                                    name: childName,
                                    imageUrl: photoUrl,
                                    points: childWallet,
                                  ),
                                ),
                              ),
                              child: Container(
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: Palette.skyGradient,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: Palette.buttonShadow,
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.person_rounded,
                                        color: Colors.white, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      l.childsetting_viewprofileBtn,
                                      style: AppTextStyles.label(13,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Manage — outlined sky
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _manageChild(childData),
                              child: Container(
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Palette.sky, width: 1.5),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.settings_rounded,
                                        color: Palette.sky, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      l.childsetting_manageBtn,
                                      style: AppTextStyles.label(13,
                                          color: Palette.sky),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
