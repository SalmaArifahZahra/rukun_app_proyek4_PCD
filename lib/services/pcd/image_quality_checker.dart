import 'dart:math';
import 'package:image/image.dart' as img;

/// Hasil quality check untuk gambar
class ImageQualityResult {
  final double blurScore; // 0.0 - 1.0 (0 = sangat blur, 1 = sangat sharp)
  final double
  brightnessScore; // 0.0 - 1.0 (0 = terlalu gelap, 1 = terlalu terang, ideal 0.5)
  final double contrastScore; // 0.0 - 1.0 (0 = no contrast, 1 = good contrast)
  final bool isAcceptableQuality;
  final List<String> warnings;

  ImageQualityResult({
    required this.blurScore,
    required this.brightnessScore,
    required this.contrastScore,
    required this.warnings,
  }) : isAcceptableQuality = _calculateAcceptable(
         blurScore,
         brightnessScore,
         contrastScore,
       );

  static bool _calculateAcceptable(
    double blur,
    double brightness,
    double contrast,
  ) {
    // Kriteria (A4 Document OCR optimized):
    // - blur > 0.6 (cukup tajam)
    // - brightness 0.2-0.95 (allow terang karena scan/photo bisa bright)
    // - contrast > 0.2 (teks terlihat dari background)
    // Note: ML Kit bisa handle terang image dengan baik, jadi relax brightness threshold
    return blur > 0.6 &&
        brightness > 0.2 &&
        brightness < 0.95 &&
        contrast > 0.2;
  }

  double get overallQuality {
    // Weighted average: blur 40%, brightness 30%, contrast 30%
    return (blurScore * 0.4 + brightnessScore * 0.3 + contrastScore * 0.3)
        .clamp(0.0, 1.0);
  }

  @override
  String toString() {
    return '''ImageQualityResult(
  blur: ${(blurScore * 100).toStringAsFixed(1)}%,
  brightness: ${(brightnessScore * 100).toStringAsFixed(1)}%,
  contrast: ${(contrastScore * 100).toStringAsFixed(1)}%,
  overall: ${(overallQuality * 100).toStringAsFixed(1)}%,
  acceptable: $isAcceptableQuality,
  warnings: $warnings
)''';
  }
}

/// Service untuk check kualitas gambar sebelum OCR
class ImageQualityChecker {
  /// Check kualitas gambar secara lengkap
  static Future<ImageQualityResult> checkQuality(img.Image image) async {
    final warnings = <String>[];

    // 1. Blur Detection (Laplacian variance)
    final blurScore = _detectBlur(image);
    if (blurScore < 0.6) {
      warnings.add(
        'Gambar terlihat blur. Coba ambil ulang dengan fokus lebih baik.',
      );
    }

    // 2. Brightness Check (A4 Document OCR optimized)
    final brightnessScore = _checkBrightness(image);
    if (brightnessScore < 0.2) {
      warnings.add('Gambar terlalu gelap. Tambahkan pencahayaan lebih baik.');
    } else if (brightnessScore > 0.9) {
      warnings.add(
        '🔆 Gambar sangat terang (scan/glare). ML Kit masih bisa OCR.',
      );
    }

    // 3. Contrast Check (A4 Document OCR)
    final contrastScore = _checkContrast(image);
    if (contrastScore < 0.2) {
      warnings.add(
        'Kontras rendah. Ambil foto dengan lighting lebih baik atau background lebih gelap.',
      );
    }

    return ImageQualityResult(
      blurScore: blurScore,
      brightnessScore: brightnessScore,
      contrastScore: contrastScore,
      warnings: warnings,
    );
  }

