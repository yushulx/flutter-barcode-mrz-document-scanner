import 'dart:ui' as ui;
import 'package:flutter_document_scan_sdk/document_result.dart';

class DocumentData {
  ui.Image? image;
  List<DocumentResult>? detectionResults;

  DocumentData({
    this.image,
    this.detectionResults,
  });
}
