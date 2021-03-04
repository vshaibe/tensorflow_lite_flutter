import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:tensorflow_lite_flutter/helpers/app_helper.dart';
import 'package:tensorflow_lite_flutter/helpers/camera_helper.dart';
import 'package:tensorflow_lite_flutter/helpers/tflite_helper.dart';
import 'package:tensorflow_lite_flutter/helpers/photo_stream_helper.dart';
import 'package:tensorflow_lite_flutter/models/result.dart';

class DetectScreen extends StatefulWidget {
  DetectScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _DetectScreenPageState createState() => _DetectScreenPageState();
}

class _DetectScreenPageState extends State<DetectScreen>
    with TickerProviderStateMixin {
  AnimationController _colorAnimController;
  Animation _colorTween;
  List<Result> outputs;
  var runCounter = 0;

  void initState() {
    super.initState();

    //Load TFLite Model
    TFLiteHelper.loadModel().then((value) {
      setState(() {
        TFLiteHelper.modelLoaded = true;
        PhotoStreamHelper.subject.add(1);
      });
    });

    //Initialize Camera
    //CameraHelper.initializeCamera();
    PhotoStreamHelper.initializePhotoStream(context);

    //Setup Animation
    _setupAnimation();

    //Subscribe to TFLite's Classify events
    TFLiteHelper.tfLiteResultsController.stream.listen((value) {
      value.forEach((element) {
        _colorAnimController.animateTo(element.confidence,
            curve: Curves.bounceIn, duration: Duration(milliseconds: 500));
      });


      //Set Results
      outputs = value;

      //Update results on screen
      setState(() {
        //Set bit to false to allow detection again
        CameraHelper.isDetecting = false;
        PhotoStreamHelper.subject.add(1);

      });
    }, onDone: () {

    }, onError: (error) {
      AppHelper.log("listen", error);
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<void>(
        // future: CameraHelper.initializeControllerFuture,
        builder: (context, snapshot) {
            return Stack(
              children:[
                //CameraPreview(CameraHelper.camera),
                _modelTestResult(),
                _buildResultsWidget(width, outputs)
              ]
            );
        },
      ),
    );
  }

  @override
  void dispose() {
    TFLiteHelper.disposeModel();
    CameraHelper.camera.dispose();
    AppHelper.log("dispose", "Clear resources.");
    super.dispose();
  }

  Widget _buildResultsWidget(double width, List<Result> outputs) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 200.0,
          width: width,
          color: Colors.white,
          child: outputs != null && outputs.isNotEmpty
              ? ListView.builder(
                  itemCount: outputs.length,
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(20.0),
                  itemBuilder: (BuildContext context, int index) {
                    return Column(
                      children: <Widget>[
                        Text(
                          outputs[index].label,
                          style: TextStyle(
                            color: _colorTween.value,
                            fontSize: 20.0,
                          ),
                        ),
                        AnimatedBuilder(
                            animation: _colorAnimController,
                            builder: (context, child) => LinearPercentIndicator(
                                  width: width * 0.88,
                                  lineHeight: 14.0,
                                  percent: outputs[index].confidence,
                                  progressColor: _colorTween.value,
                                )),
                        Text(
                          "${(outputs[index].confidence * 100.0).toStringAsFixed(2)} %",
                          style: TextStyle(
                            color: _colorTween.value,
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    );
                  })
              : Center(
                  child: Text("Wating for model to detect..",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20.0,
                      ))),
        ),
      ),
    );
  }

  Widget _modelTestResult() {
    Text t = new Text("run counter: $runCounter", style: TextStyle(
      color: Colors.black,
      fontSize: 20.0,
    ));
    PhotoStreamHelper.runDone.stream.listen((event) {
      setState(() {
        runCounter = event;
      });
    });
    return Positioned.fill(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          color: Colors.white,
          child:Center(
              child: t,
        ),
      ),
    ));
  }

  void _setupAnimation() {
    _colorAnimController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _colorTween = ColorTween(begin: Colors.green, end: Colors.red)
        .animate(_colorAnimController);
  }
}
