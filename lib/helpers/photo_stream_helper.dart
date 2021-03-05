import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import 'package:tensorflow_lite_flutter/helpers/tflite_helper.dart';
import 'package:tensorflow_lite_flutter/helpers/documentation_helper.dart';

class PhotoStreamHelper {
  static BehaviorSubject<List<String>> paths = BehaviorSubject<List<String>>();
  static bool pathsLoaded;
  static int counter = 0;
  static BehaviorSubject<int> subject = BehaviorSubject<int>();
  static BehaviorSubject<int> runDone = BehaviorSubject<int>();
  static int iteration = 0;
  static int _globalRuns = 0;

  static void initializePhotoStream(BuildContext context) async {
    DefaultAssetBundle.of(context)
        .loadString('AssetManifest.json')
        .then((value) {
      Map<String, dynamic> t = json.decode(value);
      paths.add(t.keys
          .where((element) => element.contains("representative_data"))
          .toList());
    });

    subject.stream.listen((event) {
      paths.stream.listen((event) {
        TFLiteHelper.classifyFileImage(event.elementAt(counter), context);
        counter = (counter + 1) % event.length;
        if (counter == event.length - 2) {
          iteration++;
          if (iteration == 3) {
            var t = DocumentationHelper.Instance();
            DocumentationHelper.Instance().createJson().then((val) {
              iteration = 0;
              counter = 0;
              DocumentationHelper.Instance().clearExperiment();
              _globalRuns++;
              runDone.add(_globalRuns);
            });
          }
        }
      });
    });
  }

  static disposePhotoStream() {
    subject.close();
    paths.close();
    runDone.close();
  }
}
