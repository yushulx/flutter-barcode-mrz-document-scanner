import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_document_scan_sdk/document_result.dart';
import 'dart:ui' as ui;
import 'package:flutter_document_scan_sdk_example/reader_page.dart';
import 'package:image_picker/image_picker.dart';

import 'mobile_scanner_page.dart';
import 'plugin.dart';
import 'web_scanner_page.dart';
import 'windows_scanner_page.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ui.Image? image;

  List<DocumentResult>? detectionResults = [];
  XFile? pickedFile;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    initHomePageState();
  }

  Future<void> initHomePageState() async {
    if (licenseStatus == NOT_CHECKED) {
      int? ret = await flutterDocumentScanSdkPlugin.init(
          "DLS2eyJoYW5kc2hha2VDb2RlIjoiMjAwMDAxLTE2NDk4Mjk3OTI2MzUiLCJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSIsInNlc3Npb25QYXNzd29yZCI6IndTcGR6Vm05WDJrcEQ5YUoifQ==");

      setState(() {
        if (ret != null) {
          licenseStatus = ret;
        }
      });
    }
  }

  Widget? verifyLicense(BuildContext context) {
    if (licenseStatus == NOT_CHECKED) {
      return const Center(child: CircularProgressIndicator());
    } else if (licenseStatus == 0) {
      return Center(
        child:
            Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          MaterialButton(
              textColor: Colors.white,
              color: Colors.blue,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReaderPage(
                      title: 'Document Reader',
                    ),
                  ),
                );
              },
              child: const Text('Document Reader')),
          MaterialButton(
              textColor: Colors.white,
              color: Colors.blue,
              onPressed: () {
                if (kIsWeb) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WebScannerPage(
                        title: 'Document Scanner',
                      ),
                    ),
                  );
                } else if (Platform.isAndroid || Platform.isIOS) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MobileScannerPage(
                        title: 'Document Scanner',
                      ),
                    ),
                  );
                } else if (Platform.isWindows) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WindowsScannerPage(
                        title: 'Document Scanner',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Document Scanner')),
        ]),
      );
    } else {
      return const Center(
          child: Text(
              'Please get a valid license from https://www.dynamsoft.com/customer/license/trialLicense/?product=dcv&package=cross-platform'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Dynamsoft Document Normalizer'),
        ),
        body: verifyLicense(context));
  }
}
