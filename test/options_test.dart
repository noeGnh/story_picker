import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_picker/story_picker.dart';

void main() {
  test('default options', () {
    const options = StoryPickerOptions();

    expect(options.maxVideoDuration, const Duration(seconds: 15));
    expect(options.enableTextStories, isTrue);
    expect(options.textFonts, isEmpty);
    expect(options.textBackgrounds, same(StoryBackground.defaults));
    expect(options.settingsBuilder, isNull);
    expect(options.theme.overlayIconColor, Colors.white);
  });

  test('French translations translate every string', () {
    const en = StoryPickerTranslations();
    const fr = StoryPickerTranslations.fr;
    for (final (english, french) in [
      (en.pressToWrite, fr.pressToWrite),
      (en.pressAndHoldToRecord, fr.pressAndHoldToRecord),
      (en.cameraUnavailable, fr.cameraUnavailable),
      (en.videoExportFailed, fr.videoExportFailed),
    ]) {
      expect(french, isNot(english));
      expect(french, isNotEmpty);
    }
  });

  test('French editor preset differs from the English defaults', () {
    const fr = StoryEditorI18n.fr;

    expect(fr.done, 'Terminé');
    expect(fr.cancel, 'Annuler');
    expect(fr.paintEditor.bottomNavigationBarText, 'Dessin');
    expect(fr.textEditor.inputHintText, isNot('Enter text'));
    expect(fr.cropRotateEditor.reset, isNot('Reset'));
    expect(fr.tuneEditor.brightness, isNot('Brightness'));
    expect(fr.filterEditor.filters.none, isNot('No Filter'));
    expect(fr.emojiEditor.search, isNot('Search'));
    expect(fr.various.closeEditorWarningTitle, isNot('Close Image Editor?'));
  });

  test('default backgrounds are readable', () {
    expect(StoryBackground.defaults, hasLength(5));
    for (final background in StoryBackground.defaults) {
      expect(background.textColor, isNot(background.hintColor));
    }
  });
}
