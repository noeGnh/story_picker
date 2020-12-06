import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_better_camera/camera.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:story_picker/src/models/file_model.dart';
import 'package:story_picker/src/models/options.dart';
import 'package:story_picker/src/models/result.dart';
import 'package:story_picker/src/widgets/gallery.dart';
import 'package:story_picker/src/widgets/preview/image_preview.dart';
import 'package:story_picker/src/widgets/text.dart' as textScreen;
import 'package:super_tooltip/super_tooltip.dart';

class CameraProvider extends ChangeNotifier{

  CameraController controller;
  int selectedCameraIdx;
  String imagePath;
  String videoPath;
  List cameras;

  Timer _timer;
  int _duration;
  int _durationLimit;

  FlashMode flashMode = FlashMode.off;

  Future<void> onFlashButtonPressed() async {
    switch (flashMode){
      case FlashMode.torch: flashMode = FlashMode.autoFlash; break;

      case FlashMode.off: flashMode = FlashMode.torch; break;

      default: flashMode = FlashMode.off;
    }

    await controller.setFlashMode(flashMode);

    notifyListeners();
  }

  void getAvailableCameras(bool mounted){

    Timer(const Duration(milliseconds: 500), (){

      availableCameras().then((availableCameras) {

        cameras = availableCameras;
        if (cameras.length > 0) {

          selectedCameraIdx = 0;

          notifyListeners();

          _initCameraController(cameras[selectedCameraIdx], mounted).then((void v) {});

        }else{
          print("No camera available");
        }
      }).catchError((e) {
        print('Error: $e.code\nError Message: $e.message');
      });

    });

  }

  Future _initCameraController(CameraDescription cameraDescription, bool mounted) async {
    if (controller != null) {
      await controller.dispose();
    }

    controller = CameraController(cameraDescription, ResolutionPreset.veryHigh);

    controller.addListener(() {

      if (mounted) {
        notifyListeners();
      }

      if (controller.value.hasError) {
        print('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      print(e);
    }

    if (mounted) {
      notifyListeners();
    }
  }

  void refreshCamera(bool mounted) {
    Future.delayed(Duration(milliseconds: 1000), () async {
      _initCameraController(cameras[0], mounted);
    });
  }

  void onSwitchCamera(bool mounted) {
    selectedCameraIdx = selectedCameraIdx < cameras.length - 1 ? selectedCameraIdx + 1 : 0;
    CameraDescription selectedCamera = cameras[selectedCameraIdx];
    _initCameraController(selectedCamera, mounted);
  }

  void onCapturePressed(context, options) async {

    try {

      final path = join((await getTemporaryDirectory()).path, '${DateTime.now()}.png',);

      await controller.takePicture(path);

      StoryPickerResult result = await Navigator.of(context).push(
          MaterialPageRoute(builder: (ctx) => ImagePreview(
              files: [FileModel(file: File(path), path: path, title: basename(path))],
              imagePreviewOptions: options,
              showAddButton: false,
            )
          )
      );

      if (result != null) Navigator.pop(context, result);

    } catch (e) {
      print(e);
    }

  }

  bool isRecordingVideo()
    => controller != null
    && controller.value.isInitialized
    && controller.value.isRecordingVideo;

  void startVideoRecording(BuildContext context, bool mounted) async {

    if (!controller.value.isInitialized) return null;

    final filePath = join((await getTemporaryDirectory()).path, '${DateTime.now()}.mp4',);

    if (controller.value.isRecordingVideo) return null;

    try {

      _startTimer(context, mounted);
      await controller.startVideoRecording(filePath);
      videoPath = filePath;

    } on CameraException catch (e) {

      print(e);
      videoPath = null;

    }

    if (mounted) notifyListeners();

  }

  void stopVideoRecording(BuildContext context, bool mounted) async {

    if (!controller.value.isRecordingVideo) return null;

    try {

      await controller.stopVideoRecording();
      cancelTimer();

    } on CameraException catch (e) {
      print(e);
    }

    if (mounted) notifyListeners();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {

        return AlertDialog(
          title: new Text('Vidéo enregistrée', style: TextStyle(fontWeight: FontWeight.bold),),
          content: new Text('Que voulez-vous faire ?'),
          actions: <Widget>[
            new FlatButton(
                child: new Text('Supprimer'),
                onPressed: (){
                  Navigator.of(context, rootNavigator: true).pop();
                }
            ),
            new FlatButton(
                child: new Text('Valider'),
                onPressed: (){

                  Navigator.of(context, rootNavigator: true).pop();

                  Navigator.pop(
                      context,
                      StoryPickerResult(
                          pickedFiles: [PickedFile(file: File(videoPath), path: videoPath, name: basename(videoPath))],
                          resultType: ResultType.VIDEO
                      )
                  );

                }
            ),
          ],
        );
      },
    );

  }

  void manageTooltip(BuildContext context, SuperTooltip tooltip){

    if (tooltip != null) {
      if (tooltip.isOpen){
        tooltip.close();
      }else {
        Future.delayed(const Duration(milliseconds: 1000), () {
          tooltip.show(context);
        });
        Future.delayed(const Duration(milliseconds: 4000), () {
          if (tooltip != null && tooltip.isOpen) tooltip.close();
        });
      }
    }

  }

  void _startTimer(BuildContext context, bool mounted) {

    _duration = 0;
    _timer = null;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      notifyListeners();
      if (_duration > _durationLimit) {

        stopVideoRecording(context, mounted);

      } else {
        _duration += 1;
      }
    },
    );

  }

  void cancelTimer(){
    if (_timer != null) _timer.cancel(); _timer = null;
    _duration = 0;
  }

  double getIndicatorProgress() {
    return _duration != null && _durationLimit != null ? _duration / _durationLimit : 0.0;
  }

  String showDuration() {
    if (_duration == null) return '00';

    return _duration.toString().length < 2 ? '0$_duration' : '$_duration';
  }

  set durationLimit(int d) { _durationLimit = d <= 59 ? d : 59; }

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

  openTextScreen(BuildContext context, Options options) async {

    StoryPickerResult result = await Navigator.of(context).push(
        PageTransition(
            child: textScreen.Text(options),
            type: PageTransitionType.bottomToTop
        )
    );

    if (result != null) Navigator.pop(context, result);

  }

}