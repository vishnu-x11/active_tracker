import 'dart:async';

import 'package:active_tracker/app/router.dart';
import 'package:active_tracker/core/providers/core_providers.dart';
import 'package:active_tracker/core/storage/app_database.dart';
import 'package:active_tracker/core/theme/app_palette.dart';
import 'package:active_tracker/features/auth/presentation/providers.dart';
import 'package:active_tracker/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../features/auth/fakes.dart';
import '../helpers/pump.dart';

void main() {
  sqfliteFfiInit();

  late StreamController<String?> uid;
  late FakeAuthRepository auth;

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = await tester.runAsync(() => AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi));
    uid = StreamController<String?>.broadcast();
    auth = FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db!),
          displayNameProvider.overrideWithValue('Test User'),
          accountLabelProvider.overrideWithValue('test@example.com'),
          todayProvider.overrideWithValue(DateTime(2026, 11, 5)),
          currentUidProvider.overrideWith((ref) => uid.stream),
          authRepositoryProvider.overrideWithValue(auth),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            theme: ThemeData(extensions: const [AppPalette.light]),
            routerConfig: ref.watch(routerProvider),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('signed out → login; phone path opens the number screen', (tester) async {
    await pumpApp(tester);
    expect(find.text('Active Tracker'), findsOneWidget);
    uid.add(null);
    await settleWithIo(tester);
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.ensureVisible(find.text('Continue with phone'));
    await tester.tap(find.text('Continue with phone'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in with phone'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), '98765 43210');
    await tester.tap(find.text('Send code'));
    await settleWithIo(tester);
    expect(find.text('Enter the code'), findsOneWidget);
    expect(find.text('Resend code in 0:30'), findsOneWidget);
    expect(auth.calls, ['sendCode +919876543210 -']);
  });

  testWidgets('new user → onboarding → burn target → Home', (tester) async {
    await pumpApp(tester);
    uid.add('new-user');
    await settleWithIo(tester);
    expect(find.text('Your body stats'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your weight'), findsOneWidget);
    expect(find.text('Enter your height'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '75');
    await tester.enterText(find.byType(TextField).at(1), '178');
    await tester.pumpAndSettle();
    expect(find.text('23.7'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Daily burn target'), findsOneWidget);
    expect(find.text('600'), findsOneWidget);

    await tester.tap(find.byTooltip('More, by 50 kcal'));
    await tester.pumpAndSettle();
    expect(find.text('650'), findsOneWidget);

    await tester.tap(find.text('Start tracking'));
    await settleWithIo(tester);
    expect(find.text('BURNED TODAY'), findsOneWidget);
  });

  testWidgets('signing out from the Profile tab returns to login', (tester) async {
    await pumpApp(tester);
    uid.add('leaving-user');
    await settleWithIo(tester);
    await tester.enterText(find.byType(TextField).at(0), '75');
    await tester.enterText(find.byType(TextField).at(1), '178');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start tracking'));
    await settleWithIo(tester);

    await tester.tap(find.text('Profile'));
    await settleWithIo(tester);
    await tester.scrollUntilVisible(
      find.text('Sign out'),
      300,
      scrollable: find.descendant(of: find.byType(ProfileScreen), matching: find.byType(Scrollable)).first,
    );
    await tester.drag(find.byType(ProfileScreen), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pump();
    expect(auth.calls.last, 'signOut');
    uid.add(null);
    await settleWithIo(tester);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
