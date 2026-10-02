import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';

import '../result.dart';
import '../scope.dart';
import 'preview_scaffold.dart';

class VideoPreviewScreen extends StatefulWidget {
  const VideoPreviewScreen({super.key, required this.path});

  final String path;

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  final _trimmer = Trimmer();
  double _start = 0;
  double _end = 0;
  bool _playing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _trimmer.loadVideo(videoFile: File(widget.path));
  }

  @override
  void dispose() {
    _trimmer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    final playing = await _trimmer.videoPlaybackControl(startValue: _start, endValue: _end);
    if (mounted) setState(() => _playing = playing);
  }

  void _save() {
    setState(() => _saving = true);
    _trimmer.saveTrimmedVideo(
      startValue: _start,
      endValue: _end,
      onSave: (outputPath) {
        if (!mounted) return;
        setState(() => _saving = false);
        if (outputPath != null) Navigator.of(context).pop(StoryVideoResult(outputPath));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = StoryPickerScope.of(context);
    final colors = options.theme;

    return PreviewScaffold(
      onValidate: _saving ? null : _save,
      body: Column(
        children: [
          if (_saving) LinearProgressIndicator(color: colors.accentColor),
          Expanded(child: VideoViewer(trimmer: _trimmer)),
          TrimViewer(
            trimmer: _trimmer,
            viewerHeight: 50,
            viewerWidth: MediaQuery.sizeOf(context).width,
            maxVideoLength: options.maxVideoDuration,
            durationTextStyle: TextStyle(color: colors.previewForegroundColor),
            editorProperties: TrimEditorProperties(
              scrubberPaintColor: colors.accentColor,
              borderPaintColor: colors.accentColor,
              circlePaintColor: colors.accentColor,
            ),
            onChangeStart: (value) => _start = value,
            onChangeEnd: (value) => _end = value,
            onChangePlaybackState: (playing) {
              if (mounted) setState(() => _playing = playing);
            },
          ),
          IconButton(iconSize: 80, color: colors.previewForegroundColor, onPressed: _togglePlayback, icon: Icon(_playing ? Icons.pause : Icons.play_arrow)),
        ],
      ),
    );
  }
}
