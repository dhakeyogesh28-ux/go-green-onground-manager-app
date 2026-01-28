import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OGManagerApp());

    // Verify that the login screen is shown (contains 'Login' text)
    expect(find.text('Login'), findsAtLeastNWidgets(1));
  });
}
