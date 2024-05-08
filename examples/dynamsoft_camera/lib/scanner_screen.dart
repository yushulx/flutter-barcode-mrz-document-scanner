import 'dart:io';

import 'package:dynamsoft_capture_vision_flutter/dynamsoft_capture_vision_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'history_view.dart';
import 'overlay_painter.dart';
import 'scan_provider.dart';
import 'switch_provider.dart';

import 'package:url_launcher/url_launcher_string.dart';

import 'utils.dart';

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

  bool _isFlashOn = false;
  bool _isScanning = true;
  String _scanButtonText = 'Stop Scanning';
  bool _isCameraReady = false;
  late ScanProvider _scanProvider;
  bool isPortrait = false;
  double screenWidth = 0;
  double screenHeight = 0;
  double _previewHeight = 1080;
  double _previewWidth = 1920;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sdkInit();
  }

  Future<void> _sdkInit() async {
    _scanProvider = Provider.of<ScanProvider>(context, listen: false);

    _barcodeReader = await DCVBarcodeReader.createInstance();
    _cameraEnhancer = await DCVCameraEnhancer.createInstance();

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

    // Define the scan region.
    // _cameraEnhancer.setScanRegion(Region(
    //     regionTop: 30,
    //     regionLeft: 15,
    //     regionBottom: 70,
    //     regionRight: 85,
    //     regionMeasuredByPercentage: 1));

    // Enable barcode overlay visiblity.
    // _cameraView.overlayVisible = true;

    _cameraView.torchButton = TorchButton(
      visible: true,
    );

    await _barcodeReader.enableResultVerification(true);

    // Stream listener to handle callback when barcode result is returned.
    _barcodeReader.receiveResultStream().listen((List<BarcodeResult>? res) {
      if (mounted) {
        decodeRes = res ?? [];
        if (Platform.isAndroid && isPortrait) {
        decodeRes =
            rotate90barcode(decodeRes, _previewHeight.toInt());
      }
        String msg = '';
        for (var i = 0; i < decodeRes.length; i++) {
          msg += '${decodeRes[i].barcodeText}\n';

          if (_scanProvider.results.containsKey(decodeRes[i].barcodeText)) {
            continue;
          } else {
            _scanProvider.results[decodeRes[i].barcodeText] = decodeRes[i];
          }
        }

        setState(() {});
      }
    });

    start();
  }

  Widget createURLString(String text) {
    // Create a regular expression to match URL strings.
    RegExp urlRegExp = RegExp(
      r'^(https?|http)://[^\s/$.?#].[^\s]*$',
      caseSensitive: false,
      multiLine: false,
    );

    if (urlRegExp.hasMatch(text)) {
      return InkWell(
        child: Text(
          text,
          style: const TextStyle(color: Colors.blue),
        ),
        onTap: () async {
          launchUrlString(text);
        },
      );
    } else {
      return Text(text);
    }
  }

  Widget listItem(BuildContext context, int index) {
    BarcodeResult res = decodeRes[index];

    return ListTileTheme(
        textColor: Colors.white,
        // tileColor: Colors.green,
        child: ListTile(
          title: Text(res.barcodeText),
          subtitle: Text(res.barcodeFormatString),
        ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraEnhancer.close();
    _barcodeReader.stopScanning();
    super.dispose();
  }

  Future<void> stop() async {
    await _cameraEnhancer.close();
    await _barcodeReader.stopScanning();
  }

  Future<void> start() async {
    _isCameraReady = true;
    setState(() {});

    Future.delayed(const Duration(milliseconds: 100), () async {
      // _cameraView.overlayVisible = true;
      await _barcodeReader.startScanning();
      await _cameraEnhancer.open();
    });
  }

  Widget createSwitchWidget(bool switchValue) {
    if (!_isCameraReady) {
      // Return loading indicator if camera is not ready yet.
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    SizedBox fullscreen = SizedBox(
              width: screenWidth,
              height: screenHeight,
              child: FittedBox(
                fit: BoxFit.cover,
                child: Stack(
                  children: [
                    SizedBox(
                      width: isPortrait ? _previewHeight : _previewWidth,
                      height: isPortrait ? _previewWidth : _previewHeight,
                      child: _cameraView,
                    ),
                    Positioned(
                        left: 0,
                        top: 0,
                        right: 0,
                        bottom: 0,
                        child: createOverlay(
                          decodeRes,
                        ))
                  ],
                ),
              ),
            );

    if (switchValue) {
      return Stack(
        children: [
          Container(
            color: Colors.white,
          ),
          Container(
            height: MediaQuery.of(context).size.height -
                200 -
                MediaQuery.of(context).padding.top,
            color: Colors.white,
            child: Center(
              child: createListView(context),
            ),
          ),
          if (_isScanning)
            Positioned(
              top: 0,
              right: 20,
              child: SizedBox(
                width: 160,
                height: 160,
                child: _cameraView,
              ),
            ),
          Positioned(
            bottom: 50,
            left: 50,
            right: 50,
            child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                height: 64,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (_isScanning) {
                          _isScanning = false;
                          stop();
                          _scanButtonText = 'Start Scanning';
                          setState(() {});
                        } else {
                          _isScanning = true;
                          _scanButtonText = 'Stop Scanning';
                          start();
                        }
                      },
                      child: Text(_scanButtonText),
                    ),
                    Center(
                      child: IconButton(
                        icon: const Icon(Icons.flash_on),
                        onPressed: () {
                          if (_isFlashOn) {
                            _isFlashOn = false;
                            _cameraEnhancer.turnOffTorch();
                          } else {
                            _isFlashOn = true;
                            _cameraEnhancer.turnOnTorch();
                          }
                        },
                      ),
                    ),
                  ],
                )),
          ),
        ],
      );
    } else {
      return Stack(
        children: [
          fullscreen,
          SizedBox(
            height: 100,
            child: ListView.builder(
              itemBuilder: listItem,
              itemCount: decodeRes.length,
            ),
          ),
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
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SwitchProvider switchProvider = Provider.of<SwitchProvider>(context);
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    var orientation = MediaQuery.of(context).orientation;
    isPortrait = orientation == Orientation.portrait;

    return Scaffold(
        appBar: AppBar(title: const Text('Batch/Inventory'), actions: [
          IconButton(
            icon: Switch(
              value: switchProvider.switchValue,
              onChanged: (newValue) {
                switchProvider.switchValue = newValue;

                start();
              },
            ),
            onPressed: () {},
          ),
        ]),
        body: createSwitchWidget(switchProvider.switchValue));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        start();
        break;
      case AppLifecycleState.inactive:
        stop();
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
