import 'dart:io';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../result.dart';
import '../scope.dart';

/// Edits a photo (text, drawing, stickers, filters, crop…) and closes with a
/// [StoryImageResult] when the user is done, or null when they go back.
class ImageEditorScreen extends StatefulWidget {
  const ImageEditorScreen({super.key, required this.path});

  final String path;

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  String? _outputPath;

  Future<void> _save(Uint8List bytes) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/story_${DateTime.now().microsecondsSinceEpoch}.jpg');
    await file.writeAsBytes(bytes);
    _outputPath = file.path;
  }

  void _close(EditorMode mode) {
    // Sub-editors (crop, paint…) close back to the main editor.
    if (mode != EditorMode.main) {
      Navigator.of(context).pop();
      return;
    }
    final output = _outputPath;
    Navigator.of(context).pop(output == null ? null : StoryImageResult(output));
  }

  @override
  Widget build(BuildContext context) {
    final options = StoryPickerScope.of(context);
    return ProImageEditor.file(
      File(widget.path),
      configs: options.editorConfigs,
      callbacks: ProImageEditorCallbacks(onImageEditingComplete: _save, onCloseEditor: _close),
    );
  }
}
