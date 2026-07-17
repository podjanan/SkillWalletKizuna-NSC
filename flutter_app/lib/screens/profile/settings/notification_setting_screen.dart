import 'package:flutter/material.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';

class NotificationSettingScreen extends StatefulWidget {
  const NotificationSettingScreen({super.key});

  @override
  State<NotificationSettingScreen> createState() =>
      _NotificationSettingScreenState();
}

class _NotificationSettingScreenState extends State<NotificationSettingScreen> {
  // สถานะของปุ่มต่างๆ
  bool _allNotifications = true;
  bool _likeNotification = true;
  bool _commentNotification = true;

  @override
  Widget build(BuildContext context) {
    final bool isSubOptionsEnabled = _allNotifications;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Header ---
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back,
                          size: 30, color: Colors.black87),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!
                        .notificationsetting_notificationBtn,
                    style: AppTextStyles.heading(24, color: Palette.blueChip),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // --- 2. ALL NOTIFICATIONS Toggle ---
              _buildToggleRow(
                title: AppLocalizations.of(context)!
                    .notificationsetting_allnotificationBtn,
                value: _allNotifications,
                onChanged: (val) {
                  setState(() {
                    _allNotifications = val;
                    _likeNotification = val;
                    _commentNotification = val;
                  });
                },
                isMainToggle: true,
              ),

              const SizedBox(height: 24),

              // --- 3. POST Category ---
              Text(
                AppLocalizations.of(context)!.notificationsetting_postBtn,
                style: AppTextStyles.heading(20, color: Palette.labelGrey),
              ),
              const SizedBox(height: 16),

              // --- 4. Sub Toggles ---
              _buildToggleRow(
                title:
                    AppLocalizations.of(context)!.notificationsetting_likeBtn,
                value: _likeNotification,
                onChanged: isSubOptionsEnabled
                    ? (val) {
                        setState(() {
                          _likeNotification = val;
                        });
                      }
                    : null,
                isEnabled: isSubOptionsEnabled,
              ),

              const SizedBox(height: 12),

              _buildToggleRow(
                title: AppLocalizations.of(context)!
                    .notificationsetting_commentBtn,
                value: _commentNotification,
                onChanged: isSubOptionsEnabled
                    ? (val) {
                        setState(() {
                          _commentNotification = val;
                        });
                      }
                    : null,
                isEnabled: isSubOptionsEnabled,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required bool value,
    required Function(bool)? onChanged,
    bool isMainToggle = false,
    bool isEnabled = true,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.heading(20,
                color: isEnabled ? Colors.black87 : Colors.grey.shade400),
          ),
        ),
        Transform.scale(
          scale: 0.9,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: Palette.error,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Palette.greyCard,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ),
      ],
    );
  }
}
