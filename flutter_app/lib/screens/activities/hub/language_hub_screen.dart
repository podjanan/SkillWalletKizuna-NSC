import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/ui.dart';
import '../../../routes/app_routes.dart';
import '../../../models/language_flow.dart';

class LanguageHubScreen extends StatelessWidget {
  const LanguageHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.languagehub_appTitle,
            style: luckiestH(20)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SearchBar(),
          const SizedBox(height: 14),
          // Bilingual Songs Banner Card
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.bilingualSongs);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Sing Together',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'ฟังเพลงสองภาษา + โหมดคอร์ดกีต้าร์สำหรับผู้ปกครอง',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.school_outlined, size: 18),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.languagehub_trainingTitle,
                  style: AppTextStyles.heading(16)),
            ],
          ),
          const SizedBox(height: 18),
          Text(AppLocalizations.of(context)!.languagehub_listeningSpeakingTitle,
              style: luckiestH(18, color: Palette.sky)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              PillButton(
                label: AppLocalizations.of(context)!.languagehub_easyBtn,
                bg: Palette.successAlt,
                fg: Colors.white,
                onTap: () =>
                    _openList(context, 'LISTENING AND SPEAKING', 'EASY'),
              ),
              PillButton(
                label: AppLocalizations.of(context)!.languagehub_mediumBtn,
                bg: Palette.yellow,
                fg: Colors.black,
                onTap: () =>
                    _openList(context, 'LISTENING AND SPEAKING', 'MEDIUM'),
              ),
              PillButton(
                label: AppLocalizations.of(context)!.languagehub_difficultBtn,
                bg: Palette.pink,
                fg: Colors.white,
                onTap: () =>
                    _openList(context, 'LISTENING AND SPEAKING', 'DIFFICULT'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.languagehub_fillInBlanksTitle,
              style: luckiestH(18, color: Palette.sky)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              PillButton(
                label: AppLocalizations.of(context)!.languagehub_easyBtn,
                bg: Palette.successAlt,
                fg: Colors.white,
                onTap: () => _openList(context, 'FILL IN THE BLANKS', 'EASY'),
              ),
              PillButton(
                label: AppLocalizations.of(context)!.languagehub_mediumBtn,
                bg: Palette.yellow,
                fg: Colors.black,
                onTap: () => _openList(context, 'FILL IN THE BLANKS', 'MEDIUM'),
              ),
              PillButton(
                label: AppLocalizations.of(context)!.languagehub_difficultBtn,
                bg: Palette.pink,
                fg: Colors.white,
                onTap: () =>
                    _openList(context, 'FILL IN THE BLANKS', 'DIFFICULT'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openList(BuildContext context, String topic, String level) {
    Navigator.pushNamed(
      context,
      AppRoutes.languageList,
      arguments: LangListArgs(topic, level),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF3DDF0),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.menu_rounded, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(AppLocalizations.of(context)!.languagehub_searchHint,
                  style: const TextStyle(color: Colors.black54))),
          const Icon(Icons.search, size: 20),
        ],
      ),
    );
  }
}
