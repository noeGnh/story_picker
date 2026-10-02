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
