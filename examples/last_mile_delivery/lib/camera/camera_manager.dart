import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:camera_windows/camera_windows.dart';
import 'package:delivery/data/profile_data.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_barcode_sdk/dynamsoft_barcode.dart';
import 'package:flutter_barcode_sdk/flutter_barcode_sdk.dart';
import 'package:flutter_document_scan_sdk/document_result.dart';
import 'package:flutter_ocr_sdk/mrz_line.dart';

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter_ocr_sdk/mrz_parser.dart';
import 'package:flutter_ocr_sdk/mrz_result.dart';

import '../data/driver_license.dart';
import '../global.dart';
import '../utils.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera_platform_interface/camera_platform_interface.dart';

enum ScanType { id, barcode, document }

class CameraManager {
  BuildContext context;
  CameraController? controller;
  late List<CameraDescription> _cameras;
  Size? previewSize;
  bool _isScanAvailable = true;
  List<BarcodeResult>? barcodeResults;
  List<List<MrzLine>>? mrzLines;
  List<DocumentResult>? documentResults;
  bool isDriverLicense = true;
  ScanType scanType = ScanType.id;
  bool isFinished = false;
  StreamSubscription<FrameAvailabledEvent>? _frameAvailableStreamSubscription;
  bool _isMobileWeb = false;
  DocumentResult? _base;
  int _baseIndex = 0;

  CameraManager(
      {required this.context,
      required this.cbRefreshUi,
      required this.cbIsMounted,
      required this.cbNavigation,
      required this.scanType});

  Function cbRefreshUi;
  Function cbIsMounted;
  Function cbNavigation;

  void initState() {
    initCamera();
  }

  Future<void> stopVideo() async {
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
    if (controller == null || isFinished || cbIsMounted() == false) return;

    XFile file = await controller!.takePicture();

    if (scanType == ScanType.id) {
      if (isDriverLicense) {
        var results = await barcodeReader.decodeFile(file.path);
        if (!cbIsMounted()) return;
        barcodeResults = results;
        // cbRefreshUi();
        handleDriverLicense(results);
      } else {
        var results = await mrzDetector.recognizeByFile(file.path);
        if (results == null || !cbIsMounted()) return;

        mrzLines = results;
        // cbRefreshUi();
        handleMrz(results);
      }
    } else if (scanType == ScanType.barcode) {
      var results = await barcodeReader.decodeFile(file.path);
      if (!cbIsMounted()) return;

      barcodeResults = results;

      handleBarcode(results);
    } else if (scanType == ScanType.document) {
      var results = await docScanner.detectFile(file.path);
      if (!cbIsMounted()) return;

      // results = filterResults(
      //     results, previewSize!.width.toInt(), previewSize!.height.toInt());

      if (results == null || results.isEmpty) {
        webCamera();
        return;
      }

      documentResults = results;
      cbRefreshUi();
      if (_base == null) {
        _baseIndex += 1;
        _base = results[0];
      } else {
        double previousArea = calculateArea(_base!.points[0], _base!.points[1],
            _base!.points[2], _base!.points[3]);
        double currentArea = calculateArea(results[0].points[0],
            results[0].points[1], results[0].points[2], results[0].points[3]);
        double diff = previousArea - currentArea > 0
            ? previousArea - currentArea
            : currentArea - previousArea;
        if (diff / previousArea < 0.2) {
          _baseIndex += 1;
        } else {
          _baseIndex = 1;
        }

        _base = results[0];
      }

      if (_baseIndex == 10 && results.isNotEmpty) {
        if (!isFinished) {
          isFinished = true;

          final data = await file.readAsBytes();
          ui.Image sourceImage = await decodeImageFromList(data);
          ByteData? byteData =
              await sourceImage.toByteData(format: ui.ImageByteFormat.rawRgba);

          Uint8List bytes = byteData!.buffer.asUint8List();
          int width = sourceImage.width;
          int height = sourceImage.height;
          int stride = byteData.lengthInBytes ~/ sourceImage.height;
          int format = ImagePixelFormat.IPF_ARGB_8888.index;
          handleDocument(
              bytes, width, height, stride, format, documentResults![0].points);
        }
      }
    }

    if (!isFinished) {
      webCamera();
    }
  }

