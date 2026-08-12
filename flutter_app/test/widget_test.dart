import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:skill_wallet_kizuna/screens/disclaimer/software_disclaimer_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('requires confirmation before entering the app', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MaterialApp(
        home: SoftwareDisclaimerGate(
          preferences: preferences,
          child: const Text('APP CONTENT'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ข้อตกลงในการใช้ซอฟต์แวร์'), findsOneWidget);
    expect(find.text('APP CONTENT'), findsNothing);

    final acceptButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'ยอมรับและดำเนินการต่อ'),
    );
    expect(acceptButton.onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'ยอมรับและดำเนินการต่อ'),
    );
    await tester.pumpAndSettle();

    expect(find.text('APP CONTENT'), findsOneWidget);
  });

  testWidgets('skips the disclaimer after accepting the current version',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'software_disclaimer_accepted_version':
          SoftwareDisclaimerGate.agreementVersion,
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MaterialApp(
        home: SoftwareDisclaimerGate(
          preferences: preferences,
          child: const Text('APP CONTENT'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('APP CONTENT'), findsOneWidget);
    expect(find.text('ข้อตกลงในการใช้ซอฟต์แวร์'), findsNothing);
  });
}
