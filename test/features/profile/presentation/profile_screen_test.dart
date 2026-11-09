import 'package:active_tracker/features/profile/profile_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/pump.dart';

void main() {
  testWidgets('edit weight and burn target; switch theme and boost', (tester) async {
    await pumpFeature(tester, routes: [ProfileRoutes.tab()], initial: ProfileRoutes.profile, height: 5000);
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('2.6 L'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Weight 75 kg, edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '20');
    await tester.tap(find.text('Save'));
    await settleWithIo(tester);
    expect(find.text('Weight must be 30 to 250 kg'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '80');
    await tester.tap(find.text('Save'));
    await settleWithIo(tester, rounds: 8);
    expect(find.text('2.8 L'), findsOneWidget);
    expect(find.text('128 g'), findsOneWidget);

    await tester.tap(find.text('Active burn'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '4500');
    await tester.tap(find.text('Save'));
    await settleWithIo(tester, rounds: 8);
    expect(find.text('4500 kcal'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await settleWithIo(tester);
    expect(find.text('Always dark'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await settleWithIo(tester);
    expect(find.text('Off'), findsOneWidget);
  });
}
