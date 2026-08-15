import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import 'package:skill_wallet_kizuna/models/bilingual_song_model.dart';
import 'package:skill_wallet_kizuna/screens/bilingual_song_player_screen.dart';

void main() {
  testWidgets(
      'Sing Together controls scroll without horizontal or vertical overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final song = BilingualSongModel(
      id: 'layout-test',
      titleEn: 'Good Morning Sunshine With A Long Responsive Title',
      titleTh: '',
      genre: 'test',
      targetWords: [
        TargetWordModel(
          word: 'Good Morning Sunshine',
          thaiMeaning: 'สวัสดียามเช้า',
        ),
      ],
      lyrics: List.generate(
        5,
        (index) => LyricLineModel(
          lineEn: index == 0 ? '[Intro]' : 'A long lyric line number $index',
          lineTh: 'เนื้อเพลงสำหรับทดสอบหน้าจอขนาดเล็ก',
          chord: 'C',
        ),
      ),
      isPublished: true,
      createdAt: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 520),
            textScaler: TextScaler.linear(1.2),
          ),
          child: BilingualSongPlayerScreen(song: song),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Take a photo or record evidence video'));
    await tester.pump();

    expect(find.text('Record Video'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
