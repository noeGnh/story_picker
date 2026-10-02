import 'package:flutter/material.dart';

class StoryPickerResult {
  List<PickedFile>? pickedFiles;
  ResultType? resultType;
  StoryText? storyText;

  StoryPickerResult({this.resultType, this.pickedFiles, this.storyText});
}

class StoryText {
  LinearGradient? linearGradient;
  TextAlign? align;
  String? colorHex;
  String? font;
  String? text;
  int? fontIndex;
  int? alignIndex;
  int? linearGradientIndex;

  StoryText({this.text, this.colorHex, this.font, this.align, this.linearGradient, this.fontIndex, this.alignIndex, this.linearGradientIndex});
}

class PickedFile {
  String? path;
  String? name;

  PickedFile({this.path, this.name});
}

// Renamed to lowerCamelCase with the 1.0 API rework.
// ignore: constant_identifier_names
enum ResultType { TEXT, IMAGE, VIDEO }
