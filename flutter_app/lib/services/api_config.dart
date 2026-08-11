import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl => _normalizeLocalhostForPlatform(
        dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:3000/api',
      );

  static String get authBaseUrl {
    var url = baseUrl;
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith('/api')) {
      return url.substring(0, url.length - 4);
    }
    return url;
  }

  static String _normalizeLocalhostForPlatform(String rawUrl) {
    return rawUrl;
  }
}
