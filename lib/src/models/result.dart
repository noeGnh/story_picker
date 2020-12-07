import 'dart:io';

import 'package:flutter/material.dart';

class StoryPickerResult{

  List<PickedFile> pickedFiles;
  ResultType resultType;
  StoryText storyText;

  StoryPickerResult({this.resultType, this.pickedFiles, this.storyText});

}

class StoryText{

  LinearGradient linearGradient;
  TextAlign align;
  Color color;
  String font;
  String text;

  StoryText({this.text, this.color, this.font, this.align, this.linearGradient});

}

class PickedFile{

  File file;
  String path;
  String name;

  PickedFile({this.file, this.path, this.name});

}

enum ResultType{
  TEXT,
  IMAGE,
  VIDEO
}