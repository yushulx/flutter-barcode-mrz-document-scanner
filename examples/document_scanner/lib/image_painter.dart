import 'package:flutter/material.dart';
import 'package:flutter_document_scan_sdk/document_result.dart';
import 'dart:ui' as ui;

class ImagePainter extends CustomPainter {
  ImagePainter(this.image, this.results);
  ui.Image? image;
  final List<DocumentResult> results;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    if (image != null) {
      canvas.drawImage(image!, Offset.zero, paint);
    }

    Paint circlePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (var result in results) {
      canvas.drawLine(result.points[0], result.points[1], paint);
      canvas.drawLine(result.points[1], result.points[2], paint);
      canvas.drawLine(result.points[2], result.points[3], paint);
      canvas.drawLine(result.points[3], result.points[0], paint);

      if (image != null) {
        canvas.drawCircle(result.points[0], 10, circlePaint);
        canvas.drawCircle(result.points[1], 10, circlePaint);
        canvas.drawCircle(result.points[2], 10, circlePaint);
        canvas.drawCircle(result.points[3], 10, circlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(ImagePainter oldDelegate) => true;
}
