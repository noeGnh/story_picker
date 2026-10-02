import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_picker/src/editor/image_editor_screen.dart';
import 'package:story_picker/src/editor/video_editor_screen.dart';

import 'helpers.dart';

Future<FakeFilePicker> pick(WidgetTester tester, String? path) async {
  final picker = FakeFilePicker(path);
  FilePickerPlatform.instance = picker;
  await openPicker(tester);
  await tester.tap(find.byIcon(Icons.image));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  return picker;
}

void main() {
  setUp(() => CameraPlatform.instance = FakeCameraPlatform());

  testWidgets('a picked image opens the photo editor', (tester) async {
    final picker = await pick(tester, writeTestImage('photo.JPG').path);

    expect(picker.calls, 1);
    expect(find.byType(ImageEditorScreen), findsOneWidget);
  });

  testWidgets('a picked video opens the video editor', (tester) async {
    await pick(tester, emptyFile('clip.mov').path);

    expect(find.byType(VideoEditorScreen), findsOneWidget);
  });

  testWidgets('an unsupported file is ignored', (tester) async {
    await pick(tester, emptyFile('notes.txt').path);

    expect(find.byType(ImageEditorScreen), findsNothing);
    expect(find.byType(VideoEditorScreen), findsNothing);
    expect(captureButton, findsOneWidget);
  });

  testWidgets('cancelling the system picker stays on the camera', (tester) async {
    final picker = await pick(tester, null);

    expect(picker.calls, 1);
    expect(captureButton, findsOneWidget);
  });
}
