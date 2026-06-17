import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/activity.dart';
import 'api_config.dart';
import 'api_service.dart';

/// Processing status for each recorded segment.
enum SegmentStatus { idle, processing, done, error }

class SegmentResult {
  final String id;
  final String text;
  final int maxScore; // Accuracy Score (0-100) — set after evaluation
  final SegmentStatus status;
  final String? recognizedText;
  final String? audioUrl; // local path only, never sent to backend
  final Uint8List? audioBytes; // web-only playback bytes, never sent to backend

  const SegmentResult({
    required this.id,
    required this.text,
    this.maxScore = 0,
    this.status = SegmentStatus.idle,
    this.recognizedText,
    this.audioUrl,
    this.audioBytes,
  });

  SegmentResult copyWith({
    int? maxScore,
    SegmentStatus? status,
    String? recognizedText,
    String? audioUrl,
    Uint8List? audioBytes,
  }) =>
      SegmentResult(
        id: id,
        text: text,
        maxScore: maxScore ?? this.maxScore,
        status: status ?? this.status,
        recognizedText: recognizedText ?? this.recognizedText,
        audioUrl: audioUrl ?? this.audioUrl,
        audioBytes: audioBytes ?? this.audioBytes,
      );

  // 🔒 Privacy-first: audioUrl ไม่ถูกส่งไป Backend
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'maxScore': maxScore,
        'recognizedText': recognizedText,
      };

  /// Used only for local draft persistence — includes status field.
  Map<String, dynamic> toDraftJson() => {
        'id': id,
        'text': text,
        'maxScore': maxScore,
        'status': status.name,
        'recognizedText': recognizedText,
      };

  factory SegmentResult.fromDraftJson(Map<String, dynamic> json) =>
      SegmentResult(
        id: json['id'] as String? ?? '',
        text: json['text'] as String? ?? '',
        maxScore: json['maxScore'] as int? ?? 0,
        status: SegmentStatus.values.firstWhere(
          (s) => s.name == (json['status'] as String? ?? 'idle'),
          orElse: () => SegmentStatus.idle,
        ),
        recognizedText: json['recognizedText'] as String?,
      );
}

class ActivityService {
  final ApiService _apiService = ApiService();
  String get API_BASE_URL => ApiConfig.baseUrl;

  // --- Category Constants (Thai names used in database) ---
  static const String _categoryPhysical = 'ด้านร่างกาย';

  // ----------------------------------------------------
  // 1. HELPER FUNCTIONS
  // ----------------------------------------------------
  // 1.1 Helper: ดึง OEmbed Data ผ่าน Backend proxy
  Future<Map<String, dynamic>> _fetchTikTokOEmbedData(String videoUrl) async {
    final result = await _apiService.post('/tiktok-oembed', {
      'videoUrl': videoUrl,
    });
    return result;
  }

