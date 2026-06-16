import 'package:flutter/foundation.dart';
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
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return rawUrl;
    }

    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return rawUrl;

    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      return uri.replace(host: '10.0.2.2').toString();
    }
    return rawUrl;
  }
}
