import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// แปลง category/difficulty ดิบ (ภาษาไทย) ให้เป็นข้อความตามภาษาที่เลือก
class ActivityL10n {
  static String localizedCategory(BuildContext context, String rawCategory) {
    final l10n = AppLocalizations.of(context)!;
    switch (rawCategory) {
      case 'ด้านภาษา':
        return l10n.common_categoryLanguage;
      case 'ด้านร่างกาย':
        return l10n.common_categoryPhysical;
      case 'ด้านคำนวณ':
        return l10n.common_categoryCalculate;
      default:
        return rawCategory;
    }
  }

  /// ชื่อประเภทกิจกรรมเต็ม เช่น "กิจกรรมภาษา" / "Language Activity"
  static String localizedActivityType(
      BuildContext context, String rawCategory) {
    final l10n = AppLocalizations.of(context)!;
    switch (rawCategory) {
      case 'ด้านภาษา':
        return l10n.common_activityLanguage;
      case 'ด้านร่างกาย':
        return l10n.common_activityPhysical;
      case 'ด้านคำนวณ':
        return l10n.common_activityCalculate;
      default:
        return rawCategory;
    }
  }

  static String localizedDifficulty(
      BuildContext context, String rawDifficulty) {
    final l10n = AppLocalizations.of(context)!;
    switch (rawDifficulty) {
      case 'ง่าย':
        return l10n.common_difficultyEasy;
      case 'กลาง':
        return l10n.common_difficultyMedium;
      case 'ยาก':
        return l10n.common_difficultyHard;
      default:
        return rawDifficulty;
    }
  }
}
