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

  /// Rewrites localhost asset URLs to the host used by the configured API.
  /// This keeps MinIO images working on Android emulators and real devices.
  static String resolveAssetUrl(String rawUrl) {
    final value = rawUrl.trim();
    if (value.isEmpty ||
        value.startsWith('asset:') ||
        value.startsWith('data:')) {
      return value;
    }

    final uri = Uri.tryParse(value);
    if (uri == null) return value;

    // The API may return a root-relative upload path instead of an absolute URL.
    // Resolve it against the API origin so Image.network also works on devices.
    if (!uri.hasScheme) {
      final origin = Uri.tryParse(authBaseUrl);
      if (origin == null || origin.host.isEmpty) return value;
      return origin.resolveUri(uri).toString();
    }

    // MinIO's port is commonly unreachable from a physical phone even when the
    // API itself is reachable. Send object-storage images through the public API
    // media proxy so presets only need the same host/port as normal API calls.
    if (uri.port == 9000 && uri.pathSegments.length >= 2) {
      final apiUri = Uri.tryParse(baseUrl);
      if (apiUri != null && apiUri.host.isNotEmpty) {
        return apiUri.replace(
          pathSegments: [
            ...apiUri.pathSegments.where((segment) => segment.isNotEmpty),
            'media',
            ...uri.pathSegments,
          ],
          queryParameters:
              uri.queryParameters.isEmpty ? null : uri.queryParameters,
        ).toString();
      }
    }

    if (uri.host != 'localhost' && uri.host != '127.0.0.1') return rawUrl;

    final apiUri = Uri.tryParse(baseUrl);
    if (apiUri == null || apiUri.host.isEmpty) {
      return _normalizeLocalhostForPlatform(rawUrl);
    }
    return uri.replace(host: apiUri.host).toString();
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
