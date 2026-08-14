import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_wallet_kizuna/screens/bilingual_songs_screen.dart';

void main() {
  testWidgets('song source cards grow without a RenderFlex overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.5),
          ),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: BilingualSongSourceCard(
                        title: 'เลือกเพลงของเราเพื่อร้องเพลงด้วยกัน',
                        subtitle: 'พร้อมเล่นและฝึกคำศัพท์ภาษาอังกฤษ',
                        icon: Icons.library_music_rounded,
                        selected: true,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BilingualSongSourceCard(
                        title: 'Create Your Own Song',
                        subtitle: 'Words and sentences for the whole family',
                        icon: Icons.auto_awesome_rounded,
                        selected: false,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final cards = find.byType(BilingualSongSourceCard);
    expect(cards, findsNWidgets(2));
    expect(
        tester.getSize(cards.first).height, tester.getSize(cards.last).height);
    expect(tester.getSize(cards.first).height, greaterThanOrEqualTo(128));
  });
}
