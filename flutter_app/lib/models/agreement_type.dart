import 'package:flutter/material.dart';
import '../theme/palette.dart';

/// Agreement types that map to the `[TYPE]` prefix stored in `medals.name_medals`.
enum AgreementType { time, item, privilege, family }

/// Helpers for encoding/decoding agreement type from the `name_medals` DB field.
class AgreementHelper {
  AgreementHelper._();

  static const _prefixMap = {
    AgreementType.time: 'TIME',
    AgreementType.item: 'ITEM',
    AgreementType.privilege: 'PRIVILEGE',
    AgreementType.family: 'FAMILY',
  };

  static final _reverseMap = {
    for (final e in _prefixMap.entries) e.value: e.key,
  };

  /// Matches `[TYPE]` or `[TIME:30]` prefix.
  static final _prefixRegExp = RegExp(r'^\[([A-Z]+)(?::(\d+))?\]');

  /// Encode type + name into DB string.
  /// For TIME type with duration: `[TIME:30]เล่นเกม`
  /// For others: `[ITEM]ไอศกรีม`
  static String encode(AgreementType type, String name,
      {int? durationMinutes}) {
    final tag = _prefixMap[type];
    if (type == AgreementType.time && durationMinutes != null) {
      return '[$tag:$durationMinutes]$name';
    }
    return '[$tag]$name';
  }

  /// Parse type from DB name_medals. Returns `null` for legacy rewards without prefix.
  static AgreementType? parseType(String? nameMedals) {
    if (nameMedals == null) return null;
    final match = _prefixRegExp.firstMatch(nameMedals);
    if (match == null) return null;
    return _reverseMap[match.group(1)];
  }

  /// Parse duration in minutes from `[TIME:30]...`. Returns null if not set.
  static int? parseDuration(String? nameMedals) {
    if (nameMedals == null) return null;
    final match = _prefixRegExp.firstMatch(nameMedals);
    if (match == null || match.group(2) == null) return null;
    return int.tryParse(match.group(2)!);
  }

  /// Extract display name (without prefix). Legacy names pass through unchanged.
  static String displayName(String? nameMedals) {
    if (nameMedals == null) return '';
    return nameMedals.replaceFirst(_prefixRegExp, '');
  }

  /// Icon for each agreement type.
  static IconData iconFor(AgreementType? type) {
    switch (type) {
      case AgreementType.time:
        return Icons.timer_outlined;
      case AgreementType.item:
        return Icons.card_giftcard_rounded;
      case AgreementType.privilege:
        return Icons.star_outline_rounded;
      case AgreementType.family:
        return Icons.family_restroom_outlined;
      case null:
        return Icons.card_giftcard_rounded;
    }
  }

  /// Accent color for each agreement type.
  static Color colorFor(AgreementType? type) {
    switch (type) {
      case AgreementType.time:
        return Palette.sky;
      case AgreementType.item:
        return Palette.warning;
      case AgreementType.privilege:
        return Palette.purple;
      case AgreementType.family:
        return Palette.successAlt;
      case null:
        return Palette.warning;
    }
  }

  /// Thai label for each type.
  static String labelTh(AgreementType type) {
    switch (type) {
      case AgreementType.time:
        return 'เวลา';
      case AgreementType.item:
        return 'สิ่งของ';
      case AgreementType.privilege:
        return 'สิทธิพิเศษ';
      case AgreementType.family:
        return 'กิจกรรมครอบครัว';
    }
  }

  /// English label for each type.
  static String labelEn(AgreementType type) {
    switch (type) {
      case AgreementType.time:
        return 'Time';
      case AgreementType.item:
        return 'Item';
      case AgreementType.privilege:
        return 'Privilege';
      case AgreementType.family:
        return 'Family';
    }
  }
}
