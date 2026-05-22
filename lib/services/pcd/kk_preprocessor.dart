// lib/services/pcd/kk_preprocessor.dart

import 'dart:math';

import 'package:image/image.dart' as img;

enum PreprocessMode {
  forOCRHeader,    // Header & No. KK → kontras tinggi
  forOCRTable,     // Tabel anggota → teks kecil, butuh sharpening kuat
  forQualityCheck, // Quality check saja
  fullDebug,       // Semua step, untuk development
}

class KKPreprocessor {

  static img.Image process(img.Image source, PreprocessMode mode) {
    switch (mode) {
      case PreprocessMode.forOCRHeader:
        return _headerPipeline(source);
      case PreprocessMode.forOCRTable:
        return _tablePipeline(source);
      case PreprocessMode.forQualityCheck:
        return img.grayscale(source);
      case PreprocessMode.fullDebug:
        return _fullPipeline(source);
    }
  }

  /// Pipeline untuk header KK (No. KK, Alamat, Kode Pos)
  /// Teks relatif besar → tidak perlu sharpening agresif
  static img.Image _headerPipeline(img.Image source) {
    var img0 = _resize(source, targetWidth: 1200);
    var img1 = img.grayscale(img0);
    var img2 = _clahe(img1);               // Contrast enhancement lokal
    var img3 = _unsharpMask(img2, amount: 0.8); // Soft sharpening
    return img3;
  }

  /// Pipeline untuk tabel anggota (teks kecil, dense)
  /// Butuh resolusi lebih tinggi dan sharpening kuat
  static img.Image _tablePipeline(img.Image source) {
    var img0 = _resize(source, targetWidth: 1600); // Resolusi lebih tinggi
    var img1 = img.grayscale(img0);
    var img2 = _clahe(img1, clipLimit: 4.0);
    var img3 = _unsharpMask(img2, amount: 1.5);   // Sharpening kuat
    var img4 = _adaptiveBinarize(img3);             // Binarisasi untuk teks kecil
    return img4;
  }

  static img.Image _fullPipeline(img.Image source) {
    var i = _resize(source, targetWidth: 1200);
    i = img.grayscale(i);
    i = _clahe(i);
    i = _unsharpMask(i, amount: 1.0);
    i = _adaptiveBinarize(i);
    i = _medianDenoise(i);
    return i;
  }

  static img.Image _resize(img.Image source, {required int targetWidth}) {
    if (source.width <= targetWidth) return source;
    return img.copyResize(source, width: targetWidth);
  }

