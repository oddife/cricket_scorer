import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cricket_scorer/app/app.dart';
import 'package:cricket_scorer/app/theme/theme_mode_provider.dart';

void main() {
  testWidgets('Cricket Scorer app loads', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const CricketScorerApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Cricket Scorer'), findsNWidgets(2));
    expect(find.text('Tournament'), findsOneWidget);
    expect(find.text('Normal Match'), findsOneWidget);
  });
}
