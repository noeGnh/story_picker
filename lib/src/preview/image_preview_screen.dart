import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;
import 'package:photofilters/filters/preset_filters.dart';
import 'package:photofilters/widgets/photo_filter.dart';

import '../result.dart';
import '../scope.dart';
import 'preview_scaffold.dart';

class ImagePreviewScreen extends StatefulWidget {
  const ImagePreviewScreen({super.key, required this.path});

  final String path;

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late String _path = widget.path;
  bool _loadingFilters = false;

  Future<void> _openFilters() async {
    final options = StoryPickerScope.of(context);
    final colors = options.theme;
    final source = _path;

    setState(() => _loadingFilters = true);
    final image = await Isolate.run(() => img.copyResize(img.decodeImage(File(source).readAsBytesSync())!, width: 600));
    if (!mounted) return;
    setState(() => _loadingFilters = false);

    final Map? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoFilterSelector(
          title: Text(options.translations.filters, style: TextStyle(color: colors.previewForegroundColor)),
          image: image,
          filters: presetFiltersList,
          filename: p.basename(source),
          appBarColor: colors.previewBackgroundColor,
          appBarIconsColor: colors.previewForegroundColor,
          loader: Center(child: CircularProgressIndicator(color: colors.accentColor)),
          fit: BoxFit.contain,
        ),
      ),
    );
    final File? filtered = result?['image_filtered'];
    if (filtered != null && mounted) setState(() => _path = filtered.path);
  }

  Future<void> _crop() async {
    final options = StoryPickerScope.of(context);
    final colors = options.theme;
    const presets = [
      CropAspectRatioPreset.original,
      CropAspectRatioPreset.square,
      CropAspectRatioPreset.ratio3x2,
      CropAspectRatioPreset.ratio4x3,
      CropAspectRatioPreset.ratio16x9,
    ];

    final cropped = await ImageCropper().cropImage(
      sourcePath: _path,
      compressFormat: ImageCompressFormat.png,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '',
          toolbarColor: colors.previewBackgroundColor,
          backgroundColor: colors.previewBackgroundColor,
          toolbarWidgetColor: colors.previewForegroundColor,
          activeControlsWidgetColor: colors.accentColor,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: presets,
        ),
        IOSUiSettings(
          minimumAspectRatio: 1.0,
          doneButtonTitle: options.translations.save,
          cancelButtonTitle: options.translations.cancel,
          aspectRatioPresets: presets,
        ),
      ],
    );
    if (cropped != null && mounted) setState(() => _path = cropped.path);
  }

  @override
  Widget build(BuildContext context) {
    final colors = StoryPickerScope.of(context).theme;

    return PreviewScaffold(
      onValidate: () => Navigator.of(context).pop(StoryImageResult(_path)),
      body: Column(
        children: [
          Expanded(
            child: Image.file(File(_path), key: ValueKey(_path), fit: BoxFit.contain),
          ),
          if (_loadingFilters) LinearProgressIndicator(color: colors.accentColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 30,
              children: [
                IconButton.outlined(
                  iconSize: 32,
                  color: colors.previewForegroundColor,
                  onPressed: _loadingFilters ? null : _openFilters,
                  icon: const Icon(Icons.photo_filter_sharp),
                ),
                IconButton.outlined(iconSize: 32, color: colors.previewForegroundColor, onPressed: _crop, icon: const Icon(Icons.crop)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
