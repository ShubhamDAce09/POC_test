import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iim_shillong_community/app.dart';
import 'package:iim_shillong_community/app_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login screen requires an institute email', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppBootstrap.initialize();
    await tester.pumpWidget(const CommunityApp());
    await tester.pump();

    expect(find.text('IIM Shillong'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'not-an-institute@gmail.com');
    await tester.enterText(find.byType(TextFormField).last, 'secret1');
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(
      find.text('Email must end with @iimshillong.ac.in'),
      findsOneWidget,
    );
  });
}
