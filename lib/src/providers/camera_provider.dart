import 'dart:async';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:logger/logger.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path/path.dart';
import 'package:story_picker/src/models/file_model.dart';
import 'package:story_picker/src/models/options.dart';
import 'package:story_picker/src/models/result.dart';
import 'package:story_picker/src/widgets/preview/image_preview.dart';
import 'package:story_picker/src/widgets/preview/video_preview.dart';
import 'package:story_picker/src/widgets/text.dart' as textScreen;

class CameraProvider extends ChangeNotifier {
  final Logger logger = Logger();

  CameraController? controller;
  late int selectedCameraIdx;
  String? imagePath;
  String? videoPath;
  List? cameras;

  Timer? _timer;
  int? _duration;
  int? _durationLimit;

  late Translations _translations;

  set translations(Translations translations) {
    this._translations = translations;
  }

  FlashMode flashMode = FlashMode.off;

  Future<void> onFlashButtonPressed() async {
    switch (flashMode) {
      case FlashMode.torch:
        flashMode = FlashMode.auto;
        break;

      case FlashMode.off:
        flashMode = FlashMode.torch;
        break;

      default:
        flashMode = FlashMode.off;
    }

    await controller!.setFlashMode(flashMode);

    notifyListeners();
  }

  void getAvailableCameras(bool mounted) {
    Timer(const Duration(milliseconds: 500), () {
      availableCameras().then((availableCameras) {
        cameras = availableCameras;
        if (cameras!.length > 0) {
          selectedCameraIdx = 0;

          notifyListeners();

          _initCameraController(cameras![selectedCameraIdx], mounted).then((void v) {});
        } else {
          logger.w("No camera available");
        }
      }).catchError((e) {
        logger.e('Error: ${e.code}\nError Message: ${e.message}');
      });
    });
  }

  Future _initCameraController(CameraDescription cameraDescription, bool mounted) async {
    if (controller != null) {
      await controller!.dispose();
    }

    controller = CameraController(cameraDescription, ResolutionPreset.high);

    controller!.addListener(() {
      if (mounted) {
        notifyListeners();
      }

      if (controller!.value.hasError) {
        logger.e('Camera error ${controller!.value.errorDescription}');
      }
    });

    try {
      await controller!.initialize();
    } on CameraException catch (e) {
      logger.e(e);
    }

    if (mounted) {
      notifyListeners();
    }
  }

  void refreshCamera(bool mounted) {
    Future.delayed(Duration(milliseconds: 1000), () async {
      _initCameraController(cameras![0], mounted);
    });
  }

  void onSwitchCamera(bool mounted) {
    selectedCameraIdx = selectedCameraIdx < cameras!.length - 1 ? selectedCameraIdx + 1 : 0;
    CameraDescription selectedCamera = cameras![selectedCameraIdx];
    _initCameraController(selectedCamera, mounted);
  }

  void onCapturePressed(context, options) async {
    try {
      String? path;

      await controller!.takePicture().then((XFile file) {
        path = file.path;
      });

      StoryPickerResult? result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => ImagePreview(
            files: [FileModel(filePath: path, title: basename(path!))],
            imagePreviewOptions: options,
            showAddButton: false,
          ),
        ),
      );

