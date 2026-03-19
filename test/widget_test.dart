import 'package:flutter_test/flutter_test.dart';
import 'package:unravel/main.dart';

void main() {
  testWidgets('Unravel app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const UnravelApp());
    await tester.pump(const Duration(milliseconds: 500));

    // Verify splash screen shows app name
    expect(find.text('Unravel'), findsOneWidget);
    expect(find.text("Slow down. You're safe here."), findsOneWidget);

    // Let splash timer complete to avoid pending Timer assertion at teardown.
    await tester.pump(const Duration(milliseconds: 2500));
  });
}
