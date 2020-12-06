import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:story_picker/src/models/folder_model.dart';
import 'package:story_picker/src/providers/gallery_provider.dart';
import 'package:story_picker/src/utils/utils.dart';
import 'package:story_picker/story_picker.dart';

Options options;

class Gallery extends StatelessWidget {

  Gallery(Options opt) { options = opt; }

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
  GalleryProvider galleryProvider;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    galleryProvider =  Provider.of<GalleryProvider>(context, listen: false);
    galleryProvider.getFilesPath();
  }

  @override
  void dispose() {
    galleryProvider.disposeVideoController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: options.customizationOptions.galleryCustomization.bgColor,
      appBar: AppBar(
        elevation: 0.0,
        title: Consumer<GalleryProvider>(
            builder: (ctx, provider, child){

              return provider.folders != null ? DropdownButtonHideUnderline(
                  child: DropdownButton<FolderModel>(
                    items: provider.getItems(),
                    onChanged: (FolderModel folder) => provider.onFolderSelected(folder),
                    value: provider.selectedFolder,
                  )
              ) : Container();

            }
        ),
        leading: GestureDetector(
          child: Icon(
            Icons.clear,
            color: options.customizationOptions.galleryCustomization.iconsColor,
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
                color: options.customizationOptions.galleryCustomization.iconsColor,
              ),
            ),
            onTap: (){
              galleryProvider.submit(context, options);
            },
          )
        ],
        backgroundColor: options.customizationOptions.appBarColor,
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
                          color: options.customizationOptions.galleryCustomization.bgColor,
                          child: Stack(
                            children: [
                              provider.selectedFile.type == AssetType.image ? PhotoView(
                                imageProvider: FileImage(provider.selectedFile.file),
                                backgroundDecoration: BoxDecoration(color: options.customizationOptions.galleryCustomization.bgColor),
                              ) : Chewie(
                                controller: provider.initVideoController(provider.selectedFile.file),
                              ),
                              options.customizationOptions.galleryCustomization.maxSelectable > 1 ? Positioned(
                                  right: 20,
                                  bottom: provider.selectedFile.type == AssetType.video ? 50 : 5,
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

                    return provider.selectedFolder != null && provider.selectedFolder.files.length > 0
                        ? Container(
                            color: options.customizationOptions.galleryCustomization.bgColor,
                            height: MediaQuery.of(context).size.height * 0.42,
                            child: GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4, crossAxisSpacing: 4, mainAxisSpacing: 4
                                ),
                                itemBuilder: (_, i) {
                                  var file = provider.selectedFolder.files[i];

                                  return file != null ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      GestureDetector(
                                        child: file.type == AssetType.image ? Image.file(
                                          file.file,
                                          fit: BoxFit.cover,
                                        ) : (file.thumbFile != null
                                            ? Image.file(
                                          file.thumbFile,
                                          fit: BoxFit.cover,
                                        )
                                            : (file.thumbBytes != null
                                            ? Image.memory(
                                          file.thumbBytes,
                                          fit: BoxFit.cover,
                                        )
                                            : Container()
                                        )
                                        ),
                                        onTap: () {
                                          provider.selectedFile = file;
                                          if (provider.multiSelect) provider.toggleCheckState(file);
                                        },
                                        onLongPress: (){

                                          if (options.customizationOptions.galleryCustomization.maxSelectable <= 1) return;

                                          provider.multiSelect = !provider.multiSelect;
                                          provider.toggleCheckState(file);
                                          provider.selectedFile = file;

                                        },
                                      ),
                                      provider.multiSelect ? Positioned(
                                          top: 5,
                                          right: 5,
                                          child: GestureDetector(
                                            child: Container(
                                              width: 24,
                                              height: 24,
                                              padding: EdgeInsets.only(top: 2),
                                              decoration: new BoxDecoration(
                                                  color: provider.getCheckState(file) ? options.customizationOptions.accentColor : Colors.white70,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(width: 1.5, color: options.customizationOptions.galleryCustomization.bgColor)
                                              ),
                                              child: provider.getCheckState(file)
                                                  ? Text(provider.getCheckNumber(file).toString(),
                                                  style: TextStyle(
                                                      color: Colors.white
                                                  ),
                                                  textAlign: TextAlign.center
                                              ) : Container(),
                                            ),
                                            onTap: (){

                                              provider.toggleCheckState(file);
                                              provider.selectedFile = file;

                                            },
                                          )
                                      ) : Container(),
                                      file.duration != null && file.type == AssetType.video ? Positioned(
                                          right: 5,
                                          bottom: 5,
                                          child: Text(Utils.printDuration(file.duration), style: TextStyle(color: Colors.white),)
                                      ) : Container()
                                    ],
                                  ) : Container();

                                },
                                itemCount: provider.selectedFolder.files.length
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

