// lib/services/youtube_service.dart

class YouTubeService {
  /// สร้าง HTML สำหรับฝัง YouTube Iframe + IFrame API
  /// และมีฟังก์ชัน JS ชื่อ `playSegment(start, end)`
  static String buildPlayerHtml(String videoId) {
    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
      html, body {
        margin: 0;
        padding: 0;
        background-color: #000000;
        height: 100%;
        overflow: hidden;
      }
      #player {
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
      }
    </style>
    <script src="https://www.youtube.com/iframe_api"></script>
    <script>
      var player;
      function onYouTubeIframeAPIReady() {
        player = new YT.Player('player', {
          videoId: '$videoId',
          playerVars: {
            'playsinline': 1,
            'rel': 0,
            'modestbranding': 1
          }
        });
      }

      function playSegment(start, end) {
        if (!player) return;
        player.seekTo(start, true);
        player.playVideo();
        var duration = (end - start) * 1000;
        setTimeout(function () {
          if (!player) return;
          var current = player.getCurrentTime();
          if (current >= end - 0.1) {
            player.pauseVideo();
          }
        }, duration);
      }
    </script>
  </head>
  <body>
    <div id="player"></div>
  </body>
</html>
''';
  }
}
