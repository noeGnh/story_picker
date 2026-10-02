import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:story_picker/src/models/file_model.dart';
import 'package:story_picker/src/models/result.dart';
import 'package:video_trimmer/video_trimmer.dart';

class VideoPreviewProvider extends ChangeNotifier {
  final Trimmer _trimmer = Trimmer();

  double startValue = 0.0;
  double endValue = 0.0;

  bool? _isPlaying = false;
  bool _progressVisibility = false;

  Trimmer get trimmer => _trimmer;

  bool? get isPlaying => _isPlaying;

  bool get progressVisibility => _progressVisibility;

  set isPlaying(bool? v) {
    _isPlaying = v;
    notifyListeners();
  }

  set progressVisibility(bool v) {
    _progressVisibility = v;
    notifyListeners();
  }

  List<FileModel?>? files;

  Future<void> loadVideoTrimmer() async => await _trimmer.loadVideo(videoFile: File(files![0]!.filePath!));

  Future<void> submit(BuildContext context) async {
    progressVisibility = true;

    _trimmer.saveTrimmedVideo(
      startValue: startValue,
      endValue: endValue,
      onSave: (String? outputPath) {
        progressVisibility = false;

        if (outputPath == null || !context.mounted) return;

        Navigator.pop(
          context,
          StoryPickerResult(
            pickedFiles: [PickedFile(path: outputPath, name: basename(outputPath))],
            resultType: ResultType.VIDEO,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _trimmer.dispose();
    super.dispose();
  }
}
