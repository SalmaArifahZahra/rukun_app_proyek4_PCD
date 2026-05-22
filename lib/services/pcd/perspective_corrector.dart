// lib/services/pcd/perspective_corrector.dart

import 'dart:math';
import 'dart:ui';

import 'package:image/image.dart' as img;

import 'document_detector_v2.dart';

class PerspectiveCorrector {

  /// Compute homography 3x3 matrix menggunakan DLT algorithm
  /// Memetakan 4 source points ke 4 destination points
  static List<List<double>> computeHomography(
      List<Offset> srcPoints,  // [TL, TR, BR, BL]
      List<Offset> dstPoints,  // [TL, TR, BR, BL] of target rect
      ) {
    // Build matrix A (8x8) untuk sistem linear Ah = 0
    final A = List.generate(8, (_) => List<double>.filled(9, 0));

    for (int i = 0; i < 4; i++) {
      final sx = srcPoints[i].dx;
      final sy = srcPoints[i].dy;
      final dx = dstPoints[i].dx;
      final dy = dstPoints[i].dy;

      A[2*i]   = [-sx, -sy, -1, 0, 0, 0, dx*sx, dx*sy, dx];
      A[2*i+1] = [0, 0, 0, -sx, -sy, -1, dy*sx, dy*sy, dy];
    }

    // Solve menggunakan SVD atau Gaussian elimination
    // Simplified: gunakan pseudo-inverse untuk 8x8 system
    final h = _solveHomogeneous(A);

    return [
      [h[0], h[1], h[2]],
      [h[3], h[4], h[5]],
      [h[6], h[7], h[8]],
    ];
  }

  /// Apply homography transform ke image
  static img.Image warpPerspective(
      img.Image source,
      DocumentQuad quad, {
        int? targetWidth,
        int? targetHeight,
      }) {
    // Hitung dimensi target berdasarkan panjang sisi quad
    final topWidth = _dist(quad.topLeft, quad.topRight);
    final bottomWidth = _dist(quad.bottomLeft, quad.bottomRight);
    final leftHeight = _dist(quad.topLeft, quad.bottomLeft);
    final rightHeight = _dist(quad.topRight, quad.bottomRight);

    final tW = targetWidth ?? ((topWidth + bottomWidth) / 2).round();
    final tH = targetHeight ?? ((leftHeight + rightHeight) / 2).round();

    if (tW < 50 || tH < 50) return source;

    final srcPoints = [
      quad.topLeft, quad.topRight,
      quad.bottomRight, quad.bottomLeft
    ];
    final dstPoints = [
      const Offset(0, 0),
      Offset(tW.toDouble(), 0),
      Offset(tW.toDouble(), tH.toDouble()),
      Offset(0, tH.toDouble()),
    ];

    final H = computeHomography(srcPoints, dstPoints);

    // Inverse homography (dst → src) untuk inverse mapping
    final Hinv = _invertMatrix3x3(H);

    final result = img.Image(width: tW, height: tH);

    for (int dy = 0; dy < tH; dy++) {
      for (int dx = 0; dx < tW; dx++) {
        // Apply inverse transform
        final w = Hinv[2][0]*dx + Hinv[2][1]*dy + Hinv[2][2];
        if (w.abs() < 1e-10) continue;

        final sx = (Hinv[0][0]*dx + Hinv[0][1]*dy + Hinv[0][2]) / w;
        final sy = (Hinv[1][0]*dx + Hinv[1][1]*dy + Hinv[1][2]) / w;

        // Bilinear interpolation & set pixel
        _bilinearSetPixel(result, dx, dy, source, sx, sy);
      }
    }

    return result;
  }

  static void _bilinearSetPixel(
    img.Image result, int dx, int dy,
    img.Image src, double x, double y,
  ) {
    final x0 = x.floor().clamp(0, src.width - 1);
    final x1 = (x0 + 1).clamp(0, src.width - 1);
    final y0 = y.floor().clamp(0, src.height - 1);
    final y1 = (y0 + 1).clamp(0, src.height - 1);

    final fx = x - x0;
    final fy = y - y0;

    final p00 = src.getPixel(x0, y0);
    final p10 = src.getPixel(x1, y0);
    final p01 = src.getPixel(x0, y1);
    final p11 = src.getPixel(x1, y1);

    // Interpolate setiap channel
    num lerp(num a, num b, num t) => a + (b - a) * t;

    final r = lerp(lerp(p00.r, p10.r, fx), lerp(p01.r, p11.r, fx), fy).round().clamp(0, 255);
    final g = lerp(lerp(p00.g, p10.g, fx), lerp(p01.g, p11.g, fx), fy).round().clamp(0, 255);
    final b = lerp(lerp(p00.b, p10.b, fx), lerp(p01.b, p11.b, fx), fy).round().clamp(0, 255);

    result.setPixelRgb(dx, dy, r, g, b);
  }

  static double _dist(Offset a, Offset b) {
    return sqrt(pow(b.dx - a.dx, 2) + pow(b.dy - a.dy, 2));
  }

  // Gaussian elimination untuk solve sistem linear
  static List<double> _solveHomogeneous(List<List<double>> A) {
    // Placeholder: implementasi SVD atau Gaussian elimination
    // Untuk production, gunakan package math_expressions atau ml_linalg
    return List.filled(9, 0.0);
  }

  static List<List<double>> _invertMatrix3x3(List<List<double>> m) {
    final det = m[0][0] * (m[1][1]*m[2][2] - m[2][1]*m[1][2])
        - m[0][1] * (m[1][0]*m[2][2] - m[1][2]*m[2][0])
        + m[0][2] * (m[1][0]*m[2][1] - m[1][1]*m[2][0]);

    if (det.abs() < 1e-10) return m; // Singular matrix, return as-is

    final invDet = 1.0 / det;
    return [
      [
        (m[1][1]*m[2][2] - m[2][1]*m[1][2]) * invDet,
        (m[0][2]*m[2][1] - m[0][1]*m[2][2]) * invDet,
        (m[0][1]*m[1][2] - m[0][2]*m[1][1]) * invDet,
      ],
      [
        (m[1][2]*m[2][0] - m[1][0]*m[2][2]) * invDet,
        (m[0][0]*m[2][2] - m[0][2]*m[2][0]) * invDet,
        (m[1][0]*m[0][2] - m[0][0]*m[1][2]) * invDet,
      ],
      [
        (m[1][0]*m[2][1] - m[2][0]*m[1][1]) * invDet,
        (m[2][0]*m[0][1] - m[0][0]*m[2][1]) * invDet,
        (m[0][0]*m[1][1] - m[1][0]*m[0][1]) * invDet,
      ],
    ];
  }
}