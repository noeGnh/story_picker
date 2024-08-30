import 'package:flutter/material.dart';

class Options {
  dynamic settingsTarget;
  Translations translations;
  CustomizationOptions customizationOptions;

  Options({
    this.settingsTarget,
    Translations? translations,
    CustomizationOptions? customizationOptions,
  })  : this.translations = translations ?? Translations(),
        this.customizationOptions = customizationOptions ?? CustomizationOptions();
}

class CustomizationOptions {
  Color accentColor;
  Color appBarColor;
  int videoDurationLimitInSeconds;
  TextCustomization textCustomization;
  CameraCustomization cameraCustomization;
  GalleryCustomization galleryCustomization;
  PreviewScreenCustomization previewScreenCustomization;

  CustomizationOptions({
    this.accentColor = Colors.black,
    this.appBarColor = Colors.white,
    this.videoDurationLimitInSeconds = 15,
    TextCustomization? textCustomization,
    CameraCustomization? cameraCustomization,
    GalleryCustomization? galleryCustomization,
    PreviewScreenCustomization? previewScreenCustomization,
  })  : this.textCustomization = textCustomization ?? TextCustomization(),
        this.cameraCustomization = cameraCustomization ?? CameraCustomization(),
        this.galleryCustomization = galleryCustomization ?? GalleryCustomization(),
        this.previewScreenCustomization = previewScreenCustomization ?? PreviewScreenCustomization();
}

class GalleryCustomization {
  Color bgColor;
  Color iconsColor;
  int maxSelectable;

  GalleryCustomization({
    this.iconsColor = Colors.black,
    this.bgColor = Colors.white,
    this.maxSelectable = 1,
  }) {
    if (this.maxSelectable <= 0) {
      throw ArgumentError('The value must be greater than 0');
    }
  }
}

class CameraCustomization {
  Color iconsColor;
  Color videoCaptureProgressIndicatorColor;

  CameraCustomization({
    this.iconsColor = Colors.white,
    this.videoCaptureProgressIndicatorColor = Colors.red,
  });
}

class TextCustomization {
  Color iconsColor;

  TextCustomization({
    this.iconsColor = Colors.white,
  });
}

class PreviewScreenCustomization {
  Color iconsColor;
  Color textColor;
  Color bgColor;

  PreviewScreenCustomization({
    this.iconsColor = Colors.black,
    this.textColor = Colors.black,
    this.bgColor = Colors.white,
  });
}

class Translations {
  String preview;
  String pressToWrite;
  String pressAndHoldToRecordAVideo;
  String multiSelectionDoesntSupportVideos;
  String filters;
  String save;
  String cancel;
  String recordedVideo;
  String whatDoYouWantToDo;
  String delete;
  String validate;

  Translations({
    this.preview = 'Preview',
    this.pressToWrite = 'Press to write',
    this.pressAndHoldToRecordAVideo = 'Press and hold to record a video',
    this.multiSelectionDoesntSupportVideos = 'Multi-selection does not support videos',
    this.filters = 'Filters',
    this.save = 'Save',
    this.cancel = 'Cancel',
    this.recordedVideo = 'Recorded Video',
    this.whatDoYouWantToDo = 'What do you want to do ?',
    this.delete = 'Delete',
    this.validate = 'Validate',
  });
}
