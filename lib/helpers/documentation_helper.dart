import 'dart:convert';

class DocumentationHelper {
  static DocumentationHelper _instance;
  _Experiment _exp = new _Experiment();

  static Instance() {
    if(_instance == null) _instance = new DocumentationHelper();
    return _instance;
  }

  set name(String name) {
    _exp.expName = name;
  }

  void addInfo(String fileName, int time, String result) {
    var t = _exp.expFiles.where((e) => e.name == fileName);
    if(t.isEmpty) {
      _exp.addNewFile(fileName).addThrough(time, result);
    } else {
      t.first.addThrough(time, result);
    }
  }

  void createJson() {
    String t = jsonEncode(_exp);
    print(t);
  }
}

class _Experiment {
  String expName;
  List<_ExperimentFile> expFiles;

  _Experiment() {
    this.expFiles = new List<_ExperimentFile>();
  }

  _ExperimentFile addNewFile(String path) {
    _ExperimentFile t = new _ExperimentFile(path);
    expFiles.add(t);
    return t;
  }

  Map toJson() => {
    'name': expName,
    'ExperimentalFiles': expFiles.toList()
  };
}

class _ExperimentFile {
  String name;
  double averageTime;
  List<_Through> throughList;

  _ExperimentFile(String path) {
    this.name = path;
    this.throughList = new List<_Through>();
  }
  
  void addThrough(int time, String result) {
    this.throughList.add(new _Through(time, result));
  }

  Map toJson() => {
    'name': name,
    'averageTime': throughList.map((e) => e.time).reduce((a, b) => a + b)/throughList.length,
    'throughList': throughList.toList()
  };
}

class _Through {
  int time;
  String result;

  _Through(int time, String result) {
    this.time = time;
    this.result = result;
  }

  Map toJson() => {
    'time': time,
    'results': result
  };
}