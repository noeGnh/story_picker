import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../media_picker.dart';
import '../preview/image_preview_screen.dart';
import '../result.dart';
import '../scope.dart';
import '../text/text_screen.dart';
import '../widgets/overlay_controls.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

/// Shorter recordings can produce an empty file.
const _minRecording = Duration(seconds: 1);

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  CameraController? _controller;
  bool _unavailable = false;
  bool _busy = false;
  bool _takingPicture = false;
  bool _startingRecording = false;
  bool _stopRequested = false;
  bool _showHint = true;
  FlashMode _flashMode = FlashMode.off;

  Timer? _hintTimer;
  Timer? _recordingTimer;
  Duration _recorded = Duration.zero;

  bool get _ready => _controller?.value.isInitialized ?? false;
  bool get _recording => _controller?.value.isRecordingVideo ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCameras();
    _hintTimer = Timer(const Duration(seconds: 4), () => setState(() => _showHint = false));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hintTimer?.cancel();
    _recordingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The camera plugin leaves lifecycle handling to the app.
    if (state == AppLifecycleState.inactive) {
      final controller = _controller;
      if (controller == null) return;
      _recordingTimer?.cancel();
      setState(() {
        _controller = null;
        _recorded = Duration.zero;
      });
      controller.dispose();
    } else if (state == AppLifecycleState.resumed && _controller == null && _cameras.isNotEmpty) {
      _openCamera(_cameras[_cameraIndex]);
    }
  }

  Future<void> _loadCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      // CameraException, but also PlatformException when the plugin is missing.
      debugPrint('story_picker: cannot list cameras: $e');
    }
    if (!mounted) return;
    if (_cameras.isEmpty) {
      setState(() => _unavailable = true);
      return;
    }
    await _openCamera(_cameras[_cameraIndex]);
  }

  Future<void> _openCamera(CameraDescription description) async {
    final previous = _controller;
    if (previous != null) {
      setState(() => _controller = null);
      await previous.dispose();
    }

    final controller = CameraController(description, ResolutionPreset.high);
    try {
      await controller.initialize();
      await controller.setFlashMode(_flashMode).catchError((_) {});
    } on CameraException catch (e) {
      debugPrint('story_picker: cannot open camera: ${e.code} ${e.description}');
      await controller.dispose();
      if (mounted) setState(() => _unavailable = true);
      return;
    }

    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _unavailable = false;
    });
  }

  void _switchCamera() {
    if (_cameras.length < 2 || _recording) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    _openCamera(_cameras[_cameraIndex]);
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (!_ready) return;
    final next = switch (_flashMode) {
      FlashMode.off => FlashMode.torch,
      FlashMode.torch => FlashMode.auto,
      _ => FlashMode.off,
    };
    try {
      await controller!.setFlashMode(next);
      if (mounted) setState(() => _flashMode = next);
    } on CameraException catch (e) {
      debugPrint('story_picker: flash not supported: ${e.code}');
    }
  }

  Future<void> _takePicture() async {
    if (!_ready || _busy || _recording) return;
    _busy = true;
    setState(() => _takingPicture = true);
    XFile file;
    try {
      file = await _controller!.takePicture();
    } on CameraException catch (e) {
      debugPrint('story_picker: cannot take picture: ${e.code} ${e.description}');
      return;
    } finally {
      _busy = false;
      if (mounted) setState(() => _takingPicture = false);
    }
    if (!mounted) return;
    await pushStoryScreenAndForward(context, ImagePreviewScreen(path: file.path));
  }

  Future<void> _startRecording() async {
    if (!_ready || _busy || _recording) return;
    _busy = true;
    _stopRequested = false;
    setState(() => _startingRecording = true);
    try {
      await _controller!.startVideoRecording();
    } on CameraException catch (e) {
      debugPrint('story_picker: cannot start recording: ${e.code} ${e.description}');
      return;
    } finally {
      _busy = false;
      if (mounted) setState(() => _startingRecording = false);
    }
    if (!mounted) return;

    final max = StoryPickerScope.of(context).maxVideoDuration;
    setState(() {
      _recorded = Duration.zero;
      _showHint = false;
    });
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() => _recorded += const Duration(milliseconds: 100));
      // A stop asked before the minimum duration is applied once it is reached.
      if (_recorded >= max || (_stopRequested && _recorded >= _minRecording)) _stopRecording();
    });
  }

  Future<void> _stopRecording() async {
    // Released while the recording is starting, or too early to get a
    // playable file: the timer stops it as soon as possible.
    if (_busy || (_recording && _recorded < _minRecording)) {
      _stopRequested = true;
      return;
    }
    _recordingTimer?.cancel();
    _recordingTimer = null;
    if (!_recording) return;
    _busy = true;

    XFile file;
    try {
      file = await _controller!.stopVideoRecording();
    } on CameraException catch (e) {
      debugPrint('story_picker: cannot stop recording: ${e.code} ${e.description}');
      return;
    } finally {
      _busy = false;
    }
    if (!mounted) return;
    setState(() => _recorded = Duration.zero);

    if (await file.length() == 0) {
      debugPrint('story_picker: discarding empty recording ${file.path}');
      return;
    }
    if (!mounted) return;

    final translations = StoryPickerScope.of(context).translations;
    final keep = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(translations.recordedVideo),
        content: Text(translations.whatDoYouWantToDo),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(translations.delete)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(translations.validate)),
        ],
      ),
    );
    if (keep == true && mounted) Navigator.of(context).pop(StoryVideoResult(file.path));
  }

  void _openSettings(WidgetBuilder builder) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: builder));
  }

  @override
  Widget build(BuildContext context) {
    final options = StoryPickerScope.of(context);
    final theme = options.theme;
    final settingsBuilder = options.settingsBuilder;
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null && controller.value.isInitialized) _Preview(controller),
          if (_unavailable)
            Center(
              child: Padding(padding: const EdgeInsets.all(32), child: OverlayText(options.translations.cameraUnavailable)),
            ),
          if (_recording)
            Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                child: LinearProgressIndicator(
                  value: _recorded.inMilliseconds / options.maxVideoDuration.inMilliseconds,
                  color: theme.recordingColor,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      settingsBuilder != null
                          ? OverlayIconButton(icon: Icons.settings, onPressed: () => _openSettings(settingsBuilder))
                          : const SizedBox(width: 48),
                      OverlayIconButton(icon: _flashIcon, onPressed: _ready ? _toggleFlash : null),
                      OverlayIconButton(icon: Icons.close, onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                ),
                const Spacer(),
                if (_recording)
                  Padding(padding: const EdgeInsets.only(bottom: 12), child: OverlayText('${_format(_recorded)} / ${_format(options.maxVideoDuration)}'))
                else
                  AnimatedOpacity(
                    opacity: _showHint && _ready ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Padding(padding: const EdgeInsets.only(bottom: 12), child: OverlayText(options.translations.pressAndHoldToRecord)),
                  ),
                CaptureButton(
                  recording: _recording,
                  busy: _takingPicture || _startingRecording,
                  onTap: _takePicture,
                  onLongPressStart: _startRecording,
                  onLongPressEnd: _stopRecording,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OverlayIconButton(icon: Icons.image, onPressed: _recording ? null : () => pickMediaAndPreview(context)),
                      if (options.enableTextStories)
                        OverlayIconButton(
                          icon: Icons.text_fields,
                          onPressed: _recording ? null : () => pushStoryScreenAndForward(context, const TextStoryScreen()),
                        ),
                      _cameras.length > 1
                          ? OverlayIconButton(icon: Icons.flip_camera_android, onPressed: _recording ? null : _switchCamera)
                          : const SizedBox(width: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData get _flashIcon => switch (_flashMode) {
    FlashMode.torch => Icons.flash_on,
    FlashMode.auto => Icons.flash_auto,
    _ => Icons.flash_off,
  };

  static String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}';
  }
}

/// Camera preview filling the screen, cropped rather than letterboxed.
class _Preview extends StatelessWidget {
  const _Preview(this.controller);

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    var scale = MediaQuery.sizeOf(context).aspectRatio * controller.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;
    return Transform.scale(
      scale: scale,
      child: Center(child: CameraPreview(controller)),
    );
  }
}
