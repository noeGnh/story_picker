import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_picker/story_picker.dart';

import 'helpers.dart';

void main() {
  setUp(() => CameraPlatform.instance = FakeCameraPlatform(cameras: const []));

  testWidgets('fails with a clear message when the localizations are missing', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(() => StoryPicker.pick(context), throwsA(isA<AssertionError>().having((e) => e.message, 'message', contains('StoryPicker.localizationsDelegates'))));
  });

  testWidgets('shows a message when no camera is available', (tester) async {
    await openPicker(tester);

    expect(find.text(const StoryPickerTranslations().cameraUnavailable), findsOneWidget);
  });

  testWidgets('uses the given translations', (tester) async {
    await openPicker(tester, const StoryPickerOptions(translations: StoryPickerTranslations.fr));

    expect(find.text(StoryPickerTranslations.fr.cameraUnavailable), findsOneWidget);
  });

  testWidgets('uses the given theme', (tester) async {
    await openPicker(tester, const StoryPickerOptions(theme: StoryPickerTheme(overlayIconColor: Colors.amber)));

    expect(tester.widget<Icon>(find.byIcon(Icons.close)).color, Colors.amber);
  });

  testWidgets('closing the picker returns null', (tester) async {
    final host = await openPicker(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(host.returned, isTrue);
    expect(host.result, isNull);
  });

  testWidgets('text stories can be disabled', (tester) async {
    await openPicker(tester, const StoryPickerOptions(enableTextStories: false));

    expect(find.byIcon(Icons.text_fields), findsNothing);
  });

  testWidgets('settings button only appears with a settings builder', (tester) async {
    await openPicker(tester);
    expect(find.byIcon(Icons.settings), findsNothing);
  });

  testWidgets('settings builder is opened from the camera', (tester) async {
    await openPicker(tester, StoryPickerOptions(settingsBuilder: (_) => const Scaffold(body: Text('my settings'))));

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('my settings'), findsOneWidget);
  });

  testWidgets('a text story goes all the way back to the caller', (tester) async {
    final host = await openPicker(tester);

    await tester.tap(find.byIcon(Icons.text_fields));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Hello');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(captureButton);
    await tester.pumpAndSettle();

    // Both the text screen and the camera are closed.
    expect(captureButton, findsNothing);
    expect(find.text('open'), findsOneWidget);
    expect(host.result, isA<StoryTextResult>());
  });
}
