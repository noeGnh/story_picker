import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:story_picker/story_picker.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

const backCamera = CameraDescription(name: 'back', lensDirection: CameraLensDirection.back, sensorOrientation: 90);
const frontCamera = CameraDescription(name: 'front', lensDirection: CameraLensDirection.front, sensorOrientation: 270);

/// Camera plugin replacement that records what the picker asks for.
class FakeCameraPlatform extends CameraPlatform {
  FakeCameraPlatform({this.cameras = const [backCamera], this.failInitialize = false, this.recording});

  final List<CameraDescription> cameras;
  final bool failInitialize;

  /// File returned when a recording stops. An empty file by default.
  final XFile? recording;

  final created = <String>[];
  final disposed = <int>[];
  final flashModes = <FlashMode>[];
  int pictures = 0;
  int recordingsStarted = 0;
  int recordingsStopped = 0;

  final _initialized = StreamController<CameraInitializedEvent>.broadcast();
  int _nextId = 0;

  @override
  Future<List<CameraDescription>> availableCameras() async => cameras;

  @override
  Future<int> createCameraWithSettings(CameraDescription description, MediaSettings? settings) async {
    created.add(description.name);
    return _nextId++;
  }

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) => _initialized.stream.where((e) => e.cameraId == cameraId);

  @override
  // Never emits: the controller waits on its first event.
  Stream<CameraErrorEvent> onCameraError(int cameraId) => StreamController<CameraErrorEvent>.broadcast().stream;

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() => const Stream.empty();

  @override
  Future<void> initializeCamera(int cameraId, {ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown}) async {
    if (failInitialize) throw CameraException('CameraAccessDenied', 'denied');
    _initialized.add(CameraInitializedEvent(cameraId, 1920, 1080, ExposureMode.auto, false, FocusMode.auto, false));
  }

  @override
  Widget buildPreview(int cameraId) => const ColoredBox(color: Colors.grey);

  @override
  Future<void> setFlashMode(int cameraId, FlashMode mode) async => flashModes.add(mode);

  @override
  Future<XFile> takePicture(int cameraId) async {
    pictures++;
    return XFile(writeTestImage().path);
  }

  @override
  Future<void> startVideoCapturing(VideoCaptureOptions options) async => recordingsStarted++;

  @override
  Future<XFile> stopVideoRecording(int cameraId) async {
    recordingsStopped++;
    return recording ?? XFile(emptyFile('video.mp4').path);
  }

  @override
  Future<void> dispose(int cameraId) async => disposed.add(cameraId);
}

/// File picker replacement returning [path], or nothing when null.
final class FakeFilePicker extends FilePickerPlatform {
  FakeFilePicker(this.path);

  final String? path;
  int calls = 0;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    calls++;
    final path = this.path;
    return path == null ? null : _LocalFile(File(path));
  }
}

final class _LocalFile extends PlatformFile {
  _LocalFile(this.file);

  final File file;

  @override
  String get name => file.uri.pathSegments.last;

  @override
  Uri get uri => file.uri;

  @override
  XFile get xFile => XFile(file.path);

  @override
  int? lengthSync() => file.lengthSync();

  @override
  Future<int?> length() => file.length();

  @override
  Future<Uint8List> readAsBytes() => file.readAsBytes();

  @override
  Stream<Uint8List> readAsByteStream() => file.openRead().map(Uint8List.fromList);
}

final _tempDir = Directory.systemTemp.createTempSync('story_picker_test');

File emptyFile(String name) => File('${_tempDir.path}/$name')..writeAsBytesSync(const []);

/// A 1x1 PNG.
File writeTestImage([String name = 'image.png']) => File('${_tempDir.path}/$name')
  ..writeAsBytesSync(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
    0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
    0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

/// Host app with a button that opens the picker and keeps its result. It still
/// uses package:flutter/material.dart, to check the picker works in apps that
/// have not migrated to package:material_ui.
class Host extends StatefulWidget {
  const Host(this.options, {super.key});

  final StoryPickerOptions options;

  @override
  State<Host> createState() => HostState();
}

class HostState extends State<Host> {
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

/// Opens the picker from a [Host] and returns the host's state.
Future<HostState> openPicker(WidgetTester tester, [StoryPickerOptions options = const StoryPickerOptions()]) async {
  await tester.pumpWidget(MaterialApp(localizationsDelegates: StoryPicker.localizationsDelegates, home: Host(options)));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return tester.state<HostState>(find.byType(Host, skipOffstage: false));
}

final captureButton = find.byWidgetPredicate((w) => w.runtimeType.toString() == 'CaptureButton');

/// pro_video_editor replacement: [failMetadata] and [failRender] simulate
/// unreadable videos and failed exports.
class FakeVideoEditor extends ProVideoEditor {
  FakeVideoEditor({this.failMetadata = false, this.failRender = false});

  final bool failMetadata;
  final bool failRender;
  final renders = <VideoRenderData>[];

  void emitProgress(String id, double progress) => progressCtrl.add(ProgressModel(id: id, progress: progress));

  @override
  void initializeStream() {}

  @override
  Future<VideoMetadata> getMetadata(EditorVideo value, {bool checkStreamingOptimization = false, NativeLogLevel? nativeLogLevel}) async {
    if (failMetadata) throw Exception('unreadable video');
    return VideoMetadata(
      duration: const Duration(seconds: 30),
      extension: 'mp4',
      fileSize: 1000,
      resolution: const Size(1080, 1920),
      rotation: 0,
      bitrate: 1000000,
    );
  }

  @override
  Future<List<Uint8List>> getKeyFrames(KeyFramesConfigs value, {NativeLogLevel? nativeLogLevel}) async => [];

  @override
  Future<String> renderVideoToFile(String filePath, VideoRenderData value, {NativeLogLevel? nativeLogLevel}) async {
    renders.add(value);
    if (failRender) throw Exception('render failed');
    return filePath;
  }
}

/// video_player replacement: every video is 30 s long and plays silently.
class FakeVideoPlayer extends VideoPlayerPlatform {
  final _events = <int, StreamController<VideoEvent>>{};
  final calls = <String>[];
  int _nextId = 0;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = _nextId++;
    _events[id] = StreamController<VideoEvent>()
      ..add(VideoEvent(eventType: VideoEventType.initialized, duration: const Duration(seconds: 30), size: const Size(1080, 1920)));
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events[playerId]!.stream;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const ColoredBox(color: Colors.grey);

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async => calls.add('volume $volume');

  @override
  Future<void> play(int playerId) async => calls.add('play');

  @override
  Future<void> pause(int playerId) async => calls.add('pause');

  @override
  Future<void> seekTo(int playerId, Duration position) async => calls.add('seek ${position.inSeconds}');

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<void> dispose(int playerId) async => _events.remove(playerId)?.close();
}

/// path_provider replacement pointing at the test's temporary directory.
class FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => _tempDir.path;
}