  void processDocument(List<Uint8List> bytes, int width, int height,
      List<int> strides, int format, List<int> pixelStrides) {
    docScanner
        .detectBuffer(bytes[0], width, height, strides[0], format)
        .then((results) {
      if (!cbIsMounted()) return;
      // results = filterResults(results, width, height);
      if (results == null || results.isEmpty) {
        documentResults = results;
        cbRefreshUi();
        _isScanAvailable = true;
        return;
      }
      if (MediaQuery.of(context).size.width <
          MediaQuery.of(context).size.height) {
        if (Platform.isAndroid) {
          results = rotate90document(results, previewSize!.height.toInt());
        }
      }

      documentResults = results;
      cbRefreshUi();
      if (_base == null) {
        _baseIndex += 1;
        _base = results[0];
      } else {
        double previousArea = calculateArea(_base!.points[0], _base!.points[1],
            _base!.points[2], _base!.points[3]);
        double currentArea = calculateArea(results[0].points[0],
            results[0].points[1], results[0].points[2], results[0].points[3]);
        double diff = previousArea - currentArea > 0
            ? previousArea - currentArea
            : currentArea - previousArea;
        if (diff / previousArea < 0.2) {
          _baseIndex += 1;
        } else {
          _baseIndex = 1;
        }

        _base = results[0];
      }

      if (_baseIndex == 10 && results.isNotEmpty) {
        if (!isFinished) {
          isFinished = true;

          Uint8List data = bytes[0];
          int imageWidth = width;
          int imageHeight = height;

          if (format == ImagePixelFormat.IPF_NV21.index) {
            List<Uint8List> planes = [];
            for (int planeIndex = 0; planeIndex < 3; planeIndex++) {
              Uint8List buffer;
              int planeWidth;
              int planeHeight;
              if (planeIndex == 0) {
                planeWidth = width;
                planeHeight = height;
              } else {
                planeWidth = width ~/ 2;
                planeHeight = height ~/ 2;
              }

              buffer = Uint8List(planeWidth * planeHeight);

              int pixelStride = pixelStrides[planeIndex];
              int rowStride = strides[0];
              int index = 0;
              for (int i = 0; i < planeHeight; i++) {
                for (int j = 0; j < planeWidth; j++) {
                  buffer[index++] =
                      bytes[planeIndex][i * rowStride + j * pixelStride];
                }
              }

              planes.add(buffer);
            }

            data = yuv420ToRgba8888(planes, imageWidth, imageHeight);
            if (MediaQuery.of(context).size.width <
                MediaQuery.of(context).size.height) {
              if (Platform.isAndroid) {
                data = rotate90Degrees(data, imageWidth, imageHeight);
                imageWidth = height;
                imageHeight = width;
              }
            }
          }

          handleDocument(data, imageWidth, imageHeight, imageWidth * 4,
              ImagePixelFormat.IPF_ARGB_8888.index, results[0].points);
        }
      }

      _isScanAvailable = true;
    });
  }

  void processBarcode(
      Uint8List bytes, int width, int height, int stride, int format) {
    barcodeReader
        .decodeImageBuffer(bytes, width, height, stride, format)
        .then((results) {
      if (!cbIsMounted()) return;
      if (MediaQuery.of(context).size.width <
          MediaQuery.of(context).size.height) {
        if (Platform.isAndroid) {
          results = rotate90barcode(results, previewSize!.height.toInt());
        }
      }
      barcodeResults = results;
      handleBarcode(results);

      _isScanAvailable = true;
    });
  }

  void handleDriverLicense(List<BarcodeResult> results) {
    if (results.isNotEmpty) {
      Map<String, String>? map = parseLicense(results[0].text);
      if (map.isNotEmpty) {
        ProfileData scannedData = ProfileData();
        if (map['DAC'] == null || map['DAC'] == '') {
          scannedData.firstName = 'Not found';
        } else {
          scannedData.firstName = map['DAC'];
        }

        if (map['DCS'] == null || map['DCS'] == '') {
          scannedData.lastName = 'Not found';
        } else {
          scannedData.lastName = map['DCS'];
        }

        if (map['DCG'] == null || map['DCG'] == '') {
          scannedData.nationality = 'Not found';
        } else {
          scannedData.nationality = map['DCG'];
        }

        if (map['DAQ'] == null || map['DAQ'] == '') {
          scannedData.idNumber = 'Not found';
        } else {
          scannedData.idNumber = map['DAQ'];
        }
        if (!isFinished) {
          isFinished = true;

          cbNavigation(scannedData);
        }
      }
    }
  }

  void handleMrz(List<List<MrzLine>> results) {
    if (results.isNotEmpty) {
      MrzResult information = MrzResult();

      try {
        for (List<MrzLine> area in results) {
          if (area.length == 2) {
            information = MRZ.parseTwoLines(area[0].text, area[1].text);
          } else if (area.length == 3) {
            information =
                MRZ.parseThreeLines(area[0].text, area[1].text, area[2].text);
          }
        }
      } catch (e) {
        print(e);
      }

      if (information.surname == '') {
        information.surname = 'Not found';
      }

      if (information.givenName == '') {
        information.givenName = 'Not found';
      }

      if (information.nationality == '') {
        information.nationality = 'Not found';
      }

      if (information.passportNumber == '') {
        information.passportNumber = 'Not found';
      }

      if (!isFinished) {
        isFinished = true;
        ProfileData scannedData = ProfileData();

        scannedData.firstName = information.givenName;
        scannedData.lastName = information.surname;
        scannedData.nationality = information.nationality;
        scannedData.idNumber = information.passportNumber;
        cbNavigation(scannedData);
      }
    }
  }

