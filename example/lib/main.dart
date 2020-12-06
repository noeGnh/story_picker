import 'dart:io';

import 'package:example/settings.dart';
import 'package:flutter/material.dart';
import 'package:story_picker/story_picker.dart';

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
          body: Content()
      ),
    );
  }
}

class Content extends StatefulWidget {
  @override
  _ContentState createState() => _ContentState();
}

class _ContentState extends State<Content> {

  File image;

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
            child: image != null ? Image.file(image) : Container(),
          ),
          RaisedButton(
            onPressed: () async {
              await StoryPicker.pick(context,
                  transitionType: PageTransitionType.leftToRight,
                  options: Options(
                      settingsTarget: Settings()
                  )
              );
              setState(() {});
            },
            child: Text('Pick It'),
          )
        ],
      ),
    );
  }
}