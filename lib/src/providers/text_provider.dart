import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:page_transition/page_transition.dart';
import 'package:story_picker/src/models/options.dart';
import 'package:story_picker/src/models/result.dart';
import 'package:story_picker/src/utils/constants.dart';
import 'package:story_picker/src/utils/utils.dart';
import 'package:story_picker/src/widgets/gallery.dart';

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

    StoryPickerResult? result = await Navigator.of(context).push(
        PageTransition(
            child: Gallery(options),
            type: PageTransitionType.bottomToTop
        )
    );

    if (result != null) Navigator.pop(context, result);

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