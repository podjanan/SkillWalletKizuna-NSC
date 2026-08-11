import 'package:flutter/material.dart';

enum GameCoverType { voiceQuest, spaceAdventure, singTogether }

/// Branded cover art for built-in games — matches calculate / language card style.
class GameActivityCover extends StatelessWidget {
  const GameActivityCover({
    super.key,
    required this.type,
    this.compact = false,
  });

  final GameCoverType type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    String imagePath;
    Color fallbackBg;
    IconData fallbackIcon;
    Color fallbackIconColor;

    switch (type) {
      case GameCoverType.voiceQuest:
        imagePath = 'assets/images/voice_quest_cover.png';
        fallbackBg = const Color(0xFFFFF9DE);
        fallbackIcon = Icons.mic_rounded;
        fallbackIconColor = const Color(0xFFFFB300);
        break;
      case GameCoverType.spaceAdventure:
        imagePath = 'assets/images/space_adventure_cover.png';
        fallbackBg = const Color(0xFF071A34);
        fallbackIcon = Icons.rocket_launch_rounded;
        fallbackIconColor = Colors.white;
        break;
      case GameCoverType.singTogether:
        imagePath = 'assets/images/voice_quest_cover.png';
        fallbackBg = const Color(0xFFE3F2FD);
        fallbackIcon = Icons.music_note_rounded;
        fallbackIconColor = const Color(0xFF2196F3);
        break;
    }

    return Image.asset(
      imagePath,
      width: double.infinity,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: fallbackBg,
        child: Center(
          child: Icon(
            fallbackIcon,
            color: fallbackIconColor,
            size: compact ? 30.0 : 42.0,
          ),
        ),
      ),
    );
  }
}
