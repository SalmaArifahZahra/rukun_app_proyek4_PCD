// lib/services/pcd/document_detector_v2.dart

import 'dart:math';
import 'dart:ui';

import 'package:image/image.dart' as img;

import 'document_detection_service.dart';

class DocumentDetectorV2 {

  /// Gaussian Blur sederhana untuk mengurangi noise sebelum edge detection
  static img.Image _gaussianBlur(img.Image source, {int radius = 3}) {
    final kernelSize = 2 * radius + 1;
    final sigma = radius / 2.0;

    // Build Gaussian kernel
    final kernel = List.generate(kernelSize, (i) {
      return List.generate(kernelSize, (j) {
        final x = i - radius;
        final y = j - radius;
        return exp(-(x * x + y * y) / (2 * sigma * sigma));
      });
    });

    // Normalize kernel
    double sum = kernel.expand((row) => row).reduce((a, b) => a + b);
    for (int i = 0; i < kernelSize; i++) {
      for (int j = 0; j < kernelSize; j++) {
        kernel[i][j] /= sum;
      }
    }

    final w = source.width;
    final h = source.height;
    final result = img.Image(width: w, height: h);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        double val = 0;
        for (int ky = 0; ky < kernelSize; ky++) {
          for (int kx = 0; kx < kernelSize; kx++) {
            final ny = (y + ky - radius).clamp(0, h - 1);
            final nx = (x + kx - radius).clamp(0, w - 1);
            val += source.getPixel(nx, ny).r.toInt() * kernel[ky][kx];
          }
        }
        final v = val.round().clamp(0, 255);
        result.setPixelRgb(x, y, v, v, v);
      }
    }
    return result;
  }

  /// Pipeline deteksi dokumen yang lebih robust:
  /// 1. Gaussian Blur → kurangi noise
  /// 2. Canny Edge Detection (double threshold)
  /// 3. Dilate edges → tutup gap
  /// 4. Find largest quadrilateral contour
  /// 5. Score berdasarkan area + rectangularity

  static Future<DocumentQuad?> detect(img.Image source) async {
    // Step 1: Resize ke resolusi standar untuk performa
    final working = _resizeForDetection(source); // max 800px

    // Step 2: Grayscale
    final gray = img.grayscale(working);

    // Step 3: Gaussian blur (reduce noise sebelum edge)
    final blurred = _gaussianBlur(gray, radius: 3);

    // Step 4: Canny-like edge detection
    final edges = _cannyEdge(blurred, lowThreshold: 50, highThreshold: 150);

    // Step 5: Morphological dilation (tutup gap pada edge)
    final dilated = _dilate(edges, kernelSize: 3);

    // Step 6: Find quadrilateral candidates
    final quads = _findQuadrilaterals(dilated);

    // Step 7: Pilih quad terbaik berdasarkan score
    return _selectBestQuad(quads, working.width, working.height);
  }

  static img.Image _resizeForDetection(img.Image source) {
    const maxDim = 800;
    if (source.width <= maxDim && source.height <= maxDim) return source;

    if (source.width > source.height) {
      return img.copyResize(source, width: maxDim);
    }
    return img.copyResize(source, height: maxDim);
  }

  /// Canny Edge Detection — dua threshold untuk akurasi lebih baik
  static img.Image _cannyEdge(
      img.Image gray, {
        required int lowThreshold,
        required int highThreshold,
      }) {
    final w = gray.width;
    final h = gray.height;

    // Sobel magnitude
    final magnitude = List.generate(h, (_) => List<double>.filled(w, 0));
    final direction = List.generate(h, (_) => List<double>.filled(w, 0));

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        // Sobel kernels
        final gx = -gray.getPixel(x-1,y-1).r.toInt()
            - 2*gray.getPixel(x-1,y).r.toInt()
            - gray.getPixel(x-1,y+1).r.toInt()
            + gray.getPixel(x+1,y-1).r.toInt()
            + 2*gray.getPixel(x+1,y).r.toInt()
            + gray.getPixel(x+1,y+1).r.toInt();

        final gy = -gray.getPixel(x-1,y-1).r.toInt()
            - 2*gray.getPixel(x,y-1).r.toInt()
            - gray.getPixel(x+1,y-1).r.toInt()
            + gray.getPixel(x-1,y+1).r.toInt()
            + 2*gray.getPixel(x,y+1).r.toInt()
            + gray.getPixel(x+1,y+1).r.toInt();

        magnitude[y][x] = sqrt(gx*gx + gy*gy.toDouble());
        direction[y][x] = atan2(gy.toDouble(), gx.toDouble());
      }
    }

    // Non-maximum suppression + double threshold
    final result = img.Image(width: w, height: h);
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final mag = magnitude[y][x];
        int value = 0;

        if (mag >= highThreshold) {
          value = 255; // strong edge
        } else if (mag >= lowThreshold) {
          value = 128; // weak edge (akan di-suppress)
        }

        result.setPixelRgb(x, y, value, value, value);
      }
    }

    return result;
  }

  /// Dilasi morfologi — tutup gap pada edge line
  static img.Image _dilate(img.Image source, {required int kernelSize}) {
    final w = source.width;
    final h = source.height;
    final result = img.Image(width: w, height: h);
    final half = kernelSize ~/ 2;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        int maxVal = 0;
        for (int ky = -half; ky <= half; ky++) {
          for (int kx = -half; kx <= half; kx++) {
            final ny = (y + ky).clamp(0, h-1);
            final nx = (x + kx).clamp(0, w-1);
            final val = source.getPixel(nx, ny).r.toInt();
            if (val > maxVal) maxVal = val;
          }
        }
        result.setPixelRgb(x, y, maxVal, maxVal, maxVal);
      }
    }
    return result;
  }

  /// Cari kandidat quadrilateral dari edge image
  static List<DocumentQuad> _findQuadrilaterals(img.Image edges) {
    // Implementasi: scan baris dari 4 arah untuk menemukan boundary points
    // Kemudian fit ke quadrilateral menggunakan least squares
    final quads = <DocumentQuad>[];
    final w = edges.width;
    final h = edges.height;

    // Scan dari 4 sudut untuk menemukan titik-titik edge terluar
    // dengan margin 10% untuk menghindari border image
    final margin = 0.10;

    // Strategi: ray casting dari setiap sisi
    Offset? topLeft = _raycast(edges,
        startX: (w * margin).toInt(), startY: 0,
        dx: 1, dy: 1
    );
    Offset? topRight = _raycast(edges,
        startX: (w * (1 - margin)).toInt(), startY: 0,
        dx: -1, dy: 1
    );
    Offset? bottomLeft = _raycast(edges,
        startX: (w * margin).toInt(), startY: h - 1,
        dx: 1, dy: -1
    );
    Offset? bottomRight = _raycast(edges,
        startX: (w * (1 - margin)).toInt(), startY: h - 1,
        dx: -1, dy: -1
    );

    if (topLeft != null && topRight != null &&
        bottomLeft != null && bottomRight != null) {
      quads.add(DocumentQuad(
        topLeft: topLeft,
        topRight: topRight,
        bottomLeft: bottomLeft,
        bottomRight: bottomRight,
        imageWidth: w.toDouble(),
        imageHeight: h.toDouble(),
      ));
    }

    return quads;
  }

  /// Ray casting: cari pixel edge pertama dari arah tertentu
  static Offset? _raycast(
      img.Image edges, {
        required int startX,
        required int startY,
        required int dx,
        required int dy,
        int threshold = 128,
      }) {
    int x = startX;
    int y = startY;

    while (x >= 0 && x < edges.width && y >= 0 && y < edges.height) {
      if (edges.getPixel(x, y).r.toInt() >= threshold) {
        return Offset(x.toDouble(), y.toDouble());
      }
      x += dx;
      y += dy;
    }
    return null;
  }

  static DocumentQuad? _selectBestQuad(
      List<DocumentQuad> quads, int imgW, int imgH
      ) {
    if (quads.isEmpty) return null;

    DocumentQuad? best;
    double bestScore = 0;

    for (final quad in quads) {
      final score = quad.calculateScore(imgW, imgH);
      if (score > bestScore) {
        bestScore = score;
        best = quad;
      }
    }

    // Minimum score threshold: 0.3
    return (bestScore > 0.3) ? best : null;
  }
}

