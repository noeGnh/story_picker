import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:page_transition/page_transition.dart';
import 'package:story_picker/src/models/bg_model.dart';
import 'package:story_picker/src/models/options.dart';
import 'package:story_picker/src/models/result.dart';
import 'package:story_picker/src/widgets/gallery.dart';

class TextProvider extends ChangeNotifier{

  final fonts = [
    'FreightSans',
    'MADECanvas',
    'ProximaNova',
    'AvenyT',
    'Montserrat',
    'OpenSans'
  ];

  final textAlignments = [
    TextAlign.center,
    TextAlign.left,
    TextAlign.right
  ];

  final textBackgrounds = [
    BgModel(
        linearGradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          stops: [0.1, 0.5, 0.8, 0.9],
          colors: [Colors.red, Colors.yellow, Colors.blue, Colors.purple]
        ),
        hintColor: Colors.black87,
        textColor: Colors.black
    ),
    BgModel(
        linearGradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.purple, Colors.blue]
        ),
        hintColor: Colors.black87,
        textColor: Colors.black
    ),
    BgModel(
        linearGradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.yellow, Colors.deepPurple]
        ),
        hintColor: Colors.black87,
        textColor: Colors.black
    ),
    BgModel(
        linearGradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.red, Colors.orange]
        ),
        hintColor: Colors.black87,
        textColor: Colors.black
    ),
    BgModel(
        linearGradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.yellow, Colors.green,Colors.blue]
        ),
        hintColor: Colors.black87,
        textColor: Colors.black
    )
  ];

  TextEditingController textEditingController;
  int textFontIndex, textAlignIndex, textBgIndex;
  KeyboardVisibilityController keyboardVisibilityController;

  init(){
    textBgIndex = 0;
    textFontIndex = 0;
    textAlignIndex = 0;
    textEditingController = TextEditingController();
    keyboardVisibilityController = KeyboardVisibilityController();
  }
  
  switchTextFont(){
    if (textFontIndex + 1 >= fonts.length) {
      textFontIndex = 0;
    }else{
      textFontIndex++;
    }

    notifyListeners();
  }
  
  switchTextAlign(){
    if (textAlignIndex + 1 >= textAlignments.length) {
      textAlignIndex = 0;
    }else{
      textAlignIndex++;
    }

    notifyListeners();
  }

  switchTextBackground(){
    if (textBgIndex + 1 >= textBackgrounds.length) {
      textBgIndex = 0;
    }else{
      textBgIndex++;
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

  openGalleryScreen(BuildContext context, Options options) async {

    StoryPickerResult result = await Navigator.of(context).push(
        PageTransition(
            child: Gallery(options),
            type: PageTransitionType.bottomToTop
        )
    );

    if (result != null) Navigator.pop(context, result);

  }

  submit(BuildContext context) {

    if (textEditingController.text.isEmpty) return;

    Navigator.pop(
        context,
        StoryPickerResult(
            storyText: StoryText(
              font: fonts[textFontIndex],
              text: textEditingController.text,
              align: textAlignments[textAlignIndex],
              color: textBackgrounds[textBgIndex].textColor,
              linearGradient: textBackgrounds[textBgIndex].linearGradient,
            ),
            resultType: ResultType.TEXT
        )
    );

  }

}