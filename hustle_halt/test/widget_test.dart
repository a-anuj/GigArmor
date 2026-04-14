import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hustle_halt/main.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Wrap in ProviderScope since the app uses Riverpod
    await tester.pumpWidget(const ProviderScope(child: HustleHaltApp()));

    // Wait for any initial animations or async operations to settle
    await tester.pumpAndSettle();

    // Verify that the login screen loads by finding the title/brand text
    expect(find.text('HustleHalt'), findsWidgets);
  });
}
