import 'dart:io';

import 'package:dynamsoft_capture_vision_flutter/dynamsoft_capture_vision_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'history_view.dart';
import 'overlay_painter.dart';
import 'scan_provider.dart';
import 'switch_provider.dart';
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

  bool _isFlashOn = false;
  bool _isScanning = true;
  String _scanButtonText = 'Stop Scanning';
  bool _isCameraReady = false;
  late ScanProvider _scanProvider;
  bool isPortrait = false;
  double screenWidth = 0;
  double screenHeight = 0;
  final double _previewHeight = 1080;
  final double _previewWidth = 1920;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PermissionUtil.requestCameraPermission();
    _sdkInit();
  }

  Future<void> _sdkInit() async {
    _scanProvider = Provider.of<ScanProvider>(context, listen: false);

    _cvr = CaptureVisionRouter();
    _cameraEnhancer = CameraEnhancer();

    SimplifiedCaptureVisionSettings? currentSettings =
        await _cvr.getSimplifiedSettings(EnumPresetTemplate.readBarcodes);
    if (_scanProvider.types != BigInt.zero) {
      currentSettings!.barcodeSettings!.barcodeFormatIds = _scanProvider.types;
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
    final CapturedResultReceiver receiver = CapturedResultReceiver()
      ..onDecodedBarcodesReceived = (DecodedBarcodesResult result) async {
        List<BarcodeResultItem>? res = result.items;
        if (mounted) {
          decodeRes = res ?? [];
          if (Platform.isAndroid && isPortrait) {
            decodeRes = rotate90barcode(decodeRes, _previewHeight.toInt());
          }
          for (final item in decodeRes) {
            _scanProvider.addResult(item.text, item);
          }

          setState(() {});
        }
      };
    _cvr.addResultReceiver(receiver);

    await start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Stop capturing before closing, then release the native instances.
    // Leaving them alive keeps the camera bound on some devices, so the next
    // scan screen cannot open it again.
    _cvr.stopCapturing();
    _cameraEnhancer.close();
    _cvr.dispose();
    _cameraEnhancer.dispose();
    super.dispose();
  }

  Future<void> stop() async {
    _isCameraReady = false;
    try {
      await _cvr.stopCapturing();
    } finally {
      await _cameraEnhancer.close();
    }
  }

  Future<void> start() async {
    _isCameraReady = true;
    setState(() {});

    Future.delayed(const Duration(milliseconds: 100), () async {
      if (!mounted) return;
      // Open the preview FIRST. startCapturing() can fail (an expired or
      // unreachable trial license is the usual cause); if it throws before
      // open() is awaited, the camera never opens and the screen stays black.
      try {
        await _cameraEnhancer.open();
        await _cvr.startCapturing(EnumPresetTemplate.readBarcodes);
      } catch (e) {
        debugPrint('Camera/scan start failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not start scanning: $e')),
          );
        }
      }
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
      // Fullscreen camera mode: the CustomPainter overlay already shows the
      // decoded text and quadrilaterals, so no result list is stacked here.
      return Stack(
        children: [
          fullscreen,
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
      case AppLifecycleState.hidden:
        // TODO: Handle this case.
        break;
    }
  }
}
