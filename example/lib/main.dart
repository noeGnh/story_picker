import 'dart:io';

import 'package:example/settings.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:story_picker/story_picker.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example',
      debugShowCheckedModeBanner: false,
      // Required by the picker and its editors.
      localizationsDelegates: StoryPicker.localizationsDelegates,
      home: Scaffold(appBar: AppBar(title: const Text('Example')), body: const Content(), backgroundColor: Colors.blue),
    );
  }
}

class Content extends StatefulWidget {
  const Content({super.key});

  @override
  State<Content> createState() => _ContentState();
}

class _ContentState extends State<Content> {
  StoryPickerResult? _result;

  Future<void> _pick() async {
    final result = await StoryPicker.pick(
      context,
      options: StoryPickerOptions(
        translations: StoryPickerTranslations.fr,
        textFonts: const ['Montserrat', 'OpenSans'],
        settingsBuilder: (_) => const Settings(),
        // The photo and video editors are configured with pro_image_editor types.
        editorConfigs: const ProImageEditorConfigs(i18n: StoryEditorI18n.fr),
      ),
    );
    if (result != null) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 300,
            height: 300,
            child: switch (_result) {
              StoryImageResult(:final path) => Image.file(File(path)),
              StoryVideoResult(:final path) => VideoPlayerWidget(path, key: ValueKey(path)),
              StoryTextResult(:final text, :final textAlign, :final background, :final fontFamily) => Container(
                decoration: BoxDecoration(gradient: background.gradient),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                child: Text(text, textAlign: textAlign, style: TextStyle(fontFamily: fontFamily, fontSize: 24, color: background.textColor)),
              ),
              null => const SizedBox(),
            },
          ),
          ElevatedButton(onPressed: _pick, child: const Text('Pick It')),
        ],
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String path;

  const VideoPlayerWidget(this.path, {super.key});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final VideoPlayerController _controller = VideoPlayerController.file(File(widget.path));
  late final Future<void> _initialized = _controller.initialize().then((_) {
    _controller
      ..setLooping(true)
      ..play();
  });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialized,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        return AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller));
      },
    );
  }
}
