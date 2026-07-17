import 'package:flutter/material.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import '../../theme/palette.dart';
import '../../theme/app_text_styles.dart';

class ChildNameSettingScreen extends StatefulWidget {
  final String currentName;

  const ChildNameSettingScreen({super.key, required this.currentName});

  @override
  State<ChildNameSettingScreen> createState() => _ChildNameSettingScreenState();
}

class _ChildNameSettingScreenState extends State<ChildNameSettingScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveName() {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      Navigator.pop(context, newName);
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Header ---
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.childnamesetting_editnameBtn,
                            style: AppTextStyles.heading(28, color: Palette.blueChip),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.arrow_back,
                                  size: 30, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // --- Text Field ---
                      TextField(
                        controller: _nameController,
                        style: AppTextStyles.heading(20, color: Colors.black87),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: AppLocalizations.of(context)!.namesetting_hint,
                          hintStyle: AppTextStyles.body(14, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        ),
                      ),
                      const Spacer(),

                      // --- SAVE Button ---
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _saveName,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Palette.successAlt,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            elevation: 5,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.childnamesetting_saveBtn,
                            style: AppTextStyles.heading(24, color: Colors.white),
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
