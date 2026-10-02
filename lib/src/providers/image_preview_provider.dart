import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart';
import 'package:photofilters/filters/preset_filters.dart';
import 'package:photofilters/widgets/photo_filter.dart';
import 'package:image/image.dart' as image_lib;
import 'package:story_picker/src/models/file_model.dart';
import 'package:story_picker/src/models/options.dart';
import 'package:story_picker/src/models/result.dart';

class ImagePreviewProvider extends ChangeNotifier {
  List<FileModel?>? files = [];

  late Translations _translations;

  set translations(Translations translations) {
    _translations = translations;
  }

  void _updateFiles(FileModel file, File resultFile) {
    int index = files!.indexOf(file);
    file.filePath = resultFile.path;
    files![index] = file;

    notifyListeners();
  }

  Future<void> addFilter(BuildContext context, FileModel file, Options? options) async {
    var f = File(file.filePath!);

    var image = image_lib.decodeImage(f.readAsBytesSync())!;
    image = image_lib.copyResize(image, width: 600);

    Map? filterResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoFilterSelector(
          title: Text(_translations.filters, style: TextStyle(color: options!.customizationOptions.previewScreenCustomization.iconsColor)),
          image: image,
          filters: presetFiltersList,
          filename: basename(file.filePath!),
          appBarColor: options.customizationOptions.appBarColor,
          appBarIconsColor: options.customizationOptions.previewScreenCustomization.iconsColor,
          loader: Center(child: CircularProgressIndicator(backgroundColor: options.customizationOptions.previewScreenCustomization.iconsColor)),
          fit: BoxFit.contain,
        ),
      ),
    );

    if (filterResult != null && filterResult.containsKey('image_filtered')) {
      File? resultFile = filterResult['image_filtered'];

      if (resultFile != null) {
        _updateFiles(file, resultFile);
      }
    }
  }

  Future<void> edit(FileModel file, Options options) async {
    CroppedFile? editResult = await ImageCropper().cropImage(
      sourcePath: file.filePath!,
      compressFormat: ImageCompressFormat.png,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '',
          toolbarColor: options.customizationOptions.appBarColor,
          backgroundColor: options.customizationOptions.appBarColor,
          toolbarWidgetColor: options.customizationOptions.previewScreenCustomization.iconsColor,
          activeControlsWidgetColor: options.customizationOptions.previewScreenCustomization.iconsColor,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          showCropGrid: true,
          cropStyle: CropStyle.rectangle,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(
          minimumAspectRatio: 1.0,
          title: '',
          doneButtonTitle: _translations.save,
          cancelButtonTitle: _translations.cancel,
          cropStyle: CropStyle.rectangle,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ],
    );

    if (editResult != null) {
      _updateFiles(file, File(editResult.path));
    }
  }

  void submit(BuildContext context) {
    List<PickedFile> pickedFiles = [];

    if (files != null) {
      files!.map((file) {
        pickedFiles.add(PickedFile(path: file!.filePath, name: basename(file.filePath!)));
      }).toList();

      Navigator.pop(context, StoryPickerResult(pickedFiles: pickedFiles, resultType: ResultType.IMAGE));
    }
  }
}
