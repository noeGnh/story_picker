import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:page_transition/page_transition.dart';
import 'package:story_picker/src/models/options.dart';
import 'package:story_picker/src/models/result.dart';
import 'package:story_picker/src/utils/media_picker.dart';
import 'package:story_picker/src/utils/constants.dart';
import 'package:story_picker/src/utils/utils.dart';

class TextProvider extends ChangeNotifier {
  TextEditingController? textEditingController;
  int? textFontIndex, textAlignIndex, textBgIndex;
  KeyboardVisibilityController? keyboardVisibilityController;

  void init() {
    textBgIndex = 0;
    textFontIndex = 0;
    textAlignIndex = 0;
    textEditingController = TextEditingController();
    keyboardVisibilityController = KeyboardVisibilityController();
  }

  void switchTextFont() {
    if (textFontIndex! + 1 >= StoryConstants.fonts.length) {
      textFontIndex = 0;
    } else {
      textFontIndex = textFontIndex! + 1;
    }

    notifyListeners();
  }

  void switchTextAlign() {
    if (textAlignIndex! + 1 >= StoryConstants.textAlignments.length) {
      textAlignIndex = 0;
    } else {
      textAlignIndex = textAlignIndex! + 1;
    }

    notifyListeners();
  }

  void switchTextBackground() {
    if (textBgIndex! + 1 >= StoryConstants.textBackgrounds.length) {
      textBgIndex = 0;
    } else {
      textBgIndex = textBgIndex! + 1;
    }

    notifyListeners();
  }

  Future<void> openSettingsScreen(BuildContext context, dynamic target) async {
    await Navigator.of(context).push(PageTransition(child: target, type: PageTransitionType.leftToRight));
  }

  Future<void> openGalleryScreen(BuildContext context, Options? options) => pickMediaAndPreview(context, options);

  void submit(BuildContext context) {
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
          linearGradientIndex: textBgIndex,
        ),
        resultType: ResultType.TEXT,
      ),
    );
  }
}
