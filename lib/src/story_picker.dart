import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizations;
import 'package:material_ui/material_ui.dart';

import 'camera/camera_screen.dart';
import 'options.dart';
import 'result.dart';
import 'scope.dart';

abstract final class StoryPicker {
  /// Localizations the picker and its editors need. Add them to your app:
  ///
  /// ```dart
  /// MaterialApp(localizationsDelegates: StoryPicker.localizationsDelegates, ...)
  /// ```
  ///
  /// Since Flutter 3.47 Material and Cupertino live in package:material_ui
  /// and package:cupertino_ui, with their own localization types: the
  /// delegates of package:flutter_localizations do not cover them, even in an
  /// app that still uses package:flutter/material.dart.
  static const localizationsDelegates = GlobalMaterialLocalizations.delegates;

  /// Opens the story camera and returns what the user created, or null when
  /// they closed the picker.
  static Future<StoryPickerResult?> pick(BuildContext context, {StoryPickerOptions options = const StoryPickerOptions()}) {
    assert(_hasLocalizations(context), _missingLocalizations);
    return Navigator.of(context).push(storyRoute(options, const CameraScreen()));
  }

  static bool _hasLocalizations(BuildContext context) =>
      Localizations.of<MaterialLocalizations>(context, MaterialLocalizations) != null &&
      Localizations.of<CupertinoLocalizations>(context, CupertinoLocalizations) != null;

  static const _missingLocalizations =
      'story_picker: localizations are missing. Add StoryPicker.localizationsDelegates to '
      'your MaterialApp: MaterialApp(localizationsDelegates: StoryPicker.localizationsDelegates, ...).';
}
