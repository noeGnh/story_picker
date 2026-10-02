import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:story_picker/src/providers/camera_provider.dart';
import 'package:story_picker/src/widgets/camera.dart';
import 'package:story_picker/story_picker.dart';

class StoryPicker {
  static Future<StoryPickerResult?> pick(BuildContext context, {required PageTransitionType transitionType, Options? options}) async =>
      await Navigator.of(context).push(
        PageTransition(
          child: Picker(options: options),
          type: transitionType,
        ),
      );
}

class Picker extends StatelessWidget {
  final Options? options;

  const Picker({super.key, this.options});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CameraProvider>(
      create: (_) => CameraProvider(),
      child: PickerView(options: options),
    );
  }
}

class PickerView extends StatefulWidget {
  final Options? options;

  const PickerView({super.key, this.options});

  @override
  State<PickerView> createState() => _PickerViewState();
}

class _PickerViewState extends State<PickerView> {
  @override
  Widget build(BuildContext context) {
    return Camera(cameraOptions: widget.options);
  }
}
