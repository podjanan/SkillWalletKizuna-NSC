// lib/services/storage_service.dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _boxName = 'app_storage';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _providerKey = 'auth_provider';
  static const String _oauthPhotoKey = 'oauth_photo_url';

  Box? _box;

  // ✅ Initialize Hive (ต้องเรียกใน main.dart ก่อนใช้งาน)
  Future<void> init() async {
    if (_box != null) return; // ถ้า init แล้ว ไม่ต้องทำซ้ำ

    try {
      await Hive.initFlutter();
      _box = await Hive.openBox(_boxName);
      print('✅ StorageService initialized');
    } catch (e) {
      print('❌ StorageService init error: $e');
    }
  }

  // ✅ Save token
  Future<void> saveToken(String token) async {
    await _ensureInitialized();
    await _box?.put(_tokenKey, token);
  }

  // ✅ Get token
  Future<String?> getToken() async {
    await _ensureInitialized();
    return _box?.get(_tokenKey) as String?;
  }

  // ✅ Save user
  Future<void> saveUser(User user) async {
    await _ensureInitialized();
    await _box?.put(_userKey, jsonEncode(user.toJson()));
  }

  // ✅ Get user
  Future<User?> getUser() async {
    await _ensureInitialized();
    final userData = _box?.get(_userKey) as String?;
    if (userData == null) return null;

    try {
      final json = jsonDecode(userData) as Map<String, dynamic>;
      return User.fromJson(json);
    } catch (e) {
      print('Error parsing user data: $e');
      return null;
    }
  }

  // ✅ Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ✅ Clear all data (logout)
  Future<void> clearAll() async {
    await _ensureInitialized();
    await _box?.clear();
  }

  Future<void> saveProvider(String provider) async {
    await _ensureInitialized();
    await _box?.put(_providerKey, provider);
  }

  Future<String?> getProvider() async {
    await _ensureInitialized();
    return _box?.get(_providerKey) as String?;
  }

  Future<void> saveOAuthPhotoUrl(String url) async {
    await _ensureInitialized();
    await _box?.put(_oauthPhotoKey, url);
  }

  Future<String?> getOAuthPhotoUrl() async {
    await _ensureInitialized();
    return _box?.get(_oauthPhotoKey) as String?;
  }

  // ✅ Clear specific keys
  Future<void> clearToken() async {
    await _ensureInitialized();
    await _box?.delete(_tokenKey);
  }

  Future<void> clearUser() async {
    await _ensureInitialized();
    await _box?.delete(_userKey);
  }

  // ✅ Helper: ตรวจสอบว่า Hive initialized แล้วหรือยัง
  Future<void> _ensureInitialized() async {
    if (_box == null) {
      await init();
    }
  }
}
