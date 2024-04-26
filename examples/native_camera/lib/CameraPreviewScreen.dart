import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'barcode_result.dart';
import 'global.dart';

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  static const platform = MethodChannel('barcode_scan');
  int? _textureId;
  List<BarcodeResult>? barcodeResults;
  double _previewWidth = 0.0;
  double _previewHeight = 0.0;
  bool isPortrait = false;

  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler(_handleMethod);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final int textureId = await platform.invokeMethod('startCamera');
      final double previewWidth =
          await platform.invokeMethod('getPreviewWidth');
      final double previewHeight =
          await platform.invokeMethod('getPreviewHeight');
      setState(() {
        _textureId = textureId;
        _previewWidth = previewWidth;
        _previewHeight = previewHeight;
      });
    } catch (e) {
      print(e);
    }
  }

  // https://github.com/flutter/packages/tree/main/packages/camera/camera_android_camerax
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    var orientation = MediaQuery.of(context).orientation;
    isPortrait = orientation == Orientation.portrait;
    return Scaffold(
      body: _textureId == null
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              width: screenWidth,
              height: screenHeight,
              child: FittedBox(
                fit: BoxFit.cover,
                child: Stack(
                  children: [
                    SizedBox(
                      width: isPortrait ? _previewHeight : _previewWidth,
                      height: isPortrait ? _previewWidth : _previewHeight,
                      child: Texture(textureId: _textureId!),
                    ),
                    Positioned(
                        left: 0,
                        top: 0,
                        right: 0,
                        bottom: 0,
                        child: createOverlay(
                          barcodeResults,
                        ))
                  ],
                ),
              ),
            ),
    );
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    if (call.method == "onBarcodeDetected") {
      barcodeResults =
          convertResults(List<Map<dynamic, dynamic>>.from(call.arguments));
      if (Platform.isAndroid && isPortrait && barcodeResults != null) {
        barcodeResults =
            rotate90barcode(barcodeResults!, _previewHeight.toInt());
      }

      setState(() {});
    }
  }
}
