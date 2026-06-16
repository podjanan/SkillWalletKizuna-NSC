/// Shared YouTube utilities used across multiple screens.
class YouTubeHelper {
  YouTubeHelper._();

  /// Extract YouTube video ID from various URL formats.
  static String? extractVideoId(String? url) {
    if (url == null || url.isEmpty) return null;
    final patterns = [
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/v/([a-zA-Z0-9_-]{11})'),
    ];
    for (var p in patterns) {
      final m = p.firstMatch(url);
      if (m != null && m.groupCount >= 1) return m.group(1);
    }
    // Bare 11-char ID
    if (url.length == 11 && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
      return url;
    }
    return null;
  }

  /// Build a responsive YouTube embed HTML for InAppWebView.
  static String buildEmbedHtml(String videoId) {
    return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body { width: 100%; height: 100%; overflow: hidden; background: #000; }
  iframe { width: 100%; height: 100%; border: none; }
</style>
</head>
<body>
<iframe
  src="https://www.youtube.com/embed/$videoId?playsinline=1&rel=0&modestbranding=1"
  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
  allowfullscreen>
</iframe>
</body>
</html>
''';
  }

  /// Get YouTube thumbnail URL from video ID.
  static String thumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }
}
