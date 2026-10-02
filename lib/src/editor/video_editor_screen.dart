import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:video_player/video_player.dart';

import '../options.dart';
import '../result.dart';
import '../scope.dart';

const _thumbnailCount = 10;

/// Paint and blur/pixelate brushes are not supported on videos.
const _paintModes = [
  PaintMode.freeStyle,
  PaintMode.arrow,
  PaintMode.line,
  PaintMode.rect,
  PaintMode.circle,
  PaintMode.dashLine,
  PaintMode.polygon,
  PaintMode.eraser,
];

/// Trims and edits a video (text, drawing, stickers, filters, crop…), renders
/// it and closes with a [StoryVideoResult], or null when the user goes back.
///
/// pro_image_editor only draws the editing UI: playback, trimming and the
/// final render are driven here with video_player and pro_video_editor.
class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key, required this.path});

  final String path;

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  late final EditorVideo _video = EditorVideo.file(File(widget.path));
  late final VideoPlayerController _player = VideoPlayerController.file(File(widget.path));
  late final String _taskId = DateTime.now().microsecondsSinceEpoch.toString();

  ProVideoController? _controller;
  VideoMetadata? _metadata;
  TrimDurationSpan? _span;
  TrimDurationSpan? _pendingSeek;
  bool _seeking = false;
  String? _outputPath;
  bool _failed = false;
  bool _renderFailed = false;
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _player.removeListener(_onPosition);
    _player.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final metadata = await ProVideoEditor.instance.getMetadata(_video);
      await _player.initialize();
      await _player.setLooping(false);
      _metadata = metadata;
    } catch (e) {
      debugPrint('story_picker: cannot open video ${widget.path}: $e');
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) return;

    final metadata = _metadata!;
    _controller = ProVideoController(
      videoPlayer: Center(
        child: AspectRatio(aspectRatio: _player.value.aspectRatio, child: VideoPlayer(_player)),
      ),
      initialResolution: metadata.resolution,
      videoDuration: metadata.duration,
      fileSize: metadata.fileSize,
      bitrate: metadata.bitrate,
    );
    _player.addListener(_onPosition);
    setState(() {});
    _loadThumbnails();
  }

  Future<void> _loadThumbnails() async {
    final width = MediaQuery.sizeOf(context).width / _thumbnailCount * MediaQuery.devicePixelRatioOf(context);
    try {
      final frames = await ProVideoEditor.instance.getKeyFrames(
        KeyFramesConfigs(
          video: _video,
          outputSize: Size.square(width),
          boxFit: ThumbnailBoxFit.cover,
          maxOutputFrames: _thumbnailCount,
          outputFormat: ThumbnailFormat.jpeg,
        ),
      );
      if (mounted) _controller?.thumbnails = frames.map(MemoryImage.new).toList();
    } catch (e) {
      debugPrint('story_picker: cannot read video thumbnails: $e');
      _controller?.thumbnails = [];
    }
  }

  /// Keeps the editor's play head in sync and loops inside the trimmed span.
  void _onPosition() {
    final position = _player.value.position;
    _controller?.setPlayTime(position);
    final end = _span?.end ?? _metadata!.duration;
    if (position >= end) _seekTo(_span ?? TrimDurationSpan(start: Duration.zero, end: _metadata!.duration));
  }

  Future<void> _seekTo(TrimDurationSpan span) async {
    _span = span;
    if (_seeking) {
      _pendingSeek = span;
      return;
    }
    _seeking = true;
    _controller?.pause();
    _controller?.setPlayTime(span.start);
    await _player.pause();
    await _player.seekTo(span.start);
    _seeking = false;

    final next = _pendingSeek;
    _pendingSeek = null;
    if (next != null) await _seekTo(next);
  }

  Future<void> _render(CompleteParameters parameters) async {
    final directory = await getTemporaryDirectory();
    final data = VideoRenderData(
      id: _taskId,
      videoSegments: [VideoSegment(video: _video)],
      imageLayers: [if (parameters.layers.isNotEmpty) ImageLayer(image: EditorLayerImage.memory(parameters.image))],
      blur: parameters.blur,
      colorFilters: [ColorFilter(matrix: parameters.colorFiltersCombined)],
      startTime: parameters.startTime,
      endTime: parameters.endTime,
      transform: parameters.isTransformed
          ? ExportTransform(
              width: parameters.cropWidth,
              height: parameters.cropHeight,
              rotateTurns: 4 - parameters.rotateTurns,
              x: parameters.cropX,
              y: parameters.cropY,
              flipX: parameters.flipX,
              flipY: parameters.flipY,
            )
          : null,
      enableAudio: _controller?.isAudioEnabled ?? true,
      outputFormat: VideoOutputFormat.mp4,
      bitrate: _metadata?.bitrate,
    );
    try {
      _outputPath = await ProVideoEditor.instance.renderVideoToFile('${directory.path}/story_${DateTime.now().microsecondsSinceEpoch}.mp4', data);
    } catch (e) {
      // The editor calls _close next, which then keeps the user in the editor.
      debugPrint('story_picker: video export failed: $e');
      _renderFailed = true;
      if (!mounted) return;
      final message = StoryPickerScope.of(context).translations.videoExportFailed;
      _messenger.currentState?.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _close(EditorMode mode) {
    if (mode != EditorMode.main) {
      Navigator.of(context).pop();
      return;
    }
    if (_renderFailed) {
      _renderFailed = false;
      return;
    }
    _player.pause();
    final output = _outputPath;
    Navigator.of(context).pop(output == null ? null : StoryVideoResult(output));
  }

  ProImageEditorConfigs _configs(StoryPickerOptions options) {
    final base = options.editorConfigs;
    return base.copyWith(
      mainEditor: base.mainEditor.copyWith(
        tools: const [
          SubEditorMode.paint,
          SubEditorMode.text,
          SubEditorMode.cropRotate,
          SubEditorMode.tune,
          SubEditorMode.filter,
          SubEditorMode.blur,
          SubEditorMode.emoji,
        ],
      ),
      paintEditor: base.paintEditor.copyWith(tools: _paintModes),
      videoEditor: base.videoEditor.copyWith(
        initialPlay: true,
        minTrimDuration: const Duration(seconds: 1),
        maxTrimDuration: options.maxVideoDuration,
        playTimeSmoothingDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = StoryPickerScope.of(context);
    final controller = _controller;

    if (controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: Center(
          child: _failed ? const Icon(Icons.error_outline, color: Colors.white) : CircularProgressIndicator(color: options.theme.accentColor),
        ),
      );
    }

    // Own messenger: the host app's may come from the legacy Material library.
    return ScaffoldMessenger(
      key: _messenger,
      child: ProImageEditor.video(
        controller,
        configs: _configs(options),
        callbacks: ProImageEditorCallbacks(
          onCompleteWithParameters: _render,
          onCloseEditor: _close,
          videoEditorCallbacks: VideoEditorCallbacks(
            onPlay: _player.play,
            onPause: _player.pause,
            onMuteToggle: (muted) => _player.setVolume(muted ? 0 : 1),
            onTrimSpanUpdate: (_) {
              if (_player.value.isPlaying) controller.pause();
            },
            onTrimSpanEnd: _seekTo,
          ),
        ),
      ),
    );
  }
}
