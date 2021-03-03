import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import 'package:tensorflow_lite_flutter/helpers/tflite_helper.dart';

class PhotoStreamHelper {
  static BehaviorSubject<List<String>> paths = BehaviorSubject<List<String>>();
  static bool pathsLoaded;
  static int counter = 0;
  static BehaviorSubject<int> subject = BehaviorSubject<int>();

  static void initializePhotoStream(BuildContext context) async {
    DefaultAssetBundle.of(context).loadString('AssetManifest.json').then((value) {
      Map<String, dynamic> t = json.decode(value);
      paths.add(t.keys.toList());
    });

    subject.stream.listen((event) {
      paths.stream.listen((event) {
        TFLiteHelper.classifyFileImage(event.elementAt(counter), context);
        counter = (counter+1) % event.length;
      });
    });
  }

  static disposePhotoStream() {
    subject.close();
    paths.close();
  }
}