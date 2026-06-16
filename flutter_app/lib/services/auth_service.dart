// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_config.dart';
import 'storage_service.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = StorageService();
  User? _cachedUser;
  String? _cachedToken;

  static String get _authBaseUrl => ApiConfig.authBaseUrl;

  String get _authUrl => '$_authBaseUrl/api/auth';

  // ==========================================
  // Token / session management
  // ==========================================

  Future<String?> get token async {
    _cachedToken ??= await _storage.getToken();
    return _cachedToken;
  }

  Future<bool> get isSignedIn async {
    final t = await token;
    return t != null && t.isNotEmpty;
  }

  User? get currentUser => _cachedUser;

  Future<void> _saveSession(String token, Map<String, dynamic> userJson) async {
    _cachedToken = token;
    await _storage.saveToken(token);
    try {
      _cachedUser = User.fromJson(userJson);
      await _storage.saveUser(_cachedUser!);
    } catch (e) {
      debugPrint('AuthService: error caching user: $e');
    }
  }

  Future<void> clearSession() async {
    _cachedToken = null;
    _cachedUser = null;
    await _storage.clearAll();
  }

  Future<Map<String, String>> _headers({bool withToken = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (withToken) {
      final t = await token;
      if (t != null) headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  // ==========================================
  // Auth methods
  // ==========================================

  /// Email + password sign-in
  Future<User> signInWithEmail(String email, String password) async {
    final response = await http
        .post(
          Uri.parse('$_authUrl/sign-in/email'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(body['message'] ?? body['error'] ?? 'Sign-in failed');
    }

    final sessionToken = body['token'] as String?;
    if (sessionToken == null) throw Exception('No token returned from server');
    await _saveSession(sessionToken, body['user'] as Map<String, dynamic>);
    return _cachedUser!;
  }

  /// Email + password sign-up
  Future<User> signUpWithEmail(
      String email, String password, String name) async {
    final response = await http
        .post(
          Uri.parse('$_authUrl/sign-up/email'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password, 'name': name}),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(body['message'] ?? body['error'] ?? 'Sign-up failed');
    }

    final sessionToken = body['token'] as String?;
    if (sessionToken == null) throw Exception('No token returned from server');
    await _saveSession(sessionToken, body['user'] as Map<String, dynamic>);
    return _cachedUser!;
  }

  /// Social sign-in (google / facebook) with native ID token
  Future<User> signInWithSocial({
    required String provider,
    required String idToken,
    String? accessToken,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_authUrl/sign-in/social'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'provider': provider,
            'idToken': {
              'token': idToken,
              if (accessToken != null) 'accessToken': accessToken,
            },
          }),
        )
        .timeout(const Duration(seconds: 20));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(
          body['message'] ?? body['error'] ?? 'Social sign-in failed');
    }

    // Bearer plugin returns token in body; also check Authorization header as fallback
    final sessionToken = body['token'] as String? ??
        response.headers['authorization']?.replaceFirst('Bearer ', '');
    if (sessionToken == null) {
      throw Exception('No token returned from social sign-in');
    }
    await _saveSession(sessionToken, body['user'] as Map<String, dynamic>);
    return _cachedUser!;
  }

  /// Sign out (invalidates session on server and clears local storage)
  Future<void> signOut() async {
    try {
      final headers = await _headers(withToken: true);
      await http
          .post(Uri.parse('$_authUrl/sign-out'), headers: headers)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('AuthService signOut API error (ignored): $e');
    } finally {
      await clearSession();
    }
  }

  /// Verify that the stored token is still valid. Returns session+user or null.
  Future<Map<String, dynamic>?> getSession() async {
    final t = await token;
    if (t == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$_authUrl/get-session'),
        headers: {'Authorization': 'Bearer $t'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      if (body == null) return null;

      final userJson = body['user'] as Map<String, dynamic>?;
      if (userJson != null) {
        try {
          _cachedUser = User.fromJson(userJson);
        } catch (_) {}
      }
      return body;
    } catch (e) {
      debugPrint('AuthService getSession error: $e');
      return null;
    }
  }

  /// Send password-reset email
  Future<void> forgotPassword(String email) async {
    final response = await http
        .post(
          Uri.parse('$_authUrl/forget-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'redirectTo': '$_authBaseUrl/reset-password',
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(
          body?['message'] ?? body?['error'] ?? 'Failed to send reset email');
    }
  }
}
