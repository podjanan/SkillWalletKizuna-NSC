import '../models/dynamic_vocabulary_item.dart';
import 'api_service.dart';

class DynamicVocabularyService {
  final ApiService _apiService;

  DynamicVocabularyService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<DynamicVocabularyItem> generate({required String category}) async {
    final response = await _apiService.post(
      '/dynamic-vocabulary',
      {'category': category},
    );
    return DynamicVocabularyItem.fromJson(response);
  }

  Future<DynamicVocabularyBootstrap> fetchBootstrap() async {
    final response = await _apiService.get('/dynamic-vocabulary');
    final rawCategories = response is Map
        ? response['categories'] as List<dynamic>? ?? []
        : <dynamic>[];
    final categories = rawCategories
        .map((json) =>
            DynamicVocabularyCategory.fromJson(json as Map<String, dynamic>))
        .where((category) => category.slug.isNotEmpty)
        .toList();
    final settings = response is Map
        ? Map<String, dynamic>.from(response['settings'] as Map? ?? {})
        : <String, dynamic>{};
    return DynamicVocabularyBootstrap(
      categories: categories,
      settings: settings,
    );
  }

  Future<List<DynamicVocabularyCategory>> fetchCategories() async {
    final bootstrap = await fetchBootstrap();
    return bootstrap.categories;
  }

  Future<Map<String, dynamic>> fetchSession({
    required String category,
    required String difficulty,
  }) async {
    final response = await _apiService.post(
      '/dynamic-vocabulary',
      {
        'category': category,
        'difficulty': difficulty,
        'session': true,
      },
    );
    return response;
  }
}