  // 1.2 Helper: ดึง activities จาก API พร้อม query params
  Future<List<Activity>> _fetchActivitiesFromApi({
    String? sortBy,
    String? sortOrder,
    String? category,
    String? level,
    String? parentId,
    String? ownedBy,
    int limit = 100,
  }) async {
    final params = <String, dynamic>{
      'limit': limit.toString(),
    };
    if (sortBy != null) params['sortBy'] = sortBy;
    if (sortOrder != null) params['sortOrder'] = sortOrder;
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (level != null && level.isNotEmpty) params['level'] = level;
    if (parentId != null && parentId.isNotEmpty) params['parentId'] = parentId;
    if (ownedBy != null && ownedBy.isNotEmpty) params['ownedBy'] = ownedBy;

    final List<dynamic> responseList = await _apiService.getArray(
      path: '/activities',
      queryParameters: params,
    );
    return responseList
        .map((json) => Activity.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // 1.3 Helper: เสริม TikTok oEmbed ให้ activity ที่มี video
  Future<Activity> _enrichWithOEmbed(Activity activity) async {
    if (activity.videoUrl == null || activity.category != _categoryPhysical) {
      return activity;
    }
    // ถ้า API ส่ง tiktokHtmlContent มาแล้ว ไม่ต้อง fetch ซ้ำ
    if (activity.tiktokHtmlContent != null &&
        activity.tiktokHtmlContent!.isNotEmpty) {
      return activity;
    }
    try {
      final oEmbedData = await _fetchTikTokOEmbedData(activity.videoUrl!);
      final String? thumbnailUrl = oEmbedData['thumbnailUrl'] as String?;
      final String? htmlContent = oEmbedData['html'] as String?;
      if (htmlContent != null && htmlContent.isNotEmpty) {
        final json = activity.toJson();
        json['thumbnailurl'] = thumbnailUrl ?? '';
        json['tiktokhtmlcontent'] = htmlContent;
        return Activity.fromJson(json);
      }
    } catch (e) {
      debugPrint('OEmbed failed for ${activity.name}: $e');
    }
    return activity;
  }

  // ----------------------------------------------------
  // 2. DATA FETCHING (Home Screen)
  // ----------------------------------------------------
  /// 2.1 ดึง Physical Activity Clip (สำหรับส่วน CLIP VDO หลัก)
  Future<Activity?> fetchPhysicalActivityClip(String childId) async {
    try {
      final activities = await _fetchActivitiesFromApi(
        category: 'ด้านร่างกาย',
        limit: 20,
      );
      final physicalActivity = activities.firstWhereOrNull(
        (a) => a.videoUrl != null && a.videoUrl!.isNotEmpty,
      );
      if (physicalActivity != null) {
        return await _enrichWithOEmbed(physicalActivity);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching physical clip: $e');
      return null;
    }
  }

  /// 2.2 ดึง Popular Activities (เรียงตามจำนวนรอบการเล่น)
  Future<List<Activity>> fetchPopularActivities(
    String childId, {
    String? category,
    String? level,
    String? parentId,
  }) async {
    try {
      final activities = await _fetchActivitiesFromApi(
        sortBy: 'play_count',
        sortOrder: 'desc',
        category: category,
        level: level,
        parentId: parentId,
      );
      // Enrich activities with TikTok oEmbed if needed
      final enriched = await Future.wait(
        activities.map((a) => _enrichWithOEmbed(a)),
      );
      return enriched;
    } catch (e) {
      debugPrint('Error fetching popular activities: $e');
      return [];
    }
  }

  /// 2.3 ดึง New Activities (เรียงตาม created_at)
  Future<List<Activity>> fetchNewActivities(
    String childId, {
    String? category,
    String? level,
    String? parentId,
  }) async {
    try {
      final activities = await _fetchActivitiesFromApi(
        sortBy: 'created_at',
        sortOrder: 'desc',
        category: category,
        level: level,
        parentId: parentId,
      );
      final enriched = await Future.wait(
        activities.map((a) => _enrichWithOEmbed(a)),
      );
      return enriched;
    } catch (e) {
      debugPrint('Error fetching new activities: $e');
      return [];
    }
  }

  // ----------------------------------------------------
  // 2.4 ดึง Language Activities (ตามหัวข้อและระดับ)
  // ----------------------------------------------------
  Future<List<Activity>> fetchLanguageActivities({
    String? topic,
    String? level,
  }) async {
    try {
      final activities = await _fetchActivitiesFromApi(
        category: 'ด้านภาษา',
        level: level,
      );
      debugPrint('Language Activities Found: ${activities.length}');
      return activities;
    } catch (e) {
      debugPrint('Error fetching language activities: $e');
      return [];
    }
  }

  // ----------------------------------------------------
  // 3. AI EVALUATION AND QUEST COMPLETION
  // ----------------------------------------------------
  /// 4.1 ส่งไฟล์เสียงไปประเมิน AI
  Future<Map<String, dynamic>> evaluateAudio({
    required File audioFile,
    required String originalText,
  }) async {
    try {
      final uri = Uri.parse('$API_BASE_URL/evaluate');
      final request = http.MultipartRequest('POST', uri);
      request.headers['X-API-Key'] = dotenv.env['API_SECRET_KEY'] ?? '';
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          audioFile.path,
        ),
      );
      request.fields['text'] = originalText;
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        Map<String, dynamic>? errorBody;
        try {
          errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          // ignore decode error
        }
        throw Exception(
          'AI Evaluation Failed (${response.statusCode}): '
          '${errorBody?['error'] ?? response.reasonPhrase}',
        );
      }
    } catch (e) {
      debugPrint('AI Evaluation Error: $e');
      throw Exception('Failed to send audio for evaluation: $e');
    }
  }

