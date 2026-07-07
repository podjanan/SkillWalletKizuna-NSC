import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_config.dart';
import 'auth_service.dart';

class ApiService {
  // 1. Base URL
  static String get _baseUrl => ApiConfig.baseUrl;

  // 2. Headers with Better Auth Bearer token
  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-API-Key': dotenv.env['API_SECRET_KEY'] ?? '',
    };

    final token = await AuthService().token;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // (สามารถเป็น Map หรือ List ก็ได้)
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    Uri uri = Uri.parse('$_baseUrl$path');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      Map<String, String> stringQueryParameters = queryParameters.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      uri = uri.replace(queryParameters: stringQueryParameters);
    }

    final headers = await _getHeaders();
    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return {};
      // ⚠️ คืนค่าเป็น dynamic
      return jsonDecode(response.body);
    } else {
      String errorMessage = 'Failed to load data: ${response.statusCode}';
      try {
        if (response.body.isNotEmpty) {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('error')) {
            errorMessage = errorBody['error'];
          }
        }
      } catch (_) {}
      throw Exception('API Error (${response.statusCode}): $errorMessage');
    }
  }

  Future<List<dynamic>> getArray({
    required String path,
    Map<String, dynamic>? queryParameters,
  }) async {
    final dynamic responseData =
        await get(path, queryParameters: queryParameters);

    // ✅ Case 1: Response ทั้งก้อนเป็น List
    if (responseData is List) {
      return responseData;
    }

    // ✅ Case 2: Response เป็น Map แต่ List อยู่ในคีย์ 'data'
    if (responseData is Map &&
        responseData.containsKey('data') &&
        responseData['data'] is List) {
      return responseData['data'] as List<dynamic>;
    }

    // หากไม่ใช่รูปแบบที่คาดหวัง ให้คืนค่า List ว่าง
    debugPrint('API getArray: Unexpected response format. Path: $path');
    return [];
  }

  Future<Map<String, dynamic>> getActivitiesResponse({
    required String path,
    Map<String, dynamic>? queryParameters,
  }) async {
    final dynamic responseData =
        await get(path, queryParameters: queryParameters);

    // ✅ ตรวจสอบว่าเป็น Map ก่อน Cast
    if (responseData is Map<String, dynamic>) {
      return responseData;
    }
    // ⚠️ ถ้าไม่ใช่ Map (เช่น เป็น List) ให้ throw Error เพื่อจัดการใน Service
    throw Exception(
        'API Error: Expected Map response, but received List/null.');
  }

  Future<Map<String, dynamic>> post(
    String path,
    dynamic body, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final headers = await _getHeaders();
    final response = await http
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(timeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      String errorMessage = 'Failed to process request: ${response.statusCode}';
      try {
        if (response.body.isNotEmpty) {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('error')) {
            errorMessage = errorBody['error'];
          }
        }
      } catch (_) {}
      throw Exception('API Error (${response.statusCode}): $errorMessage');
    }
  }

  Future<Map<String, dynamic>> put(String path, dynamic body) async {
    final headers = await _getHeaders();
    final response = await http
        .put(
          Uri.parse('$_baseUrl$path'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      String errorMessage = 'Failed to process request: ${response.statusCode}';
      try {
        if (response.body.isNotEmpty) {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('error')) {
            errorMessage = errorBody['error'];
          }
        }
      } catch (_) {}
      throw Exception('API Error (${response.statusCode}): $errorMessage');
    }
  }

  Future<Map<String, dynamic>> patch(String path, dynamic body) async {
    final headers = await _getHeaders();
    final response = await http
        .patch(
          Uri.parse('$_baseUrl$path'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      String errorMessage = 'Failed to process request: ${response.statusCode}';
      try {
        if (response.body.isNotEmpty) {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('error')) {
            errorMessage = errorBody['error'];
          }
        }
      } catch (_) {}
      throw Exception('API Error (${response.statusCode}): $errorMessage');
    }
  }

  /// อัปโหลดไฟล์ภาพผ่าน multipart/form-data
  /// ใช้สำหรับ POST /parents/photo และ POST /children/{id}/photo
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Uint8List bytes,
    String fieldName = 'photo',
    String filename = 'photo.jpg',
    String contentType = 'image/jpeg',
  }) async {
    final headers = await _getHeaders();
    // ลบ Content-Type ออก — multipart จะตั้งค่า boundary เอง
    headers.remove('Content-Type');

    final request =
        http.MultipartRequest('POST', Uri.parse('$_baseUrl$path'));
    request.headers.addAll(headers);
    request.files.add(http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: filename,
      contentType: MediaType.parse(contentType),
    ));

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      String errorMessage = 'Upload failed: ${response.statusCode}';
      try {
        if (response.body.isNotEmpty) {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('error')) {
            errorMessage = errorBody['error'];
          }
        }
      } catch (_) {}
      throw Exception('API Error (${response.statusCode}): $errorMessage');
    }
  }

  Future<void> delete(String path) async {
    final headers = await _getHeaders();
    final response = await http
        .delete(
          Uri.parse('$_baseUrl$path'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String errorMessage = 'Failed to delete: ${response.statusCode}';
      try {
        if (response.body.isNotEmpty) {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('error')) {
            errorMessage = errorBody['error'];
          }
        }
      } catch (_) {}
      throw Exception('API Error (${response.statusCode}): $errorMessage');
    }
  }

  // *************************************************************
  // * 5. เมธอดใหม่สำหรับ ActivityService (แก้ไข Error เก่า) *
  // *************************************************************
  Future<Map<String, dynamic>> getActivityById({
    required String path,
    Map<String, dynamic>? queryParameters,
  }) async {
    final dynamic responseData =
        await get(path, queryParameters: queryParameters);

    // ✅ ตรวจสอบว่าเป็น Map ก่อน Cast
    if (responseData is Map<String, dynamic>) {
      return responseData;
    }
    // ⚠️ ถ้าไม่ใช่ Map (เช่น เป็น List) ให้ throw Error เพื่อจัดการใน Service
    throw Exception(
        'API Error: Expected Map response for activity, but received List/null.');
  }
}
