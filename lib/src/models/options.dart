import 'dart:ui';

import 'package:flutter/material.dart';

class Options{

  dynamic settingsTarget;
  CustomizationOptions customizationOptions;

  Options({
    this.settingsTarget,
    CustomizationOptions customizationOptions
  }) : this.customizationOptions = customizationOptions ?? CustomizationOptions();

}

class CustomizationOptions{

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
    TextCustomization textCustomization,
    CameraCustomization cameraCustomization,
    GalleryCustomization galleryCustomization,
    PreviewScreenCustomization previewScreenCustomization
  }) : this.textCustomization = textCustomization ?? TextCustomization(),
       this.cameraCustomization = cameraCustomization ?? CameraCustomization(),
       this.galleryCustomization = galleryCustomization ?? GalleryCustomization(),
       this.previewScreenCustomization = previewScreenCustomization ?? PreviewScreenCustomization();

}

class GalleryCustomization{

  Color bgColor;
  Color iconsColor;
  int maxSelectable;

  GalleryCustomization({
    this.iconsColor = Colors.black,
    this.bgColor = Colors.white,
    this.maxSelectable = 1,
  }){
    if (this.maxSelectable != null && this.maxSelectable <= 0) {
      throw ArgumentError('The value must be greater than 0');
    }
  }

}

class CameraCustomization{

  Color iconsColor;
  Color videoCaptureProgressIndicatorColor;

  CameraCustomization({
    this.iconsColor = Colors.white,
    this.videoCaptureProgressIndicatorColor = Colors.red
  });

}

class TextCustomization{

  Color iconsColor;

  TextCustomization({this.iconsColor = Colors.white});

}

class PreviewScreenCustomization{

  Color iconsColor;
  Color textColor;
  Color bgColor;

  PreviewScreenCustomization({
    this.iconsColor = Colors.black,
    this.textColor = Colors.black,
    this.bgColor = Colors.white
  });

}