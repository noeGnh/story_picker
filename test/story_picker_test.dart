import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_picker/story_picker.dart';

/// A device without any camera.
class _NoCameraPlatform extends CameraPlatform {
  @override
  Future<List<CameraDescription>> availableCameras() async => [];
}

/// Host app with a button that opens the picker and keeps its result.
class _Host extends StatefulWidget {
  const _Host(this.options);

  final StoryPickerOptions options;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  StoryPickerResult? result;
  bool returned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final r = await StoryPicker.pick(context, options: widget.options);
            setState(() {
              result = r;
              returned = true;
            });
          },
          child: const Text('open'),
        ),
      ),
    );
  }
}

Future<_HostState> _open(WidgetTester tester, [StoryPickerOptions options = const StoryPickerOptions()]) async {
  await tester.pumpWidget(MaterialApp(home: _Host(options)));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return tester.state<_HostState>(find.byType(_Host, skipOffstage: false));
}

void main() {
  setUp(() => CameraPlatform.instance = _NoCameraPlatform());

  testWidgets('shows a message when no camera is available', (tester) async {
    await _open(tester);

    expect(find.text(const StoryPickerTranslations().cameraUnavailable), findsOneWidget);
  });

  testWidgets('uses the given translations', (tester) async {
    await _open(tester, const StoryPickerOptions(translations: StoryPickerTranslations.fr));

    expect(find.text(StoryPickerTranslations.fr.cameraUnavailable), findsOneWidget);
  });

  testWidgets('closing the picker returns null', (tester) async {
    final host = await _open(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(host.returned, isTrue);
    expect(host.result, isNull);
  });

  testWidgets('text stories can be disabled', (tester) async {
    await _open(tester, const StoryPickerOptions(enableTextStories: false));

    expect(find.byIcon(Icons.text_fields), findsNothing);
  });

  testWidgets('settings button only appears with a settings builder', (tester) async {
    await _open(tester);
    expect(find.byIcon(Icons.settings), findsNothing);
  });

  testWidgets('settings builder is opened from the camera', (tester) async {
    await _open(tester, StoryPickerOptions(settingsBuilder: (_) => const Scaffold(body: Text('my settings'))));

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('my settings'), findsOneWidget);
  });

  testWidgets('text story is returned to the caller with its style', (tester) async {
    final host = await _open(tester);

    await tester.tap(find.byIcon(Icons.text_fields));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '  Hello story  ');
    // Next background.
    await tester.tap(find.byWidgetPredicate((w) => w is IconButton && w.icon is Container));
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byWidgetPredicate((w) => w.runtimeType.toString() == 'CaptureButton'));
    await tester.pumpAndSettle();

    final result = host.result;
    expect(result, isA<StoryTextResult>());
    result as StoryTextResult;
    expect(result.text, 'Hello story');
    expect(result.textAlign, TextAlign.center);
    expect(result.fontFamily, isNull);
    expect(result.background, same(StoryBackground.defaults[1]));
  });

  testWidgets('empty text is not submitted', (tester) async {
    final host = await _open(tester);

    await tester.tap(find.byIcon(Icons.text_fields));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '   ');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byWidgetPredicate((w) => w.runtimeType.toString() == 'CaptureButton'));
    await tester.pumpAndSettle();

    expect(host.returned, isFalse);
  });
}
