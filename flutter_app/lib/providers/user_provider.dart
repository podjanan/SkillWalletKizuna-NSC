import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  final _apiService = ApiService();

  // ==========================================
  // 1. ส่วนข้อมูล ID (Child/Parent ID)
  // ==========================================
  String? _currentChildId; // ไม่ hardcode แล้ว - จะดึงจาก database
  String? _currentParentId;
  List<Map<String, dynamic>> _children = []; // เก็บ children ทั้งหมด

  String? get currentChildId => _currentChildId;
  String? get currentParentId => _currentParentId;
  List<Map<String, dynamic>> get children => _children;

  /// User role from Better Auth session
  String get userRole {
    return AuthService().currentUser?.role ?? 'user';
  }

  bool get isAdmin => userRole == 'admin';

  /// ดึงชื่อเด็กที่เลือกอยู่
  String? get currentChildName {
    if (_currentChildId == null || _children.isEmpty) return null;
    try {
      final childData = _children.firstWhere(
        (c) => c['child']?['child_id'] == _currentChildId,
        orElse: () => {},
      );
      return childData['child']?['name_surname'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// ดึง wallet ของเด็กที่เลือกอยู่
  int get currentChildWallet {
    if (_currentChildId == null || _children.isEmpty) return 0;
    try {
      final childData = _children.firstWhere(
        (c) => c['child']?['child_id'] == _currentChildId,
        orElse: () => {},
      );
      final wallet = childData['child']?['wallet'];
      if (wallet is int) return wallet;
      if (wallet is double) return wallet.toInt();
      if (wallet != null) return int.tryParse(wallet.toString()) ?? 0;
      return 0;
    } catch (e) {
      return 0;
    }
  }

  void setChildId(String id) {
    _currentChildId = id;
    notifyListeners();
  }

  void setParentId(String id) {
    _currentParentId = id;
    notifyListeners();
  }

  // ==========================================
  // 2. ส่วนชื่อผู้ปกครอง (Parent Name)
  // ==========================================
  // ปรับจาก 'PARENT2' เป็นค่าว่าง เพื่อรอรับข้อมูลจริงจาก Google หรือ Database
  String? _currentParentName = '';

  String? get currentParentName => _currentParentName;

  /// ใช้สำหรับอัปเดตค่าในแอปทันที (เช่น ตอน Google Login สำเร็จ)
  void setParentName(String name) {
    _currentParentName = name;
    notifyListeners();
  }

  // ==========================================
  // 3. ฟังก์ชันจัดการข้อมูลผ่าน API
  // ==========================================
  Future<void> fetchParentData() async {
    try {
      final result = await _apiService.get('/parents/me');
      _currentParentName = result['nameSurname'] ?? '';
      _currentParentId = result['parentId']?.toString();

      // Photo URL: from API response first, then from Better Auth user image
      _parentPhotoUrl = (result['photoUrl'] as String?) ??
          AuthService().currentUser?.image;

      notifyListeners();
    } catch (e) {
      debugPrint('fetchParentData error: $e');
    }
  }

  /// 3.1 ดึงข้อมูล Children จาก API
  Future<void> fetchChildrenData() async {
    try {
      // ดึง parent info ก่อน (เพื่อได้ parentId)
      if (_currentParentId == null) {
        try {
          final parentResult = await _apiService.get('/parents/me');
          _currentParentId = parentResult['parentId']?.toString();
        } catch (e) {
          // /parents/me ล้มเหลว (ไม่ได้ login หรือ API ช้า)
          // ยังคงดำเนินการต่อ — /children ใช้ auth token โดยตรง
          debugPrint(
              'fetchChildrenData: /parents/me failed ($e), continuing...');
        }
      }

      // ดึง children จาก API
      final response = await _apiService.get('/children');

      List<Map<String, dynamic>> childrenList;
      if (response is List) {
        childrenList = List<Map<String, dynamic>>.from(response);
      } else if (response is Map &&
          response.containsKey('data') &&
          response['data'] is List) {
        childrenList = List<Map<String, dynamic>>.from(response['data']);
      } else {
        childrenList = [];
      }

      if (childrenList.isNotEmpty) {
        _children = childrenList;

        final currentStillExists = _currentChildId != null &&
            _children.any((c) => c['child']?['child_id'] == _currentChildId);

        if (!currentStillExists &&
            _children.isNotEmpty &&
            _children[0]['child'] != null) {
          _currentChildId = _children[0]['child']['child_id'];
          debugPrint('Child ID set to first child: $_currentChildId');
        }

        notifyListeners();
      } else {
        _children = [];
        debugPrint('No children found');
      }
    } catch (e) {
      debugPrint('fetchChildrenData error: $e');
    }
  }

  /// 3.2 เพิ่มเด็กใหม่ผ่าน API
  Future<bool> addChild({
    required String name,
    required DateTime birthday,
    String? relationship,
  }) async {
    try {
      await _apiService.post('/children', {
        'fullName': name,
        'birthday': birthday.toIso8601String(),
        'relationship': relationship ?? 'พ่อ/แม่',
      });

      await fetchChildrenData();
      debugPrint('Child added successfully');
      return true;
    } catch (e) {
      debugPrint('addChild error: $e');
      return false;
    }
  }

  /// 3.3 แก้ไขข้อมูลเด็กผ่าน API
  Future<bool> updateChild({
    required String childId,
    String? name,
    DateTime? birthday,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['fullName'] = name;
      if (birthday != null) body['birthday'] = birthday.toIso8601String();

      if (body.isEmpty) {
        debugPrint('No updates provided');
        return false;
      }

      await _apiService.patch('/children/$childId', body);
      await fetchChildrenData();
      debugPrint('Child updated successfully: $childId');
      return true;
    } catch (e) {
      debugPrint('updateChild error: $e');
      return false;
    }
  }

  /// 3.4 ลบเด็กผ่าน API
  Future<bool> deleteChild(String childId) async {
    try {
      await _apiService.delete('/children/$childId');

      if (_currentChildId == childId) {
        _currentChildId = null;
      }

      await fetchChildrenData();
      debugPrint('Child deleted successfully: $childId');
      return true;
    } catch (e) {
      debugPrint('deleteChild error: $e');
      return false;
    }
  }

  /// 3.5 เลือกเด็กที่จะใช้งาน
  void selectChild(String childId) {
    _currentChildId = childId;
    notifyListeners();
    debugPrint('✅ Child selected: $childId');
  }

  Future<bool> updateParentName(String name) async {
    try {
      await _apiService.post('/parents/sync', {
        'fullName': name,
      });

      _currentParentName = name;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('updateParentName error: $e');
      return false;
    }
  }

  // ==========================================
  // 4. ส่วนรูปโปรไฟล์ (Profile Image URL)
  // ==========================================
  String? _parentPhotoUrl;

  String? get parentPhotoUrl => _parentPhotoUrl;

  /// Upload parent profile photo via backend API (POST /parents/photo).
  /// Backend handles Supabase Storage and updates user metadata.
  Future<bool> uploadAndSetPhoto(Uint8List bytes) async {
    try {
      final result = await _apiService.postMultipart(
        '/parents/photo',
        bytes: bytes,
      );
      final url = result['photoUrl'] as String?;
      if (url == null) return false;
      _parentPhotoUrl = url;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('uploadAndSetPhoto error: $e');
      return false;
    }
  }

  /// Revert to original OAuth provider photo (Google / Facebook).
  /// Reads the URL saved at login time, updates DB, and refreshes local state.
  Future<bool> setPhotoFromOAuth(String provider) async {
    try {
      final url = await StorageService().getOAuthPhotoUrl();
      if (url == null) return false;
      // Update DB — ignore errors so local state still updates even if server is behind
      try {
        await _apiService.put('/parents/photo', {'photoUrl': url});
      } catch (e) {
        debugPrint('setPhotoFromOAuth backend update failed (will retry on next login): $e');
      }
      _parentPhotoUrl = url;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('setPhotoFromOAuth error: $e');
      return false;
    }
  }

  /// Permanently delete the current parent account from the server,
  /// sign out, and clear all local state.
  Future<bool> deleteAccount() async {
    try {
      await _apiService.delete('/parents/me');
      await AuthService().signOut();
      clearUserData();
      await StorageService().clearAll();
      return true;
    } catch (e) {
      debugPrint('deleteAccount error: $e');
      return false;
    }
  }

  /// Upload child profile photo via backend API (POST /children/{id}/photo).
  /// Backend handles Supabase Storage and updates child.photo_url in DB.
  Future<bool> uploadChildPhoto(String childId, Uint8List bytes) async {
    try {
      final result = await _apiService.postMultipart(
        '/children/$childId/photo',
        bytes: bytes,
      );
      final url = result['photoUrl'] as String?;
      if (url == null) return false;

      // Update local children list immediately
      final idx = _children.indexWhere(
          (c) => c['child']?['child_id'] == childId);
      if (idx != -1) {
        final updated = Map<String, dynamic>.from(_children[idx]);
        final childMap =
            Map<String, dynamic>.from(updated['child'] as Map<String, dynamic>);
        childMap['photo_url'] = url;
        updated['child'] = childMap;
        _children[idx] = updated;
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('uploadChildPhoto error: $e');
      return false;
    }
  }

  // ==========================================
  // 5. ฟังก์ชันล้างค่า (ใช้ตอน Logout)
  // ==========================================
  void clearUserData() {
    _currentParentName = '';
    _currentParentId = '';
    _currentChildId = null;
    _children = [];
    _parentPhotoUrl = null;
    notifyListeners();
  }
}
