import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart';
import 'package:photofilters/filters/preset_filters.dart';
import 'package:photofilters/widgets/photo_filter.dart';
import 'package:image/image.dart' as imageLib;
import 'package:story_picker/src/models/file_model.dart';
import 'package:story_picker/src/models/options.dart';
import 'package:story_picker/src/models/result.dart';

class ImagePreviewProvider extends ChangeNotifier{

  List<FileModel> files = [];

  _updateFiles(FileModel file, File resultFile){

    int index = this.files.indexOf(file);
    file.file = resultFile;
    file.path = resultFile.path;
    this.files[index] = file;

    notifyListeners();

  }

  addFilter(BuildContext context, FileModel file, Options options) async {

    var image = imageLib.decodeImage(file.file.readAsBytesSync());
    image = imageLib.copyResize(image, width: 600);

    Map filterResult = await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => PhotoFilterSelector(
          title: Text('Filtres', style: TextStyle(color: options.customizationOptions.previewScreenCustomization.iconsColor),),
          image: image,
          filters: presetFiltersList,
          filename: basename(file.path),
          appBarColor: options.customizationOptions.appBarColor,
          appBarIconsColor: options.customizationOptions.previewScreenCustomization.iconsColor,
          loader: Center(child: CircularProgressIndicator(backgroundColor: options.customizationOptions.previewScreenCustomization.iconsColor,)),
          fit: BoxFit.contain,
        ),
      ),
    );

    if (filterResult != null && filterResult.containsKey('image_filtered')) {

      File resultFile = filterResult['image_filtered'];

      if (resultFile != null) {

        this._updateFiles(file, resultFile);

      }

    }

  }

  edit(FileModel file, Options options) async {

    File editResult = await ImageCropper.cropImage(
        sourcePath: file.path,
        cropStyle: CropStyle.rectangle,
        compressFormat: ImageCompressFormat.png,
        aspectRatioPresets: [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: '',
            toolbarColor: options.customizationOptions.appBarColor,
            statusBarColor: options.customizationOptions.appBarColor,
            backgroundColor: options.customizationOptions.appBarColor,
            toolbarWidgetColor: options.customizationOptions.previewScreenCustomization.iconsColor,
            activeControlsWidgetColor: options.customizationOptions.previewScreenCustomization.iconsColor,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            showCropGrid: true
        ),
        iosUiSettings: IOSUiSettings(
            minimumAspectRatio: 1.0,
            title: '',
            doneButtonTitle: 'Enregistrer',
            cancelButtonTitle: 'Annuler'
        )
    );

    if (editResult != null) {

      this._updateFiles(file, editResult);

    }

  }

  submit(BuildContext context){

    List<PickedFile> pickedFiles = [];

    if (files != null){
      files.map((file) {
        pickedFiles.add(PickedFile(file: file.file, path: file.path, name: basename(file.path)));
      }).toList();

      Navigator.pop(context, StoryPickerResult(pickedFiles: pickedFiles, resultType: ResultType.IMAGE));
    }

  }

}