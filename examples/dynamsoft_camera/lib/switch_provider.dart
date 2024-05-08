import 'package:flutter/foundation.dart';

class SwitchProvider extends ChangeNotifier {
  bool _switchValue = false;

  bool get switchValue => _switchValue;

  set switchValue(bool value) {
    _switchValue = value;
    notifyListeners();
  }
}
