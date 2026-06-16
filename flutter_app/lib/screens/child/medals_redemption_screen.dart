import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import '../../models/agreement_type.dart';
import '../../providers/user_provider.dart';
import '../../services/child_service.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/palette.dart';

class MedalsRedemptionScreen extends StatefulWidget {
  final String? childId;
  final String? childName;
  final int score;

  const MedalsRedemptionScreen({
    super.key,
    this.childId,
    this.childName,
    required this.score,
  });

  @override
  State<MedalsRedemptionScreen> createState() => _MedalsRedemptionScreenState();
}

class _MedalsRedemptionScreenState extends State<MedalsRedemptionScreen> {
  int _selectedIndex = 0;
  late int _currentScore;

  List<Map<String, dynamic>> _rewards = [];
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _activityHistory = [];
  bool _isLoading = true;
  bool _isEditMode = false;

  // Session state (Flow C)
  bool _sessionActive = false;
  bool _sessionPaused = true; // starts paused, user presses START
  String _sessionName = '';
  AgreementType? _sessionType;
  Timer? _sessionTimer;
  int _sessionSecondsLeft = 0;

  // Last redemption info for behavior assessment
  String? _lastRedemptionId;
  int _lastRedemptionCost = 0;

  final ChildService _childService = ChildService();

  @override
  void initState() {
    super.initState();
    _currentScore = widget.score;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  // ─── Data Loading ─────────────────────────────────────

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final userProvider = context.read<UserProvider>();
    final parentId = userProvider.currentParentId;
    final childId = widget.childId ?? userProvider.currentChildId;

    if (parentId != null && childId != null) {
      try {
        final rewards = await _childService.getRewards(parentId);
        final activityHistory = await _childService.getActivityHistory(childId);
        final pointHistory = await _childService.getPointHistory(childId);
        final stats = await _childService.getChildStats(childId);

        if (!mounted) return;
        setState(() {
          _rewards = rewards.map((r) {
            final medal = r['medals'] as Map<String, dynamic>?;
            final pointValue = medal?['point_medals'];
            int cost = 0;
            if (pointValue is int) {
              cost = pointValue;
            } else if (pointValue is double) {
              cost = pointValue.toInt();
            } else if (pointValue != null) {
              cost = int.tryParse(pointValue.toString()) ?? 0;
            }
            return {
              'id': medal?['id']?.toString() ?? '',
              'name': medal?['name_medals']?.toString() ?? '',
              'cost': cost,
            };
          }).toList();
          _history = pointHistory;
          _activityHistory = activityHistory;
          _currentScore = stats['wallet'] as int? ?? widget.score;
          _isLoading = false;
        });
      } catch (e) {
        debugPrint('Error loading data: $e');
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  // ─── Flow A: Create Agreement ─────────────────────────

  void _showAddAgreementDialog() {
    final nameController = TextEditingController();
    final costController = TextEditingController();
    final durationController = TextEditingController(text: '30');
    AgreementType selectedType = AgreementType.item;
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  loc.medalredemption_addrewardBtn,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading(22, color: Palette.sky),
                ),
                const SizedBox(height: 20),

                // Type selector label
                Text(loc.agreement_selectType,
                    style: AppTextStyles.label(14, color: Palette.deepGrey)),
                const SizedBox(height: 10),

                // Type selector - equal size grid
                Row(
                  children: AgreementType.values.map((type) {
                    final isSelected = selectedType == type;
                    final color = AgreementHelper.colorFor(type);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => selectedType = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.2)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(AgreementHelper.iconFor(type),
                                  color: color, size: 30),
                              const SizedBox(height: 6),
                              Text(
                                _localizedTypeLabel(type),
                                style: AppTextStyles.label(11, color: color),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Name field
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: loc.medalredemption_rewardnameBtn,
                    hintStyle: AppTextStyles.body(16, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Cost field
                TextField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: loc.medalredemption_costBtn,
                    hintStyle: AppTextStyles.body(16, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                // Duration field (only for TIME type)
                if (selectedType == AgreementType.time) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: loc.agreement_durationLabel,
                      hintStyle: AppTextStyles.body(16, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon:
                          const Icon(Icons.timer_outlined, color: Palette.sky),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(loc.medalredemption_cancelBtn,
                            style:
                                AppTextStyles.heading(18, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.successAlt,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () async {
                          if (nameController.text.isNotEmpty &&
                              costController.text.isNotEmpty) {
                            final userProvider = context.read<UserProvider>();
                            final parentId = userProvider.currentParentId;

                            Navigator.pop(dialogContext);

                            if (parentId != null) {
                              final duration =
                                  int.tryParse(durationController.text);
                              final encodedName = AgreementHelper.encode(
                                selectedType,
                                nameController.text.toUpperCase(),
                                durationMinutes:
                                    selectedType == AgreementType.time
                                        ? (duration ?? 30)
                                        : null,
                              );
                              await _childService.addReward(
                                parentId: parentId,
                                name: encodedName,
                                cost: int.tryParse(costController.text) ?? 0,
                              );
                              if (mounted) await _loadData();
                            }
                          }
                        },
                        child: Text(loc.medalredemption_addBtn,
                            style:
                                AppTextStyles.heading(18, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Edit Agreement ──────────────────────────────────

  void _showEditAgreementDialog(Map<String, dynamic> item) {
    final String rawName = item['name'] as String;
    final int oldCost = item['cost'] as int;
    final String medalsId = item['id']?.toString() ?? '';
    final type = AgreementHelper.parseType(rawName) ?? AgreementType.item;
    final displayName = AgreementHelper.displayName(rawName);
    final duration = AgreementHelper.parseDuration(rawName);

    final nameController = TextEditingController(text: displayName);
    final costController = TextEditingController(text: oldCost.toString());
    final durationController =
        TextEditingController(text: (duration ?? 30).toString());
    AgreementType selectedType = type;
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  loc.childsetting_manageBtn,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading(22, color: Palette.sky),
                ),
                const SizedBox(height: 20),

                // Type selector label
                Text(loc.agreement_selectType,
                    style: AppTextStyles.label(14, color: Palette.deepGrey)),
                const SizedBox(height: 10),

                // Type selector
                Row(
                  children: AgreementType.values.map((t) {
                    final isSelected = selectedType == t;
                    final c = AgreementHelper.colorFor(t);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => selectedType = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? c.withValues(alpha: 0.2)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? c : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(AgreementHelper.iconFor(t),
                                  color: c, size: 30),
                              const SizedBox(height: 6),
                              Text(
                                _localizedTypeLabel(t),
                                style: AppTextStyles.label(11, color: c),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Name field
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: loc.medalredemption_rewardnameBtn,
                    hintStyle: AppTextStyles.body(16, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Cost field
                TextField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: loc.medalredemption_costBtn,
                    hintStyle: AppTextStyles.body(16, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                // Duration field (only for TIME type)
                if (selectedType == AgreementType.time) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: loc.agreement_durationLabel,
                      hintStyle: AppTextStyles.body(16, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon:
                          const Icon(Icons.timer_outlined, color: Palette.sky),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(loc.medalredemption_cancelBtn,
                            style:
                                AppTextStyles.heading(18, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.sky,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () async {
                          if (nameController.text.isNotEmpty &&
                              costController.text.isNotEmpty) {
                            Navigator.pop(dialogContext);

                            final dur = int.tryParse(durationController.text);
                            final encodedName = AgreementHelper.encode(
                              selectedType,
                              nameController.text.toUpperCase(),
                              durationMinutes:
                                  selectedType == AgreementType.time
                                      ? (dur ?? 30)
                                      : null,
                            );
                            await _childService.updateMedal(
                              medalsId: medalsId,
                              name: encodedName,
                              cost:
                                  int.tryParse(costController.text) ?? oldCost,
                            );
                            if (mounted) await _loadData();
                          }
                        },
                        child: Text(loc.namesetting_saveBtn,
                            style:
                                AppTextStyles.heading(18, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Delete Agreement ───────────────────────────────

  void _showDeleteAgreementDialog(Map<String, dynamic> item) {
    final loc = AppLocalizations.of(context)!;
    final String rawName = item['name'] as String;
    final String medalsId = item['id']?.toString() ?? '';
    final displayName = AgreementHelper.displayName(rawName);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(loc.dialog_deleteTitle,
            style: AppTextStyles.heading(20, color: Palette.errorStrong)),
        content: Text(
          '${loc.dialog_deleteContent}\n\n"$displayName"',
          style: AppTextStyles.body(14, color: Palette.deepGrey),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(loc.dialog_cancel,
                style: AppTextStyles.body(14, color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.errorStrong,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _childService.deleteMedal(medalsId);
              if (mounted) await _loadData();
            },
            child: Text(loc.dialog_confirmDelete,
                style: AppTextStyles.heading(16, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Flow B: Confirm & Redeem ─────────────────────────

  void _showConfirmDialog(Map<String, dynamic> item) {
    final loc = AppLocalizations.of(context)!;
    final String rawName = item['name'] as String;
    final int cost = item['cost'] as int;
    final String rewardId = item['id']?.toString() ?? '';
    final type = AgreementHelper.parseType(rawName);
    final displayName = AgreementHelper.displayName(rawName);
    final color = AgreementHelper.colorFor(type);

    if (_currentScore < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.agreement_notEnoughPoints(cost - _currentScore)),
          backgroundColor: Palette.errorStrong,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(AgreementHelper.iconFor(type), color: color, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(loc.agreement_confirmTitle,
                  style: AppTextStyles.heading(20)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayName,
              style: AppTextStyles.heading(18, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$cost P',
                style: AppTextStyles.heading(22, color: color),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.agreement_confirmMsg(cost, displayName),
              style: AppTextStyles.body(14, color: Palette.deepGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(loc.medalredemption_cancelBtn,
                style: AppTextStyles.body(14, color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _executeRedemption(
                rewardId: rewardId,
                rawName: rawName,
                name: displayName,
                cost: cost,
                type: type,
              );
            },
            child: Text(loc.agreement_confirmBtn,
                style: AppTextStyles.heading(16, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeRedemption({
    required String rewardId,
    required String rawName,
    required String name,
    required int cost,
    required AgreementType? type,
  }) async {
    final userProvider = context.read<UserProvider>();
    final childId = userProvider.currentChildId;
    final parentId = userProvider.currentParentId;

    if (childId == null) return;

    final result = await _childService.redeemReward(
      childId: childId,
      rewardId: rewardId,
      rewardName: name,
      cost: cost,
      parentId: parentId,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      // Use wallet from backend response, then reload all data
      final newWallet = result['newWallet'];
      if (newWallet != null) {
        setState(() {
          _currentScore = newWallet is int
              ? newWallet
              : int.tryParse(newWallet.toString()) ?? _currentScore;
        });
      }

      // Store redemption info for behavior assessment
      _lastRedemptionId = result['redemptionId'] as String?;
      _lastRedemptionCost = cost;

      // Reload data in background to ensure consistency
      _loadData();

      // For TIME type: start session timer (Flow C)
      if (type == AgreementType.time) {
        final duration = AgreementHelper.parseDuration(rawName);
        _startSession(
            name: name, type: type!, cost: cost, durationMinutes: duration);
      } else {
        _showSuccessDialog(name);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']?.toString() ?? AppLocalizations.of(context)!.common_error),
          backgroundColor: Palette.errorStrong,
        ),
      );
    }
  }

  void _showSuccessDialog(String itemName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Icon(Icons.check_circle, color: Palette.successAlt, size: 60),
        content: Text(
          '${AppLocalizations.of(context)!.medalredemption_successfullyBtn}\n$itemName',
          textAlign: TextAlign.center,
          style: AppTextStyles.heading(20),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // After non-TIME agreements, go to behavior assessment
              _showBehaviorAssessment();
            },
            child: Text(AppLocalizations.of(context)!.addchild_okBtn,
                style: AppTextStyles.heading(18, color: Palette.sky)),
          ),
        ],
      ),
    );
  }

  // ─── Flow C: Session Timer (TIME type) ────────────────

  void _startSession({
    required String name,
    required AgreementType type,
    required int cost,
    int? durationMinutes,
  }) {
    final minutes = durationMinutes ?? 30;

    setState(() {
      _sessionActive = true;
      _sessionPaused = true; // starts paused, user presses START
      _sessionName = name;
      _sessionType = type;
      _sessionSecondsLeft = minutes * 60;
    });
  }

  void _toggleTimer() {
    if (_sessionPaused) {
      // Resume / Start
      setState(() => _sessionPaused = false);
      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_sessionPaused) return; // skip tick while paused
        setState(() {
          if (_sessionSecondsLeft > 0) {
            _sessionSecondsLeft--;
          } else {
            _endSession();
          }
        });
      });
    } else {
      // Pause
      _sessionTimer?.cancel();
      setState(() => _sessionPaused = true);
    }
  }

  void _endSession() {
    _sessionTimer?.cancel();
    setState(() {
      _sessionActive = false;
      _sessionPaused = true;
    });
    _showBehaviorAssessment();
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ─── Flow D: Behavior Assessment ──────────────────────

  void _showBehaviorAssessment() {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          loc.agreement_behaviorTitle,
          style: AppTextStyles.heading(20),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BehaviorButton(
              icon: Icons.sentiment_very_satisfied,
              label: loc.agreement_behaviorGood,
              color: Palette.successAlt,
              onTap: () {
                Navigator.pop(dialogContext);
                _applyBehaviorBonus(1);
              },
            ),
            const SizedBox(height: 10),
            _BehaviorButton(
              icon: Icons.sentiment_neutral,
              label: loc.agreement_behaviorOk,
              color: Palette.warning,
              onTap: () {
                Navigator.pop(dialogContext);
                _applyBehaviorBonus(0);
              },
            ),
            const SizedBox(height: 10),
            _BehaviorButton(
              icon: Icons.sentiment_dissatisfied,
              label: loc.agreement_behaviorBad,
              color: Palette.errorStrong,
              onTap: () {
                Navigator.pop(dialogContext);
                _applyBehaviorBonus(-1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyBehaviorBonus(int rating) async {
    final loc = AppLocalizations.of(context)!;
    // 1% of wallet-after-redemption, applied back to the redemption cost
    final delta = (_currentScore * 0.01).round().clamp(1, 999999);
    int behaviorDelta = 0;
    int adjustedCost = _lastRedemptionCost;
    String message;

    if (rating > 0) {
      behaviorDelta = delta;
      adjustedCost = (_lastRedemptionCost - delta).clamp(0, 999999);
      message = loc.agreement_bonusMsg(delta);
    } else if (rating < 0) {
      behaviorDelta = -delta;
      adjustedCost = _lastRedemptionCost + delta;
      message = loc.agreement_deductMsg(delta);
    } else {
      message = loc.agreement_noChange;
    }

    if (behaviorDelta != 0 && _lastRedemptionId != null) {
      final result = await _childService.applyBehaviorToRedemption(
        redemptionId: _lastRedemptionId!,
        behaviorDelta: behaviorDelta,
        adjustedCost: adjustedCost,
      );
      if (mounted && result['success'] == true) {
        final newWallet = result['newWallet'];
        setState(() {
          _currentScore = newWallet is int
              ? newWallet
              : int.tryParse(newWallet.toString()) ?? _currentScore;
        });
        _loadData();
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Icon(
          rating > 0
              ? Icons.celebration
              : rating < 0
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
          color: rating > 0
              ? Palette.successAlt
              : rating < 0
                  ? Palette.warning
                  : Palette.sky,
          size: 60,
        ),
        content: Text(
          '${loc.agreement_sessionComplete}\n$message',
          textAlign: TextAlign.center,
          style: AppTextStyles.heading(18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.addchild_okBtn,
                style: AppTextStyles.heading(18, color: Palette.sky)),
          ),
        ],
      ),
    );
  }

  // ─── Localized type label ─────────────────────────────

  String _localizedTypeLabel(AgreementType type) {
    final loc = AppLocalizations.of(context)!;
    switch (type) {
      case AgreementType.time:
        return loc.agreement_typeTime;
      case AgreementType.item:
        return loc.agreement_typeItem;
      case AgreementType.privilege:
        return loc.agreement_typePrivilege;
      case AgreementType.family:
        return loc.agreement_typeFamily;
    }
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // If session is active, show session overlay instead of normal UI
    if (_sessionActive) {
      return _buildSessionScreen(loc);
    }

    String title = '';
    if (_selectedIndex == 0) {
      title = loc.dairyactivity_medalsBtn.toUpperCase();
    } else if (_selectedIndex == 1) {
      title = loc.medalredemption_redemptionBtn;
    } else {
      title = loc.dairyactivity_playhistoryBtn;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title:
            Text(title, style: AppTextStyles.heading(26, color: Palette.sky)),
      ),
      body: Column(
        children: [
          // Name + Score header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Medal icon + names (left side)
                _buildMedalIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Parent name
                      Builder(builder: (context) {
                        final parentName =
                            context.watch<UserProvider>().currentParentName;
                        if (parentName != null && parentName.isNotEmpty) {
                          return Text(
                            parentName,
                            style: AppTextStyles.heading(16,
                                color: Palette.deepGrey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                      // Child name
                      if (widget.childName != null &&
                          widget.childName!.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.child_care,
                                size: 16, color: Palette.sky),
                            const SizedBox(width: 4),
                            Text(widget.childName!,
                                style: AppTextStyles.label(14,
                                    color: Palette.sky)),
                          ],
                        ),
                    ],
                  ),
                ),
                // Score (right side)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(loc.medalredemption_currentscoreBtn,
                        style: AppTextStyles.heading(16)),
                    Text('${_formatNumber(_currentScore)} P',
                        style: AppTextStyles.heading(22)),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildActivitiesPage(loc),
                _buildAgreementsPage(loc),
                _buildHistoryPage(loc),
              ],
            ),
          ),

          // Bottom Nav
          Container(
            decoration: BoxDecoration(
              gradient: Palette.orangeGradient,
              boxShadow: Palette.orangeButtonShadow,
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 64,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBottomBtn('assets/icons/coin.png', 0),
                    _buildBottomBtn('assets/icons/ticket.png', 1),
                    _buildBottomBtn('assets/icons/history-book.png', 2),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Session Screen (Flow C) ──────────────────────────

  Widget _buildSessionScreen(AppLocalizations loc) {
    final color = AgreementHelper.colorFor(_sessionType);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AgreementHelper.iconFor(_sessionType),
                    color: color, size: 64),
                const SizedBox(height: 16),
                Text(loc.agreement_sessionActive,
                    style: AppTextStyles.heading(24, color: color)),
                const SizedBox(height: 8),
                Text(_sessionName,
                    style: AppTextStyles.heading(20),
                    textAlign: TextAlign.center),
                const SizedBox(height: 32),

                // Timer circle
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.1),
                    border: Border.all(color: color, width: 4),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatTime(_sessionSecondsLeft),
                        style: AppTextStyles.heading(40, color: color),
                      ),
                      Text(loc.agreement_timeRemaining,
                          style:
                              AppTextStyles.label(12, color: Palette.deepGrey)),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // START / STOP button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _toggleTimer,
                    icon: Icon(
                      _sessionPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    label: Text(
                      _sessionPaused
                          ? loc.agreement_startTimer
                          : loc.agreement_stopTimer,
                      style: AppTextStyles.heading(20, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _sessionPaused ? Palette.successAlt : Palette.warning,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // END SESSION button (separate)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _endSession,
                    icon: const Icon(Icons.stop_rounded, size: 24),
                    label: Text(
                      loc.agreement_endSession,
                      style:
                          AppTextStyles.heading(18, color: Palette.errorStrong),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Palette.errorStrong,
                      side: const BorderSide(
                          color: Palette.errorStrong, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Tab 1: Activities ────────────────────────────────

  Widget _buildActivitiesPage(AppLocalizations loc) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Palette.sky));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(loc.medalredemption_activitiesBtn,
              style: AppTextStyles.heading(24)),
        ),
        Expanded(
          child: _activityHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_esports,
                          size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                          AppLocalizations.of(context)!
                              .medals_noActivityHistory,
                          style: AppTextStyles.heading(16, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  itemCount: _activityHistory.length,
                  itemBuilder: (context, index) {
                    final activity = _activityHistory[index];
                    final activityName =
                        activity['activity']?['name_activity'] ?? loc.medalredemption_activity;
                    final pointValue = activity['point'];
                    int scoreEarned = 0;
                    if (pointValue is int) {
                      scoreEarned = pointValue;
                    } else if (pointValue is double) {
                      scoreEarned = pointValue.toInt();
                    } else if (pointValue != null) {
                      scoreEarned = int.tryParse(pointValue.toString()) ?? 0;
                    }
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: _OutlineCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activityName.toString().toUpperCase(),
                                    style: AppTextStyles.heading(16),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '+$scoreEarned ${loc.medalredemption_points}',
                                    style: AppTextStyles.heading(14,
                                        color: Palette.successAlt),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1E9FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(loc.medalredemption_done,
                                  style: AppTextStyles.heading(14,
                                      color: Palette.sky)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── Tab 2: Agreements (was Rewards) ──────────────────

  Widget _buildAgreementsPage(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  loc.medalredemption_rewardshopBtn,
                  style: AppTextStyles.heading(20),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // EDIT toggle
              GestureDetector(
                onTap: () => setState(() => _isEditMode = !_isEditMode),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isEditMode ? Palette.warning : Palette.sky,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          _isEditMode
                              ? Icons.check_rounded
                              : Icons.edit_rounded,
                          color: Colors.white,
                          size: 18),
                      const SizedBox(width: 4),
                      Text(
                          _isEditMode
                              ? loc.namesetting_saveBtn
                              : loc.childsetting_manageBtn,
                          style:
                              AppTextStyles.heading(14, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // ADD button
              GestureDetector(
                onTap: _showAddAgreementDialog,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Palette.successAlt,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 5),
                      Text(loc.medalredemption_addBtn,
                          style:
                              AppTextStyles.heading(14, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _rewards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.handshake_outlined,
                          size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(loc.agreement_emptyList,
                          style: AppTextStyles.heading(16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(loc.agreement_emptyHint,
                          style: AppTextStyles.body(14,
                              color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  itemCount: _rewards.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _rewards[index];
                    final int cost = item['cost'] as int;
                    final bool canAfford = _currentScore >= cost;
                    final String rawName = item['name'] as String;
                    final type = AgreementHelper.parseType(rawName);
                    final displayName = AgreementHelper.displayName(rawName);
                    final color = AgreementHelper.colorFor(type);

                    return _OutlineCard(
                      onTap: _isEditMode
                          ? () => _showEditAgreementDialog(item)
                          : () => _showConfirmDialog(item),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(AgreementHelper.iconFor(type),
                                color: color, size: 28),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: AppTextStyles.heading(16,
                                      color: canAfford
                                          ? Colors.black87
                                          : Colors.grey),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (type != null)
                                  Text(
                                    _localizedTypeLabel(type),
                                    style:
                                        AppTextStyles.label(11, color: color),
                                  ),
                              ],
                            ),
                          ),
                          if (_isEditMode) ...[
                            // Edit button
                            IconButton(
                              icon: const Icon(Icons.edit_rounded,
                                  color: Palette.sky, size: 22),
                              onPressed: () => _showEditAgreementDialog(item),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            // Delete button
                            IconButton(
                              icon: const Icon(Icons.delete_rounded,
                                  color: Palette.errorStrong, size: 22),
                              onPressed: () => _showDeleteAgreementDialog(item),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ] else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: canAfford ? color : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                '$cost P',
                                style: AppTextStyles.heading(16,
                                    color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── Tab 3: History ───────────────────────────────────

  Widget _buildHistoryPage(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(loc.dairyactivity_playhistoryBtn,
              style: AppTextStyles.heading(24)),
        ),
        Expanded(
          child: _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history,
                          size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(AppLocalizations.of(context)!.medals_noHistory,
                          style: AppTextStyles.heading(16, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  itemCount: _history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final log = _history[index];
                    final isGain = log['isGain'] as bool;
                    return _OutlineCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log['action'] as String,
                                  style: AppTextStyles.heading(16),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  log['date'] as String,
                                  style: AppTextStyles.body(12,
                                      color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            log['point'] as String,
                            style: AppTextStyles.heading(18,
                                color: isGain
                                    ? Palette.successAlt
                                    : Palette.errorStrong),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── Common Widgets ───────────────────────────────────

  Widget _buildBottomBtn(String assetPath, int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isSelected ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            assetPath,
            width: isSelected ? 50 : 40,
            height: isSelected ? 50 : 40,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40),
          ),
        ),
      ),
    );
  }

  Widget _buildMedalIcon() {
    return Image.asset(
      'assets/icons/medal.png',
      width: 100,
      height: 110,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Container(
          width: 85,
          height: 85,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD45E),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2.5),
          ),
          child: const Center(
              child: Icon(Icons.star, color: Colors.white, size: 50)),
        );
      },
    );
  }
}

// ─── Behavior Rating Button ─────────────────────────────

class _BehaviorButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BehaviorButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 28),
        label:
            Text(label, style: AppTextStyles.heading(16, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

// ─── Internal Widget: OutlineCard ───────────────────────

class _OutlineCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _OutlineCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.black26, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: child,
        ),
      ),
    );
  }
}
