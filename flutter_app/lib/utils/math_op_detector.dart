/// Scans calculate-activity segments for math operators and normalises
/// question text so that `x`/`X`/`*` → `×` and `/` → `÷` in display.
class MathOpDetector {
  MathOpDetector._();

  // ── Display symbols (Unicode) ──────────────────────────
  static const String plus     = '+';
  static const String minus    = '−';   // U+2212 MINUS SIGN
  static const String multiply = '×';   // U+00D7 MULTIPLICATION SIGN
  static const String divide   = '÷';   // U+00F7 DIVISION SIGN

  // ── Colour per operator (hex, no Flutter dependency) ──
  // Matches Palette: successAlt / sky / warning / pink
  static const Map<String, int> opColorValue = {
    plus:     0xFF66BB6A, // Palette.successAlt  — green
    minus:    0xFF0D92F4, // Palette.sky          — blue
    multiply: 0xFFFF9800, // Palette.warning      — orange
    divide:   0xFFEA5B6F, // Palette.pink         — pink
  };

  // ── Regex — operator must sit between two digit characters ──
  static final _plusRe     = RegExp(r'\d\s*\+\s*\d');
  static final _minusRe    = RegExp(r'\d\s*[-−]\s*\d');
  static final _multiplyRe = RegExp(r'\d\s*[*×xX]\s*\d');
  static final _divideRe   = RegExp(r'\d\s*[/÷]\s*\d');

  // ── Public API ─────────────────────────────────────────

  /// Returns detected operators sorted by frequency (most → least).
  /// Returns an **empty list** when nothing is found (caller should
  /// treat empty as "show all four").
  static List<String> detect(dynamic segments) {
    if (segments == null) return [];
    final segs = segments is List ? segments : <dynamic>[];

    final counts = <String, int>{
      plus: 0, minus: 0, multiply: 0, divide: 0,
    };

    for (final seg in segs) {
      final text = (seg['question'] ?? seg['text'] ?? '').toString();
      counts[plus]     = counts[plus]!     + _plusRe.allMatches(text).length;
      counts[minus]    = counts[minus]!    + _minusRe.allMatches(text).length;
      counts[multiply] = counts[multiply]! + _multiplyRe.allMatches(text).length;
      counts[divide]   = counts[divide]!   + _divideRe.allMatches(text).length;
    }

    return counts.entries
        .where((e) => e.value > 0)
        .toList()
        .also((list) => list.sort((a, b) => b.value.compareTo(a.value)))
        .map((e) => e.key)
        .toList();
  }

  /// Normalises a question string for display:
  /// `x` / `X` / `*` between digits  →  `×`
  /// `/` between digits               →  `÷`
  static String normalizeQuestion(String text) {
    return text
        .replaceAllMapped(
          RegExp(r'(\d)\s*[xX*]\s*(\d)'),
          (m) => '${m[1]} × ${m[2]}',
        )
        .replaceAllMapped(
          RegExp(r'(\d)\s*/\s*(\d)'),
          (m) => '${m[1]} ÷ ${m[2]}',
        );
  }
}

// Small helper so we can sort in-place and still chain.
extension _ListExt<T> on List<T> {
  List<T> also(void Function(List<T>) fn) {
    fn(this);
    return this;
  }
}
