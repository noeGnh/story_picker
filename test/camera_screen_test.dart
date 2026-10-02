import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_picker/story_picker.dart';
import 'package:story_picker/src/editor/image_editor_screen.dart';
import 'package:story_picker/src/editor/video_editor_screen.dart';

import 'helpers.dart';

/// Presses the capture button long enough to start a recording.
Future<TestGesture> startRecording(WidgetTester tester) async {
  final gesture = await tester.startGesture(tester.getCenter(captureButton));
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
  await tester.pump();
  return gesture;
}

void main() {
  late FakeCameraPlatform camera;

  void useCamera(FakeCameraPlatform fake) => CameraPlatform.instance = camera = fake;

  setUp(() => useCamera(FakeCameraPlatform()));

  testWidgets('opens the first camera and shows the recording hint', (tester) async {
    await openPicker(tester);

    expect(camera.created, ['back']);
    expect(find.text(const StoryPickerTranslations().pressAndHoldToRecord), findsOneWidget);
    expect(find.text(const StoryPickerTranslations().cameraUnavailable), findsNothing);
  });

  testWidgets('the recording hint fades out', (tester) async {
    await openPicker(tester);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    final opacity = tester.widget<AnimatedOpacity>(
      find.ancestor(of: find.text(const StoryPickerTranslations().pressAndHoldToRecord), matching: find.byType(AnimatedOpacity)),
    );
    expect(opacity.opacity, 0);
  });

  testWidgets('shows a message when the camera cannot be opened', (tester) async {
    useCamera(FakeCameraPlatform(failInitialize: true));
    await openPicker(tester);

    expect(find.text(const StoryPickerTranslations().cameraUnavailable), findsOneWidget);
  });

  testWidgets('flash cycles through off, torch and auto', (tester) async {
    await openPicker(tester);
    expect(find.byIcon(Icons.flash_off), findsOneWidget);

    await tester.tap(find.byIcon(Icons.flash_off));
    await tester.pump();
    expect(find.byIcon(Icons.flash_on), findsOneWidget);

    await tester.tap(find.byIcon(Icons.flash_on));
    await tester.pump();
    expect(find.byIcon(Icons.flash_auto), findsOneWidget);

    await tester.tap(find.byIcon(Icons.flash_auto));
    await tester.pump();
    expect(find.byIcon(Icons.flash_off), findsOneWidget);
    // The first call applies the initial mode when the camera opens.
    expect(camera.flashModes, [FlashMode.off, FlashMode.torch, FlashMode.auto, FlashMode.off]);
  });

  testWidgets('switch button only appears with several cameras', (tester) async {
    await openPicker(tester);
    expect(find.byIcon(Icons.flip_camera_android), findsNothing);
  });

  testWidgets('switches between cameras', (tester) async {
    useCamera(FakeCameraPlatform(cameras: [backCamera, frontCamera]));
    await openPicker(tester);

    await tester.tap(find.byIcon(Icons.flip_camera_android));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.flip_camera_android));
    await tester.pumpAndSettle();

    expect(camera.created, ['back', 'front', 'back']);
    expect(camera.disposed, [0, 1]);
  });

  testWidgets('releases the camera when the app goes to the background', (tester) async {
    await openPicker(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(camera.disposed, [0]);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(camera.created, ['back', 'back']);
  });

  testWidgets('a tap takes a picture and opens the photo editor', (tester) async {
    await openPicker(tester);

    await tester.tap(captureButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(camera.pictures, 1);
    expect(find.byType(ImageEditorScreen), findsOneWidget);
  });

  testWidgets('a long press records until released', (tester) async {
    await openPicker(tester);

    final gesture = await startRecording(tester);
    expect(camera.recordingsStarted, 1);
    expect(find.text('00:00 / 00:15'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('00:02 / 00:15'), findsOneWidget);

    await gesture.up();
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(camera.recordingsStopped, 1);
    // The fake recording is empty: it is discarded instead of being edited.
    expect(find.byType(VideoEditorScreen), findsNothing);
    expect(find.text('00:02 / 00:15'), findsNothing);
  });

  testWidgets('a release under one second stops the recording at one second', (tester) async {
    await openPicker(tester);

    final gesture = await startRecording(tester);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 500));
    expect(camera.recordingsStopped, 0);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(camera.recordingsStopped, 1);
  });

  testWidgets('the recording stops at the maximum duration', (tester) async {
    await openPicker(tester, const StoryPickerOptions(maxVideoDuration: Duration(seconds: 3)));

    final gesture = await startRecording(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(camera.recordingsStopped, 1);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(camera.recordingsStopped, 1);
  });

  testWidgets('a non-empty recording opens the video editor', (tester) async {
    final video = writeTestImage('video.mp4');
    useCamera(FakeCameraPlatform(recording: XFile(video.path)));
    await openPicker(tester);

    final gesture = await startRecording(tester);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();
    // Lets the real file I/O (empty file check) complete.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(VideoEditorScreen), findsOneWidget);
  });
}
