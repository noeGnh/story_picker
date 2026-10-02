import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as ui show IconButton;
import 'package:story_picker/story_picker.dart';

import 'helpers.dart';

const _red = StoryBackground(gradient: LinearGradient(colors: [Colors.red, Colors.red]));
const _blue = StoryBackground(
  gradient: LinearGradient(colors: [Colors.blue, Colors.blue]),
  textColor: Colors.white,
);

/// Opens the picker, then the text screen.
Future<HostState> openTextScreen(WidgetTester tester, [StoryPickerOptions options = const StoryPickerOptions()]) async {
  final host = await openPicker(tester, options);
  await tester.tap(find.byIcon(Icons.text_fields));
  await tester.pumpAndSettle();
  return host;
}

Future<void> write(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump();
}

/// Closes the keyboard, then taps the capture button.
Future<void> submit(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.tap(captureButton);
  await tester.pumpAndSettle();
}

final nextBackground = find.byWidgetPredicate((w) => w is ui.IconButton && w.icon is Container);

EditableText editable(WidgetTester tester) => tester.widget<EditableText>(find.byType(EditableText));

void main() {
  setUp(() => CameraPlatform.instance = FakeCameraPlatform());

  testWidgets('text story is returned to the caller with its style', (tester) async {
    final host = await openTextScreen(tester);

    await write(tester, '  Hello story  ');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(nextBackground);
    await submit(tester);

    final result = host.result;
    expect(result, isA<StoryTextResult>());
    result as StoryTextResult;
    expect(result.text, 'Hello story');
    expect(result.textAlign, TextAlign.center);
    expect(result.fontFamily, isNull);
    expect(result.background, same(StoryBackground.defaults[1]));
  });

  testWidgets('empty text is not submitted', (tester) async {
    final host = await openTextScreen(tester);

    await write(tester, '   ');
    await submit(tester);

    expect(host.returned, isFalse);
  });

  testWidgets('the check button submits while the keyboard is open', (tester) async {
    final host = await openTextScreen(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    addTearDown(tester.view.resetViewInsets);

    await write(tester, 'Hello');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect((host.result as StoryTextResult).text, 'Hello');
  });

  testWidgets('alignment cycles through center, left and right', (tester) async {
    final host = await openTextScreen(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    addTearDown(tester.view.resetViewInsets);
    await write(tester, 'Hello');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.format_align_center));
    await tester.pump();
    expect(editable(tester).textAlign, TextAlign.left);

    await tester.tap(find.byIcon(Icons.format_align_left));
    await tester.pump();
    expect(editable(tester).textAlign, TextAlign.right);

    tester.view.resetViewInsets();
    await submit(tester);
    expect((host.result as StoryTextResult).textAlign, TextAlign.right);
  });

  testWidgets('fonts cycle through the given families', (tester) async {
    final host = await openTextScreen(tester, const StoryPickerOptions(textFonts: ['First', 'Second']));
    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    addTearDown(tester.view.resetViewInsets);
    await write(tester, 'Hello');
    await tester.pumpAndSettle();
    expect(editable(tester).style.fontFamily, 'First');

    await tester.tap(find.byIcon(Icons.font_download));
    await tester.pump();
    expect(editable(tester).style.fontFamily, 'Second');

    tester.view.resetViewInsets();
    await submit(tester);
    expect((host.result as StoryTextResult).fontFamily, 'Second');
  });

  testWidgets('font button is hidden with a single font', (tester) async {
    await openTextScreen(tester, const StoryPickerOptions(textFonts: ['Only']));
    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.font_download), findsNothing);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('custom backgrounds are used and wrap around', (tester) async {
    final host = await openTextScreen(tester, const StoryPickerOptions(textBackgrounds: [_red, _blue]));
    expect(editable(tester).style.color, _red.textColor);

    await tester.tap(nextBackground);
    await tester.pump();
    expect(editable(tester).style.color, Colors.white);

    await tester.tap(nextBackground);
    await write(tester, 'Hello');
    await submit(tester);
    expect((host.result as StoryTextResult).background, same(_red));
  });

  testWidgets('empty backgrounds fall back to the defaults', (tester) async {
    final host = await openTextScreen(tester, const StoryPickerOptions(textBackgrounds: []));

    await write(tester, 'Hello');
    await submit(tester);
    expect((host.result as StoryTextResult).background, same(StoryBackground.defaults.first));
  });

  testWidgets('shows the translated hint', (tester) async {
    await openTextScreen(tester, const StoryPickerOptions(translations: StoryPickerTranslations.fr));

    expect(find.text(StoryPickerTranslations.fr.pressToWrite), findsOneWidget);
  });

  testWidgets('long text is shrunk to fit', (tester) async {
    await openTextScreen(tester);
    double fontSize() => editable(tester).style.fontSize!;

    await write(tester, 'Short');
    expect(fontSize(), 30);

    await write(tester, 'A much longer story text ' * 12);
    expect(fontSize(), lessThan(30));
    expect(fontSize(), greaterThanOrEqualTo(16));

    await write(tester, 'Short');
    expect(fontSize(), 30);
  });

  testWidgets('closing the text screen goes back to the camera', (tester) async {
    final host = await openTextScreen(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(EditableText), findsNothing);
    expect(captureButton, findsOneWidget);
    expect(host.returned, isFalse);
  });

  testWidgets('settings are reachable from the text screen', (tester) async {
    await openTextScreen(tester, StoryPickerOptions(settingsBuilder: (_) => const Scaffold(body: Text('my settings'))));

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('my settings'), findsOneWidget);
  });
}