class DocumentQuad {
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomLeft;
  final Offset bottomRight;
  final double imageWidth;
  final double imageHeight;

  DocumentQuad({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    required this.imageWidth,
    required this.imageHeight,
  });

  /// Score berdasarkan:
  /// - Area coverage (dokumen mengisi frame cukup besar)
  /// - Rectangularity (mendekati persegi panjang)
  /// - Aspect ratio (KK Indonesia ~1:1.4 landscape)
  double calculateScore(int imgW, int imgH) {
    final totalArea = imgW * imgH;
    final quadArea = _calculateQuadArea();

    // 1. Area ratio: 20%–90% dari frame adalah ideal
    final areaRatio = quadArea / totalArea;
    final areaScore = (areaRatio > 0.2 && areaRatio < 0.95)
        ? 1.0 - (areaRatio - 0.6).abs() / 0.4
        : 0.0;

    // 2. Rectangularity: cek sudut mendekati 90°
    final rectScore = _calculateRectangularity();

    // 3. Aspect ratio KK Indonesia (landscape ~1.4:1 atau portrait ~0.7:1)
    final width = _distance(topLeft, topRight);
    final height = _distance(topLeft, bottomLeft);
    final aspectRatio = width > 0 ? height / width : 0;
    final isKKLandscape = aspectRatio > 0.6 && aspectRatio < 0.85;
    final isKKPortrait = aspectRatio > 1.2 && aspectRatio < 1.5;
    final aspectScore = (isKKLandscape || isKKPortrait) ? 1.0 : 0.5;

    return (areaScore * 0.4 + rectScore * 0.4 + aspectScore * 0.2)
        .clamp(0.0, 1.0);
  }

