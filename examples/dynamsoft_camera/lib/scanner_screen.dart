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
  late final CameraEnhancer _cameraEnhancer;
  late final CaptureVisionRouter _cvr;

  List<BarcodeResultItem> decodeRes = [];
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

    _cvr = await CaptureVisionRouter.instance;
    _cameraEnhancer = CameraEnhancer.instance;

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

    // Bind the `CameraEnhancer` object to the `CaptureVisionRouter` object
    _cvr.setInput(_cameraEnhancer);

    // Add `CapturedResultReceiver`
    late final CapturedResultReceiver _receiver = CapturedResultReceiver()
      ..onDecodedBarcodesReceived = (DecodedBarcodesResult result) async {
        List<BarcodeResultItem>? res = result.items;
        if (mounted) {
          decodeRes = res ?? [];
          if (Platform.isAndroid && isPortrait) {
            decodeRes = rotate90barcode(decodeRes, _previewHeight.toInt());
          }
          String msg = '';
          for (var i = 0; i < decodeRes.length; i++) {
            msg += '${decodeRes[i].text}\n';

            if (_scanProvider.results.containsKey(decodeRes[i].text)) {
              continue;
            } else {
              _scanProvider.results[decodeRes[i].text] = decodeRes[i];
            }
          }

          setState(() {});
        }
      };
    _cvr.addResultReceiver(_receiver);

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
    BarcodeResultItem res = decodeRes[index];

    return ListTileTheme(
        textColor: Colors.white,
        // tileColor: Colors.green,
        child: ListTile(
          title: Text(res.text),
          subtitle: Text(res.formatString),
        ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraEnhancer.close();
    _cvr.stopCapturing();
    super.dispose();
  }

  Future<void> stop() async {
    await _cameraEnhancer.close();
    await _cvr.stopCapturing();
  }

  Future<void> start() async {
    _isCameraReady = true;
    setState(() {});

    Future.delayed(const Duration(milliseconds: 100), () async {
      await _cvr.startCapturing(EnumPresetTemplate.readBarcodes);
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
              child: CameraView(cameraEnhancer: _cameraEnhancer),
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
                child: CameraView(cameraEnhancer: _cameraEnhancer),
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
