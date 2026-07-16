import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final imagePath = _isVoiceQuest
        ? 'assets/images/voice_quest_cover.png'
        : 'assets/images/space_adventure_cover.png';
    final fallbackBg =
        _isVoiceQuest ? const Color(0xFFFFF9DE) : const Color(0xFF071A34);
    final fallbackIcon =
        _isVoiceQuest ? Icons.mic_rounded : Icons.rocket_launch_rounded;
    final fallbackIconColor =
        _isVoiceQuest ? const Color(0xFFFFB300) : Colors.white;

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
