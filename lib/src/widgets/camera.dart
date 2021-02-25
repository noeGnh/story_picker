import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:story_picker/src/models/options.dart';
import 'package:story_picker/src/providers/camera_provider.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:torch_compat/torch_compat.dart';

Options options;

class Camera extends StatefulWidget {

  Camera({Key key, @required Options cameraOptions}) : super(key: key) {
    options = cameraOptions;
  }

  @override
  _CameraState createState() => _CameraState();

}

class _CameraState extends State<Camera> {

  CameraProvider cameraProvider;

  @override
  void initState() {
    super.initState();

    cameraProvider =  Provider.of<CameraProvider>(context, listen: false);
    cameraProvider.getAvailableCameras(mounted);

    cameraProvider.translations = options.translations;
    cameraProvider.durationLimit = options.customizationOptions.videoDurationLimitInSeconds;
  }

  @override
  void dispose() {
    cameraProvider.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;

    return Consumer<CameraProvider>(
        builder: (ctx, provider, child){
          return Stack(
            children: <Widget>[
              CameraPreviewWidget(),
              cameraProvider.isRecordingVideo() ? Positioned(
                top: 28,
                child: Container(
                  width: size.width,
                  child: LinearProgressIndicator(
                    value: provider.getIndicatorProgress(),
                    valueColor: AlwaysStoppedAnimation<Color>(options.customizationOptions.cameraCustomization.videoCaptureProgressIndicatorColor),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ) : Container(),
              Positioned(
                top: 50,
                child: Container(
                    alignment: Alignment.center,
                    width: size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        options.settingsTarget != null ? SettingsIconWidget() : FlashToggleIconWidget(),
                        options.settingsTarget != null ? FlashToggleIconWidget() : Container(),
                        CloseIconWidget(),
                      ],
                    ),
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
                        child: CaptureControl(cameraProvider),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          GalleryIconWidget(),
                          TextIconWidget(),
                          CameraToggleIconWidget(mounted),
                        ],
                      ),
                    ],
                  )
                ),
              )
            ],
          );
        }
    );

  }

}

class CameraPreviewWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;

    CameraProvider cameraProvider =  Provider.of<CameraProvider>(context, listen: true);

    if (cameraProvider.controller == null || !cameraProvider.controller.value.isInitialized) {
      return Container(color: Colors.transparent);
    }

    var scale = size.aspectRatio * cameraProvider.controller.value.aspectRatio;

    if (scale < 1) scale = 1 / scale;

    return Transform.scale(
      scale: scale,
      child: Center(
        child: CameraPreview(cameraProvider.controller),
      ),
    );

  }
}

class GalleryIconWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    CameraProvider cameraProvider =  Provider.of<CameraProvider>(context, listen: true);

    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.only(left: 21),
        child: Icon(Icons.image, color: options.customizationOptions.cameraCustomization.iconsColor, size: 32,),
      ),
      onTap: (){
        cameraProvider.openGalleryScreen(context, options);
      },
    );

  }
}

class TextIconWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    CameraProvider cameraProvider =  Provider.of<CameraProvider>(context, listen: true);

    return GestureDetector(
      child: Icon(Icons.text_fields, color: options.customizationOptions.cameraCustomization.iconsColor, size: 32,),
      onTap: (){
        cameraProvider.openTextScreen(context, options);
      },
    );

  }
}

class CameraToggleIconWidget extends StatelessWidget {

  final bool mounted;

  IconData _getCameraLensIcon(CameraLensDirection direction) {
    switch (direction) {
      case CameraLensDirection.back:
        return Icons.camera_rear;
      case CameraLensDirection.front:
        return Icons.camera_front;
      case CameraLensDirection.external:
        return Icons.camera;
      default:
        return Icons.device_unknown;
    }
  }

  CameraToggleIconWidget(this.mounted);

