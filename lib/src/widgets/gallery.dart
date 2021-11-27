import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:story_picker/src/models/file_model.dart';
import 'package:story_picker/src/models/folder_model.dart';
import 'package:story_picker/src/providers/gallery_provider.dart';
import 'package:story_picker/src/utils/utils.dart';
import 'package:story_picker/story_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

Options? options;

class Gallery extends StatelessWidget {

  Gallery(Options? opt) { options = opt; }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GalleryProvider>(
      create: (_) => GalleryProvider(),
      child: GalleryView(),
    );
  }

}

class GalleryView extends StatefulWidget {
  @override
  _GalleryViewState createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> with AutomaticKeepAliveClientMixin{
  late GalleryProvider galleryProvider;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    galleryProvider =  Provider.of<GalleryProvider>(context, listen: false);
    galleryProvider.getFilesPath();

    galleryProvider.translations = options!.translations;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: options!.customizationOptions.galleryCustomization.bgColor,
      appBar: AppBar(
        elevation: 0.0,
        title: Consumer<GalleryProvider>(
            builder: (ctx, provider, child){

              return provider.folders != null ? DropdownButtonHideUnderline(
                  child: DropdownButton<FolderModel>(
                    items: provider.getItems() as List<DropdownMenuItem<FolderModel>>?,
                    onChanged: (FolderModel? folder) => provider.onFolderSelected(folder!),
                    value: provider.selectedFolder,
                  )
              ) : Container();

            }
        ),
        leading: GestureDetector(
          child: Icon(
            Icons.clear,
            color: options!.customizationOptions.galleryCustomization.iconsColor,
          ),
          onTap: (){
            Navigator.pop(context, null);
          },
        ),
        actions: [
          GestureDetector(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(
                Icons.check,
                color: options!.customizationOptions.galleryCustomization.iconsColor,
              ),
            ),
            onTap: (){
              galleryProvider.submit(context, options);
            },
          )
        ],
        backgroundColor: options!.customizationOptions.appBarColor,
      ),
      body: SafeArea(
          child: Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.35,
                child: Consumer<GalleryProvider>(
                    builder: (ctx, provider, child){

                      return provider.selectedFile != null ?
                      Container(
                          height: MediaQuery.of(context).size.height * 0.35,
                          width: MediaQuery.of(context).size.width,
                          color: options!.customizationOptions.galleryCustomization.bgColor,
                          child: Stack(
                            children: [
                              provider.selectedFile!.type == AssetType.image
                                  ? GalleryImagePreview(provider)
                                  : GalleryVideoPreview(provider, Key(path.basename(provider.selectedFile!.filePath!))),
                              options!.customizationOptions.galleryCustomization.maxSelectable > 1 ? Positioned(
                                  right: 20,
                                  bottom: provider.selectedFile!.type == AssetType.video ? 50 : 5,
                                  child: GestureDetector(
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: new BoxDecoration(
                                        color: Colors.black26,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.add_to_photos,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    onTap: (){
                                      provider.multiSelect = !provider.multiSelect;
                                      provider.toggleCheckState(provider.selectedFile);
                                    },
                                  )
                              ) : Container()
                            ],
                          )
                      ) : Container();

                    }
                ),
              ),
              Divider(),
              Consumer<GalleryProvider>(
                  builder: (ctx, provider, child){

                    return provider.selectedFolder != null && provider.selectedFolder!.files!.length > 0
                        ? Container(
                            color: options!.customizationOptions.galleryCustomization.bgColor,
                            height: MediaQuery.of(context).size.height * 0.42,
                            child: GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4, crossAxisSpacing: 4, mainAxisSpacing: 4
                                ),
                                itemBuilder: (_, i) {
                                  var file = provider.selectedFolder!.files![i];

                                  return GalleryItem(
                                    file: file,
                                    provider: provider,
                                  );

                                },
                                itemCount: provider.selectedFolder!.files!.length
                            ),
                          ) : Container();

                  }
              ),
            ],
          )
      ),
    );
  }
}

