# story_picker

A story-style capture flow for Flutter apps: full-screen camera (tap for a photo, press and hold for a video), text stories on a colored background, the system media picker, and a preview before the result goes back to your app.

> 1.0 is in progress. Photo filters, cropping and video trimming will move to [pro_image_editor](https://pub.dev/packages/pro_image_editor) and [pro_video_editor](https://pub.dev/packages/pro_video_editor) before the stable release.

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

Add the camera and microphone permissions, and the cropper activity, to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<application ...>
    <activity
        android:name="com.yalantis.ucrop.UCropActivity"
        android:screenOrientation="portrait"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar" />
</application>
```

No storage permission is needed: picking from the device goes through the system picker.

Until the video trimmer is replaced, apps on AGP 9 also need these two lines in `android/gradle.properties`, because one of its native dependencies still uses the legacy Kotlin plugin:

```properties
android.builtInKotlin=false
android.newDsl=false
```

### iOS

Add `NSCameraUsageDescription`, `NSMicrophoneUsageDescription` and `NSPhotoLibraryUsageDescription` to `ios/Runner/Info.plist`.

## Usage

```dart
final result = await StoryPicker.pick(context);

switch (result) {
  case StoryImageResult(:final path):
    // Photo taken or picked, possibly filtered or cropped.
  case StoryVideoResult(:final path):
    // Video recorded or picked, possibly trimmed.
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
  ),
);
```

| Option | Default | |
| --- | --- | --- |
| `theme` | `StoryPickerTheme()` | Colors of the overlay icons, recording bar, preview screens and accents. |
| `translations` | English | All user-facing strings. `StoryPickerTranslations.fr` is built in. |
| `maxVideoDuration` | 15 s | Longest video the camera records and the trimmer keeps. |
| `enableTextStories` | `true` | Shows the text story button on the camera. |
| `textFonts` | `[]` | Font families the text screen cycles through. Declare them in your app's `pubspec.yaml`. When empty, the default font is used and the font button is hidden. |
| `textBackgrounds` | `StoryBackground.defaults` | Gradients the text screen cycles through. |
| `settingsBuilder` | `null` | Screen opened by the settings button. The button is hidden when null. |

## Migrating from 0.0.x

| 0.0.x | 1.0 |
| --- | --- |
| `StoryPicker.pick(context, transitionType: ..., options: Options(...))` | `StoryPicker.pick(context, options: StoryPickerOptions(...))` |
| `Options.settingsTarget` (any widget) | `StoryPickerOptions.settingsBuilder` (`WidgetBuilder`) |
| `Options.disableTextStories` | `StoryPickerOptions.enableTextStories` (inverted) |
| `CustomizationOptions` and its 4 sub-classes | `StoryPickerTheme` |
| `videoDurationLimitInSeconds` (capped at 60) | `maxVideoDuration` (`Duration`, no cap) |
| `GalleryCustomization.maxSelectable` | Removed: multi-selection never worked with the system picker. |
| `Translations` | `StoryPickerTranslations`; `multiSelectionDoesntSupportVideos` removed, `cameraUnavailable` added |
| `StoryPickerResult.resultType` + `pickedFiles` / `storyText` | Sealed `StoryImageResult`, `StoryVideoResult`, `StoryTextResult` |
| `StoryText.colorHex`, `linearGradient`, `fontIndex`, … | `StoryTextResult.background` (`gradient`, `textColor`), `fontFamily`, `textAlign` |
| Bundled fonts (FreightSans, MADECanvas, ProximaNova, AvenyT, Montserrat, OpenSans) | Removed: pass your own families in `textFonts`. |
| `package:page_transition` re-exported | No longer exported. |
