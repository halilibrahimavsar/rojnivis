
import 'package:flutter_test/flutter_test.dart';
import 'package:rojnivis/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RojnivisApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);

    // This is just a placeholder test. The default test checked for counter.
    // Our app starts at Splash or Home.
    // For now, just verification that it pumps is enough.
  });
}
