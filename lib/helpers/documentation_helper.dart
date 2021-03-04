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
}

class _Through {
  int time;
  String results;

  _Through(int time, String result) {
    this.time = time;
    this.results = result;
  }
}