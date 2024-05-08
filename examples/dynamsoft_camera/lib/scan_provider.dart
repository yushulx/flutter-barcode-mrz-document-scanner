import 'package:dynamsoft_capture_vision_flutter/dynamsoft_capture_vision_flutter.dart';
import 'package:flutter/foundation.dart';

class ScanProvider extends ChangeNotifier {
  int _types = 0;

  int get types => _types;

  set types(int value) {
    _types = value;
    notifyListeners();
  }

  final Map<String, BarcodeResult> _results = {};

  Map<String, BarcodeResult> get results => _results;

  void addResult(String key, BarcodeResult result) {
    _results[key] = result;
    notifyListeners();
  }

  void clearResults() {
    _results.clear();
    notifyListeners();
  }

  void removeResult(String key) {
    _results.remove(key);
    notifyListeners();
  }
}
