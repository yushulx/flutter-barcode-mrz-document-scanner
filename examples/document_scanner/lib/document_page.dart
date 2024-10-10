import 'dart:io';
import 'dart:ui';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:flutter_document_scan_sdk/document_result.dart';
import 'package:flutter_document_scan_sdk/flutter_document_scan_sdk_platform_interface.dart';
import 'package:flutter_document_scan_sdk/template.dart';
import 'package:flutter_document_scan_sdk/normalized_image.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'image_painter.dart';
import 'plugin.dart';
import 'utils.dart';

class DocumentPage extends StatefulWidget {
  const DocumentPage(
      {super.key, required this.detectionResults, required this.sourceImage});

  final List<DocumentResult> detectionResults;
  final ui.Image sourceImage;

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  ui.Image? normalizedUiImage;

  NormalizedImage? normalizedImage;
  String _pixelFormat = 'grayscale';

  @override
  void initState() {
    super.initState();
    initDocumentState();
  }

  Future<ui.Image> loadImage(XFile file) async {
    final data = await file.readAsBytes();
    return await decodeImageFromList(data);
  }

  Future<void> initDocumentState() async {
    await flutterDocumentScanSdkPlugin.setParameters(Template.grayscale);
    await normalizeBuffer(
        widget.sourceImage, widget.detectionResults[0].points);
  }

  Widget createCustomImage(BuildContext context, ui.Image image,
      List<DocumentResult> detectionResults) {
    return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top -
            80,
        child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
                width: image.width.toDouble(),
                height: image.height.toDouble(),
                child: CustomPaint(
                  painter: ImagePainter(image, detectionResults),
                ))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document'),
      ),
      body: Center(
        child: Stack(children: <Widget>[
          Center(
              child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: normalizedUiImage == null
                  ? Image.asset('images/default.png')
                  : createCustomImage(context, normalizedUiImage!, []),
            ),
          )),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Radio(
                value: 'binary',
                groupValue: _pixelFormat,
                onChanged: (String? value) async {
                  setState(() {
                    _pixelFormat = value!;
                  });

                  await flutterDocumentScanSdkPlugin
                      .setParameters(Template.binary);

                  if (widget.detectionResults.isNotEmpty) {
                    await normalizeBuffer(
                        widget.sourceImage, widget.detectionResults[0].points);
                  }
                },
              ),
              const Text('Binary'),
              Radio(
                value: 'grayscale',
                groupValue: _pixelFormat,
                onChanged: (String? value) async {
                  setState(() {
                    _pixelFormat = value!;
                  });

                  await flutterDocumentScanSdkPlugin
                      .setParameters(Template.grayscale);

                  if (widget.detectionResults.isNotEmpty) {
                    await normalizeBuffer(
                        widget.sourceImage, widget.detectionResults[0].points);
                  }
                },
              ),
              const Text('Gray'),
              Radio(
                value: 'color',
                groupValue: _pixelFormat,
                onChanged: (String? value) async {
                  setState(() {
                    _pixelFormat = value!;
                  });

                  await flutterDocumentScanSdkPlugin
                      .setParameters(Template.color);

                  if (widget.detectionResults.isNotEmpty) {
                    await normalizeBuffer(
                        widget.sourceImage, widget.detectionResults[0].points);
                  }
                },
              ),
              const Text('Color'),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 100,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      MaterialButton(
                          textColor: Colors.white,
                          color: Colors.blue,
                          onPressed: () async {
                            String fileName =
                                '${DateTime.now().millisecondsSinceEpoch}.png';
                            String? path;
                            if (kIsWeb) {
                              path = fileName;
                            } else if (Platform.isAndroid || Platform.isIOS) {
                              Directory directory =
                                  await getApplicationDocumentsDirectory();
                              path = join(directory.path, fileName);
                            } else {
                              path = await getSavePath(suggestedName: fileName);
                              path ??= fileName;
                            }

                            if (normalizedUiImage != null) {
                              const String mimeType = 'image/png';
                              ByteData? data = await normalizedUiImage!
                                  .toByteData(format: ui.ImageByteFormat.png);
                              if (data != null) {
                                final XFile imageFile = XFile.fromData(
                                  data.buffer.asUint8List(),
                                  mimeType: mimeType,
                                );
                                await imageFile.saveTo(path);
                                showAlert(context, 'Save',
                                    'Document saved to ${path}');
                                return;
                              }

                              showAlert(
                                  context, 'Save', 'Failed to save document');
                            }
                          },
                          child: const Text("Save Document"))
                    ]),
              ),
            ],
          )
        ]),
      ),
    );
  }

  Future<void> normalizeFile(String file, dynamic points) async {
    normalizedImage =
        await flutterDocumentScanSdkPlugin.normalizeFile(file, points);
    if (normalizedImage != null) {
      decodeImageFromPixels(normalizedImage!.data, normalizedImage!.width,
          normalizedImage!.height, PixelFormat.rgba8888, (ui.Image img) {
        normalizedUiImage = img;
        setState(() {});
      });
    }
  }

  Future<void> normalizeBuffer(ui.Image sourceImage, dynamic points) async {
    ByteData? byteData =
        await sourceImage.toByteData(format: ui.ImageByteFormat.rawRgba);

    Uint8List bytes = byteData!.buffer.asUint8List();
    int width = sourceImage.width;
    int height = sourceImage.height;
    int stride = byteData.lengthInBytes ~/ sourceImage.height;
    int format = ImagePixelFormat.IPF_ARGB_8888.index;

    normalizedImage = await flutterDocumentScanSdkPlugin.normalizeBuffer(
        bytes, width, height, stride, format, points);
    if (normalizedImage != null) {
      decodeImageFromPixels(normalizedImage!.data, normalizedImage!.width,
          normalizedImage!.height, PixelFormat.rgba8888, (ui.Image img) {
        normalizedUiImage = img;
        setState(() {});
      });
    }
  }
}
