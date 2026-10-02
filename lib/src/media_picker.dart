import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import 'preview/image_preview_screen.dart';
import 'preview/video_preview_screen.dart';
import 'scope.dart';

const _imageExtensions = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'};
const _videoExtensions = {'mp4', 'mkv', 'mov', 'wmv', 'flv', 'avi', 'webm', '3gp'};

/// Opens the system media picker, shows the matching preview screen and
/// closes the calling screen with the result when the user validates it.
Future<void> pickMediaAndPreview(BuildContext context) async {
  final picked = await FilePicker.pickFile(type: FileType.media);
  final path = picked?.path;
  if (path == null || !context.mounted) return;

  final extension = p.extension(path).replaceFirst('.', '').toLowerCase();
  final Widget? preview = switch (extension) {
    _ when _imageExtensions.contains(extension) => ImagePreviewScreen(path: path),
    _ when _videoExtensions.contains(extension) => VideoPreviewScreen(path: path),
    _ => null,
  };
  if (preview == null) {
    debugPrint('story_picker: unsupported media type: $path');
    return;
  }

  await pushStoryScreenAndForward(context, preview);
}
