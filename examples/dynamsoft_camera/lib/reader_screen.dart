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
  List<BarcodeResultItem> _results = [];
  late final CaptureVisionRouter _cvr;
  late ScanProvider _scanProvider;

  @override
  void initState() {
    super.initState();
    _sdkInit();
  }

  Future<void> _sdkInit() async {
    _scanProvider = Provider.of<ScanProvider>(context, listen: false);

    _cvr = CaptureVisionRouter.instance;
    SimplifiedCaptureVisionSettings? currentSettings =
        await _cvr.getSimplifiedSettings(EnumPresetTemplate.readBarcodes);
    if (_scanProvider.types != 0) {
      currentSettings!.barcodeSettings!.barcodeFormatIds =
          _scanProvider.types as BigInt;
    } else {
      currentSettings!.barcodeSettings!.barcodeFormatIds =
          EnumBarcodeFormat.all;
    }

    currentSettings.barcodeSettings!.expectedBarcodesCount = 0;
    // Apply the new runtime settings to the barcode reader.
    await _cvr.updateSettings(EnumPresetTemplate.readBarcodes, currentSettings);
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
                CapturedResult capturedResult = await _cvr.captureFile(
                    _file!, EnumPresetTemplate.readBarcodes);
                _results = capturedResult.decodedBarcodesResult!.items ?? [];
                for (var i = 0; i < _results.length; i++) {
                  if (_scanProvider.results.containsKey(_results[i].text)) {
                    continue;
                  } else {
                    _scanProvider.results[_results[i].text] = _results[i];
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
                CapturedResult capturedResult = await _cvr.captureFile(
                    _file!, EnumPresetTemplate.readBarcodes);
                _results = capturedResult.decodedBarcodesResult!.items ?? [];
                for (var i = 0; i < _results.length; i++) {
                  if (_scanProvider.results.containsKey(_results[i].text)) {
                    continue;
                  } else {
                    _scanProvider.results[_results[i].text] = _results[i];
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
