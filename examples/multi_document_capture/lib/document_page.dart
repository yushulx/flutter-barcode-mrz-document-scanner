import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dynamsoft_capture_vision_flutter/dynamsoft_capture_vision_flutter.dart';

class DocumentPage {
  ImageData? originalImage;
  ImageData normalizedImage;
  Quadrilateral? quad;
  int colorMode = 0; // 0=colour, 1=grayscale, 2=binary
  int rotationDegrees = 0;

  Uint8List? _cachedBytes;

  DocumentPage({
    this.originalImage,
    required this.normalizedImage,
    this.quad,
  });

  bool get hasOriginalImage => originalImage != null;

  void rotate90() {
    rotationDegrees = (rotationDegrees + 90) % 360;
    _cachedBytes = null;
  }

  void setColorMode(int mode) {
    if (colorMode != mode) {
      colorMode = mode;
      _cachedBytes = null;
    }
  }

  void invalidateCache() {
    _cachedBytes = null;
  }

  Future<ImageData> getDisplayImage() async {
    ImageData image = normalizedImage;

    if (colorMode == 1) {
      final converted = await ImageProcessor().convertToGray(normalizedImage);
      if (converted != null) {
        // Preserve EXIF orientation after color conversion
        converted.orientation = normalizedImage.orientation;
        image = converted;
      }
    } else if (colorMode == 2) {
      final converted = await ImageProcessor().convertToBinaryLocal(normalizedImage, compensation: 15);
      if (converted != null) {
        converted.orientation = normalizedImage.orientation;
        image = converted;
      }
    }

    return image;
  }

  Future<Uint8List?> getDisplayBytes() async {
    if (_cachedBytes != null) return _cachedBytes;
    final image = await getDisplayImage();
    final raw = await ImageIO().saveToMemory(image, EnumImageFileFormat.png);
    if (raw == null) return null;
    final bytes = rotationDegrees != 0 ? await _rotateBytes(raw, rotationDegrees) : raw;
    _cachedBytes = bytes;
    return bytes;
  }

  void updateFromQuadEdit(ImageData newNormalized, Quadrilateral newQuad) {
    normalizedImage = newNormalized;
    quad = newQuad;
    colorMode = 0;
    _cachedBytes = null;
  }

  static Future<Uint8List> _rotateBytes(Uint8List bytes, int degrees) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final src = frame.image;

    final int srcW = src.width;
    final int srcH = src.height;
    final int dstW = (degrees == 90 || degrees == 270) ? srcH : srcW;
    final int dstH = (degrees == 90 || degrees == 270) ? srcW : srcH;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, dstW.toDouble(), dstH.toDouble()),
    );

    canvas.translate(dstW / 2.0, dstH / 2.0);
    canvas.rotate(degrees * 3.14159265358979 / 180.0);
    canvas.drawImage(
        src, ui.Offset(-srcW / 2.0, -srcH / 2.0), ui.Paint());

    final picture = recorder.endRecording();
    final resultImage = await picture.toImage(dstW, dstH);
    final byteData =
        await resultImage.toByteData(format: ui.ImageByteFormat.png);

    src.dispose();
    resultImage.dispose();

    return byteData!.buffer.asUint8List();
  }
}
