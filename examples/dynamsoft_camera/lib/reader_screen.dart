import 'dart:io';

import 'package:dynamsoft_capture_vision_flutter/dynamsoft_capture_vision_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:image_picker/image_picker.dart';

import 'package:provider/provider.dart';

import 'overlay_painter.dart';
import 'scan_provider.dart';
import 'history_view.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _imagePicker = ImagePicker();
  String? _file;
  List<BarcodeResult> _results = [];
  late final DCVBarcodeReader _barcodeReader;
  late ScanProvider _scanProvider;

  @override
  void initState() {
    super.initState();
    _sdkInit();
  }

  Future<void> _sdkInit() async {
    _scanProvider = Provider.of<ScanProvider>(context, listen: false);

    _barcodeReader = await DCVBarcodeReader.createInstance();

    // Get the current runtime settings of the barcode reader.
    DBRRuntimeSettings currentSettings =
        await _barcodeReader.getRuntimeSettings();
    // Set the barcode format to read.

    if (_scanProvider.types != 0) {
      currentSettings.barcodeFormatIds = _scanProvider.types;
    } else {
      currentSettings.barcodeFormatIds = EnumBarcodeFormat.BF_ALL;
    }

    // currentSettings.minResultConfidence = 70;
    // currentSettings.minBarcodeTextLength = 50;

    // Set the expected barcode count to 0 when you are not sure how many barcodes you are scanning.
    // Set the expected barcode count to 1 can maximize the barcode decoding speed.
    currentSettings.expectedBarcodeCount = 0;
    // Apply the new runtime settings to the barcode reader.
    await _barcodeReader
        .updateRuntimeSettingsFromTemplate(EnumDBRPresetTemplate.DEFAULT);
    await _barcodeReader.updateRuntimeSettings(currentSettings);
  }

  Widget getImage() {
    return _file == null
        ? Image.asset(
            'images/default.png',
          )
        : Image.file(
            File(_file!),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: () async {
              XFile? pickedFile =
                  await _imagePicker.pickImage(source: ImageSource.camera);

              if (pickedFile != null) {
                final rotatedImage = await FlutterExifRotation.rotateImage(
                    path: pickedFile.path);
                _file = rotatedImage.path;
                _results = await _barcodeReader.decodeFile(_file!) ?? [];
                for (var i = 0; i < _results.length; i++) {
                  if (_scanProvider.results
                      .containsKey(_results[i].barcodeText)) {
                    continue;
                  } else {
                    _scanProvider.results[_results[i].barcodeText] =
                        _results[i];
                  }
                }
                setState(() {});
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_open),
            onPressed: () async {
              XFile? pickedFile =
                  await _imagePicker.pickImage(source: ImageSource.gallery);

              if (pickedFile != null) {
                final rotatedImage = await FlutterExifRotation.rotateImage(
                    path: pickedFile.path);
                _file = rotatedImage.path;
                _results = await _barcodeReader.decodeFile(_file!) ?? [];
                for (var i = 0; i < _results.length; i++) {
                  if (_scanProvider.results
                      .containsKey(_results[i].barcodeText)) {
                    continue;
                  } else {
                    _scanProvider.results[_results[i].barcodeText] =
                        _results[i];
                  }
                }
                setState(() {});
              }
            },
          )
        ],
      ),
      body: Center(
        child: Stack(
          children: <Widget>[
            SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Stack(
                    children: [
                      getImage(),
                      Positioned(
                        top: 0.0,
                        right: 0.0,
                        bottom: 0.0,
                        left: 0.0,
                        child: _results.isEmpty
                            ? Container(
                                color: Colors.black.withOpacity(0.1),
                                child: const Center(
                                  child: Text(
                                    'No barcode detected',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ))
                            : createOverlay(_results),
                      ),
                    ],
                  ),
                )),
            Positioned(
                bottom: 50,
                left: 50,
                right: 50,
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HistoryView(
                                  title: 'Scan Results',
                                )),
                      );
                    },
                    child: const Text('Show Results'),
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