  /// Deteksi blur menggunakan Laplacian variance
  /// Semakin tinggi variance, semakin tajam gambar
  static double _detectBlur(img.Image image) {
    final gray = img.grayscale(image);
    final w = gray.width;
    final h = gray.height;

    // Compute Laplacian
    final laplacian = <double>[];

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final center = gray.getPixel(x, y).r.toInt();
        final neighbors = [
          gray.getPixel(x - 1, y).r.toInt(),
          gray.getPixel(x + 1, y).r.toInt(),
          gray.getPixel(x, y - 1).r.toInt(),
          gray.getPixel(x, y + 1).r.toInt(),
        ];

        final laplacianValue = 4 * center - neighbors.reduce((a, b) => a + b);
        laplacian.add(laplacianValue.toDouble());
      }
    }

    if (laplacian.isEmpty) return 0.0;

    // Calculate variance
    final mean = laplacian.reduce((a, b) => a + b) / laplacian.length;
    final variance =
        laplacian.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
        laplacian.length;

    // Normalize ke 0-1 range
    // Blur threshold ditemukan empiris: variance ~500 = acceptable sharpness
    // variance ~100 = blur
    // variance ~2000+ = over-sharp/noise
    final normalizedScore = (variance / 2000).clamp(0.0, 1.0);

    return normalizedScore;
  }

  /// Check brightness level (A4 Document optimized)
  /// Return value ideal: 0.3 - 0.8 (medium brightness)
  /// Accept range: 0.2 - 0.95 (allow brighter scans/photos)
  ///
  /// Note: ML Kit Text Recognition handles bright images well,
  /// so we're more lenient with brightness for scanned A4 documents
  static double _checkBrightness(img.Image image) {
    final gray = img.grayscale(image);
    double sum = 0;
    int pixelCount = 0;

    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        sum += gray.getPixel(x, y).r.toInt();
        pixelCount++;
      }
    }

    final avgBrightness = sum / pixelCount / 255.0;

    // Ideal brightness: 0.3 - 0.8 (medium)
    // Score: normalized distance dari ideal range
    // Allow higher brightness (0.95) untuk scanned documents
    if (avgBrightness < 0.2) {
      return avgBrightness; // Terlalu gelap
    } else if (avgBrightness > 0.8) {
      return 1.0 - (avgBrightness - 0.8); // Terlalu terang
    } else {
      return 1.0; // Ideal range
    }
  }

  /// Check contrast level menggunakan standard deviation
  /// Semakin tinggi std dev, semakin baik contrast
  static double _checkContrast(img.Image image) {
    final gray = img.grayscale(image);
    final pixels = <int>[];

    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        pixels.add(gray.getPixel(x, y).r.toInt());
      }
    }

    if (pixels.isEmpty) return 0.0;

    // Calculate mean
    final mean = pixels.reduce((a, b) => a + b) / pixels.length;

    // Calculate standard deviation
    final variance =
        pixels.map((p) => pow(p - mean, 2).toInt()).reduce((a, b) => a + b) /
        pixels.length;
    final stdDev = sqrt(variance);

    // Normalize: good contrast ~50-100 std dev
    // Ideal threshold: 30-100+ (accept 0.3-1.0 range)
    final normalizedScore = (stdDev / 100).clamp(0.0, 1.0);

    return normalizedScore;
  }

  /// Rekomendasi perbaikan berdasarkan quality result
  static String getRecommendation(ImageQualityResult result) {
    if (result.isAcceptableQuality) {
      return '✅ Kualitas gambar baik. Siap untuk ekstraksi data.';
    }

    final recommendations = <String>[];

    if (result.blurScore < 0.6) {
      recommendations.add('📸 Gunakan flash atau cahaya lebih baik');
      recommendations.add('🤚 Pegang kamera dengan stabil');
    }

    if (result.brightnessScore < 0.3) {
      recommendations.add('💡 Tambahkan pencahayaan');
    } else if (result.brightnessScore > 0.8) {
      recommendations.add('🔆 Kurangi pencahayaan atau glare');
    }

    if (result.contrastScore < 0.3) {
      recommendations.add('🎨 Pastikan teks/KK jelas terlihat');
      recommendations.add('📄 Hindari background yang terlalu mirip warna KK');
    }

    return recommendations.join('\n');
  }
}
