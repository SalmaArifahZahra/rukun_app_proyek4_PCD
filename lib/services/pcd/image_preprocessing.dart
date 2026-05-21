import 'dart:math';

import 'package:image/image.dart' as img;

/// PCD (Pengolahan Citra Digital) Image Preprocessing Pipeline
///
/// Pipeline steps:
/// 1. Resize — Standarisasi ukuran agar konsisten & hemat memori
/// 2. Grayscale — Konversi ke 1 channel (R*0.299 + G*0.587 + B*0.114)
/// 3. Normalisasi [0,1] + Contrast Enhancement — Histogram Equalization
/// 4. Sharpening — Laplacian kernel convolution
/// 5. Adaptive Threshold — Binarisasi lokal (mean-based)
/// 6. Noise Reduction — Median filter 3x3
class ImagePreprocessor {
  /// Target width untuk resize (menjaga aspect ratio)
  static const int targetWidth = 1080;

  /// Ukuran blok untuk adaptive threshold
  static const int adaptiveBlockSize = 15;

  /// Konstanta C untuk adaptive threshold
  static const double adaptiveC = 10.0;

  /// Menjalankan PCD pipeline RINGAN untuk OCR.
  ///
  /// ML Kit memiliki preprocessing internal, sehingga binarisasi
  /// (adaptive threshold) justru menghancurkan gradien yang dibutuhkan.
  /// Pipeline ringan: Resize → Grayscale → Normalize+Contrast → Sharpen
  static img.Image processForOCR(img.Image source) {
    // Step 1: Resize — standarisasi ukuran
    var processed = _resize(source);

    // Step 2: Grayscale — konversi ke 1 channel
    processed = _toGrayscale(processed);

    // Step 3 & 4: Normalisasi [0,1] + Contrast Enhancement
    processed = _normalizeAndEnhanceContrast(processed);

    // Step 5: Sharpening — pertajam tepi huruf
    processed = _sharpen(processed);

    // NOTE: Adaptive Threshold & Median Filter TIDAK dipakai untuk OCR
    // karena ML Kit butuh informasi gradien pixel, bukan binary image.

    return processed;
  }

  /// Menjalankan FULL PCD pipeline (semua 7 step).
  ///
  /// Termasuk binarisasi dan noise reduction.
  /// Digunakan untuk keperluan visualisasi/debug/akademis.
  static img.Image processFullPipeline(img.Image source) {
    // Step 1-4: Sama seperti processForOCR
    var processed = processForOCR(source);

    // Step 5: Adaptive Threshold — binarisasi hitam/putih
    processed = _adaptiveThreshold(processed);

    // Step 6: Noise Reduction — median filter
    processed = _medianFilter(processed);

    return processed;
  }

  // ──────────────────────────────────────────────
  // Step 1: Resize
  // ──────────────────────────────────────────────

  /// Resize gambar ke target width, menjaga aspect ratio.
  /// Jika gambar sudah lebih kecil dari target, tidak di-resize.
  static img.Image _resize(img.Image source) {
    if (source.width <= targetWidth) return source;
    return img.copyResize(source, width: targetWidth);
  }

  // ──────────────────────────────────────────────
  // Step 2: Grayscale
  // ──────────────────────────────────────────────

  /// Konversi gambar ke grayscale menggunakan luminance formula.
  static img.Image _toGrayscale(img.Image source) {
    return img.grayscale(source);
  }

  // ──────────────────────────────────────────────
  // Step 3 & 4: Normalisasi [0,1] + Histogram Equalization
  // ──────────────────────────────────────────────