  void handleBarcode(List<BarcodeResult> results) {
    if (results.isNotEmpty) {
      if (!isFinished) {
        isFinished = true;
        var random = Random();
        var element = orders[random.nextInt(orders.length)];
        cbNavigation(element);
      }
    }
  }

  void handleDocument(Uint8List bytes, int width, int height, int stride,
      int format, dynamic points) {
    docScanner
        .normalizeBuffer(bytes, width, height, stride, format, points)
        .then((normalizedImage) {
      if (normalizedImage != null) {
        PixelFormat pixelFormat = PixelFormat.rgba8888;
        if (!kIsWeb && Platform.isIOS) {
          pixelFormat = PixelFormat.bgra8888;
        }
        decodeImageFromPixels(normalizedImage.data, normalizedImage.width,
            normalizedImage.height, pixelFormat, (ui.Image img) {
          cbNavigation(img);
        });
      }
    });
  }

  void processId(
      Uint8List bytes, int width, int height, int stride, int format) {
    if (isDriverLicense) {
      barcodeReader
          .decodeImageBuffer(bytes, width, height, stride, format)
          .then((results) {
        if (!cbIsMounted()) return;
        if (MediaQuery.of(context).size.width <
            MediaQuery.of(context).size.height) {
          if (Platform.isAndroid) {
            results = rotate90barcode(results, previewSize!.height.toInt());
          }
        }
        barcodeResults = results;
        // cbRefreshUi();
        handleDriverLicense(results);

        _isScanAvailable = true;
      });
    } else {
      barcodeResults = null;
      cbRefreshUi();
      mrzDetector
          .recognizeByBuffer(bytes, width, height, stride, format)
          .then((results) {
        if (results == null || !cbIsMounted()) return;

        if (MediaQuery.of(context).size.width <
            MediaQuery.of(context).size.height) {
          if (Platform.isAndroid) {
            results = rotate90mrz(results, previewSize!.height.toInt());
          }
        }

        mrzLines = results;
        // cbRefreshUi();
        handleMrz(results);

        _isScanAvailable = true;
      });
    }
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

      if (scanType == ScanType.id) {
        processId(
            availableImage.planes[0].bytes,
            availableImage.width,
            availableImage.height,
            availableImage.planes[0].bytesPerRow,
            format);
      } else if (scanType == ScanType.barcode) {
        processBarcode(
            availableImage.planes[0].bytes,
            availableImage.width,
            availableImage.height,
            availableImage.planes[0].bytesPerRow,
            format);
      } else if (scanType == ScanType.document) {
        if (Platform.isAndroid) {
          processDocument(
              [
                availableImage.planes[0].bytes,
                availableImage.planes[1].bytes,
                availableImage.planes[2].bytes
              ],
              availableImage.width,
              availableImage.height,
              [
                availableImage.planes[0].bytesPerRow,
                availableImage.planes[1].bytesPerRow,
                availableImage.planes[2].bytesPerRow
              ],
              format,
              [
                availableImage.planes[0].bytesPerPixel!,
                availableImage.planes[1].bytesPerPixel!,
                availableImage.planes[2].bytesPerPixel!
              ]);
        } else if (Platform.isIOS) {
          processDocument(
              [availableImage.planes[0].bytes],
              availableImage.width,
              availableImage.height,
              [availableImage.planes[0].bytesPerRow],
              format,
              []);
        }
      }
    });
  }

  Future<void> startVideo() async {
    barcodeResults = null;
    mrzLines = null;
    documentResults = null;

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

      if (scanType == ScanType.id) {
        processId(data, width, height, width * 4,
            ImagePixelFormat.IPF_ARGB_8888.index);
      } else if (scanType == ScanType.barcode) {
        processBarcode(data, width, height, width * 4,
            ImagePixelFormat.IPF_ARGB_8888.index);
      } else if (scanType == ScanType.document) {
        processDocument([data], width, height, [width * 4],
            ImagePixelFormat.IPF_ARGB_8888.index, []);
      }
    }
  }

  Future<void> initCamera() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      _cameras = await availableCameras();
      int index = 0;

      for (; index < _cameras.length; index++) {
        CameraDescription description = _cameras[index];
        if (description.name.toLowerCase().contains('back')) {
          _isMobileWeb = true;
          break;
        }
      }
      if (_cameras.isEmpty) return;

      if (!kIsWeb) {
        toggleCamera(0);
      } else {
        if (_isMobileWeb) {
          toggleCamera(index);
        } else {
          toggleCamera(0);
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

    if (kIsWeb && !_isMobileWeb) {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(-1.0, 1.0), // Flip horizontally
        child: CameraPreview(controller!),
      );
    }

    return CameraPreview(controller!);
  }

  Future<void> toggleCamera(int index) async {
    if (controller != null) controller!.dispose();

    controller = CameraController(_cameras[index], ResolutionPreset.high);
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
