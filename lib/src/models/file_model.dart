import 'dart:io';

import 'dart:ui';
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

class FileModel{

  File file;
  File thumbFile;
  Uint8List thumbBytes;
  AssetType type;
  Duration duration;
  Size size;
  int width;
  int height;
  DateTime createDt;
  DateTime modifiedDt;
  double latitude;
  double longitude;
  LatLng ll;
  String mediaUrl;
  String title;
  String relativePath;
  String path;

  FileModel({this.file, this.thumbFile, this.thumbBytes, this.duration, this.type, this.size, this.width,
    this.height, this.createDt, this.modifiedDt, this.latitude, this.longitude,
    this.ll, this.mediaUrl, this.title, this.relativePath, this.path});

}