import 'package:material_ui/material_ui.dart';

import '../media_picker.dart';
import '../options.dart';
import '../result.dart';
import '../scope.dart';
import '../widgets/overlay_controls.dart';

const _alignments = [TextAlign.center, TextAlign.left, TextAlign.right];
const _maxFontSize = 30.0;
const _minFontSize = 16.0;

/// Room kept for the capture button and the bottom row when the keyboard is
/// hidden, on each side of the centered text.
const _controlsHeight = 150.0;

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
  void initState() {
    super.initState();
    _text.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  /// Largest font size, in steps of 2, at which [text] fits in [size].
  double _fitFontSize(String text, TextStyle style, Size size) {
    final painter = TextPainter(textAlign: _alignments[_alignIndex], textDirection: Directionality.of(context), textScaler: MediaQuery.textScalerOf(context));
    try {
      for (var fontSize = _maxFontSize; fontSize > _minFontSize; fontSize -= 2) {
        painter.text = TextSpan(
          text: text,
          style: style.copyWith(fontSize: fontSize),
        );
        painter.layout(maxWidth: size.width);
        if (painter.height <= size.height) return fontSize;
      }
      return _minFontSize;
    } finally {
      painter.dispose();
    }
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
    // Read above the Scaffold, which hides the view insets from its body.
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardVisible = keyboardHeight > 0;
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final room = Size(
                        constraints.maxWidth - 4, // Leaves room for the cursor.
                        keyboardVisible ? constraints.maxHeight - keyboardHeight - 16 : constraints.maxHeight - 2 * _controlsHeight,
                      );
                      // TextField merges the theme's bodyLarge (line height…) into its style.
                      final style = Theme.of(context).textTheme.bodyLarge!.merge(TextStyle(fontFamily: fontFamily, color: background.textColor));
                      final hint = options.translations.pressToWrite;
                      final fontSize = _fitFontSize(_text.text.isEmpty ? hint : _text.text, style, room);
                      return TextField(
                        controller: _text,
                        style: style.copyWith(fontSize: fontSize),
                        textAlign: _alignments[_alignIndex],
                        minLines: 1,
                        maxLines: 16,
                        maxLength: 700,
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: hint,
                          hintStyle: style.copyWith(fontSize: fontSize, color: background.hintColor),
                        ),
                      );
                    },
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
