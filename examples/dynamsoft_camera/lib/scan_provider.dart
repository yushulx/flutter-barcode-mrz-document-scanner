import 'package:dynamsoft_capture_vision_flutter/dynamsoft_capture_vision_flutter.dart';
import 'package:flutter/foundation.dart';

class ScanProvider extends ChangeNotifier {
  BigInt _types = BigInt.zero;

  BigInt get types => _types;

  set types(BigInt value) {
    _types = value;
    notifyListeners();
  }

  final Map<String, BarcodeResultItem> _results = {};

  Map<String, BarcodeResultItem> get results => _results;

  /// Adds a barcode to the batch once. Live frames repeat the same code many
  /// times, so the text value is the dedup key and listeners are notified only
  /// when a genuinely new item arrives.
  bool addResult(String key, BarcodeResultItem result) {
    if (_results.containsKey(key)) return false;
    _results[key] = result;
    notifyListeners();
    return true;
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
