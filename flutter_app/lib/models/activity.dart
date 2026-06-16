// lib/models/activity.dart

import 'dart:convert'; // 🆕 จำเป็นสำหรับการใช้ jsonDecode
import 'package:flutter/foundation.dart'; // สำหรับ debugPrint

class Activity {
  final String id;
  final String name;
  final String category;
  final String content;
  final String difficulty;
  final int maxScore;
  final String? description;
  final String? videoUrl;

  // segments: ใช้ dynamic เพื่อรองรับ List<Map<String, dynamic>> ที่ถูก decode แล้ว
  final dynamic segments;

  final String? thumbnailUrl;
  final String? tiktokHtmlContent;

  // 🆕 เพิ่ม fields สำหรับเรียงกิจกรรม
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ----------------------------------------------------
  // CONSTRUCTOR
  // ----------------------------------------------------

  Activity({
    required this.id,
    required this.name,
    required this.category,
    required this.content,
    required this.difficulty,
    required this.maxScore,
    this.description,
    this.videoUrl,
    this.segments,
    this.thumbnailUrl,
    this.tiktokHtmlContent,
    this.createdAt, // 🆕
    this.updatedAt, // 🆕
  });

  // ----------------------------------------------------
  // JSON MAPPING (Deserialization)
  // ----------------------------------------------------

  factory Activity.fromJson(Map<String, dynamic> json) {
    dynamic segmentsData = json['segments'];

    // 🟢 Logic จัดการ Double-Encoded JSON String
    if (segmentsData is String) {
      try {
        segmentsData = jsonDecode(segmentsData);
      } catch (e) {
        segmentsData = null;
        debugPrint('Warning: Failed to decode segments JSON string: $e');
      }
    }

    // Helper: รองรับทั้ง snake_case (Supabase direct) และ camelCase (API)
    T? pick<T>(String snakeKey, String camelKey) {
      return (json[snakeKey] ?? json[camelKey]) as T?;
    }

    final rawMaxScore = json['maxscore'] ?? json['maxScore'] ?? 0;

    return Activity(
      id: (json['activity_id'] ?? json['activityId'] ?? json['id']) as String,
      name: (json['name_activity'] ?? json['nameActivity'] ?? json['name'])
          as String,
      category: json['category'] as String,
      content: json['content'] as String,
      difficulty: (json['level_activity'] ?? json['difficulty']) as String,
      maxScore: rawMaxScore is int
          ? rawMaxScore
          : int.tryParse(rawMaxScore.toString()) ?? 0,
      description: pick<String>('description_activity', 'description'),
      videoUrl: pick<String>('videourl', 'videoUrl'),
      segments: segmentsData,
      thumbnailUrl: pick<String>('thumbnailurl', 'thumbnailUrl'),
      tiktokHtmlContent: pick<String>('tiktokhtmlcontent', 'tiktokHtmlContent'),
      createdAt: _tryParseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _tryParseDate(json['update_at'] ?? json['updatedAt']),
    );
  }

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // ----------------------------------------------------
  // JSON MAPPING (Serialization)
  // ----------------------------------------------------

  Map<String, dynamic> toJson() {
    // ✅ ใช้ key แบบ snake_case เหมือนกับ database และ fromJson()
    return {
      'activity_id': id,
      'name_activity': name,
      'category': category,
      'content': content,
      'level_activity': difficulty,
      'maxscore': maxScore,
      'description_activity': description,
      'videourl': videoUrl,
      'segments': segments,
      'thumbnailurl': thumbnailUrl, // ✅ snake_case
      'tiktokhtmlcontent': tiktokHtmlContent, // ✅ snake_case

      // 🆕 แปลง DateTime เป็น ISO8601 String
      'created_at': createdAt?.toIso8601String(),
      'update_at': updatedAt?.toIso8601String(),
    };
  }
}
