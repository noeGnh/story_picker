import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('shows the button that opens the picker', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.widgetWithText(ElevatedButton, 'Pick It'), findsOneWidget);
  });
}