  /// CLAHE (Contrast Limited Adaptive Histogram Equalization)
  /// Lebih baik dari global histogram equalization untuk dokumen
  /// karena menangani pencahayaan tidak merata (shadow, glare)
  static img.Image _clahe(
      img.Image gray, {
        int tileSize = 8,
        double clipLimit = 2.0,
      }) {
    final w = gray.width;
    final h = gray.height;
    final result = img.Image(width: w, height: h);

    final tilesX = (w / tileSize).ceil();
    final tilesY = (h / tileSize).ceil();

    // Pre-compute LUT untuk setiap tile
    final luts = List.generate(
        tilesY, (_) => List.generate(tilesX, (_) => List<int>.filled(256, 0))
    );

    for (int ty = 0; ty < tilesY; ty++) {
      for (int tx = 0; tx < tilesX; tx++) {
        final x0 = (tx * tileSize).clamp(0, w-1);
        final y0 = (ty * tileSize).clamp(0, h-1);
        final x1 = ((tx+1) * tileSize).clamp(0, w);
        final y1 = ((ty+1) * tileSize).clamp(0, h);

        // Histogram tile
        final hist = List<int>.filled(256, 0);
        for (int y = y0; y < y1; y++) {
          for (int x = x0; x < x1; x++) {
            hist[gray.getPixel(x, y).r.toInt()]++;
          }
        }

        // Clip histogram
        final pixelCount = (x1-x0) * (y1-y0);
        final clipValue = (clipLimit * pixelCount / 256).round();
        int excess = 0;
        for (int i = 0; i < 256; i++) {
          if (hist[i] > clipValue) {
            excess += hist[i] - clipValue;
            hist[i] = clipValue;
          }
        }
        // Redistribute excess
        final redistribute = excess ~/ 256;
        for (int i = 0; i < 256; i++) {
          hist[i] += redistribute;
        }

        // Build LUT dari clipped histogram
        int cdf = 0;
        final minCdf = hist.firstWhere((h) => h > 0, orElse: () => 0);
        for (int i = 0; i < 256; i++) {
          cdf += hist[i];
          luts[ty][tx][i] = ((cdf - minCdf) * 255 /
              (pixelCount - minCdf)).round().clamp(0, 255);
        }
      }
    }

    // Apply dengan bilinear interpolation antar tile
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final pixel = gray.getPixel(x, y).r.toInt();

        final tx = (x / tileSize - 0.5).clamp(0, tilesX-1);
        final ty = (y / tileSize - 0.5).clamp(0, tilesY-1);

        final tx0 = tx.floor().clamp(0, tilesX-1);
        final tx1 = (tx0+1).clamp(0, tilesX-1);
        final ty0 = ty.floor().clamp(0, tilesY-1);
        final ty1 = (ty0+1).clamp(0, tilesY-1);

        final fx = tx - tx0;
        final fy = ty - ty0;

        // Bilinear interpolation dari 4 tile LUT
        final val = (
            luts[ty0][tx0][pixel] * (1-fx) * (1-fy) +
                luts[ty0][tx1][pixel] * fx * (1-fy) +
                luts[ty1][tx0][pixel] * (1-fx) * fy +
                luts[ty1][tx1][pixel] * fx * fy
        ).round().clamp(0, 255);

        result.setPixelRgb(x, y, val, val, val);
      }
    }

    return result;
  }

  /// Unsharp Masking — lebih natural dari Laplacian sharpening
  /// Formula: sharpened = original + amount * (original - blurred)
  static img.Image _unsharpMask(img.Image source, {double amount = 1.0}) {
    final blurred = _gaussianBlur(source, sigma: 2.0);
    final w = source.width;
    final h = source.height;
    final result = img.Image(width: w, height: h);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final orig = source.getPixel(x, y).r.toInt();
        final blur = blurred.getPixel(x, y).r.toInt();
        final sharp = (orig + amount * (orig - blur)).round().clamp(0, 255);
        result.setPixelRgb(x, y, sharp, sharp, sharp);
      }
    }
    return result;
  }

  /// Gaussian blur dengan sigma parameter
  static img.Image _gaussianBlur(img.Image source, {double sigma = 1.5}) {
    final radius = (sigma * 3).ceil();
    final kernelSize = 2 * radius + 1;

    // Build Gaussian kernel
    final kernel = List.generate(kernelSize, (i) {
      return List.generate(kernelSize, (j) {
        final x = i - radius;
        final y = j - radius;
        return exp(-(x*x + y*y) / (2 * sigma * sigma));
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
            final ny = (y + ky - radius).clamp(0, h-1);
            final nx = (x + kx - radius).clamp(0, w-1);
            val += source.getPixel(nx, ny).r.toInt() * kernel[ky][kx];
          }
        }
        final v = val.round().clamp(0, 255);
        result.setPixelRgb(x, y, v, v, v);
      }
    }
    return result;
  }

  /// Adaptive binarization dengan Sauvola method
  /// Lebih baik untuk dokumen dengan background tidak uniform
  static img.Image _adaptiveBinarize(img.Image gray, {int windowSize = 31}) {
    final w = gray.width;
    final h = gray.height;
    final result = img.Image(width: w, height: h);
    final half = windowSize ~/ 2;
    final k = 0.15; // Sauvola parameter (0.1–0.25)
    final R = 128.0; // Dynamic range of standard deviation

    // Integral image untuk mean dan variance
    final intSum = List.generate(h+1, (_) => List<double>.filled(w+1, 0));
    final intSumSq = List.generate(h+1, (_) => List<double>.filled(w+1, 0));

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = gray.getPixel(x, y).r.toInt().toDouble();
        intSum[y+1][x+1] = p + intSum[y][x+1] + intSum[y+1][x] - intSum[y][x];
        intSumSq[y+1][x+1] = p*p + intSumSq[y][x+1] + intSumSq[y+1][x] - intSumSq[y][x];
      }
    }

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final x0 = max(0, x - half);
        final y0 = max(0, y - half);
        final x1 = min(w, x + half + 1);
        final y1 = min(h, y + half + 1);

        final count = (x1 - x0) * (y1 - y0);

        final sum = intSum[y1][x1] - intSum[y0][x1] - intSum[y1][x0] + intSum[y0][x0];
        final sumSq = intSumSq[y1][x1] - intSumSq[y0][x1] - intSumSq[y1][x0] + intSumSq[y0][x0];

        final mean = sum / count;
        final variance = max(0, sumSq / count - mean * mean);
        final stdDev = sqrt(variance);

        // Sauvola threshold
        final threshold = mean * (1 + k * (stdDev / R - 1));

        final pixel = gray.getPixel(x, y).r.toInt();
        final value = pixel >= threshold ? 255 : 0;
        result.setPixelRgb(x, y, value, value, value);
      }
    }

    return result;
  }

  /// Median filter 3×3 untuk salt-and-pepper noise
  static img.Image _medianDenoise(img.Image source) {
    final w = source.width;
    final h = source.height;
    final result = img.Image(width: w, height: h);

    for (int y = 1; y < h-1; y++) {
      for (int x = 1; x < w-1; x++) {
        final neighbors = <int>[];
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            neighbors.add(source.getPixel(x+kx, y+ky).r.toInt());
          }
        }
        neighbors.sort();
        final m = neighbors[4];
        result.setPixelRgb(x, y, m, m, m);
      }
    }
    return result;
  }
}