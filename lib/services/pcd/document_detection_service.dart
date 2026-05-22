import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Simple point class untuk integer coordinates
class IntPoint {
  final int x;
  final int y;
  IntPoint(this.x, this.y);
}

/// Hasil deteksi corners dari dokumen
class DocumentCorners {
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomRight;
  final Offset bottomLeft;
  final double confidence; // 0.0 - 1.0

  DocumentCorners({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
    required this.confidence,
  });

  /// Hitung apakah persegi panjang (confidence berdasarkan aspect ratio)
  bool get isValidRectangle {
    final aspectRatio = _calculateAspectRatio();
    // KK ratio kurang lebih 1:1.4 (210mm x 297mm), accept 0.6 - 1.5
    return aspectRatio > 0.6 && aspectRatio < 1.5;
  }

  double _calculateAspectRatio() {
    final width = _distance(topLeft, topRight);
    final height = _distance(topLeft, bottomLeft);
    return width > 0 ? height / width : 0;
  }

  static double _distance(Offset p1, Offset p2) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    return sqrt(dx * dx + dy * dy);
  }
}

/// Service untuk deteksi dan koreksi perspektif dokumen KK
class DocumentDetectionService {
  /// Deteksi corners dokumen dari gambar
  /// Menggunakan edge detection + contour finding
  static Future<DocumentCorners?> detectDocumentCorners(
    img.Image source,
  ) async {
    try {
      // Step 1: Konversi ke grayscale
      final gray = img.grayscale(source);

      // Step 2: Edge detection (Sobel filter)
      final edges = _applySobelEdgeDetection(gray);

      // Step 3: Cari kontour terbesar (harusnya dokumen)
      final contour = _findLargestContour(edges);

      if (contour == null || contour.isEmpty) {
        return null;
      }

      // Step 4: Approximate kontour ke 4 corners
      final corners = _approximateRectangle(contour);

      if (corners == null) {
        return null;
      }

      return corners;
    } catch (e) {
      print('❌ Error detecting corners: $e');
      return null;
    }
  }

