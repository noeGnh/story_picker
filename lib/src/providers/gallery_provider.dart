import 'dart:io';
import 'dart:typed_data';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
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
import 'package:video_player/video_player.dart';

class GalleryProvider extends ChangeNotifier{

  FileModel _selectedFile;
  FolderModel _selectedFolder;
  List<FileModel> _files = [];
  List<FolderModel> _folders = [];

  int _multiSelectLimit = 5;
  bool _multiSelect = false;

  File oldVideoFile;
  ChewieController chewieController;
  VideoPlayerController videoPlayerController;

  List<FileModel> get files => this._files;
  List<FolderModel> get folders => this._folders;
  FileModel get selectedFile => this._selectedFile;
  FolderModel get selectedFolder => this._selectedFolder;

  get multiSelect => this._multiSelect;
  get multiSelectLimit => this._multiSelectLimit;

  set multiSelect(bool b){
    this._files.clear();
    this._multiSelect = b;
    notifyListeners();
  }

  set multiSelectLimit(bool b){ this._multiSelect = b; }

  set selectedFile(FileModel file){ this._selectedFile = file; notifyListeners(); }

  getCheckNumber(FileModel file) => this._files.indexOf(file) + 1;

  getCheckState(FileModel file) => this._files.contains(file);

  toggleCheckState(FileModel file){
    if (getCheckState(file)){
      this._files.remove(file);
    }else{
      if (file.type == AssetType.video) {
        StoryUtils.showToast('La multi-selection ne supporte pas les vidéos.');
        return;
      }

      if (this._files.length >= this._multiSelectLimit) {
        StoryUtils.showToast('La limite est de ${this._multiSelectLimit} images.');
        return;
      }

      this._files.add(file);
    }
    notifyListeners();
  }

  ChewieController initVideoController(File file) {

    if (oldVideoFile == null || oldVideoFile != file) {

      VideoPlayerController videoPlayerController = VideoPlayerController.file(file);

      ChewieController chewieController = ChewieController(
        videoPlayerController: videoPlayerController,
        allowedScreenSleep: false,
        allowFullScreen: false,
        aspectRatio: 3 / 2,
        autoPlay: true,
        looping: false,
      );

      this.oldVideoFile = file;
      this.chewieController = chewieController;
      this.videoPlayerController = videoPlayerController;

      return chewieController;

    }

    return this.chewieController;

  }

  pauseVideo() async {
    if (chewieController != null && chewieController.isPlaying) await chewieController.pause();
  }

  playVideo() async {
    if (chewieController != null && !chewieController.isPlaying) await chewieController.play();
  }

  disposeVideoController(){
    try{

      if (chewieController != null) chewieController.dispose(); chewieController = null;
      if (videoPlayerController != null) videoPlayerController.dispose(); videoPlayerController = null;

    }catch(e){
      print(e);
    }
  }

  getFilesPath() async {

    if (!await Permission.storage.request().isGranted) return;

    final String cacheDir = '${(await getApplicationDocumentsDirectory()).path}/instaPicker';

    var result = await PhotoManager.requestPermission();
    if (result) {

      var paths = await PhotoManager.getAssetPathList(
          hasAll: false,
          filterOption: FilterOptionGroup()
            ..setOption(AssetType.video, FilterOption(
                durationConstraint: const DurationConstraint(
                  max: Duration(hours: 1),
                )
            ))
      );

      for(int i = 0; i < paths.length; i++){

        AssetPathEntity path = paths[i];

        List<FileModel> fileList = [];
        List<AssetEntity> assetList = await path.assetList;

        await Future.wait(
            assetList.map((asset) async {

              File f = await asset.file; File thumbFile; Uint8List thumbBytes;

              if (asset.type != AssetType.image && asset.type != AssetType.video) return;

              if (asset.type == AssetType.video) {

                try{

                  String thumbPath = '$cacheDir/${basename(f.path).split('.')[0]}.png';

                  if (await File(thumbPath).exists()) {

                    thumbFile = File(thumbPath);

                  } else {

                    thumbBytes = await asset.thumbData;

                    final thumbFile = await File(thumbPath).create(recursive: true);

                    await thumbFile.writeAsBytes(thumbBytes);

                    assert(thumbFile != null);

                  }

                }catch(e){
                  print(e);
                }

              }

              fileList.add(FileModel(
                  file: f,
                  thumbFile: thumbFile,
                  thumbBytes: thumbBytes,
                  duration: asset.videoDuration,
                  type: asset.type,
                  size: asset.size,
                  width: asset.width,
                  height: asset.height,
                  createDt: asset.createDateTime,
                  modifiedDt: asset.modifiedDateTime,
                  latitude: asset.latitude,
                  longitude: asset.longitude,
                  title: asset.title,
                  relativePath: asset.relativePath,
                  path: f.path
              ));

            }).toList()
        );

        if (fileList.isEmpty) return;

        this._folders.add(FolderModel(
            files: fileList,
            name: path.name,
            id: path.id,
            type: path.albumType,
            count: path.assetCount
        ));

        if (this._folders != null && this._folders.length == 1){

          this._selectedFolder = this._folders[0];
          this._selectedFile = this._folders[0].files[0];

        }

        notifyListeners();

      }

    }

  }

  List<DropdownMenuItem> getItems() {
    return this._folders.map((e) => DropdownMenuItem(
      child: SizedBox(
        width: 190,
        child: Text(e.name, textAlign: TextAlign.start, overflow: TextOverflow.ellipsis,),
      ),
      value: e,
    )
    ).toList() ?? [];
  }

  void onFolderSelected(FolderModel folder, {int index = 0}) {
    assert(folder.files.length > 0);

    disposeVideoController();

    this._selectedFile = folder.files[index];

    this._selectedFolder = folder;

    notifyListeners();
  }

  void submit(BuildContext context, Options options) async {

    if (this._multiSelect) {

      this._returnImageResult(context, options);

    } else {

      if (this._selectedFile != null){

        this._files.clear();
        this._files.add(this._selectedFile);

        if (this._selectedFile.type == AssetType.video) {

          if (this._selectedFile.duration != null && this._selectedFile.duration.inMinutes < 10) {

            Future.delayed(Duration(milliseconds: 1000), () async { pauseVideo(); });

            StoryPickerResult result = await Navigator.of(context).push(
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
            StoryUtils.showToast('Cette vidéo est trop longue !');
          }

        } else {

          this._returnImageResult(context, options);

        }

      }else{
        StoryUtils.showToast('Aucun fichier sélectionné');
      }

    }

  }

  void _returnImageResult(BuildContext context, Options options) async {

    this.selectedFile = this._files[0];

    StoryPickerResult result = await Navigator.of(context).push(
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