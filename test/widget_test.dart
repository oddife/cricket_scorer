import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cricket_scorer/app/app.dart';

void main() {
  testWidgets('Cricket Scorer app loads', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CricketScorerApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Cricket Scorer'), findsNWidgets(2));
    expect(find.text('Tournament'), findsOneWidget);
    expect(find.text('Normal Match'), findsOneWidget);
  });
}
