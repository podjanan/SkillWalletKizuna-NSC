import 'package:flutter/material.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import '../../services/child_service.dart';
import '../../routes/app_routes.dart';
import '../../theme/palette.dart';
import '../../theme/app_text_styles.dart';

class ChildrenInfoScreen extends StatefulWidget {
  const ChildrenInfoScreen({super.key});

  @override
  State<ChildrenInfoScreen> createState() => _ChildrenInfoScreenState();
}

class _ChildrenInfoScreenState extends State<ChildrenInfoScreen> {
  final ChildService childService = ChildService();
  bool _isLoading = false;

  final List<_ChildFields> _children = [_ChildFields()];

  List<String> _relationOptions(AppLocalizations l10n) => [
        l10n.relation_parent,
        l10n.relation_grandparentPaternal,
        l10n.relation_grandparentMaternal,
        l10n.relation_auntUncle,
        l10n.relation_caregiver,
        l10n.relation_nanny,
      ];

  @override
  void dispose() {
    for (final c in _children) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                children: [
                  Text(
                    l10n.register_registerBtn,
                    style: AppTextStyles.heading(28, color: Palette.sky),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.register_additionalBtn,
                    style: AppTextStyles.heading(22, color: Palette.sky),
                  ),
                  const SizedBox(height: 20),
                  ..._children.asMap().entries.map((e) {
                    final i = e.key;
                    final c = e.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.register_namesurnamechildBtn(i + 1),
                                  style: AppTextStyles.heading(16,
                                      color: Palette.errorStrong),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_children.length > 1)
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _children.removeAt(i).dispose();
                                  }),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(Icons.close,
                                        size: 26, color: Colors.black87),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: c.nameCtrl,
                            decoration: _dec(hint: l10n.register_childNameHint),
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            style:
                                AppTextStyles.body(14, color: Colors.black87),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.register_birthdayBtn,
                            style: AppTextStyles.heading(16,
                                color: Palette.errorStrong),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => _pickBirthday(i),
                            child: AbsorbPointer(
                              child: TextField(
                                controller: c.birthCtrl,
                                decoration:
                                    _dec(hint: l10n.register_birthdayHint),
                                style: AppTextStyles.body(14,
                                    color: Colors.black87),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.relation_label,
                            style: AppTextStyles.heading(16,
                                color: Palette.errorStrong),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => _pickRelation(i, l10n),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFBBDEFB),
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.selectedRelation ?? l10n.relation_hint,
                                      style: AppTextStyles.body(
                                        14,
                                        color: c.selectedRelation != null
                                            ? Colors.black87
                                            : Colors.black38,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down,
                                      color: Colors.black54),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Center(
                    child: InkWell(
                      onTap: () =>
                          setState(() => _children.add(_ChildFields())),
                      borderRadius: BorderRadius.circular(40),
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black54),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, size: 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sticky bottom bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: const BoxDecoration(
                color: Palette.cream,
                border: Border(top: BorderSide(color: Colors.black12)),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: _isLoading ? null : () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back,
                            color: _isLoading ? Colors.grey : Palette.pink,
                            size: 26,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.register_backBtn,
                            style: AppTextStyles.heading(22,
                                color:
                                    _isLoading ? Colors.grey : Palette.pink),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _submit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.successAlt,
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : Text(
                              l10n.common_ok,
                              style: AppTextStyles.heading(20,
                                  color: Colors.white),
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

  Future<void> _pickRelation(int index, AppLocalizations l10n) async {
    final options = _relationOptions(l10n);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
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
                  style: AppTextStyles.heading(18, color: Palette.errorStrong),
                ),
              ),
              ...options.map((option) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 2),
                    title: Text(
                      option,
                      style: AppTextStyles.body(16, color: Colors.black87),
                    ),
                    trailing: _children[index].selectedRelation == option
                        ? const Icon(Icons.check, color: Palette.sky)
                        : null,
                    onTap: () {
                      setState(
                          () => _children[index].selectedRelation = option);
                      Navigator.pop(ctx);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _pickBirthday(int index) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _children[index].birthday ??
          DateTime(now.year - 7, now.month, now.day),
      firstDate: DateTime(now.year - 20),
      lastDate: now,
      helpText: AppLocalizations.of(context)!.register_pickbirthday,
    );

    if (picked != null) {
      setState(() {
        _children[index].birthday = picked;
        _children[index].birthCtrl.text =
            '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/'
            '${picked.year}';
      });
    }
  }

  Future<void> _submit(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    for (var i = 0; i < _children.length; i++) {
      if (_children[i].nameCtrl.text.trim().isEmpty ||
          _children[i].birthCtrl.text.trim().isEmpty ||
          _children[i].selectedRelation == null) {
        _toast(l10n.register_requiredinformation(i + 1));
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final childrenData = _children
          .map((c) => {
                'fullName': c.nameCtrl.text.trim(),
                'dob': c.birthday?.toIso8601String(),
                'relation': c.selectedRelation,
              })
          .toList();

      final addedChildren = await childService.addChildren(childrenData);
      setState(() => _isLoading = false);

      if (addedChildren.isNotEmpty) {
        _toast(l10n.register_sus(addedChildren.length));
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        }
      } else {
        _toast(l10n.register_Anerroroccurredplstry);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Submit error: $e');
      _toast(AppLocalizations.of(context)!.register_Anerroroccurred(e));
    }
  }

  InputDecoration _dec({String? hint}) => InputDecoration(
        filled: true,
        fillColor: const Color(0xFFBBDEFB),
        hintText: hint,
        hintStyle: AppTextStyles.body(14, color: Colors.black38),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: BorderSide.none,
        ),
      );
}

class _ChildFields {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController birthCtrl = TextEditingController();
  String? selectedRelation;
  DateTime? birthday;

  void dispose() {
    nameCtrl.dispose();
    birthCtrl.dispose();
  }
}
