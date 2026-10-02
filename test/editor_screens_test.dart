import 'dart:io';
import 'dart:typed_data';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:story_picker/story_picker.dart';
import 'package:story_picker/src/editor/image_editor_screen.dart';
import 'package:story_picker/src/editor/video_editor_screen.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'helpers.dart';

/// Picks [path] from the camera screen and waits for its editor.
Future<HostState> openEditor(WidgetTester tester, String path, [StoryPickerOptions options = const StoryPickerOptions()]) async {
  FilePickerPlatform.instance = FakeFilePicker(path);
  final host = await openPicker(tester, options);
  await tester.tap(find.byIcon(Icons.image));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  return host;
}

ProImageEditor editor(WidgetTester tester) => tester.widget<ProImageEditor>(find.byType(ProImageEditor));

final _parameters = CompleteParameters.fromMap(const {'startTime': 2000000, 'endTime': 12000000});

void main() {
  setUp(() {
    CameraPlatform.instance = FakeCameraPlatform();
    PathProviderPlatform.instance = FakePathProvider();
    VideoPlayerPlatform.instance = FakeVideoPlayer();
  });

  group('photo editor', () {
    testWidgets('returns the edited image to the caller', (tester) async {
      final host = await openEditor(tester, writeTestImage().path);
      final callbacks = editor(tester).callbacks;

      await tester.runAsync(() => callbacks.onImageEditingComplete!(Uint8List.fromList([1, 2, 3])));
      callbacks.onCloseEditor!(EditorMode.main);
      await tester.pumpAndSettle();

      final result = host.result;
      expect(result, isA<StoryImageResult>());
      expect(File((result as StoryImageResult).path).readAsBytesSync(), [1, 2, 3]);
      expect(find.byType(ImageEditorScreen), findsNothing);
    });

    testWidgets('closing without saving goes back to the camera', (tester) async {
      final host = await openEditor(tester, writeTestImage().path);

      editor(tester).callbacks.onCloseEditor!(EditorMode.main);
      await tester.pumpAndSettle();

      expect(find.byType(ImageEditorScreen), findsNothing);
      expect(captureButton, findsOneWidget);
      expect(host.returned, isFalse);
    });

    testWidgets('uses the given editor configuration', (tester) async {
      await openEditor(tester, writeTestImage().path, const StoryPickerOptions(editorConfigs: ProImageEditorConfigs(i18n: StoryEditorI18n.fr)));

      expect(editor(tester).configs.i18n.done, 'Terminé');
    });
  });

  group('video editor', () {
    late FakeVideoEditor videoEditor;

    void useVideoEditor(FakeVideoEditor fake) => ProVideoEditor.instance = videoEditor = fake;

    setUp(() => useVideoEditor(FakeVideoEditor()));

    testWidgets('shows an error when the video cannot be read', (tester) async {
      useVideoEditor(FakeVideoEditor(failMetadata: true));
      await openEditor(tester, emptyFile('broken.mp4').path);
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byType(ProImageEditor), findsNothing);
    });

    testWidgets('renders the trimmed video and returns it', (tester) async {
      final host = await openEditor(tester, emptyFile('clip.mp4').path);
      final callbacks = editor(tester).callbacks;

      await tester.runAsync(() => callbacks.onCompleteWithParameters!(_parameters));
      callbacks.onCloseEditor!(EditorMode.main);
      await tester.pumpAndSettle();

      final render = videoEditor.renders.single;
      expect(render.startTime, const Duration(seconds: 2));
      expect(render.endTime, const Duration(seconds: 12));
      expect(render.imageLayers, isEmpty);
      expect(render.transform, isNull);
      expect(render.enableAudio, isTrue);
      expect(host.result, isA<StoryVideoResult>());
      expect((host.result as StoryVideoResult).path, endsWith('.mp4'));
    });

    testWidgets('a failed render keeps the user in the editor', (tester) async {
      useVideoEditor(FakeVideoEditor(failRender: true));
      final host = await openEditor(tester, emptyFile('clip.mp4').path);
      final callbacks = editor(tester).callbacks;

      await tester.runAsync(() => callbacks.onCompleteWithParameters!(_parameters));
      callbacks.onCloseEditor!(EditorMode.main);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(const StoryPickerTranslations().videoExportFailed), findsOneWidget);
      expect(find.byType(VideoEditorScreen), findsOneWidget);

      // The user can still leave afterwards.
      callbacks.onCloseEditor!(EditorMode.main);
      await tester.pumpAndSettle();
      expect(find.byType(VideoEditorScreen), findsNothing);
      expect(host.returned, isFalse);
    });

    testWidgets('trimming is limited to the maximum video duration', (tester) async {
      await openEditor(tester, emptyFile('clip.mp4').path, const StoryPickerOptions(maxVideoDuration: Duration(seconds: 20)));

      final configs = editor(tester).configs;
      expect(configs.videoEditor.maxTrimDuration, const Duration(seconds: 20));
      expect(configs.videoEditor.minTrimDuration, const Duration(seconds: 1));
      expect(configs.mainEditor.tools, isNot(contains(SubEditorMode.sticker)));
      expect(configs.paintEditor.tools, isNot(contains(PaintMode.blur)));
    });

    testWidgets('the loading dialog shows the render progress', (tester) async {
      await openEditor(tester, emptyFile('clip.mp4').path);
      final configs = editor(tester).configs;
      // A render gives the task id the dialog listens to.
      await tester.runAsync(() => editor(tester).callbacks.onCompleteWithParameters!(_parameters));
      final taskId = videoEditor.renders.single.id;

      // A new app: the picker's routes would stay above a new home.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(localizationsDelegates: StoryPicker.localizationsDelegates, home: configs.dialogConfigs.widgets.loadingDialog!('Rendering', configs)),
      );
      expect(find.text('Rendering'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);

      videoEditor.emitProgress('another task', 0.9);
      await tester.pump();
      expect(find.textContaining('%'), findsNothing);

      videoEditor.emitProgress(taskId, 0.42);
      await tester.pump();
      expect(find.text('42 %'), findsOneWidget);
    });

    testWidgets("keeps the host app's loading dialog", (tester) async {
      Widget hostDialog(String message, ProImageEditorConfigs configs) => const Text('host dialog');
      await openEditor(
        tester,
        emptyFile('clip.mp4').path,
        StoryPickerOptions(
          editorConfigs: ProImageEditorConfigs(
            dialogConfigs: DialogConfigs(widgets: DialogWidgets(loadingDialog: hostDialog)),
          ),
        ),
      );

      expect(editor(tester).configs.dialogConfigs.widgets.loadingDialog, same(hostDialog));
    });
  });
}
