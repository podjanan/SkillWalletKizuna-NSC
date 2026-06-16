import 'package:flutter/material.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/child_service.dart';
import '../../routes/app_routes.dart';
import '../../theme/palette.dart';
import '../../theme/app_text_styles.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key, this.isRequired = false});

  /// When true: used after registration or startup with no children.
  /// Back button shows logout dialog; OK button calls API and navigates home.
  /// When false (default): used from child settings; returns data via Navigator.pop.
  final bool isRequired;

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDayController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();
  DateTime? _selectedBirthday;
  String? _selectedRelation;
  bool _isLoading = false;


  List<String> _relationOptions(AppLocalizations l10n) => [
        l10n.relation_parent,
        l10n.relation_grandparentPaternal,
        l10n.relation_grandparentMaternal,
        l10n.relation_auntUncle,
        l10n.relation_caregiver,
        l10n.relation_nanny,
      ];

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ??
          DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Palette.blueChip,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
        _birthDayController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _pickRelation(AppLocalizations l10n) async {
    final options = _relationOptions(l10n);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  l10n.relation_label,
                  style: AppTextStyles.heading(18, color: Palette.error),
                ),
              ),
              ...options.map((option) => ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                    title: Text(
                      option,
                      style: AppTextStyles.body(16, color: Colors.black87),
                    ),
                    trailing: _selectedRelation == option
                        ? const Icon(Icons.check, color: Palette.blueChip)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedRelation = option;
                        _relationController.text = option;
                      });
                      Navigator.pop(ctx);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        ),
    );
  }

  // ── Required mode: show logout confirmation ──────────────────────────────
  Future<void> _showLogoutDialog() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.addchild_logoutTitle,
          style: AppTextStyles.heading(18),
        ),
        content: Text(
          l10n.addchild_logoutMsg,
          style: AppTextStyles.body(14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.common_cancel,
              style: AppTextStyles.body(14, color: Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.setting_logoutBtn,
              style: AppTextStyles.body(14, color: Palette.pink),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await AuthService().signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.welcome,
          (route) => false,
        );
      }
    }
  }

  // ── Required mode: submit → call API → navigate home ────────────────────
  Future<void> _submitRequired(AppLocalizations l10n) async {
    final name = _nameController.text.trim();
    if (name.isEmpty ||
        _birthDayController.text.isEmpty ||
        _selectedRelation == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          l10n.addchild_errorRequiredFields,
          style: AppTextStyles.body(14),
        ),
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final child = await ChildService().addChild(
        fullName: name,
        dob: _selectedBirthday,
        relationship: _selectedRelation,
      );
      if (child != null && mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      } else if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            l10n.register_Anerroroccurredplstry,
            style: AppTextStyles.body(14),
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString(), style: AppTextStyles.body(14)),
        ));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDayController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !widget.isRequired,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.isRequired) _showLogoutDialog();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
            onPressed: widget.isRequired
                ? _showLogoutDialog
                : () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Text(
            l10n.register_registerBtn,
            style: AppTextStyles.heading(28, color: Palette.blueChip)
                .copyWith(letterSpacing: 1.5),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  l10n.register_additionalBtn,
                  style: AppTextStyles.heading(20, color: Palette.blueChip),
                ),
              ),
              const SizedBox(height: 30),

              // ── Name ─────────────────────────────────────────────────────
              Text(
                l10n.addchild_namesurnameBtn,
                style: AppTextStyles.heading(16, color: Palette.error),
              ),
              const SizedBox(height: 5),
              _inputContainer(
                child: TextField(
                  controller: _nameController,
                  style: AppTextStyles.body(15, color: Colors.black87),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Birthday ──────────────────────────────────────────────────
              Text(
                l10n.addchild_birthdayBtn,
                style: AppTextStyles.heading(16, color: Palette.error),
              ),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: _selectBirthday,
                child: _inputContainer(
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _birthDayController,
                      style: AppTextStyles.body(15, color: Colors.black87),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        hintText: l10n.register_pickbirthday,
                        hintStyle:
                            AppTextStyles.body(15, color: Colors.grey),
                        suffixIcon: const Icon(Icons.calendar_today,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Relationship ──────────────────────────────────────────────
              Text(
                l10n.relation_label,
                style: AppTextStyles.heading(16, color: Palette.error),
              ),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: () => _pickRelation(l10n),
                child: _inputContainer(
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _relationController,
                      style: AppTextStyles.body(15, color: Colors.black87),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        hintText: l10n.relation_hint,
                        hintStyle: AppTextStyles.body(15, color: Colors.grey),
                        suffixIcon: const Icon(Icons.arrow_drop_down,
                            color: Colors.black54),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // ── OK Button ─────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (widget.isRequired) {
                            _submitRequired(l10n);
                          } else {
                            // Normal mode: validate name and pop with data
                            final name = _nameController.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.addchild_errorName,
                                    style: AppTextStyles.heading(14),
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.pop(context, {
                              'name': name,
                              'birthday':
                                  _selectedBirthday ?? DateTime.now(),
                              'relation': _selectedRelation,
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isLoading ? Colors.grey : Palette.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          l10n.addchild_okBtn,
                          style: AppTextStyles.heading(24, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputContainer({required Widget child}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Palette.lightBlue,
        borderRadius: BorderRadius.circular(25),
      ),
      child: child,
    );
  }
}
