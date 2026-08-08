import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bilingual_song_model.dart';
import 'api_config.dart';

class BilingualSongService {
  static Future<List<BilingualSongModel>> fetchSongs({bool publishedOnly = true}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/admin/bilingual-songs?publishedOnly=$publishedOnly');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((json) => BilingualSongModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load songs: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching bilingual songs: $e');
      // Return demo fallback songs if API is offline
      return _getDemoSongs();
    }
  }

  static List<BilingualSongModel> _getDemoSongs() {
    return [
      BilingualSongModel(
        id: 'demo-1',
        titleEn: 'Happy Friends Song',
        titleTh: 'เพลงเพื่อนๆ มีความสุข',
        genre: 'Upbeat Nursery Rhyme',
        isPublished: true,
        createdAt: DateTime.now().toIso8601String(),
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        targetWords: [
          TargetWordModel(word: 'sing', thaiMeaning: 'ร้องเพลง', phonetic: 'sing'),
          TargetWordModel(word: 'play', thaiMeaning: 'เล่น', phonetic: 'play'),
          TargetWordModel(word: 'happy', thaiMeaning: 'มีความสุข', phonetic: 'HAP-pee'),
        ],
        lyrics: [
          LyricLineModel(lineEn: 'We can sing a happy song!', lineTh: 'พวกเราร้องเพลงมีความสุขกัน!', chord: 'C'),
          LyricLineModel(lineEn: 'We can play all day long!', lineTh: 'พวกเราเล่นกันได้ทั้งวัน!', chord: 'G'),
          LyricLineModel(lineEn: 'Clap your hands and jump with me!', lineTh: 'ตบมือและกระโดดไปกับฉัน!', chord: 'Am'),
          LyricLineModel(lineEn: 'Happy friends as you can see!', lineTh: 'เพื่อนๆ มีความสุขอย่างเห็นได้ชัด!', chord: 'F'),
        ],
      ),
    ];
  }
}