class GalleryImagePreview extends StatelessWidget {
  final GalleryProvider provider;

  GalleryImagePreview(this.provider);

  @override
  Widget build(BuildContext context) {
    return PhotoView(
      imageProvider: FileImage(File(provider.selectedFile!.filePath!)),
      backgroundDecoration: BoxDecoration(color: options!.customizationOptions.galleryCustomization.bgColor),
    );
  }
}

class GalleryVideoPreview extends StatefulWidget {
  final GalleryProvider provider;
  final Key key;

  GalleryVideoPreview(this.provider, this.key) : super(key: key);

  @override
  _GalleryVideoPreviewState createState() => _GalleryVideoPreviewState();
}

class _GalleryVideoPreviewState extends State<GalleryVideoPreview> {

  Future<bool>? _init;
  late ChewieController _chewieController;
  late VideoPlayerController _videoPlayerController;

  @override
  void initState() {
    super.initState();

    _videoPlayerController = VideoPlayerController.file(File(widget.provider.selectedFile!.filePath!));

    _init = initVideoPlayer();
  }

  Future<bool> initVideoPlayer() async {
    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      allowFullScreen: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      autoPlay: true,
      looping: false,
    );

    return true;
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<bool>(
      future: _init,
      builder: (ctx, snp){

        if (!snp.hasData) return Center(
            child: CircularProgressIndicator(
                backgroundColor: options!.customizationOptions.accentColor
            )
        );

        return VisibilityDetector(
            key: widget.key,
            onVisibilityChanged: (VisibilityInfo info) {
              if(info.visibleFraction == 0)
                _chewieController.pause();
              else
                _chewieController.play();
            },
            child: Chewie(controller: _chewieController)
        );

      }
    );

  }

}

class GalleryItem extends StatefulWidget {
  final FileModel? file;
  final GalleryProvider? provider;

  GalleryItem({Key? key, this.file, this.provider}) : super(key: key);

  @override
  _GalleryItemState createState() => _GalleryItemState();
}

class _GalleryItemState extends State<GalleryItem> with AutomaticKeepAliveClientMixin{

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return widget.file != null ? Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          child: File(widget.file!.thumbPath!) != null
              ? Image.file(
            File(widget.file!.thumbPath!),
            fit: BoxFit.cover,
          )
              : Container(color: Colors.grey),
          onTap: () {
            widget.provider!.selectedFile = widget.file;
            if (widget.provider!.multiSelect) widget.provider!.toggleCheckState(widget.file);
          },
          onLongPress: (){

            if (options!.customizationOptions.galleryCustomization.maxSelectable == 1) return;

            widget.provider!.multiSelect = !widget.provider!.multiSelect;
            widget.provider!.toggleCheckState(widget.file);
            widget.provider!.selectedFile = widget.file;

          },
        ),
        widget.provider!.multiSelect ? Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              child: Container(
                width: 24,
                height: 24,
                padding: EdgeInsets.only(top: 2),
                decoration: new BoxDecoration(
                    color: widget.provider!.getCheckState(widget.file) ? options!.customizationOptions.accentColor : Colors.white70,
                    shape: BoxShape.circle,
                    border: Border.all(width: 1.5, color: options!.customizationOptions.galleryCustomization.bgColor)
                ),
                child: widget.provider!.getCheckState(widget.file)
                    ? Text(widget.provider!.getCheckNumber(widget.file).toString(),
                    style: TextStyle(
                        color: Colors.white
                    ),
                    textAlign: TextAlign.center
                ) : Container(),
              ),
              onTap: (){

                widget.provider!.toggleCheckState(widget.file);
                widget.provider!.selectedFile = widget.file;

              },
            )
        ) : Container(),
        widget.file!.duration != null && widget.file!.type == AssetType.video ? Positioned(
            right: 5,
            bottom: 5,
            child: Text(StoryUtils.printDuration(widget.file!.duration!), style: TextStyle(color: Colors.white),)
        ) : Container()
      ],
    ) : Container();
  }
}

