import 'package:dynamsoft_capture_vision_flutter/dynamsoft_capture_vision_flutter.dart';
import 'package:flutter/material.dart';

import 'globals.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  late final DCVCameraEnhancer _cameraEnhancer;
  late final DCVBarcodeReader _barcodeReader;

  final DCVCameraView _cameraView = DCVCameraView();

  List<BarcodeResult> decodeRes = [];
  String? resultText;
  bool faceLens = false;
  bool _isScanning = true;
  bool _ready = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sdkInit();
  }

  Future<void> _sdkInit() async {
    try {
      await DCVBarcodeReader.initLicense(
          'DLS2eyJoYW5kc2hha2VDb2RlIjoiMjAwMDAxLTE2NDk4Mjk3OTI2MzUiLCJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSIsInNlc3Npb25QYXNzd29yZCI6IndTcGR6Vm05WDJrcEQ5YUoifQ==');
    } catch (e) {
      print(e);
    }
    _barcodeReader = await DCVBarcodeReader.createInstance();
    _cameraEnhancer = await DCVCameraEnhancer.createInstance();

    // Get the current runtime settings of the barcode reader.
    DBRRuntimeSettings currentSettings =
        await _barcodeReader.getRuntimeSettings();
    // Set the barcode format to read.
    currentSettings.barcodeFormatIds =
        EnumBarcodeFormat.BF_ONED | EnumBarcodeFormat.BF_QR_CODE;

    // currentSettings.minResultConfidence = 70;
    // currentSettings.minBarcodeTextLength = 50;

    // Set the expected barcode count to 0 when you are not sure how many barcodes you are scanning.
    // Set the expected barcode count to 1 can maximize the barcode decoding speed.
    currentSettings.expectedBarcodeCount = 0;
    // Apply the new runtime settings to the barcode reader.
    await _barcodeReader
        .updateRuntimeSettingsFromTemplate(EnumDBRPresetTemplate.DEFAULT);
    await _barcodeReader.updateRuntimeSettings(currentSettings);

    // Define the scan region.
    _cameraEnhancer.setScanRegion(Region(
        regionTop: 30,
        regionLeft: 15,
        regionBottom: 70,
        regionRight: 85,
        regionMeasuredByPercentage: 1));

    // Enable barcode overlay visiblity.
    _cameraView.overlayVisible = true;

    _cameraView.torchButton = TorchButton(
      visible: true,
    );

    await _barcodeReader.enableResultVerification(true);

    // Stream listener to handle callback when barcode result is returned.
    _barcodeReader.receiveResultStream().listen((List<BarcodeResult>? res) {
      if (mounted) {
        decodeRes = res ?? [];
        String msg = '';
        for (var i = 0; i < decodeRes.length; i++) {
          msg += '${decodeRes[i].barcodeText}\n';
        }
        if (msg.isNotEmpty && _ready) {
          // _barcodeReader.stopScanning();
          // _isScanning = false;
          _ready = false;
          sendMessage(msg);

          // setState(() {
          //   decodeRes = [];
          //   _cameraView.overlayVisible = false;
          // });
          Future.delayed(const Duration(seconds: 2), () async {
            _ready = true;
          });
        }

        setState(() {});
      }
    });

    await _cameraEnhancer.open();

    // Enable video barcode scanning.
    // If the camera is opened, the barcode reader will start the barcode decoding thread when you triggered the startScanning.
    // The barcode reader will scan the barcodes continuously before you trigger stopScanning.
    _barcodeReader.startScanning();
  }

  Widget listItem(BuildContext context, int index) {
    BarcodeResult res = decodeRes[index];

    return ListTileTheme(
        textColor: Colors.white,
        // tileColor: Colors.green,
        child: ListTile(
          title: Text(res.barcodeFormatString),
          subtitle: Text(res.barcodeText),
        ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraEnhancer.close();
    _barcodeReader.stopScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Barcode Scanner'),
        ),
        body: Stack(
          children: [
            Container(
              child: _cameraView,
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                itemBuilder: listItem,
                itemCount: decodeRes.length,
              ),
            ),
            Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Container(
                  width: 64,
                  height: 64,
                  child: MaterialButton(
                    onPressed: () {
                      if (_isScanning == true) {
                        _barcodeReader.stopScanning();
                        _isScanning = false;
                        setState(() {
                          decodeRes = [];
                          _cameraView.overlayVisible = false;
                        });
                      } else {
                        _barcodeReader.startScanning();
                        _isScanning = true;
                        _cameraView.overlayVisible = true;
                      }
                    },
                    color: _isScanning ? Colors.blue : Colors.red,
                    shape: const CircleBorder(),
                  ),
                ))
          ],
        ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _barcodeReader.startScanning();
        _cameraEnhancer.open();
        break;
      case AppLifecycleState.inactive:
        _cameraEnhancer.close();
        _barcodeReader.stopScanning();
        break;
      case AppLifecycleState.paused:
        // TODO: Handle this case.
        break;
      case AppLifecycleState.detached:
        // TODO: Handle this case.
        break;
    }
  }
}
