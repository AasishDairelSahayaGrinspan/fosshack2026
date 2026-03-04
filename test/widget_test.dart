import 'package:flutter_test/flutter_test.dart';
import 'package:mindhaven/main.dart';

void main() {
  testWidgets('Unravel app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const UnravelApp());
    await tester.pump(const Duration(milliseconds: 500));

    // Verify splash screen shows app name
    expect(find.text('Unravel'), findsOneWidget);
    expect(find.text('Your quiet place.'), findsOneWidget);
  });
}