  /// Apply Sobel edge detection
  static img.Image _applySobelEdgeDetection(img.Image source) {
    final w = source.width;
    final h = source.height;
    final result = img.Image(width: w, height: h);

    // Sobel kernel for X and Y
    const sobelX = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1],
    ];

    const sobelY = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1],
    ];

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        int gx = 0;
        int gy = 0;

        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = source.getPixel(x + kx, y + ky).r.toInt();
            gx += pixel * sobelX[ky + 1][kx + 1];
            gy += pixel * sobelY[ky + 1][kx + 1];
          }
        }

        final magnitude = (sqrt(gx * gx + gy * gy).toInt()).clamp(0, 255);
        result.setPixelRgb(x, y, magnitude, magnitude, magnitude);
      }
    }

    // Threshold untuk binarisasi
    return _thresholdImage(result);
  }

  /// Binarisasi dengan threshold
  static img.Image _thresholdImage(img.Image source, {int threshold = 100}) {
    final w = source.width;
    final h = source.height;
    final result = img.Image(width: w, height: h);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final pixel = source.getPixel(x, y).r.toInt();
        final value = pixel > threshold ? 255 : 0;
        result.setPixelRgb(x, y, value, value, value);
      }
    }

    return result;
  }

  /// Cari kontour terbesar (harusnya dokumen)
  static List<IntPoint>? _findLargestContour(img.Image binaryImage) {
    final w = binaryImage.width;
    final h = binaryImage.height;
    final visited = List<List<bool>>.generate(
      h,
      (_) => List<bool>.filled(w, false),
    );

    List<IntPoint>? largestContour;
    int largestSize = 0;

    // Flood fill untuk menemukan semua kontour
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (!visited[y][x] && binaryImage.getPixel(x, y).r.toInt() > 128) {
          final contour = _floodFill(binaryImage, visited, x, y);

          if (contour.length > largestSize && contour.length > 100) {
            largestSize = contour.length;
            largestContour = contour;
          }
        }
      }
    }

    return largestContour;
  }

  /// Flood fill untuk mengekstrak pixel yang terhubung
  static List<IntPoint> _floodFill(
    img.Image image,
    List<List<bool>> visited,
    int startX,
    int startY,
  ) {
    final contour = <IntPoint>[];
    final queue = <(int, int)>[(startX, startY)];
    final h = image.height;
    final w = image.width;

    while (queue.isNotEmpty) {
      final (x, y) = queue.removeAt(0);

      if (x < 0 || x >= w || y < 0 || y >= h || visited[y][x]) continue;

      visited[y][x] = true;
      contour.add(IntPoint(x, y));

      // 4-connectivity
      if (image.getPixel(x + 1, y).r.toInt() > 128) {
        queue.add((x + 1, y));
      }
      if (image.getPixel(x - 1, y).r.toInt() > 128) {
        queue.add((x - 1, y));
      }
      if (image.getPixel(x, y + 1).r.toInt() > 128) {
        queue.add((x, y + 1));
      }
      if (image.getPixel(x, y - 1).r.toInt() > 128) {
        queue.add((x, y - 1));
      }
    }

    return contour;
  }

  /// Approximate kontour ke 4 corners menggunakan corner detection
  static DocumentCorners? _approximateRectangle(List<IntPoint> contour) {
    if (contour.length < 4) return null;

    // Cari extreme points (top-left, top-right, bottom-left, bottom-right)
    var minX = contour[0].x;
    var maxX = contour[0].x;
    var minY = contour[0].y;
    var maxY = contour[0].y;

    for (final point in contour) {
      if (point.x < minX) minX = point.x;
      if (point.x > maxX) maxX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.y > maxY) maxY = point.y;
    }

    // Divide menjadi 4 quadrant dan cari corner terdekat di setiap quadrant
    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;

    IntPoint? topLeft, topRight, bottomLeft, bottomRight;

    for (final point in contour) {
      if (point.x < centerX && point.y < centerY) {
        // Top-left quadrant
        if (topLeft == null ||
            _distanceFromOrigin(point.x.toDouble(), point.y.toDouble()) <
                _distanceFromOrigin(
                  topLeft.x.toDouble(),
                  topLeft.y.toDouble(),
                )) {
          topLeft = point;
        }
      } else if (point.x > centerX && point.y < centerY) {
        // Top-right quadrant
        if (topRight == null ||
            _distanceFromCorner(
                  point.x.toDouble(),
                  point.y.toDouble(),
                  maxX.toDouble(),
                  minY.toDouble(),
                ) <
                _distanceFromCorner(
                  topRight.x.toDouble(),
                  topRight.y.toDouble(),
                  maxX.toDouble(),
                  minY.toDouble(),
                )) {
          topRight = point;
        }
      } else if (point.x < centerX && point.y > centerY) {
        // Bottom-left quadrant
        if (bottomLeft == null ||
            _distanceFromCorner(
                  point.x.toDouble(),
                  point.y.toDouble(),
                  minX.toDouble(),
                  maxY.toDouble(),
                ) <
                _distanceFromCorner(
                  bottomLeft.x.toDouble(),
                  bottomLeft.y.toDouble(),
                  minX.toDouble(),
                  maxY.toDouble(),
                )) {
          bottomLeft = point;
        }
      } else if (point.x > centerX && point.y > centerY) {
        // Bottom-right quadrant
        if (bottomRight == null ||
            _distanceFromCorner(
                  point.x.toDouble(),
                  point.y.toDouble(),
                  maxX.toDouble(),
                  maxY.toDouble(),
                ) <
                _distanceFromCorner(
                  bottomRight.x.toDouble(),
                  bottomRight.y.toDouble(),
                  maxX.toDouble(),
                  maxY.toDouble(),
                )) {
          bottomRight = point;
        }
      }
    }

    if (topLeft == null ||
        topRight == null ||
        bottomLeft == null ||
        bottomRight == null) {
      return null;
    }

    final confidence = _calculateCornerConfidence(
      topLeft,
      topRight,
      bottomLeft,
      bottomRight,
    );

    return DocumentCorners(
      topLeft: Offset(topLeft.x.toDouble(), topLeft.y.toDouble()),
      topRight: Offset(topRight.x.toDouble(), topRight.y.toDouble()),
      bottomLeft: Offset(bottomLeft.x.toDouble(), bottomLeft.y.toDouble()),
      bottomRight: Offset(bottomRight.x.toDouble(), bottomRight.y.toDouble()),
      confidence: confidence,
    );
  }

  /// Hitung confidence berdasarkan angle dan regularity
  static double _calculateCornerConfidence(
    IntPoint tl,
    IntPoint tr,
    IntPoint bl,
    IntPoint br,
  ) {
    // Idealnya sudut = 90 derajat
    final angle1 = _angleBetweenVectors(tl, tr, tl, bl);
    final angle2 = _angleBetweenVectors(tr, tl, tr, br);
    final angle3 = _angleBetweenVectors(bl, tl, bl, br);
    final angle4 = _angleBetweenVectors(br, tr, br, bl);

    final angles = [angle1, angle2, angle3, angle4];
    final deviation =
        angles.map((a) => (a - 90).abs()).reduce((a, b) => a + b) / 4;

    // Confidence: semakin mendekati 90 derajat, semakin tinggi confidence
    final angleConfidence = (1 - (deviation / 90)).clamp(0.0, 1.0);

    // Regularity: check apakah sisi sejajar cukup konsisten
    final topLength = _distance(tl, tr).toDouble();
    final bottomLength = _distance(bl, br).toDouble();
    final leftLength = _distance(tl, bl).toDouble();
    final rightLength = _distance(tr, br).toDouble();

    final heightAvg = (leftLength + rightLength) / 2;
    final widthAvg = (topLength + bottomLength) / 2;

    final heightDev =
        ((leftLength - heightAvg).abs() + (rightLength - heightAvg).abs()) / 2;
    final widthDev =
        ((topLength - widthAvg).abs() + (bottomLength - widthAvg).abs()) / 2;

    final regularityConfidence =
        (1 - ((heightDev + widthDev) / (heightAvg + widthAvg)) / 2).clamp(
          0.0,
          1.0,
        );

    // Combined confidence
    return (angleConfidence * 0.6 + regularityConfidence * 0.4).clamp(0.0, 1.0);
  }

  static double _angleBetweenVectors(
    IntPoint start,
    IntPoint end1,
    IntPoint end2,
    IntPoint point2,
  ) {
    final v1 = (x: end1.x - start.x, y: end1.y - start.y);
    final v2 = (x: point2.x - start.x, y: point2.y - start.y);

    final dotProduct = v1.x * v2.x + v1.y * v2.y;
    final mag1 = sqrt(v1.x * v1.x + v1.y * v1.y);
    final mag2 = sqrt(v2.x * v2.x + v2.y * v2.y);

    if (mag1 == 0 || mag2 == 0) return 90;

    final cosAngle = dotProduct / (mag1 * mag2);
    return acos(cosAngle.clamp(-1.0, 1.0)) * 180 / pi;
  }

  static double _distanceFromOrigin(double x, double y) {
    return sqrt(x * x + y * y);
  }

  static double _distanceFromCorner(
    double x,
    double y,
    double cornerX,
    double cornerY,
  ) {
    return sqrt(pow(x - cornerX, 2) + pow(y - cornerY, 2)).toDouble();
  }

  static int _distance(IntPoint p1, IntPoint p2) {
    final dx = p2.x - p1.x;
    final dy = p2.y - p1.y;
    return sqrt(dx * dx + dy * dy).toInt();
  }

  /// Apply perspective correction pada gambar
  static img.Image correctPerspective(
    img.Image source,
    DocumentCorners corners,
  ) {
    try {
      // Calculate target dimensions dengan explicit double to int conversion
      final w1 = DocumentCorners._distance(
        corners.topLeft,
        corners.topRight,
      ).toInt(); // top edge width
      final w2 = DocumentCorners._distance(
        corners.bottomLeft,
        corners.bottomRight,
      ).toInt(); // bottom edge width
      final targetWidth = (w1 + w2) ~/ 2; // average width

      final h1 = DocumentCorners._distance(
        corners.topLeft,
        corners.bottomLeft,
      ).toInt(); // left edge height
      final h2 = DocumentCorners._distance(
        corners.topRight,
        corners.bottomRight,
      ).toInt(); // right edge height
      final targetHeight = (h1 + h2) ~/ 2; // average height

      // Ensure minimum dimensions
      if (targetWidth < 100 || targetHeight < 100) {
        debugPrint(
          '⚠️  Calculated perspective dimensions too small: ${targetWidth}x${targetHeight}',
        );
        return source;
      }

      // Simple 4-point perspective transform
      return _perspectiveTransform(source, corners, targetWidth, targetHeight);
    } catch (e) {
      debugPrint('❌ Error correcting perspective: $e');
      return source;
    }
  }

  /// 4-point perspective transform menggunakan bilinear interpolation
  static img.Image _perspectiveTransform(
    img.Image source,
    DocumentCorners corners,
    int targetWidth,
    int targetHeight,
  ) {
    final result = img.Image(width: targetWidth, height: targetHeight);

    final p0 = (x: corners.topLeft.dx, y: corners.topLeft.dy);
    final p1 = (x: corners.topRight.dx, y: corners.topRight.dy);
    final p2 = (x: corners.bottomRight.dx, y: corners.bottomRight.dy);
    final p3 = (x: corners.bottomLeft.dx, y: corners.bottomLeft.dy);

    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        final u = x / targetWidth;
        final v = y / targetHeight;

        // Bilinear interpolation di source space
        final srcX =
            p0.x * (1 - u) * (1 - v) +
            p1.x * u * (1 - v) +
            p2.x * u * v +
            p3.x * (1 - u) * v;

        final srcY =
            p0.y * (1 - u) * (1 - v) +
            p1.y * u * (1 - v) +
            p2.y * u * v +
            p3.y * (1 - u) * v;

        // Get pixel dari source dengan bilinear interpolation
        final x0 = srcX.floor();
        final x1 = x0 + 1;
        final y0 = srcY.floor();
        final y1 = y0 + 1;

        if (x0 >= 0 && x1 < source.width && y0 >= 0 && y1 < source.height) {
          final fx = srcX - x0;
          final fy = srcY - y0;

          final p00 = source.getPixel(x0, y0);
          final p10 = source.getPixel(x1, y0);
          final p01 = source.getPixel(x0, y1);
          final p11 = source.getPixel(x1, y1);

          final r =
              (p00.r * (1 - fx) * (1 - fy) +
                      p10.r * fx * (1 - fy) +
                      p01.r * (1 - fx) * fy +
                      p11.r * fx * fy)
                  .toInt();
          
          final g =
              (p00.g * (1 - fx) * (1 - fy) +
                      p10.g * fx * (1 - fy) +
                      p01.g * (1 - fx) * fy +
                      p11.g * fx * fy)
                  .toInt();

          final b =
              (p00.b * (1 - fx) * (1 - fy) +
                      p10.b * fx * (1 - fy) +
                      p01.b * (1 - fx) * fy +
                      p11.b * fx * fy)
                  .toInt();

          result.setPixelRgb(x, y, r, g, b);
        }
      }
    }

    return result;
  }
}
