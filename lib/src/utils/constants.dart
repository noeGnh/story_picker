import 'package:flutter/material.dart';
import 'package:story_picker/src/models/bg_model.dart';

abstract class StoryConstants {
  static final fonts = [
    'FreightSans',
    'MADECanvas',
    'ProximaNova',
    'AvenyT',
    'Montserrat',
    'OpenSans',
  ];

  static final textAlignments = [
    TextAlign.center,
    TextAlign.left,
    TextAlign.right,
  ];

  static final textBackgrounds = [
    BgModel(
      linearGradient: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        stops: [
          0.1,
          0.5,
          0.8,
          0.9,
        ],
        colors: [
          Colors.red,
          Colors.yellow,
          Colors.blue,
          Colors.purple,
        ],
      ),
      hintColor: Colors.black87,
      textColor: Colors.black,
    ),
    BgModel(
      linearGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.purple,
          Colors.blue,
        ],
      ),
      hintColor: Colors.black87,
      textColor: Colors.black,
    ),
    BgModel(
      linearGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.yellow,
          Colors.deepPurple,
        ],
      ),
      hintColor: Colors.black87,
      textColor: Colors.black,
    ),
    BgModel(
      linearGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.red,
          Colors.orange,
        ],
      ),
      hintColor: Colors.black87,
      textColor: Colors.black,
    ),
    BgModel(
      linearGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.yellow,
          Colors.green,
          Colors.blue,
        ],
      ),
      hintColor: Colors.black87,
      textColor: Colors.black,
    )
  ];
}
