import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

abstract class Utils{

  static String printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");

    String twoDigitHours = twoDigits(duration.inHours);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    return duration.inHours > 0
        ? "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds"
        : "$twoDigitMinutes:$twoDigitSeconds";
  }

  static void showToast(String msg){

    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 16.0,
        webShowClose: true
    );

  }

}