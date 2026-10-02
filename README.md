# story_picker

A story-style capture flow for Flutter apps: full-screen camera (tap for a photo, press and hold for a video), text stories on a colored background and the system media picker. Photos and videos then open in an editor (text, drawing, emojis, filters, crop, trim) powered by [pro_image_editor](https://pub.dev/packages/pro_image_editor) and [pro_video_editor](https://pub.dev/packages/pro_video_editor), and the result goes back to your app.

Requires Flutter 3.47 or later. Android `minSdk` 24.

## Install

The package is not published on pub.dev. Add it from Git:

```yaml
dependencies:
  story_picker:
    git:
      url: https://github.com/noeGnh/story_picker.git
      ref: master
```

### Android

Add the camera and microphone permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

No storage permission is needed: picking from the device goes through the system picker.

### iOS

Add `NSCameraUsageDescription`, `NSMicrophoneUsageDescription` and `NSPhotoLibraryUsageDescription` to `ios/Runner/Info.plist`.

### Localizations

Since Flutter 3.47, Material and Cupertino live in `package:material_ui` and `package:cupertino_ui`, with their own localization types that the delegates of `flutter_localizations` do not provide. The picker uses these libraries, so add its delegates to your app, even if it still uses `package:flutter/material.dart`:

```dart
MaterialApp(
  localizationsDelegates: StoryPicker.localizationsDelegates,
  // ...
)
```

In debug builds, `StoryPicker.pick` fails with an explicit message when they are missing.

## Usage

```dart
final result = await StoryPicker.pick(context);

switch (result) {
  case StoryImageResult(:final path):
    // Photo taken or picked, after editing.
  case StoryVideoResult(:final path):
    // Video recorded or picked, after editing and trimming.
  case StoryTextResult(:final text, :final background, :final fontFamily, :final textAlign):
    // Text story.
  case null:
    // The user closed the picker.
}
```

## Options

```dart
StoryPicker.pick(
  context,
  options: StoryPickerOptions(
    translations: StoryPickerTranslations.fr,
    maxVideoDuration: const Duration(seconds: 30),
    enableTextStories: true,
    textFonts: const ['Montserrat', 'OpenSans'],
    textBackgrounds: StoryBackground.defaults,
    settingsBuilder: (context) => const MySettingsScreen(),
    theme: const StoryPickerTheme(accentColor: Colors.deepPurple),
    // pro_image_editor configuration: translations, theme, tools…
    editorConfigs: const ProImageEditorConfigs(i18n: StoryEditorI18n.fr),
  ),
);
```

| Option | Default | |
| --- | --- | --- |
| `theme` | `StoryPickerTheme()` | Colors of the overlay icons and progress indicators, the recording bar and the capture button's progress indicator. |
| `translations` | English | Strings of the camera and text screens. `StoryPickerTranslations.fr` is built in. |
| `maxVideoDuration` | 15 s | Longest video the camera records and the video editor lets the user keep. |
| `enableTextStories` | `true` | Shows the text story button on the camera. |
| `textFonts` | `[]` | Font families the text screen cycles through. Declare them in your app's `pubspec.yaml`. When empty, the default font is used and the font button is hidden. |
| `textBackgrounds` | `StoryBackground.defaults` | Gradients the text screen cycles through. |
| `settingsBuilder` | `null` | Screen opened by the settings button. The button is hidden when null. |
| `editorConfigs` | `ProImageEditorConfigs()` | Base configuration of the photo and video editors, with [pro_image_editor](https://pub.dev/packages/pro_image_editor) types: `i18n` for translations (`StoryEditorI18n.fr` is built in), theme, tools… The video editor adds its own trim limits, drops the tools videos do not support and shows the render progress, unless `dialogConfigs` provides a loading dialog. |

## Migrating from 0.0.x

| 0.0.x | 1.0 |
| --- | --- |
| `StoryPicker.pick(context, transitionType: ..., options: Options(...))` | `StoryPicker.pick(context, options: StoryPickerOptions(...))` |
| `Options.settingsTarget` (any widget) | `StoryPickerOptions.settingsBuilder` (`WidgetBuilder`) |
| `Options.disableTextStories` | `StoryPickerOptions.enableTextStories` (inverted) |
| `CustomizationOptions` and its 4 sub-classes | `StoryPickerTheme` for the camera and text screens, `editorConfigs` for the editors |
| `videoDurationLimitInSeconds` (capped at 60) | `maxVideoDuration` (`Duration`, no cap) |
| `GalleryCustomization.maxSelectable` | Removed: multi-selection never worked with the system picker. |
| `Translations` | `StoryPickerTranslations` keeps `pressToWrite`, `pressAndHoldToRecord` and adds `cameraUnavailable`, `videoExportFailed`; the editor strings move to `editorConfigs.i18n` (`StoryEditorI18n.fr` for French) |
| `StoryPickerResult.resultType` + `pickedFiles` / `storyText` | Sealed `StoryImageResult`, `StoryVideoResult`, `StoryTextResult` |
| `StoryText.colorHex`, `linearGradient`, `fontIndex`, … | `StoryTextResult.background` (`gradient`, `textColor`), `fontFamily`, `textAlign` |
| Bundled fonts (FreightSans, MADECanvas, ProximaNova, AvenyT, Montserrat, OpenSans) | Removed: pass your own families in `textFonts`. |
| `package:page_transition` re-exported | No longer exported. |
| Filters (photofilters), crop (image_cropper), trim (video_trimmer) screens | pro_image_editor / pro_video_editor; remove `UCropActivity` from your manifest |
| Recorded video: "delete / validate" dialog | Opens the video editor |
| — | Add `StoryPicker.localizationsDelegates` to your `MaterialApp` |
