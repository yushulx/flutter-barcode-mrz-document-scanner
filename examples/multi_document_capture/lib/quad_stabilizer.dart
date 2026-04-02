import 'dart:math' as math;
import 'package:dynamsoft_capture_vision_flutter/dynamsoft_capture_vision_flutter.dart';

/// Measures geometric stability of detected quads across consecutive frames
/// using IoU (Intersection over Union) and area delta. Fires [onStable]
/// when the quad remains stable for [stableFrameCount] consecutive frames.
///
/// Port of the Android `QuadStabilizer` class.
class QuadStabilizer {
  double iouThreshold;
  double areaDeltaThreshold;
  int stableFrameCount;
  bool autoCaptureEnabled;

  Quadrilateral? _previousQuad;
  int _consecutiveStableFrames = 0;
  void Function()? onStable;

  QuadStabilizer({
    this.iouThreshold = 0.85,
    this.areaDeltaThreshold = 0.15,
    this.stableFrameCount = 3,
    this.autoCaptureEnabled = true,
    this.onStable,
  });

  void reset() {
    _previousQuad = null;
    _consecutiveStableFrames = 0;
  }

  void feedQuad(Quadrilateral quad) {
    if (!autoCaptureEnabled) return;

    if (_previousQuad == null) {
      _previousQuad = quad;
      _consecutiveStableFrames = 0;
      return;
    }

    final double iou = calculateIoU(_previousQuad!, quad);
    final double prevArea = _calculateQuadArea(_previousQuad!);
    final double currArea = _calculateQuadArea(quad);
    final double areaDelta =
        prevArea > 0 ? (currArea - prevArea).abs() / prevArea : 1.0;

    if (iou >= iouThreshold && areaDelta <= areaDeltaThreshold) {
      _consecutiveStableFrames++;
      if (_consecutiveStableFrames >= stableFrameCount) {
        onStable?.call();
        reset();
      }
    } else {
      _consecutiveStableFrames = 0;
    }

    _previousQuad = quad;
  }

  /// Bounding-box IoU between two quadrilaterals.
  static double calculateIoU(Quadrilateral a, Quadrilateral b) {
    final boundsA = _getBounds(a);
    final boundsB = _getBounds(b);

    final iLeft = math.max(boundsA[0], boundsB[0]);
    final iTop = math.max(boundsA[1], boundsB[1]);
    final iRight = math.min(boundsA[2], boundsB[2]);
    final iBottom = math.min(boundsA[3], boundsB[3]);

    if (iLeft >= iRight || iTop >= iBottom) return 0;

    final double intersectionArea =
        (iRight - iLeft).toDouble() * (iBottom - iTop).toDouble();
    final double areaA =
        (boundsA[2] - boundsA[0]).toDouble() * (boundsA[3] - boundsA[1]).toDouble();
    final double areaB =
        (boundsB[2] - boundsB[0]).toDouble() * (boundsB[3] - boundsB[1]).toDouble();
    final double unionArea = areaA + areaB - intersectionArea;

    return unionArea > 0 ? intersectionArea / unionArea : 0;
  }

  static List<int> _getBounds(Quadrilateral quad) {
    final points = quad.points;
    int minX = 0x7FFFFFFF, minY = 0x7FFFFFFF;
    int maxX = -0x7FFFFFFF, maxY = -0x7FFFFFFF;
    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.x > maxX) maxX = p.x;
      if (p.y > maxY) maxY = p.y;
    }
    return [minX, minY, maxX, maxY];
  }

  /// Shoelace formula for polygon area.
  static double _calculateQuadArea(Quadrilateral quad) {
    final p = quad.points;
    double area = 0;
    final n = p.length;
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += p[i].x.toDouble() * p[j].y.toDouble();
      area -= p[j].x.toDouble() * p[i].y.toDouble();
    }
    return area.abs() / 2.0;
  }
}
