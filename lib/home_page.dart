import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_barcode_sdk/dynamsoft_barcode.dart';
import 'package:flutter_barcode_sdk/flutter_barcode_sdk.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'result_page.dart';
import 'utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'camera_page.dart';
import 'global.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final picker = ImagePicker();

  void openResultPage(List<BarcodeResult> barcodeResults) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(barcodeResults: barcodeResults),
        ));
  }

  void scanImage() async {
    XFile? photo = await picker.pickImage(source: ImageSource.gallery);

    if (photo == null) {
      return;
    }

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      File rotatedImage =
          await FlutterExifRotation.rotateImage(path: photo.path);
      photo = XFile(rotatedImage.path);
    }

    Uint8List fileBytes = await photo.readAsBytes();

    ui.Image image = await decodeImageFromList(fileBytes);

    ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData != null) {
      if (kIsWeb) {
        barcodeReader.setParameters(readerTemplate);
      }
      List<BarcodeResult>? results = await barcodeReader.decodeImageBuffer(
          byteData.buffer.asUint8List(),
          image.width,
          image.height,
          byteData.lengthInBytes ~/ image.height,
          ImagePixelFormat.IPF_ARGB_8888.index);

      if (results.isNotEmpty) {
        openResultPage(results);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var title = const Padding(
      padding: EdgeInsets.only(
        top: 32,
      ),
      child: Text('BARCODE SCANNER',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            color: Colors.white,
          )),
    );

    var description = Padding(
        padding: const EdgeInsets.only(top: 7, left: 33, right: 33),
        child: Text(
            "Whether it's distorted, dark, distant, blurred, batch or moving, we can scan it. At speed.",
            style: TextStyle(
              fontSize: 18,
              color: colorTitle,
            )));

    final buttons = Padding(
        padding: const EdgeInsets.only(top: 44),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
                onTap: () {
                  if (!kIsWeb && Platform.isLinux) {
                    showAlert(context, "Warning",
                        "${Platform.operatingSystem} is not supported");
                    return;
                  }

                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return const CameraPage();
                  }));
                },
                child: Container(
                  width: 150,
                  height: 125,
                  decoration: BoxDecoration(
                    color: colorOrange,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        "images/icon-camera.png",
                        width: 90,
                        height: 60,
                      ),
                      const Text(
                        "Camera Scan",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      )
                    ],
                  ),
                )),
            GestureDetector(
                onTap: () {
                  scanImage();
                },
                child: Container(
                  width: 150,
                  height: 125,
                  decoration: BoxDecoration(
                    color: colorBackground,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        "images/icon-image.png",
                        width: 90,
                        height: 60,
                      ),
                      const Text(
                        "Image Scan",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      )
                    ],
                  ),
                ))
          ],
        ));
    final image = Image.asset(
      "images/image-barcode.png",
      width: MediaQuery.of(context).size.width,
      fit: BoxFit.cover,
    );
    return Scaffold(
      body: Column(
        children: [
          title,
          description,
          buttons,
          const SizedBox(
            height: 34,
          ),
          Expanded(
              child: Stack(
            children: [
              Positioned.fill(
                child: image,
              ),
              if (!isLicenseValid)
                Opacity(
                  opacity: 0.8,
                  child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 40,
                      color: const Color(0xffFF1A1A),
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: InkWell(
                          onTap: () {
                            launchUrlString(
                                'https://www.dynamsoft.com/customer/license/trialLicense?product=dbr');
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.white, size: 20),
                              Text(
                                "  License expired! Renew your license ->",
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ))),
                )
            ],
          ))
        ],
      ),
    );
  }
}
