// lib/services/mock_auth_service.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_service.dart';

/// Mock Authentication Service สำหรับ Development
/// ใช้เมื่อไม่สามารถ login ได้ (เช่น ไม่มี Google OAuth credentials)
class MockAuthService {
  static bool get isDeveloperMode {
    return dotenv.env['DEVELOPER_MODE']?.toLowerCase() == 'true';
  }

  /// สร้าง Mock Session สำหรับ Development
  /// ⚠️ ใช้สำหรับ development เท่านั้น! ห้ามใช้ใน production
  static Future<void> createMockSession() async {
    if (!isDeveloperMode) {
      throw Exception('Mock session can only be created in developer mode');
    }

    const mockEmail = 'developer@skillwalletkizuna.dev';
    const mockName = 'Developer (Mock User)';

    print('🔧 Creating mock session for development...');
    print('📧 Mock Email: $mockEmail');

    try {
      await ApiService().post('/parents/sync', {
        'email': mockEmail,
        'fullName': mockName,
      });
      print('✅ Mock user data created via API');
    } catch (e) {
      print('⚠️ Could not create mock user via API: $e');
      print('ℹ️ Make sure the backend is running and reachable');
    }
  }

  static bool shouldUseMockAuth() {
    return isDeveloperMode;
  }

  static void printDebugInfo() {
    if (isDeveloperMode) {
      print('');
      print('═══════════════════════════════════════');
      print('🔧 DEVELOPER MODE ENABLED');
      print('═══════════════════════════════════════');
      print('Authentication will be bypassed');
      print('Mock user will be used for testing');
      print('⚠️  DO NOT use this in production!');
      print('═══════════════════════════════════════');
      print('');
    }
  }
}
