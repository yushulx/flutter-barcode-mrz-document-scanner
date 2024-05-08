import 'package:flutter/material.dart';
import 'package:dynamsoft_capture_vision_flutter/dynamsoft_capture_vision_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _is1dChecked = true;
  bool _isQrChecked = true;
  bool _isPdf417Checked = true;
  bool _isDataMatrixChecked = true;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // override the pop action
      onWillPop: () async {
        int format = 0;
        if (_is1dChecked) {
          format |= EnumBarcodeFormat.BF_ONED;
        }
        if (_isQrChecked) {
          format |= EnumBarcodeFormat.BF_QR_CODE;
        }
        if (_isPdf417Checked) {
          format |= EnumBarcodeFormat.BF_PDF417;
        }
        if (_isDataMatrixChecked) {
          format |= EnumBarcodeFormat.BF_DATAMATRIX;
        }
        Navigator.pop(context, {'format': format});
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: ListView(
          children: <Widget>[
            CheckboxListTile(
              title: const Text('1D Barcode'),
              value: _is1dChecked,
              onChanged: (bool? value) {
                setState(() {
                  _is1dChecked = value!;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('QR Code'),
              value: _isQrChecked,
              onChanged: (bool? value) {
                setState(() {
                  _isQrChecked = value!;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('PDF417'),
              value: _isPdf417Checked,
              onChanged: (bool? value) {
                setState(() {
                  _isPdf417Checked = value!;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('DataMatrix'),
              value: _isDataMatrixChecked,
              onChanged: (bool? value) {
                setState(() {
                  _isDataMatrixChecked = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
