import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wastemanagementapp/core/di/service_locator.dart';
import 'package:wastemanagementapp/main.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    mockSecureStorage();
    await sl.reset();
    await setupServiceLocator();
  });

  testWidgets('First launch lands on Onboarding, not the camera', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: WasteClassifierApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Know your bin, instantly'), findsOneWidget);
    expect(find.textContaining('Camera Viewfinder'), findsNothing);
  });

  testWidgets('Completing onboarding lands on Home with a Scan Item CTA', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: WasteClassifierApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Welcome -> Permissions -> Council selection -> Get Started
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Scan an Item'), findsOneWidget);
    expect(find.text('Waste Classifier'), findsOneWidget);
  });
}