      if (result != null) Navigator.pop(context, result);
    } catch (e) {
      logger.e(e);
    }
  }

  bool isRecordingVideo() => controller != null && controller!.value.isInitialized && controller!.value.isRecordingVideo;

  void startVideoRecording(BuildContext context, bool mounted) async {
    if (!controller!.value.isInitialized) return null;

    if (controller!.value.isRecordingVideo) return null;

    try {
      _startTimer(context, mounted);
      await controller!.startVideoRecording();
    } on CameraException catch (e) {
      logger.e(e);
      videoPath = null;
    }

    if (mounted) notifyListeners();
  }

  void stopVideoRecording(BuildContext context, bool mounted) async {
    if (!controller!.value.isRecordingVideo) return null;

    try {
      await controller!.stopVideoRecording().then((XFile file) {
        videoPath = file.path;
      });

      cancelTimer();
    } on CameraException catch (e) {
      logger.e(e);
    }

    if (mounted) notifyListeners();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text(
            this._translations.recordedVideo,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: new Text(this._translations.whatDoYouWantToDo),
          actions: <Widget>[
            new TextButton(
              child: new Text(this._translations.delete),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
            new TextButton(
              child: new Text(this._translations.validate),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();

                Navigator.pop(
                  context,
                  StoryPickerResult(
                    pickedFiles: [PickedFile(path: videoPath, name: basename(videoPath!))],
                    resultType: ResultType.VIDEO,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void manageTooltip(JustTheController tooltip) {
    if (tooltip.value == TooltipStatus.isShowing) {
      tooltip.hideTooltip();
    } else {
      Future.delayed(const Duration(milliseconds: 1000), () {
        tooltip.showTooltip(immediately: false);
      });
      Future.delayed(const Duration(milliseconds: 5000), () {
        if (tooltip.value == TooltipStatus.isShowing) tooltip.hideTooltip();
      });
    }
  }

  void _startTimer(BuildContext context, bool mounted) {
    _duration = 0;
    _timer = null;

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        notifyListeners();
        if (_duration! >= _durationLimit!) {
          stopVideoRecording(context, mounted);
        } else {
          _duration = _duration! + 1;
        }
      },
    );
  }

  void cancelTimer() {
    if (_timer != null) _timer!.cancel();
    _timer = null;
    _duration = 0;
  }

  double getIndicatorProgress() {
    return _duration != null && _durationLimit != null ? _duration! / _durationLimit! : 0.0;
  }

  String showDuration() {
    if (_duration == null) return '00';

    return _duration.toString().length < 2 ? '0$_duration' : '$_duration';
  }

  set durationLimit(int d) {
    _durationLimit = d <= 60 ? d : 60;
  }

  openSettingsScreen(BuildContext context, dynamic target) async {
    await Navigator.of(context).push(PageTransition(
      child: target,
      type: PageTransitionType.leftToRight,
    ));
  }

  openGalleryScreen(BuildContext context, Options? options) async {
    const imgExtensions = ['jpg', 'png', 'jpeg', 'gif', 'webp'];
    const vidExtensions = ['mp4', 'mkv', 'mov', 'wmv', 'flv', 'avi', 'webm'];

    FilePickerResult? pickedResult = await FilePicker.platform.pickFiles(
      type: FileType.media,
    );

    if (pickedResult != null) {
      StoryPickerResult? result;

      if (imgExtensions.contains(extension(pickedResult.files.single.path!).substring(1).toLowerCase())) {
        result = await Navigator.of(context).push(
          PageTransition(
            child: ImagePreview(
              files: [
                FileModel(
                  filePath: pickedResult.files.single.path!,
                  relativePath: pickedResult.files.single.path!,
                  thumbPath: pickedResult.files.single.path!,
                  title: basename(pickedResult.files.single.path!),
                ),
              ],
              imagePreviewOptions: options,
              showAddButton: options!.customizationOptions.galleryCustomization.maxSelectable > 1,
            ),
            type: PageTransitionType.bottomToTop,
          ),
        );
      } else if (vidExtensions.contains(extension(pickedResult.files.single.path!).substring(1).toLowerCase())) {
        result = await Navigator.of(context).push(
          PageTransition(
            child: VideoPreview(
              files: [
                FileModel(
                  filePath: pickedResult.files.single.path!,
                  relativePath: pickedResult.files.single.path!,
                  thumbPath: pickedResult.files.single.path!,
                  title: basename(pickedResult.files.single.path!),
                )
              ],
              imagePreviewOptions: options,
            ),
            type: PageTransitionType.bottomToTop,
          ),
        );
      }

      if (result != null) Navigator.pop(context, result);
    }
  }

  openTextScreen(BuildContext context, Options? options) async {
    StoryPickerResult? result = await Navigator.of(context).push(
      PageTransition(
        child: textScreen.Text(options),
        type: PageTransitionType.bottomToTop,
      ),
    );

    if (result != null) Navigator.pop(context, result);
  }
}
