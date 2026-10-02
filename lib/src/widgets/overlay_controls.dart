import 'package:material_ui/material_ui.dart';

import '../scope.dart';

const _shadows = [Shadow(blurRadius: 6, color: Colors.black54)];

/// Icon drawn over the camera preview or a text story background, with a
/// shadow so it stays visible on bright content.
class OverlayIconButton extends StatelessWidget {
  const OverlayIconButton({super.key, required this.icon, required this.onPressed, this.tooltip});

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final color = StoryPickerScope.of(context).theme.overlayIconColor;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: 32,
      icon: Icon(icon, color: color, shadows: _shadows),
    );
  }
}

/// Overlay text with the same shadow as [OverlayIconButton].
class OverlayText extends StatelessWidget {
  const OverlayText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final color = StoryPickerScope.of(context).theme.overlayIconColor;
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(color: color, fontSize: 15, shadows: _shadows).merge(style),
    );
  }
}

/// Round shutter button.
class CaptureButton extends StatelessWidget {
  const CaptureButton({super.key, this.onTap, this.onLongPressStart, this.onLongPressEnd, this.recording = false, this.busy = false});

  final VoidCallback? onTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final bool recording;

  /// Shows a spinner, e.g. while a photo is being taken.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = StoryPickerScope.of(context).theme;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        onLongPressStart: onLongPressStart == null ? null : (_) => onLongPressStart!(),
        onLongPressEnd: onLongPressEnd == null ? null : (_) => onLongPressEnd!(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: recording ? 96 : 80,
          height: recording ? 96 : 80,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.overlayIconColor, width: 5),
            boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: recording ? theme.recordingColor : theme.overlayIconColor),
            child: busy
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: theme.accentColor),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
