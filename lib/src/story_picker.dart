import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/cupertino.dart' as legacy_cupertino;
import 'package:flutter/material.dart' as legacy;
import 'package:flutter_localizations/flutter_localizations.dart' as legacy_l10n;
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
  /// and package:cupertino_ui, and the copies still in package:flutter have
  /// their own localization types. The editors use the new libraries, some
  /// dependencies still use the old ones, so both sets are needed whichever
  /// one your app uses.
  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    cupertino.GlobalCupertinoLocalizations.delegate,
    legacy_l10n.GlobalWidgetsLocalizations.delegate,
    legacy_l10n.GlobalMaterialLocalizations.delegate,
    legacy_l10n.GlobalCupertinoLocalizations.delegate,
  ];

  /// Opens the story camera and returns what the user created, or null when
  /// they closed the picker.
  static Future<StoryPickerResult?> pick(BuildContext context, {StoryPickerOptions options = const StoryPickerOptions()}) {
    assert(_hasLocalizations(context), _missingLocalizations);
    return Navigator.of(context).push(storyRoute(options, const CameraScreen()));
  }

  static bool _hasLocalizations(BuildContext context) =>
      Localizations.of<MaterialLocalizations>(context, MaterialLocalizations) != null &&
      Localizations.of<cupertino.CupertinoLocalizations>(context, cupertino.CupertinoLocalizations) != null &&
      Localizations.of<legacy.MaterialLocalizations>(context, legacy.MaterialLocalizations) != null &&
      Localizations.of<legacy_cupertino.CupertinoLocalizations>(context, legacy_cupertino.CupertinoLocalizations) != null;

  static const _missingLocalizations =
      'story_picker: localizations are missing. Add StoryPicker.localizationsDelegates to '
      'your MaterialApp: MaterialApp(localizationsDelegates: StoryPicker.localizationsDelegates, ...).';
}
