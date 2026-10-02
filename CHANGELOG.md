## 1.0.0-dev.3

- New `StoryEditorI18n.fr`: French translations of every editor tool the picker shows, for `ProImageEditorConfigs(i18n: ...)`.
- The video editor shows the render progress as a percentage. A loading dialog set in `editorConfigs.dialogConfigs` still takes precedence.
- The text screen no longer depends on auto_size_text_field: the text shrinks from 30 to 16 to fit above the keyboard, and the character counter is hidden.
- `StoryPicker.localizationsDelegates` is now `GlobalMaterialLocalizations.delegates` from `material_ui`: the `package:flutter` Material and Cupertino delegates are no longer needed.
- Progress indicators on the dark editor screens use `StoryPickerTheme.overlayIconColor`, so they stay visible with the default black `accentColor`.

## 1.0.0-dev.2

- Photos and videos open in [pro_image_editor](https://pub.dev/packages/pro_image_editor): text, drawing, emojis, filters, tune, blur, crop/rotate, and for videos trimming (limited to `maxVideoDuration`) with a final render through [pro_video_editor](https://pub.dev/packages/pro_video_editor). Replaces photofilters, image_cropper and video_trimmer.
- A recorded video now opens the video editor instead of the "delete / validate" dialog.
- New `StoryPickerOptions.editorConfigs` to configure the editors (translations, theme, tools).
- New `StoryPicker.localizationsDelegates`, required in the host app's `MaterialApp`. `StoryPicker.pick` asserts when they are missing.
- Migrated to `package:material_ui` (Flutter 3.47+).
- If a video export fails, the user stays in the editor with a message (`StoryPickerTranslations.videoExportFailed`).
- Removed: the preview screens, `StoryPickerTheme.previewBackgroundColor` / `previewForegroundColor`, and the translations they used.
- Android: the temporary AGP 9 flags are no longer needed; `UCropActivity` no longer has to be declared.

## 1.0.0-dev.1

Breaking: new public API. See "Migrating from 0.0.x" in the README.

- `StoryPickerOptions`, `StoryPickerTheme`, `StoryPickerTranslations` (with French) and `StoryBackground`, all `const`.
- Sealed `StoryPickerResult`: `StoryImageResult`, `StoryVideoResult`, `StoryTextResult`.
- Fonts are no longer bundled; the app passes its own families in `textFonts`.
- Camera: released when the app goes to the background and reopened on return, black background, shadowed icons readable on bright scenes, message when no camera is available, spinner while a photo or a recording starts, recording time shown against the limit.
- Video: a recording shorter than one second is extended to one second, and an empty file is never returned.
- Removed dependencies: provider, page_transition, logger, just_the_tooltip, flutter_keyboard_visibility.
- Widget tests.

## 0.0.8

- Stabilization: file_picker 13, dead gallery and 11 unused dependencies removed, several crash fixes.
