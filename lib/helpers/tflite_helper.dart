import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:tensorflow_lite_flutter/models/result.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tensorflow_lite_flutter/helpers/documentation_helper.dart';

import 'app_helper.dart';

class TFLiteHelper {
  static StreamController<List<Result>> tfLiteResultsController =
      new StreamController.broadcast();
  static List<Result> _outputs = List();
  static var modelLoaded = false;
  static var uuid = Uuid();
  static int _iteration;

  static Future<String> loadModel() async {
    AppHelper.log("loadModel", "Loading model..");
    String modelName = "assets/model_latency_quant.tflite";
    DocumentationHelper.Instance().name = modelName;

    return Tflite.loadModel(
      model: modelName,
      labels: "assets/labels.txt",
    );
  }

  static classifyImage(CameraImage image) async {
    var t = uuid.v4();
    FlutterLogs.logInfo("START", t, DateTime.now().toIso8601String());
    await Tflite.runModelOnFrame(
            bytesList: image.planes.map((plane) {
              return plane.bytes;
            }).toList(),
            numResults: 5,
            imageHeight: image.height,
            imageWidth: image.width,
            imageMean: 0.0,
            imageStd: 1.0)
        .then((value) {
      if (value.isNotEmpty) {
        AppHelper.log("classifyImage", "Results loaded. ${value.length}");
        FlutterLogs.logInfo("END", t, DateTime.now().toIso8601String());

        //Clear previous results
        _outputs.clear();

        value.forEach((element) {
          _outputs.add(Result(
              element['confidence'], element['index'], element['label']));

          AppHelper.log("classifyImage",
              "${element['confidence']} , ${element['index']}, ${element['label']}");
        });
      }

      //Sort results according to most confidence
      _outputs.sort((a, b) => a.confidence.compareTo(b.confidence));

      //Send results
      tfLiteResultsController.add(_outputs);
    });
  }

  static classifyFileImage(String path, BuildContext context) async {
    ByteData bytes = await DefaultAssetBundle.of(context).load(path);
    img.Image oriImage = img.decodeJpg(bytes.buffer.asUint8List());
    FlutterLogs.logInfo("START_FileStream", path, DateTime.now().toIso8601String());
    DateTime startTime = new DateTime.now();
    await Tflite.runModelOnBinary(
            binary: imageToByteListFloat32(oriImage, 224, 127.5, 127.5),
            numResults: 5,
            threshold: 0.05,
            asynch: true)
        .then((value) {
      if (value.isNotEmpty) {
        String res = "";

        FlutterLogs.logInfo("END_FileStream", path, DateTime.now().toIso8601String());
        AppHelper.log("classifyImage", "Results loaded. ${value.length}");

        //Clear previous results
        _outputs.clear();

        value.forEach((element) {
          _outputs.add(Result(
              element['confidence'], element['index'], element['label']));
          res += "{" + element['confidence'].toString() + "," +  element['index'].toString() + "," + element['label'] + "}";

          AppHelper.log("classifyImage",
              "${element['confidence']} , ${element['index']}, ${element['label']}");
        });
        DocumentationHelper.Instance().addInfo(path, DateTime.now().difference(startTime).inMilliseconds, res);
      }

      //Sort results according to most confidence
      _outputs.sort((a, b) => a.confidence.compareTo(b.confidence));

      //Send results
      tfLiteResultsController.add(_outputs);
    });
  }

  static classifyByte(Uint8List image, String name) async {
    FlutterLogs.logInfo(
        "START_FileStream", name, DateTime.now().toIso8601String());
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    FlutterLogs.logInfo("VALUE_FileStream", name, image.toString());
    await Tflite.runModelOnFrame(
            bytesList: [image].toList(),
            numResults: 5,
            imageHeight: 640,
            imageWidth: 480,
            imageMean: 0.0,
            imageStd: 1.0,
            asynch: true)
        .then((value) {
      FlutterLogs.logInfo(
          "END_FileStream", name, DateTime.now().toIso8601String());
      if (value.isNotEmpty) {
        AppHelper.log("classifyImage", "Results loaded. ${value.length}");

        //Clear previous results
        _outputs.clear();

        value.forEach((element) {
          _outputs.add(Result(
              element['confidence'], element['index'], element['label']));

          AppHelper.log("classifyImage",
              "${element['confidence']} , ${element['index']}, ${element['label']}");
        });
      }

      //Sort results according to most confidence
      _outputs.sort((a, b) => a.confidence.compareTo(b.confidence));

      //Send results
      tfLiteResultsController.add(_outputs);
    }).catchError((e) {
      FlutterLogs.logInfo("ERROR_FileStream", name, e.toString());
    });
  }

  static void disposeModel() {
    Tflite.close();
    tfLiteResultsController.close();
  }

  static Uint8List imageToByteListFloat32(
      img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (img.getRed(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getGreen(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getBlue(pixel) - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }
}
