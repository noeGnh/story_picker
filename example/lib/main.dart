import 'dart:io';

import 'package:example/settings.dart';
import 'package:flutter/material.dart';
import 'package:story_picker/story_picker.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Example",
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text("Example"),
        ),
        body: Content(),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

class Content extends StatefulWidget {
  @override
  _ContentState createState() => _ContentState();
}

class _ContentState extends State<Content> {
  String? mediaPath;
  ResultType? mediaType;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 300,
            height: 300,
            child: mediaPath != null && mediaType != null ? (mediaType == ResultType.IMAGE ? Image.file(File(mediaPath!)) : VideoPlayerWidget(mediaPath!)) : Container(),
          ),
          ElevatedButton(
            onPressed: () async {
              var result = await StoryPicker.pick(
                context,
                transitionType: PageTransitionType.leftToRight,
                options: Options(settingsTarget: Settings()),
              );
              if (result != null) {
                mediaPath = result.pickedFiles![0].path;
                mediaType = result.resultType;
              }
              setState(() {});
            },
            child: Text('Pick It'),
          )
        ],
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String path;

  const VideoPlayerWidget(this.path, {Key? key}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    _controller = VideoPlayerController.file(
      File(widget.path),
    );

    _initializeVideoPlayerFuture = _controller.initialize();

    _controller.setLooping(true);
    _controller.play();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