  /// 4.1b ส่งเสียงจากหน่วยความจำ (Web) ไปประเมิน AI
  Future<Map<String, dynamic>> evaluateAudioBytes({
    required Uint8List audioBytes,
    required String originalText,
    String filename = 'recording.m4a',
  }) async {
    try {
      final uri = Uri.parse('$API_BASE_URL/evaluate');

      final request = http.MultipartRequest('POST', uri);
      request.headers['X-API-Key'] = dotenv.env['API_SECRET_KEY'] ?? '';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          audioBytes,
          filename: filename,
          contentType: MediaType('audio', 'wav'),
        ),
      );
      request.fields['text'] = originalText;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        Map<String, dynamic>? errorBody;
        try {
          errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
        throw Exception(
          'AI Evaluation Failed (${response.statusCode}): '
          '${errorBody?['error'] ?? response.reasonPhrase}',
        );
      }
    } catch (e) {
      debugPrint('AI Evaluation (bytes) Error: $e');
      throw Exception('Failed to send audio bytes for evaluation: $e');
    }
  }

  /// 4.2 คำนวณคะแนนรวมและส่ง Payload ไปบันทึกใน CMS
  Future<Map<String, dynamic>> finalizeQuest({
    required String childId,
    required String activityId,
    required List<SegmentResult> segmentResults,
    required int activityMaxScore,
    Map<String, dynamic>? evidence,
    int? parentScore, // 🆕 รับ parentScore แยกเป็น parameter
    int? timeSpent, // ⏱️ เวลาที่ใช้ในการทำกิจกรรม (วินาที)
    bool useDirectScore = false, // 🆕 สำหรับกิจกรรมวิเคราะห์ที่ใช้คะแนนดิบ
  }) async {
    final numSections = segmentResults.length;

    int finalScore;
    int calculatedScore;

    if (useDirectScore) {
      // 🎯 สำหรับกิจกรรมวิเคราะห์: ใช้คะแนนดิบโดยตรง
      double totalScore = 0.0;
      for (var res in segmentResults) {
        totalScore += res.maxScore;
      }
      finalScore = parentScore ?? totalScore.toInt();
      calculatedScore = totalScore.toInt(); // คะแนนดิบ

      print('📊 Service Debug (Direct Score):');
      print('  - Total raw score: $totalScore');
      print('  - Activity maxScore: $activityMaxScore');
      print('  - finalScore: $finalScore');
    } else {
      // 📚 สำหรับกิจกรรมภาษา: คำนวณจาก accuracy percentage
      double totalAccuracy = 0.0;
      for (var res in segmentResults) {
        totalAccuracy += res.maxScore;
      }
      final averageAccuracy =
          numSections > 0 ? (totalAccuracy / numSections) : 0.0;
      final scoreEarned = (activityMaxScore * (averageAccuracy / 100)).floor();

      finalScore = parentScore ?? scoreEarned;
      calculatedScore = parentScore ?? averageAccuracy.round();

      print('📊 Service Debug (Percentage):');
      print('  - Average accuracy: $averageAccuracy%');
      print('  - scoreEarned: $scoreEarned');
      print('  - finalScore: $finalScore');
    }

    print('  - parentScore received: $parentScore');
    print('  - evidence: $evidence');

    // 3. สร้าง Payload
    final payload = {
      'childId': childId,
      'activityId': activityId,
      'totalScoreEarned': finalScore,
      'timeSpent': timeSpent,
      'segmentResults': segmentResults.map((r) => r.toJson()).toList(),
      'evidence': evidence,
      'parentScore': parentScore,
    };
    print('📦 Payload to Backend: $payload');
    try {
      final res = await _apiService.post('/complete-quest', payload);
      res['scoreEarned'] = finalScore;
      res['calculatedScore'] = calculatedScore;
      return res;
    } catch (e) {
      debugPrint('Finalize Quest Error: $e');
      throw Exception('Failed to finalize quest and save record.');
    }
  }

  /// สร้างกิจกรรมใหม่ผ่าน backend API
  Future<Map<String, dynamic>> createActivity({
    required String parentId,
    required String name,
    required String category,
    required String content,
    required String difficulty,
    required int maxScore,
    String? description,
    String? videoUrl,
    List<Map<String, dynamic>>? segments,
    bool isPublic = true,
  }) async {
    final payload = {
      'name': name,
      'category': category,
      'content': content,
      'difficulty': difficulty,
      'maxScore': maxScore,
      'parentId': parentId,
      'isPublic': isPublic,
      if (description != null) 'description': description,
      if (videoUrl != null && videoUrl.isNotEmpty) 'videoUrl': videoUrl,
      if (segments != null) 'segments': segments,
    };
    return _apiService.post('/activities', payload);
  }

  /// ดึงกิจกรรมที่ผู้ปกครองคนนี้สร้าง
  Future<List<Activity>> fetchMyActivities(String parentId) async {
    try {
      final activities = await _fetchActivitiesFromApi(
        ownedBy: parentId,
        sortBy: 'created_at',
        sortOrder: 'desc',
      );
      final enriched = await Future.wait(
        activities.map((a) => _enrichWithOEmbed(a)),
      );
      return enriched;
    } catch (e) {
      debugPrint('Error fetching my activities: $e');
      return [];
    }
  }

  /// แก้ไขกิจกรรมผ่าน backend API
  Future<Map<String, dynamic>> updateActivity({
    required String activityId,
    String? name,
    String? category,
    String? content,
    String? difficulty,
    int? maxScore,
    String? description,
    String? videoUrl,
    List<Map<String, dynamic>>? segments,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (category != null) payload['category'] = category;
    if (content != null) payload['content'] = content;
    if (difficulty != null) payload['difficulty'] = difficulty;
    if (maxScore != null) payload['maxScore'] = maxScore;
    if (description != null) payload['description'] = description;
    if (videoUrl != null) payload['videoUrl'] = videoUrl;
    if (segments != null) payload['segments'] = segments;
    return _apiService.patch('/activities/$activityId', payload);
  }

  /// ลบกิจกรรมผ่าน backend API
  Future<void> deleteActivity(String activityId) async {
    await _apiService.delete('/activities/$activityId');
  }
}
