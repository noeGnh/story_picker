import 'file_model.dart';

class FolderModel {
  List<FileModel>? files;
  String? name;
  String? id;
  int? type;
  int? count;

  FolderModel({this.files, this.name, this.id, this.type, this.count});
}
