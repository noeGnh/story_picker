import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:logger/logger.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:story_picker/src/models/file_model.dart';
import 'package:story_picker/src/models/folder_model.dart';
import 'package:story_picker/src/models/options.dart';
import 'package:story_picker/src/models/result.dart';
import 'package:story_picker/src/utils/utils.dart';
import 'package:story_picker/src/widgets/preview/image_preview.dart';
import 'package:story_picker/src/widgets/preview/video_preview.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class GalleryProvider extends ChangeNotifier{

  final Logger logger = Logger();

  static const int VIDEO_LENGTH_LIMIT = 30;

  FileModel? _selectedFile;
  late Translations _translations;
  FolderModel? _selectedFolder;
  List<FileModel?> _files = [];
  List<FolderModel> _folders = [];

  int _multiSelectLimit = 5;
  bool _multiSelect = false;

  List<FileModel?> get files => this._files;
  List<FolderModel> get folders => this._folders;
  FileModel? get selectedFile => this._selectedFile;
  FolderModel? get selectedFolder => this._selectedFolder;

  bool get multiSelect => this._multiSelect;
  int get multiSelectLimit => this._multiSelectLimit;

  set multiSelect(bool b){
    this._files.clear();
    this._multiSelect = b;
    notifyListeners();
  }

  set selectedFile(FileModel? file){ this._selectedFile = file; notifyListeners(); }

  set translations(Translations translations){ this._translations = translations; }

  getCheckNumber(FileModel? file) => this._files.indexOf(file) + 1;

  getCheckState(FileModel? file) => this._files.contains(file);

  toggleCheckState(FileModel? file){
    if (getCheckState(file)){
      this._files.remove(file);
    }else{
      if (file!.type == AssetType.video) {
        StoryUtils.showToast(this._translations.multiSelectionDoesntSupportVideos);
        return;
      }

      if (this._files.length >= this._multiSelectLimit) {
        logger.w('The limit is ${this._multiSelectLimit} images.');
        return;
      }

      this._files.add(file);
    }
    notifyListeners();
  }

  getFilesPath() async {

    if (!await Permission.storage.request().isGranted) return;

    final String cacheDir = '${(await getTemporaryDirectory()).path}/galleryPicker';

    var result = await PhotoManager.requestPermission();
    if (result) {

      var paths = await PhotoManager.getAssetPathList(
          hasAll: false,
          filterOption: FilterOptionGroup()
            ..setOption(AssetType.video, FilterOption(
                durationConstraint: const DurationConstraint(
                  max: Duration(minutes: VIDEO_LENGTH_LIMIT),
                )
            ))
      );

      for(int i = 0; i < paths.length; i++){

        AssetPathEntity path = paths[i];

        List<FileModel> fileList = [];
        List<AssetEntity> assetList = await path.assetList;

        for(int y = 0; y < assetList.length; y++){

          File? file = await assetList[y].file; File? thumbFile;

          if (assetList[y].type == AssetType.image || assetList[y].type == AssetType.video) {

            if (['.mp4', '.png', '.jpg', '.jpeg', '.gif'].contains(extension(file!.path).toLowerCase())) {

              try{

                String thumbName =
                (basename(file.path).split('.')[0] + path.id +
                    (assetList[y].type == AssetType.video ? '.mp4' : '')).replaceAll(' ', '');
                String thumbPath = '$cacheDir/$thumbName.jpg';

                if (await File(thumbPath).exists()) {

                  thumbFile = File(thumbPath);

                } else {

                  Uint8List? thumbBytes;

                  if (assetList[y].type == AssetType.video){

                    thumbBytes = await VideoThumbnail.thumbnailData(
                      video: file.path,
                      imageFormat: ImageFormat.JPEG,
                      maxWidth: 128,
                      quality: 95,
                    );

                  }else{

                    thumbBytes = await FlutterImageCompress.compressWithFile(
                      file.path,
                      minHeight: 144,
                      minWidth: 144,
                      quality: 95,
                    );

                  }

                  thumbFile = await File(thumbPath).create(recursive: true);

                  thumbFile = await thumbFile.writeAsBytes(thumbBytes!);

                }

              }catch(e){
                print(e);
              }

              if (thumbFile != null){

                fileList.add(FileModel(
                    duration: assetList[y].videoDuration,
                    type: assetList[y].type,
                    size: assetList[y].size,
                    width: assetList[y].width,
                    height: assetList[y].height,
                    createDt: assetList[y].createDateTime,
                    modifiedDt: assetList[y].modifiedDateTime,
                    latitude: assetList[y].latitude,
                    longitude: assetList[y].longitude,
                    title: assetList[y].title,
                    relativePath: assetList[y].relativePath,
                    filePath: file.path,
                    thumbPath: thumbFile.path
                ));

              }

            }

          }

        }

        if (fileList.isNotEmpty) {

          this._folders.add(FolderModel(
              files: fileList,
              name: path.name,
              id: path.id,
              type: path.albumType,
              count: path.assetCount
          ));

          if (this._folders.length == 1){

            this._selectedFolder = this._folders[0];
            this._selectedFile = this._folders[0].files![0];

          }

        }

        notifyListeners();

      }

    }

  }

  List<DropdownMenuItem> getItems() {
    return this._folders.map((e) => DropdownMenuItem(
      child: SizedBox(
        width: 190,
        child: Text(e.name!, textAlign: TextAlign.start, overflow: TextOverflow.ellipsis,),
      ),
      value: e,
    )
    ).toList();
  }

  void onFolderSelected(FolderModel folder, {int index = 0}) {
    assert(folder.files!.length > 0);

    this._selectedFile = folder.files![index];

    this._selectedFolder = folder;

    notifyListeners();
  }

  void submit(BuildContext context, Options? options) async {

    if (this._multiSelect) {

      this._returnImageResult(context, options!);

    } else {

      if (this._selectedFile != null){

        this._files.clear();
        this._files.add(this._selectedFile);

        if (this._selectedFile!.type == AssetType.video) {

          if (this._selectedFile!.duration != null && this._selectedFile!.duration!.inMinutes < VIDEO_LENGTH_LIMIT) {

            StoryPickerResult? result = await Navigator.of(context).push(
                PageTransition(
                    child: VideoPreview(
                      files: this._files,
                      imagePreviewOptions: options,
                    ),
                    type: PageTransitionType.bottomToTop
                )
            );

            if (result != null) Navigator.pop(context, result);

          } else {
            logger.w('Too long video !');
          }

        } else {

          this._returnImageResult(context, options!);

        }

      }else{
        logger.i('No file selected');
      }

    }

  }

  void _returnImageResult(BuildContext context, Options options) async {

    this.selectedFile = this._files[0];

    StoryPickerResult? result = await Navigator.of(context).push(
        PageTransition(
            child: ImagePreview(
                files: this._files,
                imagePreviewOptions: options,
                showAddButton: options.customizationOptions.galleryCustomization.maxSelectable > 1
            ),
            type: PageTransitionType.bottomToTop
        )
    );

    if (result != null) Navigator.pop(context, result);

  }

}