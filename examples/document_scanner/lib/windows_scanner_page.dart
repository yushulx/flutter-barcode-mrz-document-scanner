import 'dart:async';
import 'dart:ui';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:camera_windows/camera_windows.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera_windows/camera_windows.dart';
import 'package:flutter_document_scan_sdk/document_result.dart';
import 'package:flutter_document_scan_sdk/flutter_document_scan_sdk_platform_interface.dart';

import 'document_data.dart';
import 'image_painter.dart';
import 'plugin.dart';
import 'reader_page.dart';
import 'utils.dart';
import 'dart:ui' as ui;

class WindowsScannerPage extends StatefulWidget {
  const WindowsScannerPage({super.key, required this.title});
  final String title;

  @override
  State<WindowsScannerPage> createState() => _WindowsScannerPageState();
}

class _WindowsScannerPageState extends State<WindowsScannerPage>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = <CameraDescription>[];
  String _selectedItem = '';
  final List<String> _cameraNames = [];
  Size? _previewSize;
  int _cameraId = -1;
  bool _initialized = false;
  StreamSubscription<CameraErrorEvent>? _errorStreamSubscription;
  StreamSubscription<CameraClosingEvent>? _cameraClosingStreamSubscription;
  StreamSubscription<FrameAvailabledEvent>? _frameAvailableStreamSubscription;
  bool _isScanAvailable = true;
  final ResolutionPreset _resolutionPreset = ResolutionPreset.veryHigh;
  bool _loading = true;
  List<DocumentResult>? _detectionResults = [];
  DocumentData? _documentData;
  bool _enableCapture = false;

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    initCamera();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> initCamera() async {
    try {
      _cameras = await CameraPlatform.instance.availableCameras();
      _cameraNames.clear();
      for (CameraDescription description in _cameras) {
        _cameraNames.add(description.name);
      }
      _selectedItem = _cameraNames[0];
    } on PlatformException catch (e) {}

    toggleCamera(0);

    setState(() {
      _loading = false;
    });
  }

  void _onCameraError(CameraErrorEvent event) {
    if (mounted) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Error: ${event.description}')));

      // Dispose camera on camera error as it can not be used anymore.
      _disposeCurrentCamera();
      initCamera();
    }
  }

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void _onCameraClosing(CameraClosingEvent event) {
    if (mounted) {
      _showInSnackBar('Camera is closing');
    }
  }

  void _showInSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 1),
    ));
  }

  void _onFrameAvailable(FrameAvailabledEvent event) {
    if (mounted) {
      Map<String, dynamic> map = event.toJson();
      final Uint8List? data = map['bytes'] as Uint8List?;
      if (data != null) {
        if (!_isScanAvailable) {
          return;
        }

        _isScanAvailable = false;
        int width = _previewSize!.width.toInt();
        int height = _previewSize!.height.toInt();
        flutterDocumentScanSdkPlugin
            .detectBuffer(data, width, height, width * 4,
                ImagePixelFormat.IPF_ARGB_8888.index)
            .then((results) {
          _detectionResults = results;
          _isScanAvailable = true;
          setState(() {});

          if (_enableCapture &&
              _detectionResults != null &&
              _detectionResults!.isNotEmpty) {
            _enableCapture = false;
            final coordinates = _detectionResults;
            createImage(data, width, height, ui.PixelFormat.rgba8888)
                .then((ui.Image value) {
              _documentData = DocumentData(
                image: value,
                detectionResults: coordinates,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ReaderPage(
                          title: 'Document Editor',
                          documentData: _documentData,
                        )),
              );
            });
          }
        }).catchError((error) {
          _isScanAvailable = true;
        });
      }
    }
  }

  /// Initializes the camera on the device.
  Future<void> toggleCamera(int index) async {
    assert(!_initialized);

    if (_cameras.isEmpty) {
      return;
    }

    int cameraId = -1;
    try {
      final CameraDescription camera = _cameras[index];

      cameraId = await CameraPlatform.instance.createCamera(
        camera,
        _resolutionPreset,
      );

      _errorStreamSubscription?.cancel();
      _errorStreamSubscription = CameraPlatform.instance
          .onCameraError(cameraId)
          .listen(_onCameraError);

      _cameraClosingStreamSubscription?.cancel();
      _cameraClosingStreamSubscription = CameraPlatform.instance
          .onCameraClosing(cameraId)
          .listen(_onCameraClosing);

      _frameAvailableStreamSubscription?.cancel();
      _frameAvailableStreamSubscription =
          (CameraPlatform.instance as CameraWindows)
              .onFrameAvailable(cameraId)
              .listen(_onFrameAvailable);

      final Future<CameraInitializedEvent> initialized =
          CameraPlatform.instance.onCameraInitialized(cameraId).first;

      await CameraPlatform.instance.initializeCamera(
        cameraId,
      );

      final CameraInitializedEvent event = await initialized;
      _previewSize = Size(
        event.previewWidth,
        event.previewHeight,
      );

      if (mounted) {
        setState(() {
          _initialized = true;
          _cameraId = cameraId;
        });
      }
    } on CameraException catch (e) {
      try {
        if (cameraId >= 0) {
          await CameraPlatform.instance.dispose(cameraId);
        }
      } on CameraException catch (e) {
        debugPrint('Failed to dispose camera: ${e.code}: ${e.description}');
      }

      // Reset state.
      if (mounted) {
        setState(() {
          _initialized = false;
          _cameraId = -1;
          _previewSize = null;
        });
      }
    }
  }

  Future<void> _disposeCurrentCamera() async {
    if (_cameraId >= 0 && _initialized) {
      try {
        await CameraPlatform.instance.dispose(_cameraId);

        if (mounted) {
          setState(() {
            _initialized = false;
            _cameraId = -1;
            _previewSize = null;
          });
        }
      } on CameraException catch (e) {
        print(e);
      }
    }
  }

  Widget _buildPreview() {
    return CameraPlatform.instance.buildPreview(_cameraId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    destroyCamera();
    super.dispose();
  }

  void destroyCamera() {
    _disposeCurrentCamera();
    _errorStreamSubscription?.cancel();
    _errorStreamSubscription = null;
    _cameraClosingStreamSubscription?.cancel();
    _cameraClosingStreamSubscription = null;
    _frameAvailableStreamSubscription?.cancel();
    _frameAvailableStreamSubscription = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      initCamera();
    } else if (state == AppLifecycleState.paused) {
      destroyCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    ResolutionPreset.values
        .map<DropdownMenuItem<ResolutionPreset>>((ResolutionPreset value) {
      return DropdownMenuItem<ResolutionPreset>(
        value: value,
        child: Text(value.toString()),
      );
    }).toList();
    return WillPopScope(
        // override the pop action
        onWillPop: () async {
          return true;
        },
        child: Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
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
                            _cameraId < 0
                                ? Image.asset(
                                    'images/default.png',
                                  )
                                : SizedBox(
                                    width: _previewSize == null
                                        ? 640
                                        : _previewSize!.width,
                                    height: _previewSize == null
                                        ? 480
                                        : _previewSize!.height,
                                    child: _buildPreview()),
                            Positioned(
                              top: 0.0,
                              right: 0.0,
                              bottom: 0.0,
                              left: 0.0,
                              child: _detectionResults == null ||
                                      _detectionResults!.isEmpty
                                  ? Container(
                                      color: Colors.black.withOpacity(0.1),
                                      child: const Center(
                                        child: Text(
                                          'No document detected',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ))
                                  : CustomPaint(
                                      painter: ImagePainter(
                                          null, _detectionResults!),
                                    ),
                            ),
                          ],
                        ),
                      )),
                  Align(
                      alignment:
                          _loading ? Alignment.center : Alignment.topCenter,
                      child: _loading
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Detecting cameras...'),
                              ],
                            )
                          : DropdownButton<String>(
                              value: _selectedItem,
                              items: _cameraNames.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue == null || newValue == '') return;
                                int index = _cameraNames.indexOf(newValue);
                                toggleCamera(index);
                              },
                            )),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                if (_cameraId < 0) {
                  return;
                }
                _enableCapture = true;
              },
              tooltip: 'Capture the document',
              child: const Icon(Icons.camera_alt),
            )));
  }
}
