// lib/services/child_service.dart
import 'package:flutter/foundation.dart';
import '../models/child_model.dart';
import 'api_service.dart';

class ChildService {
  final ApiService _apiService = ApiService();

  // ✅ Get children for current parent
  Future<List<Child>> getChildren() async {
    try {
      final response = await _apiService.get('/children');
      List<dynamic> data;
      if (response is List) {
        data = response;
      } else if (response is Map &&
          response.containsKey('data') &&
          response['data'] is List) {
        data = response['data'];
      } else {
        return [];
      }
      return data
          .map((json) => Child.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Get children exception: $e');
      return [];
    }
  }

  // ✅ Add child via API
  Future<Child?> addChild({
    required String fullName,
    DateTime? dob,
    String? relationship,
  }) async {
    try {
      final result = await _apiService.post('/children', {
        'fullName': fullName,
        'birthday': dob?.toIso8601String() ?? '',
        'relationship': relationship ?? 'พ่อ/แม่',
      });
      try {
        return Child.fromJson(result);
      } catch (_) {
        // API call succeeded but response format doesn't match Child.fromJson
        // Return a minimal Child object so addChildren() knows it was created
        return Child(fullName: fullName, dob: dob);
      }
    } catch (e) {
      debugPrint('Add child exception: $e');
      return null;
    }
  }

  // ✅ Add multiple children
  Future<List<Child>> addChildren(
      List<Map<String, dynamic>> childrenData) async {
    List<Child> addedChildren = [];

    for (var childData in childrenData) {
      DateTime? dob;
      final dobData = childData['dob'];
      if (dobData is String) {
        dob = DateTime.tryParse(dobData);
      } else if (dobData is DateTime) {
        dob = dobData;
      }

      final child = await addChild(
        fullName: childData['fullName'] as String,
        dob: dob,
        relationship: childData['relation'] as String?,
      );

      if (child != null) {
        addedChildren.add(child);
      }
    }

    return addedChildren;
  }

  // ✅ Update child via API
  Future<Child?> updateChild({
    required String childId,
    String? fullName,
    DateTime? dob,
  }) async {
    try {
      final result = await _apiService.patch('/children/$childId', {
        if (fullName != null) 'fullName': fullName,
        if (dob != null) 'birthday': dob.toIso8601String(),
      });
      return Child.fromJson(result);
    } catch (e) {
      debugPrint('Update child exception: $e');
      return null;
    }
  }

  // ✅ Delete child via API
  Future<bool> deleteChild(String childId) async {
    try {
      await _apiService.delete('/children/$childId');
      return true;
    } catch (e) {
      debugPrint('Delete child exception: $e');
      return false;
    }
  }

  // =====================================================
  // ACTIVITY HISTORY
  // =====================================================

  /// ดึงประวัติกิจกรรมของเด็ก
  Future<List<Map<String, dynamic>>> getActivityHistory(String childId) async {
    try {
      final response =
          await _apiService.get('/children/$childId/activity-history');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      debugPrint('getActivityHistory error: $e');
      return [];
    }
  }

  /// ดึงสรุปคะแนนของเด็ก
  Future<Map<String, dynamic>> getChildStats(String childId) async {
    try {
      final result = await _apiService.get('/children/$childId/stats');
      if (result is Map<String, dynamic>) {
        return result;
      }
      return {'wallet': 0, 'name': '', 'totalActivities': 0};
    } catch (e) {
      debugPrint('getChildStats error: $e');
      return {'wallet': 0, 'name': '', 'totalActivities': 0};
    }
  }

  // =====================================================
  // MEDALS/REWARDS MANAGEMENT
  // =====================================================

  /// ดึง medals ที่ผู้ปกครองสร้าง
  Future<List<Map<String, dynamic>>> getMedals(String parentId) async {
    try {
      final response = await _apiService.get('/medals');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      debugPrint('getMedals error: $e');
      return [];
    }
  }

  // Alias for backward compatibility
  Future<List<Map<String, dynamic>>> getRewards(String parentId) async {
    return getMedals(parentId);
  }

  /// เพิ่ม medal ใหม่ผ่าน API
  Future<Map<String, dynamic>?> addMedal({
    required String parentId,
    required String name,
    required int cost,
  }) async {
    try {
      final result = await _apiService.post('/medals', {
        'name': name,
        'cost': cost,
      });

      if (result['id'] != null) {
        return {
          'id': result['id'],
          'name_medals': name,
          'point_medals': cost,
        };
      }
      return result;
    } catch (e) {
      debugPrint('addMedal error: $e');
      return null;
    }
  }

  // Alias for backward compatibility
  Future<Map<String, dynamic>?> addReward({
    required String parentId,
    required String name,
    required int cost,
    String? description,
    String? iconName,
  }) async {
    return addMedal(parentId: parentId, name: name, cost: cost);
  }

  /// อัพเดท medal (ชื่อ + คะแนน) ผ่าน backend API
  Future<bool> updateMedal({
    required String medalsId,
    required String name,
    required int cost,
  }) async {
    try {
      final result = await _apiService.post('/update-medal', {
        'medalsId': medalsId,
        'name': name,
        'cost': cost,
      });
      return result['success'] == true;
    } catch (e) {
      debugPrint('updateMedal error: $e');
      return false;
    }
  }

  /// ลบ medal ผ่าน backend API
  Future<bool> deleteMedal(String medalsId) async {
    try {
      final result = await _apiService.post('/delete-medal', {
        'medalsId': medalsId,
      });
      return result['success'] == true;
    } catch (e) {
      debugPrint('deleteMedal error: $e');
      return false;
    }
  }

  // Alias for backward compatibility
  Future<bool> deleteReward(String rewardId) async {
    return deleteMedal(rewardId);
  }

  /// แลก medal (ผ่าน backend API)
  Future<Map<String, dynamic>> redeemMedal({
    required String childId,
    required String medalsId,
    required String parentId,
    required int cost,
  }) async {
    try {
      final result = await _apiService.post('/redeem-medal', {
        'childId': childId,
        'medalsId': medalsId,
        'cost': cost,
      });

      final newWallet = result['newWallet'];
      return {
        'success': result['success'] == true,
        'newWallet': newWallet is int
            ? newWallet
            : int.tryParse(newWallet.toString()) ?? 0,
        'message': result['message'] ?? 'แลกของรางวัลสำเร็จ!',
        'redemptionId': result['redemptionId'] as String?,
      };
    } catch (e) {
      debugPrint('redeemMedal error: $e');
      return {
        'success': false,
        'error': 'เกิดข้อผิดพลาด: $e',
      };
    }
  }

  // Alias for backward compatibility
  Future<Map<String, dynamic>> redeemReward({
    required String childId,
    required String rewardId,
    required String rewardName,
    required int cost,
    String? parentId,
  }) async {
    return redeemMedal(
      childId: childId,
      medalsId: rewardId,
      parentId: parentId ?? '',
      cost: cost,
    );
  }

  /// ดึงประวัติการแลก
  Future<List<Map<String, dynamic>>> getRedemptionHistory(
      String childId) async {
    try {
      final response = await _apiService.get('/children/$childId/redemptions');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      debugPrint('getRedemptionHistory error: $e');
      return [];
    }
  }

  /// ปรับ wallet ของเด็ก (บวก/ลบ) ผ่าน backend API
  Future<Map<String, dynamic>> adjustWallet({
    required String childId,
    required int delta,
  }) async {
    try {
      final result = await _apiService.post('/adjust-wallet', {
        'childId': childId,
        'delta': delta,
      });

      final newWallet = result['newWallet'];
      return {
        'success': result['success'] == true,
        'newWallet': newWallet is int
            ? newWallet
            : int.tryParse(newWallet.toString()) ?? 0,
      };
    } catch (e) {
      debugPrint('adjustWallet error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// อัพเดท redemption record ด้วย behavior assessment result
  /// behaviorDelta: บวก = ดี (คืนคะแนน), ลบ = ไม่ดี (หักเพิ่ม), 0 = ไม่เปลี่ยน
  /// adjustedCost: ต้นทุนจริงที่บันทึกใน record
  Future<Map<String, dynamic>> applyBehaviorToRedemption({
    required String redemptionId,
    required int behaviorDelta,
    required int adjustedCost,
  }) async {
    try {
      final result = await _apiService.patch(
        '/redemptions/$redemptionId',
        {'behaviorDelta': behaviorDelta, 'adjustedCost': adjustedCost},
      );
      final newWallet = result['newWallet'];
      return {
        'success': result['success'] == true,
        'newWallet': newWallet is int
            ? newWallet
            : int.tryParse(newWallet.toString()) ?? 0,
      };
    } catch (e) {
      debugPrint('applyBehaviorToRedemption error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// ดึงประวัติคะแนน (ได้และใช้)
  Future<List<Map<String, dynamic>>> getPointHistory(String childId) async {
    try {
      final activities = await getActivityHistory(childId);
      final redemptions = await getRedemptionHistory(childId);

      List<Map<String, dynamic>> history = [];

      for (var activity in activities) {
        final point = activity['point'];
        int pointValue = 0;
        if (point is int) {
          pointValue = point;
        } else if (point is double) {
          pointValue = point.toInt();
        } else if (point != null) {
          pointValue = int.tryParse(point.toString()) ?? 0;
        }

        history.add({
          'type': 'earn',
          'action': activity['activity']?['name_activity'] ?? 'กิจกรรม',
          'point': '+$pointValue',
          'isGain': true,
          'date': activity['created_at'] ?? '',
        });
      }

      for (var redemption in redemptions) {
        final cost = redemption['point_for_reward'];
        int costValue = 0;
        if (cost is int) {
          costValue = cost;
        } else if (cost is double) {
          costValue = cost.toInt();
        } else if (cost != null) {
          costValue = int.tryParse(cost.toString()) ?? 0;
        }

        final medalName = redemption['medals']?['name_medals'] ?? 'ของรางวัล';
        history.add({
          'type': 'spend',
          'action': 'แลก $medalName',
          'point': '-$costValue',
          'isGain': false,
          'date': redemption['created_at'] ?? '',
        });
      }

      history
          .sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

      return history;
    } catch (e) {
      debugPrint('getPointHistory error: $e');
      return [];
    }
  }
}
