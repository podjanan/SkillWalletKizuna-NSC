import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.parentName,
    required this.categoryValue,
    required this.onCategoryChanged,
  });

  final String? parentName;
  final String categoryValue;
  final ValueChanged<String?> onCategoryChanged;

  static const blush = Color(0xFFF6D9DC);
  static const sky = Color(0xFF0D92F4);
  static const deepSky = Color(0xFF7DBEF1);

  @override
  Widget build(BuildContext context) {
    // 1. ดึง Localizations มาเตรียมไว้
    final loc = AppLocalizations.of(context)!;

    // 2. สร้าง Map สำหรับแปลง Key เป็น Text ภาษาปัจจุบัน
    Map<String, String> categoryTitle = {
      'CATEGORY': loc.home_categoryBtn,
      'PHYSICAL': loc.home_physicalBtn,
      'LANGUAGE': loc.home_languageBtn,
      'CALCULATION': loc.home_calculationBtn,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Search pill ---
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: blush,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.menu, color: Colors.black87),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  style: TextStyle(
                    fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                    fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    // ใช้ Text จาก AppLocalizations
                    hintText: loc.home_searchBtn,
                    // ปรับ Style Hint ให้รองรับภาษาไทย
                    hintStyle: TextStyle(
                      fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                      fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                      color: Colors.black54,
                      fontSize: 16,
                      letterSpacing: .5,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.search, color: Colors.black54),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- Parent Name ---
        if (parentName != null && parentName!.isNotEmpty)
          Text(
            parentName!,
            style: TextStyle(
              fontFamily: GoogleFonts.luckiestGuy().fontFamily,
              fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
              fontSize: 28,
              height: 1.0,
              color: sky,
            ),
          ),
        const SizedBox(height: 12),

        // --- Dropdown Category ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: deepSky.withOpacity(.75),
            borderRadius: BorderRadius.circular(28),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: categoryValue,
              borderRadius: BorderRadius.circular(16),
              dropdownColor: deepSky,
              icon:
                  const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
              // Style ของตัวที่เลือกโชว์อยู่
              style: TextStyle(
                fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                fontSize: 20,
                color: Colors.white,
              ),
              items: const [
                'CATEGORY',
                'PHYSICAL',
                'LANGUAGE',
                'CALCULATION',
              ]
                  .map(
                    (v) => DropdownMenuItem<String>(
                      value: v,
                      child: Text(
                        categoryTitle[v]!,
                        // Style ของตัวเลือกใน Dropdown (เผื่อต้องการปรับแยก)
                        style: TextStyle(
                          fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                          fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onCategoryChanged,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