  /// Melakukan normalisasi pixel ke range [0,1] sekaligus
  /// meningkatkan kontras via histogram equalization.
  ///
  /// Proses:
  /// 1. Hitung histogram (distribusi intensitas pixel)
  /// 2. Hitung CDF (Cumulative Distribution Function)
  /// 3. Normalisasi: v_norm = pixel / 255.0 (implisit dalam equalization)
  /// 4. Equalize: v_eq = (CDF(v) - CDF_min) / (total - CDF_min)
  /// 5. Map kembali ke [0, 255] untuk representasi gambar
  static img.Image _normalizeAndEnhanceContrast(img.Image source) {
    final w = source.width;
    final h = source.height;

    // Hitung histogram
    final histogram = List<int>.filled(256, 0);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final pixel = source.getPixel(x, y);
        histogram[pixel.r.toInt()]++;
      }
    }

    // Hitung CDF (Cumulative Distribution Function)
    final totalPixels = w * h;
    final cdf = List<int>.filled(256, 0);
    cdf[0] = histogram[0];
    for (int i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + histogram[i];
    }

    // Cari CDF minimum (non-zero pertama)
    int cdfMin = 0;
    for (int i = 0; i < 256; i++) {
      if (cdf[i] > 0) {
        cdfMin = cdf[i];
        break;
      }
    }

    // Build lookup table (LUT) untuk equalisasi
    // Normalisasi [0,1] terintegrasi: pixel/255.0 → equalize → map back
    final lut = List<int>.filled(256, 0);
    final denominator = totalPixels - cdfMin;
    if (denominator > 0) {
      for (int i = 0; i < 256; i++) {
        lut[i] = ((cdf[i] - cdfMin) * 255 / denominator).round().clamp(0, 255);
      }
    }

    // Apply LUT ke setiap pixel
    final result = img.Image(width: w, height: h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final gray = source.getPixel(x, y).r.toInt();
        final eq = lut[gray];
        result.setPixelRgb(x, y, eq, eq, eq);
      }
    }

    return result;
  }

  // ──────────────────────────────────────────────
  // Step 5: Sharpening (Laplacian Kernel)
  // ──────────────────────────────────────────────

  /// Sharpening menggunakan konvolusi kernel Laplacian.
  ///
  /// Kernel:
  /// ```
  ///  [ 0, -1,  0]
  ///  [-1,  5, -1]
  ///  [ 0, -1,  0]
  /// ```
  ///
  /// Efek: mempertajam tepi huruf sehingga OCR lebih akurat.
  static img.Image _sharpen(img.Image source) {
    final w = source.width;
    final h = source.height;
    final result = img.Image(width: w, height: h);

    const kernel = [
      [0, -1, 0],
      [-1, 5, -1],
      [0, -1, 0],
    ];

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        // Border pixels: salin langsung (tidak bisa konvolusi penuh)
        if (x == 0 || y == 0 || x == w - 1 || y == h - 1) {
          final p = source.getPixel(x, y);
          result.setPixelRgb(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt());
          continue;
        }

        // Konvolusi 3x3
        int sum = 0;
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = source.getPixel(x + kx, y + ky);
            sum += pixel.r.toInt() * kernel[ky + 1][kx + 1];
          }
        }

        final clamped = sum.clamp(0, 255);
        result.setPixelRgb(x, y, clamped, clamped, clamped);
      }
    }

    return result;
  }

  // ──────────────────────────────────────────────
  // Step 6: Adaptive Threshold (Binarisasi)
  // ──────────────────────────────────────────────

  /// Binarisasi menggunakan adaptive threshold berbasis mean lokal.
  ///
  /// Menggunakan integral image untuk perhitungan mean yang efisien.
  /// Setiap pixel dibandingkan dengan rata-rata tetangganya:
  /// - Jika pixel < (mean_lokal - C) → hitam (teks/foreground)
  /// - Jika tidak → putih (background)
  ///
  /// Keunggulan vs simple threshold: menangani pencahayaan tidak merata.
  static img.Image _adaptiveThreshold(img.Image source) {
    final w = source.width;
    final h = source.height;
    final result = img.Image(width: w, height: h);
    final halfBlock = adaptiveBlockSize ~/ 2;

    // Build integral image untuk kalkulasi mean cepat O(1) per pixel
    final integral = List.generate(
      h,
      (_) => List<int>.filled(w, 0),
    );

    for (int y = 0; y < h; y++) {
      int rowSum = 0;
      for (int x = 0; x < w; x++) {
        rowSum += source.getPixel(x, y).r.toInt();
        integral[y][x] = rowSum + (y > 0 ? integral[y - 1][x] : 0);
      }
    }

    // Apply adaptive threshold
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final y1 = max(0, y - halfBlock);
        final y2 = min(h - 1, y + halfBlock);
        final x1 = max(0, x - halfBlock);
        final x2 = min(w - 1, x + halfBlock);

        final count = (y2 - y1 + 1) * (x2 - x1 + 1);

        // Hitung sum area dari integral image
        int sum = integral[y2][x2];
        if (x1 > 0) sum -= integral[y2][x1 - 1];
        if (y1 > 0) sum -= integral[y1 - 1][x2];
        if (x1 > 0 && y1 > 0) sum += integral[y1 - 1][x1 - 1];

        final mean = sum / count;
        final pixel = source.getPixel(x, y).r.toInt();

        // Pixel lebih gelap dari mean lokal → foreground (hitam)
        final value = pixel < (mean - adaptiveC) ? 0 : 255;
        result.setPixelRgb(x, y, value, value, value);
      }
    }

    return result;
  }

  // ──────────────────────────────────────────────
  // Step 7: Noise Reduction (Median Filter)
  // ──────────────────────────────────────────────

  /// Median filter 3x3 untuk menghilangkan noise salt-and-pepper.
  ///
  /// Mengambil median dari 9 pixel tetangga, efektif menghilangkan
  /// titik-titik noise kecil tanpa blur berlebihan pada tepi huruf.
  static img.Image _medianFilter(img.Image source) {
    final w = source.width;
    final h = source.height;
    final result = img.Image(width: w, height: h);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        // Border pixels: salin langsung
        if (x == 0 || y == 0 || x == w - 1 || y == h - 1) {
          final p = source.getPixel(x, y);
          result.setPixelRgb(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt());
          continue;
        }

        // Ambil 9 tetangga
        final neighbors = <int>[];
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            neighbors.add(source.getPixel(x + kx, y + ky).r.toInt());
          }
        }

        // Sortir dan ambil median (elemen ke-5 dari 9)
        neighbors.sort();
        final median = neighbors[4];
        result.setPixelRgb(x, y, median, median, median);
      }
    }

    return result;
  }
}
