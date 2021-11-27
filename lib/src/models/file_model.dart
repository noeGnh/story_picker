
import 'dart:ui';

import 'package:photo_manager/photo_manager.dart';

class FileModel{

  AssetType? type;
  Duration? duration;
  Size? size;
  int? width;
  int? height;
  DateTime? createDt;
  DateTime? modifiedDt;
  double? latitude;
  double? longitude;
  LatLng? ll;
  String? mediaUrl;
  String? title;
  String? relativePath;
  String? filePath;
  String? thumbPath;

  FileModel({this.duration, this.type, this.size, this.width, this.height, this.createDt, this.modifiedDt,
    this.latitude, this.longitude, this.ll, this.mediaUrl, this.title, this.relativePath, this.filePath, this.thumbPath});

}