import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:story_picker/src/models/result.dart';
import 'package:story_picker/src/providers/camera_provider.dart';
import 'package:story_picker/src/providers/picker_provider.dart';
import 'package:story_picker/src/widgets/camera.dart';
import 'package:story_picker/story_picker.dart';

class StoryPicker{

  static Future<StoryPickerResult?> pick(
      BuildContext context,
      {
        required PageTransitionType transitionType,
        Options? options
      }
  ) async
  => await Navigator.of(context).push(
      PageTransition(
          child: Picker(options: options),
          type: transitionType
      )
  );

}

class Picker extends StatelessWidget {

  final Options? options;

  Picker({this.options});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PickerProvider>(create: (_) => PickerProvider()),
        ChangeNotifierProvider<CameraProvider>(create: (_) => CameraProvider()),
      ],
      child: PickerView(options: options),
    );
  }

}

class PickerView extends StatefulWidget {

  final Options? options;

  PickerView({Key? key, this.options}) : super(key: key);

  @override
  _PickerViewState createState() => _PickerViewState();

}

class _PickerViewState extends State<PickerView> {
  @override
  Widget build(BuildContext context) {
    return Camera(cameraOptions : widget.options);
  }
}