  @override
  Widget build(BuildContext context) {

    CameraProvider cameraProvider =  Provider.of<CameraProvider>(context, listen: true);

    if (cameraProvider.cameras == null || cameraProvider.cameras.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(right: 21),
        child: Icon(_getCameraLensIcon(null), color: options.customizationOptions.cameraCustomization.iconsColor, size: 32,),
      );
    }

    CameraDescription selectedCamera = cameraProvider.cameras[cameraProvider.selectedCameraIdx];
    CameraLensDirection lensDirection = selectedCamera.lensDirection;

    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.only(right: 21),
        child: Icon(_getCameraLensIcon(lensDirection), color: options.customizationOptions.cameraCustomization.iconsColor, size: 32,),
      ),
      onTap: (){
        cameraProvider.onSwitchCamera(mounted);
      },
    );

  }
}

class SettingsIconWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    CameraProvider cameraProvider =  Provider.of<CameraProvider>(context, listen: true);

    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.only(left: 21),
        child: Icon(Icons.settings, color: options.customizationOptions.cameraCustomization.iconsColor, size: 32),
      ),
      onTap: (){
        cameraProvider.openSettingsScreen(context, options.settingsTarget);
      },
    );

  }
}

class FlashToggleIconWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    CameraProvider cameraProvider =  Provider.of<CameraProvider>(context, listen: true);

    IconData iconData;

    switch(cameraProvider.flashMode){
      case FlashMode.auto:  iconData = Icons.flash_auto; break;

      case FlashMode.torch: iconData = Icons.flash_on; break;

      default:  iconData = Icons.flash_off;
    }

    return FutureBuilder<bool>(
        future: TorchCompat.hasTorch,
        builder: (ctx, snapshot){

          return snapshot.hasData && snapshot.data
              ? GestureDetector(
                child: Padding(
                  padding: EdgeInsets.only(left: options.settingsTarget != null ? 0 : 21),
                  child: Icon(iconData, color: options.customizationOptions.cameraCustomization.iconsColor, size: 32,),
                ),
                onTap: (){
                  if (cameraProvider.controller != null && cameraProvider.controller.value.isInitialized){
                    cameraProvider.onFlashButtonPressed();
                  }
                },
              )
              : Spacer();

        }
    );

  }
}

class CloseIconWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.only(right: 21),
        child: Icon(Icons.close, color: options.customizationOptions.cameraCustomization.iconsColor, size: 32,),
      ),
      onTap: (){
        Navigator.pop(context, null);
      },
    );
  }
}

class CaptureControl extends StatefulWidget {
  final CameraProvider cameraProvider;

  CaptureControl(this.cameraProvider, {Key key}) : super(key: key);

  @override
  _CaptureControlState createState() => _CaptureControlState();
}

class _CaptureControlState extends State<CaptureControl> {

  final SuperTooltip superTooltip = SuperTooltip(
    popupDirection: TooltipDirection.up,
    borderRadius: 3.0,
    borderWidth: 0.0,
    hasShadow: false,
    content: Material(
      child: Text(
        options.translations.pressAndHoldToRecordAVideo,
        softWrap: true,
      ),
    ),
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {

      widget.cameraProvider.manageTooltip(context, superTooltip);

    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.cameraProvider.isRecordingVideo() ? Container(
          margin: EdgeInsets.only(bottom: 15),
          child: Text(
            "00:${widget.cameraProvider.showDuration()}",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: options.customizationOptions.cameraCustomization.iconsColor,
                decoration: TextDecoration.none,
                fontSize: 15
            ),
          ),
        ) : Container(),
        Stack(
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
                          color: options.customizationOptions.cameraCustomization.iconsColor
                      ),
                    ),
                    onLongPressStart: (d) => widget.cameraProvider.startVideoRecording(context, mounted),
                    onLongPressEnd: (d) => widget.cameraProvider.stopVideoRecording(context, mounted),
                    onTap: () => widget.cameraProvider.onCapturePressed(context, options),
                  ),
                )
            )

          ],
        )
      ],
    );
  }

}

