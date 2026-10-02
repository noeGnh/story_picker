import 'package:flutter/widgets.dart';

import 'options.dart';

/// What the user created, returned by [StoryPicker.pick].
sealed class StoryPickerResult {
  const StoryPickerResult();
}

/// A photo taken with the camera or picked from the device.
final class StoryImageResult extends StoryPickerResult {
  const StoryImageResult(this.path);

  /// Local path of the (possibly edited) image.
  final String path;
}

/// A video recorded with the camera or picked from the device.
final class StoryVideoResult extends StoryPickerResult {
  const StoryVideoResult(this.path);

  /// Local path of the (possibly trimmed) video.
  final String path;
}

/// A text written on a colored background.
final class StoryTextResult extends StoryPickerResult {
  const StoryTextResult({required this.text, required this.textAlign, required this.background, this.fontFamily});

  final String text;
  final TextAlign textAlign;
  final StoryBackground background;

  /// One of [StoryPickerOptions.textFonts], or null for the default font.
  final String? fontFamily;
}
