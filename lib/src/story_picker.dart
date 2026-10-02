import 'package:flutter/widgets.dart';

import 'camera/camera_screen.dart';
import 'options.dart';
import 'result.dart';
import 'scope.dart';

abstract final class StoryPicker {
  /// Opens the story camera and returns what the user created, or null when
  /// they closed the picker.
  static Future<StoryPickerResult?> pick(BuildContext context, {StoryPickerOptions options = const StoryPickerOptions()}) {
    return Navigator.of(context).push(storyRoute(options, const CameraScreen()));
  }
}
