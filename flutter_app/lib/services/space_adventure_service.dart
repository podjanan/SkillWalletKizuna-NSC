import 'api_service.dart';

class SpaceAdventureArea {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> items;

  const SpaceAdventureArea({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.items,
  });

  factory SpaceAdventureArea.fromJson(Map<String, dynamic> json) {
    return SpaceAdventureArea(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      items: List<String>.from(json['items'] as List? ?? const []),
    );
  }
}

class SpaceAdventureScanResult {
  final bool success;
  final List<String> objects;
  final String? error;
  final String? reason;

  const SpaceAdventureScanResult({
    required this.success,
    required this.objects,
    this.error,
    this.reason,
  });
}

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

  Future<List<SpaceAdventureArea>> getAreas() async {
    try {
      final res = await _apiService.get(
        '/space-adventure/areas',
        queryParameters: {'activeOnly': 'true'},
      );
      if (res['success'] == true && res['areas'] is List) {
        return (res['areas'] as List)
            .map((json) => SpaceAdventureArea.fromJson(json as Map<String, dynamic>))
            .where((area) => area.items.isNotEmpty)
            .toList();
      }
    } catch (e) {
      print('Error loading space adventure areas: $e');
    }
    return [];
  }

  Future<SpaceAdventureScanResult> scanRoom(String base64Image) async {
    try {
      final res = await _apiService.post(
        '/space-adventure/scan',
        {'image': base64Image},
        timeout: const Duration(seconds: 180),
      );
      if (res['success'] == true && res['objects'] is List) {
        return SpaceAdventureScanResult(
          success: true,
          objects: List<String>.from(res['objects']),
        );
      }
      return SpaceAdventureScanResult(
        success: false,
        objects: List<String>.from(res['objects'] as List? ?? const []),
        error: (res['error'] ?? 'Unable to scan room image.').toString(),
        reason: (res['reason'] ?? '').toString(),
      );
    } catch (e) {
      print('Error scanning room image: $e');
      return SpaceAdventureScanResult(
        success: false,
        objects: const [],
        error: 'Unable to scan room image.',
        reason: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> verifyObject(String base64Image, String target) async {
    try {
      final res = await _apiService.post(
        '/space-adventure/verify',
        {
          'image': base64Image,
          'target': target,
        },
        timeout: const Duration(seconds: 180),
      );
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
      'reason': 'Detection service is not ready. Please try again.',
    };
  }

}
