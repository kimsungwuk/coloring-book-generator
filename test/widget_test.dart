// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:my_coloring_book/main.dart';

void main() {
  testWidgets('App should start without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyColoringBookApp());

    // Verify that the app starts successfully
    expect(find.byType(MyColoringBookApp), findsOneWidget);
  });
}
