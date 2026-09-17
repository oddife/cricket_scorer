import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cricket_scorer/app/app.dart';
import 'package:cricket_scorer/app/theme/theme_mode_provider.dart';
import 'package:cricket_scorer/core/database/database_provider.dart';
import 'package:cricket_scorer/data/database/app_database.dart';

void main() {
  testWidgets('Cricket Scorer app loads', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final database = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          appDatabaseProvider.overrideWithValue(database),
        ],
        child: const CricketScorerApp(),
      ),
    );

    await tester.pump();

    expect(find.text('Cricket Scorer'), findsNWidgets(2));
    expect(find.text('Start a Match'), findsOneWidget);
    expect(find.text('Tournament'), findsOneWidget);
    expect(find.text('Match Centre'), findsOneWidget);
    expect(find.text('Management'), findsOneWidget);
  });
}
