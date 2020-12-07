import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';
import 'package:story_picker/src/providers/text_provider.dart';
import 'package:story_picker/src/utils/constants.dart';
import 'package:story_picker/story_picker.dart';

Options options;

class Text extends StatelessWidget {

  Text(Options opt){ options = opt; }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TextProvider>(
      create: (_) => TextProvider(),
      child: TextView(),
    );
  }

}

class TextView extends StatefulWidget {
  @override
  _TextViewState createState() => _TextViewState();
}

class _TextViewState extends State<TextView> {

  TextProvider textProvider;

  @override
  void initState() {
    super.initState();

    textProvider = Provider.of<TextProvider>(context, listen: false);
    textProvider.init();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _textPreviewWidget(Size size, num deviceRatio, bool isKeyboardVisible) {

    return Container(
        decoration: BoxDecoration(
            gradient: StoryConstants.textBackgrounds[textProvider.textBgIndex].linearGradient
        ),
        child: Container(
          alignment: isKeyboardVisible ? Alignment.topCenter : Alignment.center,
          padding: EdgeInsets.only(left: 16, right: 16, top: isKeyboardVisible ? 100 : 0),
          child: Material(
            color: Colors.transparent,
            child: AutoSizeTextField(
              controller: textProvider.textEditingController,
              style: TextStyle(
                fontSize: 30,
                fontFamily: StoryConstants.fonts[textProvider.textFontIndex],
                color: StoryConstants.textBackgrounds[textProvider.textBgIndex].textColor,
              ),
              textAlign: StoryConstants.textAlignments[textProvider.textAlignIndex],
              minFontSize: 16,
              minLines: 1,
              maxLines: 16,
              maxLength: 700,
              decoration: InputDecoration(
                border: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintStyle: TextStyle(
                  fontFamily: StoryConstants.fonts[textProvider.textFontIndex],
                  color: StoryConstants.textBackgrounds[textProvider.textBgIndex].hintColor,
                ),
                hintText: "Appuyez pour écrire",
              ),
            )
          ),
        )
    );

  }

  Widget _hiddenKeyboardTopRow(){

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        options.settingsTarget != null ? _settingsIconWidget() : Container(),
        Container(),
        _closeIconWidget(),
      ],
    );

  }

  Widget _visibleKeyboardTopRow(){

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        _textAlignIconWidget(),
        _textFontIconWidget(),
        _validateIconWidget(),
      ],
    );

  }

  Widget _validateIconWidget(){

    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.only(right: 21),
        child: Icon(Icons.check, color: options.customizationOptions.textCustomization.iconsColor, size: 32,),
      ),
      onTap: (){
        textProvider.submit(context);
      },
    );

  }

  Widget _textFontIconWidget(){

    return GestureDetector(
      child: Icon(Icons.font_download, color: options.customizationOptions.textCustomization.iconsColor, size: 32,),
      onTap: (){
        textProvider.switchTextFont();
      },
    );

  }

  Widget _textAlignIconWidget(){

    IconData alignIcon;

    switch(textProvider.textAlignIndex){
      case 0:
        alignIcon = Icons.format_align_center;
        break;

      case 1:
        alignIcon = Icons.format_align_left;
        break;

      case 2:
        alignIcon = Icons.format_align_right;
        break;
    }

    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.only(left: 21),
        child: Icon(alignIcon, color: options.customizationOptions.textCustomization.iconsColor, size: 32,),
      ),
      onTap: (){
        textProvider.switchTextAlign();
      },
    );

  }

  Widget _settingsIconWidget(){

    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.only(left: 21),
        child: Icon(Icons.settings, color: options.customizationOptions.textCustomization.iconsColor, size: 32,),
      ),
      onTap: (){
        textProvider.openSettingsScreen(context, options.settingsTarget);
      },
    );

  }

  Widget _closeIconWidget(){

    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.only(right: 21),
        child: Icon(Icons.close, color: options.customizationOptions.textCustomization.iconsColor, size: 32,),
      ),
      onTap: (){
        Navigator.pop(context, null);
      },
    );

  }

  Widget _captureControlWidget(context) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              border: Border.all(color: Colors.white, width: 5)
          ),
        ),
        Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: GestureDetector(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: options.customizationOptions.textCustomization.iconsColor
                  ),
                ),
                onTap: (){
                  textProvider.submit(context);
                },
              ),
            )
        )

      ],
    );
  }

  Widget _galleryIconWidget(){

    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.only(left: 21),
        child: Icon(Icons.image, color: options.customizationOptions.textCustomization.iconsColor, size: 32,),
      ),
      onTap: (){
        textProvider.openGalleryScreen(context, options);
      },
    );

  }

  Widget _bgColorChangeIconWidget(){

    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.only(right: 21),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
              gradient: StoryConstants.textBackgrounds[textProvider.textBgIndex].linearGradient
          ),
        )
      ),
      onTap: (){
        textProvider.switchTextBackground();
      },
    );

  }

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;

    return Consumer<TextProvider>(
        builder: (ctx, provider, child){

          return KeyboardVisibilityBuilder(
            builder: (context, isKeyboardVisible){

              return KeyboardDismissOnTap(
                child: Stack(
                  children: <Widget>[
                    _textPreviewWidget(size, deviceRatio, isKeyboardVisible),
                    Positioned(
                      top: 50,
                      child: Container(
                        alignment: Alignment.center,
                        width: size.width,
                        child: isKeyboardVisible ? _visibleKeyboardTopRow() : _hiddenKeyboardTopRow()
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      child: Container(
                          alignment: Alignment.center,
                          width: size.width,
                          child: Column(
                            children: [
                              Center(
                                child: _captureControlWidget(context),
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  _galleryIconWidget(),
                                  Container(),
                                  _bgColorChangeIconWidget(),
                                ],
                              )
                            ],
                          )
                      ),
                    )
                  ],
                ),
              );

            },
          );

        }
    );

  }

}
