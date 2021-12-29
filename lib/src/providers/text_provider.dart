import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path/path.dart';
import 'package:story_picker/src/models/file_model.dart';
import 'package:story_picker/src/models/options.dart';
import 'package:story_picker/src/models/result.dart';
import 'package:story_picker/src/utils/constants.dart';
import 'package:story_picker/src/utils/utils.dart';
import 'package:story_picker/src/widgets/preview/image_preview.dart';
import 'package:story_picker/src/widgets/preview/video_preview.dart';

class TextProvider extends ChangeNotifier{

  TextEditingController? textEditingController;
  int? textFontIndex, textAlignIndex, textBgIndex;
  KeyboardVisibilityController? keyboardVisibilityController;

  init(){
    textBgIndex = 0;
    textFontIndex = 0;
    textAlignIndex = 0;
    textEditingController = TextEditingController();
    keyboardVisibilityController = KeyboardVisibilityController();
  }
  
  switchTextFont(){
    if (textFontIndex! + 1 >= StoryConstants.fonts.length) {
      textFontIndex = 0;
    }else{
      textFontIndex = textFontIndex! + 1;
    }

    notifyListeners();
  }
  
  switchTextAlign(){
    if (textAlignIndex! + 1 >= StoryConstants.textAlignments.length) {
      textAlignIndex = 0;
    }else{
      textAlignIndex = textAlignIndex! + 1;
    }

    notifyListeners();
  }

  switchTextBackground(){
    if (textBgIndex! + 1 >= StoryConstants.textBackgrounds.length) {
      textBgIndex = 0;
    }else{
      textBgIndex = textBgIndex! + 1;
    }

    notifyListeners();
  }

  openSettingsScreen(BuildContext context, dynamic target) async {

    await Navigator.of(context).push(
        PageTransition(
            child: target,
            type: PageTransitionType.leftToRight
        )
    );

  }

  openGalleryScreen(BuildContext context, Options? options) async {

    const imgExtensions = ['jpg', 'png', 'jpeg', 'gif', 'webp'];
    const vidExtensions = ['mp4', 'mkv', 'mov', 'wmv', 'flv', 'avi', 'webm'];

    FilePickerResult? pickedResult = await FilePicker.platform.pickFiles(
        type: FileType.media
    );

    if (pickedResult != null) {

      StoryPickerResult? result;

      if (imgExtensions.contains( extension(pickedResult.files.single.path!).substring(1).toLowerCase() )){

        result = await Navigator.of(context).push(
            PageTransition(
                child: ImagePreview(
                    files: [FileModel(
                        filePath: pickedResult.files.single.path!,
                        relativePath: pickedResult.files.single.path!,
                        thumbPath: pickedResult.files.single.path!,
                        title: basename(pickedResult.files.single.path!)
                    )],
                    imagePreviewOptions: options,
                    showAddButton: options!.customizationOptions.galleryCustomization.maxSelectable > 1
                ),
                type: PageTransitionType.bottomToTop
            )
        );

      } else if (vidExtensions.contains( extension(pickedResult.files.single.path!).substring(1).toLowerCase() )){

        result = await Navigator.of(context).push(
            PageTransition(
                child: VideoPreview(
                  files: [FileModel(
                      filePath: pickedResult.files.single.path!,
                      relativePath: pickedResult.files.single.path!,
                      thumbPath: pickedResult.files.single.path!,
                      title: basename(pickedResult.files.single.path!)
                  )],
                  imagePreviewOptions: options,
                ),
                type: PageTransitionType.bottomToTop
            )
        );

      }

      if (result != null) Navigator.pop(context, result);

    }

  }

  submit(BuildContext context) {

    if (textEditingController!.text.isEmpty) return;

    Navigator.pop(
        context,
        StoryPickerResult(
            storyText: StoryText(
              font: StoryConstants.fonts[textFontIndex!],
              text: textEditingController!.text,
              align: StoryConstants.textAlignments[textAlignIndex!],
              colorHex: StoryConstants.textBackgrounds[textBgIndex!].textColor!.toHex(),
              linearGradient: StoryConstants.textBackgrounds[textBgIndex!].linearGradient,
              fontIndex: textFontIndex,
              alignIndex: textAlignIndex,
              linearGradientIndex: textAlignIndex
            ),
            resultType: ResultType.TEXT
        )
    );

  }

}