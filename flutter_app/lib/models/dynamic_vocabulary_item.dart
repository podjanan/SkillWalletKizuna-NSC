class DynamicVocabularyItem {
  final String word;
  final String category;
  final String? thaiMeaning;
  final String? phonetic;
  final String? imageUrl;
  final String? imageSource;
  final String query;

  const DynamicVocabularyItem({
    required this.word,
    required this.category,
    required this.query,
    this.thaiMeaning,
    this.phonetic,
    this.imageUrl,
    this.imageSource,
  });

  factory DynamicVocabularyItem.fromJson(Map<String, dynamic> json) {
    return DynamicVocabularyItem(
      word: json['word']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      thaiMeaning: json['thaiMeaning']?.toString(),
      phonetic: json['phonetic']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      imageSource: json['imageSource']?.toString(),
      query: json['query']?.toString() ?? '',
    );
  }
}

class DynamicVocabularyCategory {
  final String slug;
  final String label;
  final String? thaiLabel;
  final String? icon;
  final String? color;

  const DynamicVocabularyCategory({
    required this.slug,
    required this.label,
    this.thaiLabel,
    this.icon,
    this.color,
  });

  factory DynamicVocabularyCategory.fromJson(Map<String, dynamic> json) {
    return DynamicVocabularyCategory(
      slug: json['slug']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      thaiLabel: json['thaiLabel']?.toString(),
      icon: json['icon']?.toString(),
      color: json['color']?.toString(),
    );
  }
}

class DynamicVocabularyBootstrap {
  final List<DynamicVocabularyCategory> categories;
  final Map<String, dynamic> settings;

  const DynamicVocabularyBootstrap({
    required this.categories,
    required this.settings,
  });
}
