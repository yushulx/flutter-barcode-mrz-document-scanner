import 'package:flutter/material.dart';
import 'package:flutter_barcode_sdk/dynamsoft_barcode.dart';
import 'package:flutter_barcode_sdk/flutter_barcode_sdk.dart';

FlutterBarcodeSdk barcodeReader = FlutterBarcodeSdk();

Future<int> initBarcodeSDK() async {
  int ret = await barcodeReader.setLicense(
      'DLS2eyJoYW5kc2hha2VDb2RlIjoiMjAwMDAxLTE2NDk4Mjk3OTI2MzUiLCJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSIsInNlc3Npb25QYXNzd29yZCI6IndTcGR6Vm05WDJrcEQ5YUoifQ==');
  await barcodeReader.init();
  await barcodeReader.setBarcodeFormats(BarcodeFormat.ALL);
  return ret;
}

Color colorMainTheme = const Color(0xff1D1B20);
Color colorOrange = const Color(0xffFE8E14);
Color colorTitle = const Color(0xffF5F5F5);
Color colorSelect = const Color(0xff757575);
Color colorText = const Color(0xff888888);
Color colorBackground = const Color(0xFF323234);
Color colorSubtitle = const Color(0xffCCCCCC);
Color colorGreen = const Color(0xff6AC4BB);

Widget createOverlay(
  List<BarcodeResult>? barcodeResults,
) {
  return CustomPaint(
    painter: OverlayPainter(barcodeResults),
  );
}

class OverlayPainter extends CustomPainter {
  List<BarcodeResult>? barcodeResults;

  OverlayPainter(this.barcodeResults);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    if (barcodeResults != null) {
      for (var result in barcodeResults!) {
        double minX = result.x1.toDouble();
        double minY = result.y1.toDouble();
        if (result.x2 < minX) minX = result.x2.toDouble();
        if (result.x3 < minX) minX = result.x3.toDouble();
        if (result.x4 < minX) minX = result.x4.toDouble();
        if (result.y2 < minY) minY = result.y2.toDouble();
        if (result.y3 < minY) minY = result.y3.toDouble();
        if (result.y4 < minY) minY = result.y4.toDouble();

        canvas.drawLine(Offset(result.x1.toDouble(), result.y1.toDouble()),
            Offset(result.x2.toDouble(), result.y2.toDouble()), paint);
        canvas.drawLine(Offset(result.x2.toDouble(), result.y2.toDouble()),
            Offset(result.x3.toDouble(), result.y3.toDouble()), paint);
        canvas.drawLine(Offset(result.x3.toDouble(), result.y3.toDouble()),
            Offset(result.x4.toDouble(), result.y4.toDouble()), paint);
        canvas.drawLine(Offset(result.x4.toDouble(), result.y4.toDouble()),
            Offset(result.x1.toDouble(), result.y1.toDouble()), paint);

        TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: result.text,
            style: const TextStyle(
              color: Colors.yellow,
              fontSize: 22.0,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(minWidth: 0, maxWidth: size.width);
        textPainter.paint(canvas, Offset(minX, minY));
      }
    }
  }

  @override
  bool shouldRepaint(OverlayPainter oldDelegate) => true;
}

List<BarcodeResult> rotate90barcode(List<BarcodeResult> input, int height) {
  List<BarcodeResult> output = [];
  for (BarcodeResult result in input) {
    int x1 = result.x1;
    int x2 = result.x2;
    int x3 = result.x3;
    int x4 = result.x4;
    int y1 = result.y1;
    int y2 = result.y2;
    int y3 = result.y3;
    int y4 = result.y4;

    BarcodeResult newResult = BarcodeResult(
        result.format,
        result.text,
        height - y1,
        x1,
        height - y2,
        x2,
        height - y3,
        x3,
        height - y4,
        x4,
        result.angle,
        result.barcodeBytes);

    output.add(newResult);
  }

  return output;
}
