import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart' as legacy show InputBorder, InputDecoration, Material, MaterialType;
import 'package:material_ui/material_ui.dart';

import '../media_picker.dart';
import '../options.dart';
import '../result.dart';
import '../scope.dart';
import '../widgets/overlay_controls.dart';

const _alignments = [TextAlign.center, TextAlign.left, TextAlign.right];

class TextStoryScreen extends StatefulWidget {
  const TextStoryScreen({super.key});

  @override
  State<TextStoryScreen> createState() => _TextStoryScreenState();
}

class _TextStoryScreenState extends State<TextStoryScreen> {
  final _text = TextEditingController();
  int _fontIndex = 0;
  int _alignIndex = 0;
  int _backgroundIndex = 0;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  List<StoryBackground> _backgrounds(StoryPickerOptions options) => options.textBackgrounds.isEmpty ? StoryBackground.defaults : options.textBackgrounds;

  void _submit(StoryPickerOptions options) {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(
      StoryTextResult(
        text: text,
        textAlign: _alignments[_alignIndex],
        background: _backgrounds(options)[_backgroundIndex],
        fontFamily: options.textFonts.isEmpty ? null : options.textFonts[_fontIndex],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = StoryPickerScope.of(context);
    final backgrounds = _backgrounds(options);
    final background = backgrounds[_backgroundIndex];
    final fontFamily = options.textFonts.isEmpty ? null : options.textFonts[_fontIndex];
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final settingsBuilder = options.settingsBuilder;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: background.gradient),
          child: SafeArea(
            child: Stack(
              children: [
                Container(
                  alignment: keyboardVisible ? Alignment.topCenter : Alignment.center,
                  padding: EdgeInsets.fromLTRB(16, keyboardVisible ? 80 : 0, 16, 0),
                  // auto_size_text_field still uses package:flutter/material.dart.
                  child: legacy.Material(
                    type: legacy.MaterialType.transparency,
                    child: AutoSizeTextField(
                      controller: _text,
                      style: TextStyle(fontSize: 30, fontFamily: fontFamily, color: background.textColor),
                      textAlign: _alignments[_alignIndex],
                      minFontSize: 16,
                      minLines: 1,
                      maxLines: 16,
                      maxLength: 700,
                      decoration: legacy.InputDecoration(
                        border: legacy.InputBorder.none,
                        hintText: options.translations.pressToWrite,
                        hintStyle: TextStyle(fontFamily: fontFamily, color: background.hintColor),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: keyboardVisible
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OverlayIconButton(
                              icon: switch (_alignments[_alignIndex]) {
                                TextAlign.left => Icons.format_align_left,
                                TextAlign.right => Icons.format_align_right,
                                _ => Icons.format_align_center,
                              },
                              onPressed: () => setState(() => _alignIndex = (_alignIndex + 1) % _alignments.length),
                            ),
                            if (options.textFonts.length > 1)
                              OverlayIconButton(
                                icon: Icons.font_download,
                                onPressed: () => setState(() => _fontIndex = (_fontIndex + 1) % options.textFonts.length),
                              ),
                            OverlayIconButton(icon: Icons.check, onPressed: () => _submit(options)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            settingsBuilder != null
                                ? OverlayIconButton(
                                    icon: Icons.settings,
                                    onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: settingsBuilder)),
                                  )
                                : const SizedBox(width: 48),
                            OverlayIconButton(icon: Icons.close, onPressed: () => Navigator.of(context).pop()),
                          ],
                        ),
                ),
                if (!keyboardVisible)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CaptureButton(onTap: () => _submit(options)),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              OverlayIconButton(icon: Icons.image, onPressed: () => pickMediaAndPreview(context)),
                              IconButton(
                                onPressed: () => setState(() => _backgroundIndex = (_backgroundIndex + 1) % backgrounds.length),
                                icon: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: options.theme.overlayIconColor),
                                    gradient: backgrounds[(_backgroundIndex + 1) % backgrounds.length].gradient,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
