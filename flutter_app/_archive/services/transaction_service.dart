// lib/services/transaction_service.dart

import 'api_service.dart';
// import 'dart:convert'; // อาจจำเป็นถ้ามีการจัดการ JSON โดยตรง

class TransactionService {
  // สร้าง instance ของ ApiService เพื่อใช้เรียก HTTP methods
  final ApiService _api = ApiService();

  // --------------------------------------------------------
  // 1. POST /api/activity-record (บันทึกภารกิจและเพิ่มคะแนน)
  // --------------------------------------------------------
  Future<Map<String, dynamic>> submitActivity({
    required String activityId,
    required int totalScoreEarned,
    // Note: ควรส่ง Parent/Child ID ที่ดึงมาจาก UserProvider/Token
    required String
        parentId, // ส่งไปด้วยเพื่อให้ Backend ตรวจสอบความสัมพันธ์ได้
    required String childId,
    required List<Map<String, dynamic>> segmentResults,
    Map<String, dynamic>? evidence, // Optional field
  }) async {
    final body = {
      'activityId': activityId,
      'totalScoreEarned': totalScoreEarned,
      'segmentResults': segmentResults,
      'parentId': parentId, // ส่ง Parent/Child ID ไปกับ Body
      'childId': childId,
      'evidence': evidence,
    };

    // เรียกใช้ post method ของ ApiService
    final responseData = await _api.post('/activity-record', body);

    // คืนค่า Response ที่ได้รับจาก Backend (เช่น message, recordId)
    return responseData;
  }

  // --------------------------------------------------------
  // 2. POST /api/redeem-reward (แลกของรางวัลและหักคะแนน)
  // --------------------------------------------------------
  Future<Map<String, dynamic>> redeemReward({
    required String rewardId,
    required String parentId,
    required String childId,
  }) async {
    final body = {
      'parentId': parentId,
      'childId': childId,
      'rewardId': rewardId,
    };

    // เรียกใช้ post method ของ ApiService
    final responseData = await _api.post('/redeem-reward', body);

    // คืนค่า Response ที่ได้รับจาก Backend (เช่น newScore, message)
    return responseData;
  }
}
