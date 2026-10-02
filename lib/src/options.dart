import 'package:flutter/material.dart';

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
}

/// Colors used across the picker screens.
@immutable
class StoryPickerTheme {
  const StoryPickerTheme({
    this.accentColor = Colors.black,
    this.overlayIconColor = Colors.white,
    this.recordingColor = Colors.red,
    this.previewBackgroundColor = Colors.white,
    this.previewForegroundColor = Colors.black,
  });

  /// Progress indicators and trimmer handles.
  final Color accentColor;

  /// Icons drawn over the camera preview and the text story background.
  final Color overlayIconColor;

  /// Video recording progress bar.
  final Color recordingColor;

  /// Background of the preview screens and their app bar.
  final Color previewBackgroundColor;

  /// Icons and title of the preview screens.
  final Color previewForegroundColor;
}

/// User-facing strings. [StoryPickerTranslations.fr] provides French.
@immutable
class StoryPickerTranslations {
  const StoryPickerTranslations({
    this.preview = 'Preview',
    this.pressToWrite = 'Press to write',
    this.pressAndHoldToRecord = 'Press and hold to record a video',
    this.filters = 'Filters',
    this.save = 'Save',
    this.cancel = 'Cancel',
    this.recordedVideo = 'Recorded video',
    this.whatDoYouWantToDo = 'What do you want to do?',
    this.delete = 'Delete',
    this.validate = 'Validate',
    this.cameraUnavailable = 'Camera unavailable. Check that the app is allowed to use it.',
  });

  static const fr = StoryPickerTranslations(
    preview: 'Aperçu',
    pressToWrite: 'Appuyez pour écrire',
    pressAndHoldToRecord: 'Maintenez pour filmer',
    filters: 'Filtres',
    save: 'Enregistrer',
    cancel: 'Annuler',
    recordedVideo: 'Vidéo enregistrée',
    whatDoYouWantToDo: 'Que voulez-vous faire ?',
    delete: 'Supprimer',
    validate: 'Valider',
    cameraUnavailable: "Caméra indisponible. Vérifiez que l'application a le droit de l'utiliser.",
  );

  final String preview;
  final String pressToWrite;
  final String pressAndHoldToRecord;
  final String filters;
  final String save;
  final String cancel;
  final String recordedVideo;
  final String whatDoYouWantToDo;
  final String delete;
  final String validate;
  final String cameraUnavailable;
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
