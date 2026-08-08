class LyricLineModel {
  final String lineEn;
  final String lineTh;
  final String chord;

  LyricLineModel({
    required this.lineEn,
    required this.lineTh,
    required this.chord,
  });

  factory LyricLineModel.fromJson(Map<String, dynamic> json) {
    return LyricLineModel(
      lineEn: json['lineEn']?.toString() ?? '',
      lineTh: json['lineTh']?.toString() ?? '',
      chord: json['chord']?.toString() ?? 'C',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lineEn': lineEn,
      'lineTh': lineTh,
      'chord': chord,
    };
  }
}

class TargetWordModel {
  final String word;
  final String thaiMeaning;
  final String? phonetic;

  TargetWordModel({
    required this.word,
    required this.thaiMeaning,
    this.phonetic,
  });

  factory TargetWordModel.fromJson(Map<String, dynamic> json) {
    return TargetWordModel(
      word: json['word']?.toString() ?? '',
      thaiMeaning: json['thaiMeaning']?.toString() ?? '',
      phonetic: json['phonetic']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'thaiMeaning': thaiMeaning,
      'phonetic': phonetic,
    };
  }
}

class BilingualSongModel {
  final String id;
  final String titleEn;
  final String titleTh;
  final String genre;
  final List<TargetWordModel> targetWords;
  final List<LyricLineModel> lyrics;
  final String? audioUrl;
  final String? coverUrl;
  final bool isPublished;
  final String createdAt;

  BilingualSongModel({
    required this.id,
    required this.titleEn,
    required this.titleTh,
    required this.genre,
    required this.targetWords,
    required this.lyrics,
    this.audioUrl,
    this.coverUrl,
    required this.isPublished,
    required this.createdAt,
  });

  factory BilingualSongModel.fromJson(Map<String, dynamic> json) {
    return BilingualSongModel(
      id: json['id']?.toString() ?? '',
      titleEn: json['titleEn']?.toString() ?? '',
      titleTh: json['titleTh']?.toString() ?? '',
      genre: json['genre']?.toString() ?? 'Upbeat Nursery Rhyme',
      targetWords: (json['targetWords'] as List<dynamic>?)
              ?.map((w) => TargetWordModel.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      lyrics: (json['lyrics'] as List<dynamic>?)
              ?.map((l) => LyricLineModel.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
      audioUrl: json['audioUrl']?.toString(),
      coverUrl: json['coverUrl']?.toString(),
      isPublished: json['isPublished'] as bool? ?? true,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleEn': titleEn,
      'titleTh': titleTh,
      'genre': genre,
      'targetWords': targetWords.map((w) => w.toJson()).toList(),
      'lyrics': lyrics.map((l) => l.toJson()).toList(),
      'audioUrl': audioUrl,
      'coverUrl': coverUrl,
      'isPublished': isPublished,
      'createdAt': createdAt,
    };
  }
}
