import 'package:flutter/material.dart';
import 'package:flutter_better_camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:story_picker/src/models/options.dart';
import 'package:story_picker/src/providers/camera_provider.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:torch_compat/torch_compat.dart';

class Camera extends StatefulWidget {

  final Options options;

  Camera({Key key, this.options}) : super(key: key);

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

    cameraProvider.durationLimit = widget.options.customizationOptions.videoDurationLimitInSeconds;
  }

  @override
  void dispose() {
    super.dispose();
  }

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

  Widget _cameraPreviewWidget(Size size, num deviceRatio) {

    if (cameraProvider.controller == null || !cameraProvider.controller.value.isInitialized) {
      return Container(color: Colors.transparent);
    }

    return Transform.scale(
      scale: cameraProvider.controller.value.aspectRatio / deviceRatio,
      child: Center(
        child: AspectRatio(
          aspectRatio: cameraProvider.controller.value.aspectRatio,
          child: CameraPreview(cameraProvider.controller),
        ),
      ),
    );

  }

  Widget _galleryIconWidget(){

    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.only(left: 21),
        child: Icon(Icons.image, color: widget.options.customizationOptions.cameraCustomization.iconsColor, size: 32,),
      ),
      onTap: (){
        cameraProvider.openGalleryScreen(context, widget.options);
      },
    );

  }

  Widget _textIconWidget(){

    return GestureDetector(
      child: Icon(Icons.text_fields, color: widget.options.customizationOptions.cameraCustomization.iconsColor, size: 32,),
      onTap: (){
        cameraProvider.openTextScreen(context, widget.options);
      },
    );

  }

  Widget _cameraToggleIconWidget() {
    if (cameraProvider.cameras == null || cameraProvider.cameras.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(right: 21),
        child: Icon(_getCameraLensIcon(null), color: widget.options.customizationOptions.cameraCustomization.iconsColor, size: 32,),
      );
    }

    CameraDescription selectedCamera = cameraProvider.cameras[cameraProvider.selectedCameraIdx];
    CameraLensDirection lensDirection = selectedCamera.lensDirection;

    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.only(right: 21),
        child: Icon(_getCameraLensIcon(lensDirection), color: widget.options.customizationOptions.cameraCustomization.iconsColor, size: 32,),
      ),
      onTap: (){
        cameraProvider.onSwitchCamera(mounted);
      },
    );
  }

  Widget _settingsIconWidget(){

    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.only(left: 21),
        child: Icon(Icons.settings, color: widget.options.customizationOptions.cameraCustomization.iconsColor, size: 32,),
      ),
      onTap: (){
        cameraProvider.openSettingsScreen(context, widget.options.settingsTarget);
      },
    );

  }

  Widget _flashToggleIconWidget() {

    IconData iconData;

    switch(cameraProvider.flashMode){
      case FlashMode.autoFlash:  iconData = Icons.flash_auto; break;

      case FlashMode.torch: iconData = Icons.flash_on; break;

      default:  iconData = Icons.flash_off;
    }

    return FutureBuilder<bool>(
        future: TorchCompat.hasTorch,
        builder: (ctx, snapshot){

          return snapshot.hasData && snapshot.data
              ? GestureDetector(
                  child: Padding(
                    padding: EdgeInsets.only(left: widget.options.settingsTarget != null ? 0 : 21),
                    child: Icon(iconData, color: widget.options.customizationOptions.cameraCustomization.iconsColor, size: 32,),
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

  Widget _closeIconWidget(){

    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.only(right: 21),
        child: Icon(Icons.close, color: widget.options.customizationOptions.cameraCustomization.iconsColor, size: 32,),
      ),
      onTap: (){
        Navigator.pop(context, null);
      },
    );

  }

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;

    return Consumer<CameraProvider>(
        builder: (ctx, provider, child){
          return Stack(
            children: <Widget>[
              _cameraPreviewWidget(size, deviceRatio),
              cameraProvider.isRecordingVideo() ? Positioned(
                top: 28,
                child: Container(
                  width: size.width,
                  child: LinearProgressIndicator(
                    value: provider.getIndicatorProgress(),
                    valueColor: AlwaysStoppedAnimation<Color>(widget.options.customizationOptions.cameraCustomization.videoCaptureProgressIndicatorColor),
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
                        widget.options.settingsTarget != null ? _settingsIconWidget() : _flashToggleIconWidget(),
                        widget.options.settingsTarget != null ? _flashToggleIconWidget() : Container(),
                        _closeIconWidget(),
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
                        child: CaptureControl(cameraProvider, widget.options),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          _galleryIconWidget(),
                          _textIconWidget(),
                          _cameraToggleIconWidget(),
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

class CaptureControl extends StatefulWidget {
  final CameraProvider cameraProvider;
  final Options options;

  CaptureControl(this.cameraProvider, this.options, {Key key}) : super(key: key);

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
        "Appuyez longuement pour enregistrer une vidéo",
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
                color: widget.options.customizationOptions.cameraCustomization.iconsColor,
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
                          color: widget.options.customizationOptions.cameraCustomization.iconsColor
                      ),
                    ),
                    onLongPressStart: (d) => widget.cameraProvider.startVideoRecording(context, mounted),
                    onLongPressEnd: (d) => widget.cameraProvider.stopVideoRecording(context, mounted),
                    onTap: () => widget.cameraProvider.onCapturePressed(context, widget.options),
                  ),
                )
            )

          ],
        )
      ],
    );
  }

}