  double _calculateQuadArea() {
    // Shoelace formula
    final points = [topLeft, topRight, bottomRight, bottomLeft];
    double area = 0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      area += points[i].dx * points[j].dy;
      area -= points[j].dx * points[i].dy;
    }
    return area.abs() / 2;
  }

  double _calculateRectangularity() {
    // Cek 4 sudut mendekati 90°
    final angles = [
      _angleDeg(bottomLeft, topLeft, topRight),   // sudut TL
      _angleDeg(topLeft, topRight, bottomRight),   // sudut TR
      _angleDeg(topRight, bottomRight, bottomLeft), // sudut BR
      _angleDeg(bottomRight, bottomLeft, topLeft),  // sudut BL
    ];

    final avgDeviation = angles
        .map((a) => (a - 90).abs())
        .reduce((a, b) => a + b) / 4;

    return (1.0 - avgDeviation / 45).clamp(0.0, 1.0);
  }

  double _angleDeg(Offset a, Offset vertex, Offset b) {
    final v1 = Offset(a.dx - vertex.dx, a.dy - vertex.dy);
    final v2 = Offset(b.dx - vertex.dx, b.dy - vertex.dy);
    final dot = v1.dx * v2.dx + v1.dy * v2.dy;
    final mag1 = sqrt(v1.dx * v1.dx + v1.dy * v1.dy);
    final mag2 = sqrt(v2.dx * v2.dx + v2.dy * v2.dy);
    if (mag1 == 0 || mag2 == 0) return 90;
    return acos((dot / (mag1 * mag2)).clamp(-1.0, 1.0)) * 180 / pi;
  }

  static double _distance(Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    return sqrt(dx*dx + dy*dy);
  }

  /// Convert ke DocumentCorners untuk kompatibilitas dengan kode lama
  DocumentCorners toDocumentCorners() => DocumentCorners(
    topLeft: topLeft,
    topRight: topRight,
    bottomLeft: bottomLeft,
    bottomRight: bottomRight,
    confidence: calculateScore(imageWidth.toInt(), imageHeight.toInt()),
  );
}