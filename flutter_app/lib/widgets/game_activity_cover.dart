import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/palette.dart';

enum GameCoverType { voiceQuest, spaceAdventure }

/// Branded cover art for built-in games — matches calculate / language card style.
class GameActivityCover extends StatelessWidget {
  const GameActivityCover({
    super.key,
    required this.type,
    this.compact = false,
  });

  final GameCoverType type;
  final bool compact;

  bool get _isVoiceQuest => type == GameCoverType.voiceQuest;

  Color get _accent =>
      _isVoiceQuest ? const Color(0xFFFFB300) : Palette.pink;

  String get _title => _isVoiceQuest ? 'Voice Quest' : 'Space Adventure';

  String get _tag => _isVoiceQuest ? 'LANGUAGE' : 'PHYSICAL';

  IconData get _icon =>
      _isVoiceQuest ? Icons.mic_rounded : Icons.rocket_launch_rounded;

  @override
  Widget build(BuildContext context) {
    if (!_isVoiceQuest) {
      return Image.asset(
        'assets/images/space_adventure_cover.png',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: Color(0xFF071A34),
          child: Center(
            child: Icon(Icons.rocket_launch_rounded,
                color: Colors.white, size: 42),
          ),
        ),
      );
    }

    final headerSize = compact ? 8.0 : 11.0;
    final iconSize = compact ? 30.0 : 48.0;
    final tagSize = compact ? 6.0 : 8.0;
    final inset = compact ? 6.0 : 10.0;

    return ColoredBox(
      color: const Color(0xFFFFF9DE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 10,
              vertical: compact ? 4 : 7,
            ),
            decoration: BoxDecoration(gradient: Palette.skyGradient),
            child: Text(
              _title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label(headerSize, color: Colors.white),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: Container(
                    margin: EdgeInsets.all(inset),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(compact ? 8 : 14),
                      border: Border.all(
                        color: _accent.withValues(alpha: 0.45),
                        width: 1.5,
                      ),
                      boxShadow: Palette.softShadow,
                    ),
                    child: Center(
                      child: Icon(_icon, size: iconSize, color: _accent),
                    ),
                  ),
                ),
                Positioned(
                  left: compact ? 4 : 8,
                  bottom: compact ? 3 : 6,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 5 : 7,
                      vertical: compact ? 2 : 3,
                    ),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _tag,
                      style: AppTextStyles.label(tagSize, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
