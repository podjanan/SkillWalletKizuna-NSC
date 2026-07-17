import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import '../../../providers/user_provider.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';

class NameSettingScreen extends StatefulWidget {
  const NameSettingScreen({super.key});

  @override
  State<NameSettingScreen> createState() => _NameSettingScreenState();
}

class _NameSettingScreenState extends State<NameSettingScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final currentName = context.read<UserProvider>().currentParentName ?? '';
    _nameController = TextEditingController(text: currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    final userProvider = context.read<UserProvider>();
    final success = await userProvider.updateParentName(newName);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.namesetting_saveFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Header ---
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back,
                                size: 30, color: Colors.black87),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            AppLocalizations.of(context)!.namesetting_changenameBtn,
                            style: AppTextStyles.heading(24, color: Palette.blueChip),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // --- Input Field Label ---
                      Text(
                        AppLocalizations.of(context)!.namesetting_enternewnameBtn,
                        style: AppTextStyles.body(16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),

                      // --- Input TextField ---
                      TextField(
                        controller: _nameController,
                        style: AppTextStyles.heading(20, color: Colors.black87),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: AppLocalizations.of(context)!.namesetting_hint,
                          hintStyle: AppTextStyles.body(20, color: Colors.black38),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),

                      const Spacer(),

                      // --- Save Button ---
                      SizedBox(
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _saveName,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Palette.successAlt,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.namesetting_saveBtn,
                            style: AppTextStyles.heading(22, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}
