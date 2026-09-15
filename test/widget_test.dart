import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iim_shillong_community/app.dart';
import 'package:iim_shillong_community/app_bootstrap.dart';

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxTries = 60,
}) async {
  for (var i = 0; i < maxTries; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Widget not found: $finder');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppBootstrap.initialize();
  });

  testWidgets('login screen requires an institute email', (tester) async {
    await tester.pumpWidget(const CommunityApp());
    await tester.pump();

    expect(find.text('IIM Shillong'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'not-an-institute@gmail.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secret1');
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(
      find.text('Email must end with @iimshillong.ac.in'),
      findsOneWidget,
    );
  });

  testWidgets(
    'demo flow: login, sample Excel, electives, personalized timetable',
    (tester) async {
      await tester.pumpWidget(const CommunityApp());
      await tester.pump();

      await tester.enterText(
        find.byType(TextFormField).first,
        'shubham.pgpex26@iimshillong.ac.in',
      );
      await tester.enterText(find.byType(TextFormField).last, 'secret1');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));

      await pumpUntilFound(tester, find.text('Office timetable'));

      await tester.tap(find.text('Load sample PGPEx timetable'));
      await pumpUntilFound(tester, find.text('Your subjects'));

      expect(find.textContaining('Managerial Economics'), findsWidgets);
      expect(find.textContaining('FinTech Strategy'), findsOneWidget);

      await tester.tap(find.textContaining('FinTech Strategy'));
      await tester.pump();
      await tester.tap(find.text('Save 1 elective'));

      await pumpUntilFound(tester, find.text('My timetable'));
      expect(find.textContaining('Managerial Economics'), findsWidgets);
      expect(find.textContaining('FinTech Strategy'), findsWidgets);
      expect(find.textContaining('Digital Marketing'), findsNothing);
      expect(find.textContaining('Supply Chain Analytics'), findsNothing);
    },
  );
}
