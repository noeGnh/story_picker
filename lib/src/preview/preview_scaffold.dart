import 'package:flutter/material.dart';

import '../scope.dart';

/// App bar with back and validate actions shared by the preview screens.
class PreviewScaffold extends StatelessWidget {
  const PreviewScaffold({super.key, required this.body, required this.onValidate});

  final Widget body;
  final VoidCallback? onValidate;

  @override
  Widget build(BuildContext context) {
    final options = StoryPickerScope.of(context);
    final colors = options.theme;

    return Scaffold(
      backgroundColor: colors.previewBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.previewBackgroundColor,
        foregroundColor: colors.previewForegroundColor,
        title: Text(options.translations.preview),
        actions: [IconButton(onPressed: onValidate, tooltip: options.translations.validate, icon: const Icon(Icons.check))],
      ),
      body: SafeArea(child: body),
    );
  }
}
