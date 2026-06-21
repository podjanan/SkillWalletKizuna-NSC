import 'api_service.dart';

class SpaceAdventureService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final res = await _apiService.get('/space-adventure/settings');
      if (res['success'] == true) {
        return res['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error loading space adventure settings: $e');
    }
    return {'scorePerItem': 10, 'timerLimit': 60};
  }

  Future<List<String>> scanRoom(String base64Image) async {
    try {
      final res = await _apiService.post('/space-adventure/scan', {
        'image': base64Image,
      });
      if (res['success'] == true && res['objects'] is List) {
        return List<String>.from(res['objects']);
      }
    } catch (e) {
      print('Error scanning room image: $e');
    }
    return ['pillow', 'chair', 'bed', 'book', 'toy', 'bottle', 'cup'];
  }

  Future<Map<String, dynamic>> verifyObject(String base64Image, String target) async {
    try {
      final res = await _apiService.post('/space-adventure/verify', {
        'image': base64Image,
        'target': target,
      });
      if (res['success'] == true) {
        return {
          'match': res['match'] ?? false,
          'confidence': res['confidence'] ?? 0.0,
          'reason': res['reason'] ?? '',
        };
      }
    } catch (e) {
      print('Error verifying object image: $e');
    }
    return {
      'match': false,
      'confidence': 0.0,
      'reason': 'Error calling vision AI check. Try again!',
    };
  }

  Future<bool> submitScore(String playerName, int score) async {
    try {
      final res = await _apiService.post('/space-adventure/score', {
        'playerName': playerName,
        'score': score,
      });
      return res['success'] == true;
    } catch (e) {
      print('Error submitting score: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final res = await _apiService.get('/space-adventure/score');
      if (res['success'] == true && res['scores'] is List) {
        return List<Map<String, dynamic>>.from(res['scores']);
      }
    } catch (e) {
      print('Error loading leaderboard: $e');
    }
    return [];
  }
}
