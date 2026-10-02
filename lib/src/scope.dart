import 'package:flutter/material.dart';

import 'options.dart';
import 'result.dart';

/// Makes the session's [StoryPickerOptions] available to every picker screen.
class StoryPickerScope extends InheritedWidget {
  const StoryPickerScope({super.key, required this.options, required super.child});

  final StoryPickerOptions options;

  static StoryPickerOptions of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StoryPickerScope>();
    assert(scope != null, 'No StoryPickerScope found. Open the picker with StoryPicker.pick.');
    return scope!.options;
  }

  @override
  bool updateShouldNotify(StoryPickerScope oldWidget) => options != oldWidget.options;
}

/// Pushes [screen] as a slide-up page that keeps the current [StoryPickerScope].
///
/// Routes are siblings in the [Navigator], so the scope has to be carried over.
Future<StoryPickerResult?> pushStoryScreen(BuildContext context, Widget screen) {
  final options = StoryPickerScope.of(context);
  return Navigator.of(context).push(storyRoute(options, screen));
}

/// Same as [pushStoryScreen], then closes the calling screen with the result
/// when there is one, so the result goes all the way back to the caller.
Future<void> pushStoryScreenAndForward(BuildContext context, Widget screen) async {
  final result = await pushStoryScreen(context, screen);
  if (result != null && context.mounted) Navigator.of(context).pop(result);
}

Route<StoryPickerResult> storyRoute(StoryPickerOptions options, Widget screen) {
  return PageRouteBuilder<StoryPickerResult>(
    pageBuilder: (_, _, _) => StoryPickerScope(options: options, child: screen),
    transitionsBuilder: (_, animation, _, child) => SlideTransition(
      position: Tween(begin: const Offset(0, 1), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation),
      child: child,
    ),
  );
}
