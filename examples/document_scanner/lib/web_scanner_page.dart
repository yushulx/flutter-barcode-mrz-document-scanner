import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:flutter_document_scan_sdk/document_result.dart';

import 'document_data.dart';
import 'image_painter.dart';
import 'plugin.dart';
import 'reader_page.dart';

class WebScannerPage extends StatefulWidget {
  const WebScannerPage({super.key, required this.title});
  final String title;

  @override
  State<WebScannerPage> createState() => _WebScannerPageState();
}

class _WebScannerPageState extends State<WebScannerPage>
    with WidgetsBindingObserver {
  late List<CameraDescription> _cameras;
  CameraController? _controller;
  bool _isCameraReady = false;
  String _selectedItem = '';
  final List<String> _cameraNames = [''];
  bool _loading = true;
  List<DocumentResult>? _detectionResults = [];
  Size? _previewSize;
  DocumentData? _documentData;
  bool _enableCapture = false;

  @override
  void initState() {
    super.initState();
    initCamera();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> toggleCamera(int index) async {
    _isCameraReady = false;
    if (_controller != null) _controller!.dispose();

    _controller = CameraController(_cameras[index], ResolutionPreset.medium);
    _controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }

      _isCameraReady = true;
      _previewSize = _controller!.value.previewSize;
      setState(() {});

      decodeFrames();
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

    setState(() {
      _selectedItem = _cameras[index].name;
    });
  }

  Future<void> initCamera() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      _cameraNames.clear();
      for (CameraDescription description in _cameras) {
        _cameraNames.add(description.name);
      }
      _selectedItem = _cameraNames[0];

      toggleCamera(0);
    } on CameraException catch (e) {
      print(e);
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> decodeFrames() async {
    if (_controller == null || !_isCameraReady) return;

    Future.delayed(const Duration(milliseconds: 20), () async {
      if (_controller == null || !_isCameraReady) return;

      XFile file = await _controller!.takePicture();
      _detectionResults =
          await flutterDocumentScanSdkPlugin.detectFile(file.path);
      if (!mounted) return;
      setState(() {});

      if (_enableCapture &&
          _detectionResults != null &&
          _detectionResults!.isNotEmpty) {
        _enableCapture = false;
        final coordinates = _detectionResults;
        final data = await file.readAsBytes();
        decodeImageFromList(data).then((ui.Image value) {
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
      decodeFrames();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      initCamera();
    } else if (state == AppLifecycleState.paused) {
      dispose();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_controller != null) _controller!.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        // override the pop action
        onWillPop: () async {
          _isCameraReady = false;
          return true;
        },
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Scanner'),
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
                            _controller == null
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
                                    child: CameraPreview(
                                      _controller!,
                                    )),
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
                _enableCapture = true;
              },
              tooltip: 'Capture the document',
              child: const Icon(Icons.camera_alt),
            )));
  }
}
