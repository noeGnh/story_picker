import 'package:material_ui/material_ui.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

/// Configuration of a [StoryPicker.pick] session.
@immutable
class StoryPickerOptions {
  const StoryPickerOptions({
    this.theme = const StoryPickerTheme(),
    this.translations = const StoryPickerTranslations(),
    this.maxVideoDuration = const Duration(seconds: 15),
    this.enableTextStories = true,
    this.textFonts = const [],
    this.textBackgrounds = StoryBackground.defaults,
    this.settingsBuilder,
    this.editorConfigs = const ProImageEditorConfigs(),
  });

  final StoryPickerTheme theme;
  final StoryPickerTranslations translations;

  /// Longest video the camera records and the trimmer keeps.
  final Duration maxVideoDuration;

  /// Shows the text story entry point on the camera screen.
  final bool enableTextStories;

  /// Font families the text screen cycles through. They must be declared by
  /// the host app. When empty, the theme's default font is used and the font
  /// switch button is hidden.
  final List<String> textFonts;

  /// Backgrounds the text screen cycles through. [StoryBackground.defaults]
  /// is used when empty.
  final List<StoryBackground> textBackgrounds;

  /// Builds the screen opened by the settings button. The button is hidden
  /// when null.
  final WidgetBuilder? settingsBuilder;

  /// Base configuration of the photo and video editors (pro_image_editor):
  /// translations through `i18n`, theme, available tools… The video editor
  /// adds its own trim limits and drops the tools videos do not support.
  final ProImageEditorConfigs editorConfigs;
}

/// Colors used across the picker screens.
@immutable
class StoryPickerTheme {
  const StoryPickerTheme({this.accentColor = Colors.black, this.overlayIconColor = Colors.white, this.recordingColor = Colors.red});

  /// Progress indicators.
  final Color accentColor;

  /// Icons drawn over the camera preview and the text story background.
  final Color overlayIconColor;

  /// Video recording progress bar.
  final Color recordingColor;
}

/// User-facing strings of the camera and text screens. [StoryPickerTranslations.fr]
/// provides French. The editors are translated through
/// [StoryPickerOptions.editorConfigs].
@immutable
class StoryPickerTranslations {
  const StoryPickerTranslations({
    this.pressToWrite = 'Press to write',
    this.pressAndHoldToRecord = 'Press and hold to record a video',
    this.cameraUnavailable = 'Camera unavailable. Check that the app is allowed to use it.',
    this.videoExportFailed = 'The video could not be exported. Please try again.',
  });

  static const fr = StoryPickerTranslations(
    pressToWrite: 'Appuyez pour écrire',
    pressAndHoldToRecord: 'Maintenez pour filmer',
    cameraUnavailable: "Caméra indisponible. Vérifiez que l'application a le droit de l'utiliser.",
    videoExportFailed: "La vidéo n'a pas pu être exportée. Veuillez réessayer.",
  );

  final String pressToWrite;
  final String pressAndHoldToRecord;
  final String cameraUnavailable;
  final String videoExportFailed;
}

/// Background of a text story.
@immutable
class StoryBackground {
  const StoryBackground({required this.gradient, this.textColor = Colors.black, this.hintColor = Colors.black87});

  final Gradient gradient;
  final Color textColor;
  final Color hintColor;

  static const defaults = [
    StoryBackground(
      gradient: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        stops: [0.1, 0.5, 0.8, 0.9],
        colors: [Colors.red, Colors.yellow, Colors.blue, Colors.purple],
      ),
    ),
    StoryBackground(gradient: LinearGradient(colors: [Colors.purple, Colors.blue])),
    StoryBackground(gradient: LinearGradient(colors: [Colors.yellow, Colors.deepPurple])),
    StoryBackground(gradient: LinearGradient(colors: [Colors.red, Colors.orange])),
    StoryBackground(gradient: LinearGradient(colors: [Colors.yellow, Colors.green, Colors.blue])),
  ];
}
