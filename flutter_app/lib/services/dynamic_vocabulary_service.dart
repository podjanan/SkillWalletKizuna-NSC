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

  Future<List<DynamicVocabularyCategory>> fetchCategories() async {
    final response = await _apiService.get('/dynamic-vocabulary');
    final rawCategories = response is Map
        ? response['categories'] as List<dynamic>? ?? []
        : <dynamic>[];
    return rawCategories
        .map((json) =>
            DynamicVocabularyCategory.fromJson(json as Map<String, dynamic>))
        .where((category) => category.slug.isNotEmpty)
        .toList();
  }
}
