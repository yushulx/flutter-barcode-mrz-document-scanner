import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:flutter_document_scan_sdk/document_result.dart';
import 'package:flutter_document_scan_sdk/flutter_document_scan_sdk_platform_interface.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import 'document_data.dart';
import 'document_page.dart';
import 'image_painter.dart';
import 'plugin.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key, required this.title, this.documentData});

  final String title;
  final DocumentData? documentData;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  ui.Image? image;

  List<DocumentResult>? detectionResults = [];
  XFile? pickedFile;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  Future<ui.Image> loadImage(XFile file) async {
    final data = await file.readAsBytes();
    return await decodeImageFromList(data);
  }

  Widget createCustomImage() {
    if (widget.documentData != null) {
      image = widget.documentData!.image;
      detectionResults = widget.documentData!.detectionResults;
    }
    if (image == null) {
      return Image.asset('images/default.png');
    } else {
      return SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              80,
          child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                  width: image!.width.toDouble(),
                  height: image!.height.toDouble(),
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      if (details.localPosition.dx < 0 ||
                          details.localPosition.dy < 0 ||
                          details.localPosition.dx > image!.width ||
                          details.localPosition.dy > image!.height) {
                        return;
                      }

                      for (int i = 0; i < detectionResults!.length; i++) {
                        for (int j = 0;
                            j < detectionResults![i].points.length;
                            j++) {
                          if ((detectionResults![i].points[j] -
                                      details.localPosition)
                                  .distance <
                              20) {
                            bool isCollided = false;
                            for (int index = 1; index < 4; index++) {
                              int otherIndex = (j + 1) % 4;
                              if ((detectionResults![i].points[otherIndex] -
                                          details.localPosition)
                                      .distance <
                                  20) {
                                isCollided = true;
                                return;
                              }
                            }

                            setState(() {
                              if (!isCollided) {
                                detectionResults![i].points[j] =
                                    details.localPosition;
                              }
                            });
                          }
                        }
                      }
                    },
                    child: CustomPaint(
                      painter: ImagePainter(image, detectionResults!),
                    ),
                  ))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(children: <Widget>[
        Center(
          child: SingleChildScrollView(
              child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: createCustomImage(),
          )),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: 100,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    if (widget.documentData == null)
                      MaterialButton(
                          textColor: Colors.white,
                          color: Colors.blue,
                          onPressed: () async {
                            if (kIsWeb ||
                                Platform.isWindows ||
                                Platform.isLinux) {
                              const XTypeGroup typeGroup = XTypeGroup(
                                label: 'images',
                                extensions: <String>['jpg', 'png'],
                              );
                              pickedFile = await openFile(
                                  acceptedTypeGroups: <XTypeGroup>[typeGroup]);
                            } else if (Platform.isAndroid || Platform.isIOS) {
                              pickedFile = await picker.pickImage(
                                  source: ImageSource.gallery);
                            }

                            if (pickedFile != null) {
                              if (!kIsWeb &&
                                  (Platform.isAndroid || Platform.isIOS)) {
                                File rotatedImage =
                                    await FlutterExifRotation.rotateImage(
                                        path: pickedFile!.path);
                                pickedFile = XFile(rotatedImage.path);
                              }

                              image = await loadImage(pickedFile!);
                              if (image == null) {
                                print("loadImage failed");
                                return;
                              }

                              ByteData? byteData = await image!.toByteData(
                                  format: ui.ImageByteFormat.rawRgba);
                              detectionResults =
                                  await flutterDocumentScanSdkPlugin
                                      .detectBuffer(
                                          byteData!.buffer.asUint8List(),
                                          image!.width,
                                          image!.height,
                                          byteData.lengthInBytes ~/
                                              image!.height,
                                          ImagePixelFormat.IPF_ARGB_8888.index);

                              setState(() {});
                              if (detectionResults!.isEmpty) {
                                print("No document detected");
                              } else {
                                setState(() {});
                                print("Document detected");
                              }
                            }
                          },
                          child: const Text('Load Document')),
                    MaterialButton(
                        textColor: Colors.white,
                        color: Colors.blue,
                        onPressed: () async {
                          if (!mounted || detectionResults!.isEmpty) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DocumentPage(
                                sourceImage: image!,
                                detectionResults: detectionResults!,
                              ),
                            ),
                          );
                        },
                        child: const Text("Rectify Document"))
                  ]),
            ),
          ],
        )
      ]),
    );
  }
}
