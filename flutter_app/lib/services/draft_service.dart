// lib/services/draft_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple int notifier — bumped on save/clear so widgets can rebuild.
class DraftVersionNotifier extends ValueNotifier<int> {
  DraftVersionNotifier() : super(0);
  void bump() => value++;
}

/// Persists in-progress activity state across app restarts.
/// One draft per child (keyed by childId). Expires after 24 h.
class DraftService {
  static const String _keyPrefix = 'activity_draft';
  static const Duration _draftExpiry = Duration(hours: 24);

  static const String typePhysical = 'physical';
  static const String typeLanguage = 'language';
  static const String typeCalculate = 'calculate';

  /// Bumped whenever a draft is saved or cleared — banner listens to this.
  static final DraftVersionNotifier versionNotifier = DraftVersionNotifier();

  // ── Save ──────────────────────────────────────────────────────────────────

  static Future<void> saveDraft({
    required String childId,
    required String type,
    required String activityId,
    required Map<String, dynamic> activityJson,
    required Map<String, dynamic> data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final draft = {
      'childId': childId,
      'type': type,
      'activityId': activityId,
      'activityJson': activityJson,
      'savedAt': DateTime.now().toIso8601String(),
      'data': data,
    };
    await prefs.setString('${_keyPrefix}_$childId', jsonEncode(draft));
    versionNotifier.bump();
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  /// Returns null if no draft exists or if it has expired (> 24 h).
  static Future<Map<String, dynamic>?> loadDraft(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_keyPrefix}_$childId');
    if (raw == null) return null;
    try {
      final draft = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.parse(draft['savedAt'] as String);
      if (DateTime.now().difference(savedAt) > _draftExpiry) {
        await clearDraft(childId);
        return null;
      }
      return draft;
    } catch (_) {
      await clearDraft(childId);
      return null;
    }
  }

  // ── Clear ─────────────────────────────────────────────────────────────────

  static Future<void> clearDraft(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_keyPrefix}_$childId');
    versionNotifier.bump();
  }
}
