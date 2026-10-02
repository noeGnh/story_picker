import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path/path.dart';
import 'package:story_picker/src/models/file_model.dart';
import 'package:story_picker/src/models/options.dart';
import 'package:story_picker/src/models/result.dart';
import 'package:story_picker/src/widgets/preview/image_preview.dart';
import 'package:story_picker/src/widgets/preview/video_preview.dart';

const _imgExtensions = ['jpg', 'png', 'jpeg', 'gif', 'webp'];
const _vidExtensions = ['mp4', 'mkv', 'mov', 'wmv', 'flv', 'avi', 'webm'];

/// Opens the system media picker, shows the matching preview screen and pops
/// [context] with the result when the user validates it.
Future<void> pickMediaAndPreview(BuildContext context, Options? options) async {
  final picked = await FilePicker.pickFile(type: FileType.media);
  final path = picked?.path;
  if (path == null || !context.mounted) return;

  final ext = extension(path).replaceFirst('.', '').toLowerCase();
  final files = [FileModel(filePath: path, relativePath: path, thumbPath: path, title: basename(path))];

  Widget? preview;
  if (_imgExtensions.contains(ext)) {
    preview = ImagePreview(files: files, imagePreviewOptions: options, showAddButton: options!.customizationOptions.galleryCustomization.maxSelectable > 1);
  } else if (_vidExtensions.contains(ext)) {
    preview = VideoPreview(files: files, imagePreviewOptions: options);
  }
  if (preview == null) return;

  final StoryPickerResult? result = await Navigator.of(context).push(PageTransition(child: preview, type: PageTransitionType.bottomToTop));

  if (result != null && context.mounted) Navigator.pop(context, result);
}
