import 'dart:async';

import 'package:camera_windows/camera_windows.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_barcode_sdk/dynamsoft_barcode.dart';
import 'package:flutter_barcode_sdk/flutter_barcode_sdk.dart';

import '../global.dart';

import 'package:camera_platform_interface/camera_platform_interface.dart';

class CameraManager {
  BuildContext context;
  CameraController? controller;
  late List<CameraDescription> _cameras;
  Size? previewSize;
  bool _isScanAvailable = true;
  List<BarcodeResult>? barcodeResults;
  bool isDriverLicense = true;
  bool isFinished = false;
  StreamSubscription<FrameAvailabledEvent>? _frameAvailableStreamSubscription;
  int cameraIndex = 0;
  bool isReadyToGo = false;
  bool _isWebFrameStarted = false;

  CameraManager(
      {required this.context,
      required this.cbRefreshUi,
      required this.cbIsMounted,
      required this.cbNavigation});

  Function cbRefreshUi;
  Function cbIsMounted;
  Function cbNavigation;

  void initState() {
    initCamera();
  }

  Future<void> switchCamera() async {
    if (_cameras.length == 1) return;
    isFinished = true;

    if (kIsWeb) {
      await waitForStop();
    }

    cameraIndex = cameraIndex == 0 ? 1 : 0;
    toggleCamera(cameraIndex);
  }

  void resumeCamera() {
    toggleCamera(cameraIndex);
  }

  void pauseCamera() {
    stopVideo();
  }

  Future<void> waitForStop() async {
    while (true) {
      if (_isWebFrameStarted == false) {
        break;
      }

      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<void> stopVideo() async {
    isFinished = true;
    if (kIsWeb) {
      await waitForStop();
    }
    if (controller == null) return;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await controller!.stopImageStream();
    }

    controller!.dispose();
    controller = null;

    _frameAvailableStreamSubscription?.cancel();
    _frameAvailableStreamSubscription = null;
  }

  Future<void> webCamera() async {
    _isWebFrameStarted = true;
    while (!(controller == null || isFinished || cbIsMounted() == false)) {
      XFile? file = await controller?.takePicture();
      // calculate elapsed time
      if (file != null) {
        // var start = DateTime.now().millisecondsSinceEpoch;
        var results = await barcodeReader.decodeFile(file.path);
        // var end = DateTime.now().millisecondsSinceEpoch;
        // print('decodeFile time: ${end - start}');
        if (!cbIsMounted()) break;

        barcodeResults = results;
      }

      cbRefreshUi();
      if (isReadyToGo && barcodeResults != null) {
        handleBarcode(barcodeResults!);
      }
    }
    _isWebFrameStarted = false;
  }

  void handleBarcode(List<BarcodeResult> results) {
    if (results.isNotEmpty) {
      if (!isFinished) {
        isFinished = true;
        cbNavigation(results);
      }
    }
  }

  void processId(
      Uint8List bytes, int width, int height, int stride, int format) {
    barcodeReader
        .decodeImageBuffer(bytes, width, height, stride, format)
        .then((results) {
      if (!cbIsMounted()) {
        return;
      }

      if (MediaQuery.of(context).size.width <
          MediaQuery.of(context).size.height) {
        if (Platform.isAndroid && results.isNotEmpty) {
          results = rotate90barcode(results, previewSize!.height.toInt());
        }
      }

      barcodeResults = results;
      cbRefreshUi();
      if (isReadyToGo) {
        handleBarcode(results);
      }

      _isScanAvailable = true;
    });
  }

  Future<void> mobileCamera() async {
    await controller!.startImageStream((CameraImage availableImage) async {
      assert(defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
      if (cbIsMounted() == false || isFinished) return;
      int format = ImagePixelFormat.IPF_NV21.index;

      switch (availableImage.format.group) {
        case ImageFormatGroup.yuv420:
          format = ImagePixelFormat.IPF_NV21.index;
          break;
        case ImageFormatGroup.bgra8888:
          format = ImagePixelFormat.IPF_ARGB_8888.index;
          break;
        default:
          format = ImagePixelFormat.IPF_RGB_888.index;
      }

      if (!_isScanAvailable) {
        return;
      }

      _isScanAvailable = false;

      processId(availableImage.planes[0].bytes, availableImage.width,
          availableImage.height, availableImage.planes[0].bytesPerRow, format);
    });
  }

  Future<void> startVideo() async {
    barcodeResults = null;

    isFinished = false;

    cbRefreshUi();

    if (kIsWeb) {
      webCamera();
    } else if (Platform.isAndroid || Platform.isIOS) {
      mobileCamera();
    } else if (Platform.isWindows) {
      _frameAvailableStreamSubscription?.cancel();
      _frameAvailableStreamSubscription =
          (CameraPlatform.instance as CameraWindows)
              .onFrameAvailable(controller!.cameraId)
              .listen(_onFrameAvailable);
    }
  }

  void _onFrameAvailable(FrameAvailabledEvent event) {
    if (cbIsMounted() == false || isFinished) return;

    Map<String, dynamic> map = event.toJson();
    final Uint8List? data = map['bytes'] as Uint8List?;
    if (data != null) {
      if (!_isScanAvailable) {
        return;
      }

      _isScanAvailable = false;
      int width = previewSize!.width.toInt();
      int height = previewSize!.height.toInt();

      processId(
          data, width, height, width * 4, ImagePixelFormat.IPF_ARGB_8888.index);
    }
  }

  Future<void> initCamera() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      _cameras = await availableCameras();
      // int index = 0;

      // for (; index < _cameras.length; index++) {
      //   CameraDescription description = _cameras[index];
      //   if (description.name.toLowerCase().contains('back')) {
      //     _isMobileWeb = true;
      //     break;
      //   }
      // }
      if (_cameras.isEmpty) return;

      if (!kIsWeb) {
        toggleCamera(cameraIndex);
      } else {
        if (_cameras.length > 1) {
          cameraIndex = 1;
          toggleCamera(cameraIndex);
        } else {
          toggleCamera(cameraIndex);
        }
      }
    } on CameraException catch (e) {
      print(e);
    }
  }

  Widget getPreview() {
    if (controller == null || !controller!.value.isInitialized || isFinished) {
      return Container(
        child: const Text('No camera available!'),
      );
    }

    // if (kIsWeb && !_isMobileWeb) {
    //   return Transform(
    //     alignment: Alignment.center,
    //     transform: Matrix4.identity()..scale(-1.0, 1.0), // Flip horizontally
    //     child: CameraPreview(controller!),
    //   );
    // }

    return CameraPreview(controller!);
  }

  Future<void> toggleCamera(int index) async {
    // if (controller != null) controller!.dispose();
    ResolutionPreset preset = ResolutionPreset.high;
    if (kIsWeb) {
      preset = ResolutionPreset.medium;
    }
    controller = CameraController(_cameras[index], preset);
    controller!.initialize().then((_) {
      if (!cbIsMounted()) {
        return;
      }

      previewSize = controller!.value.previewSize;

      startVideo();
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            break;
          default:
            break;
        }
      }
    });
  }
}
