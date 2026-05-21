import 'dart:ui';

/// Confidence score untuk setiap field yang diekstrak
class FieldConfidence {
  final String fieldName;
  final String? value;
  final double confidence; // 0.0 - 1.0
  final String? validationError; // Error message jika ada

  FieldConfidence({
    required this.fieldName,
    required this.value,
    required this.confidence,
    this.validationError,
  });

  bool get isValid => validationError == null;
  bool get isHighConfidence => confidence > 0.7;
  bool get isMediumConfidence => confidence > 0.4 && confidence <= 0.7;
  bool get isLowConfidence => confidence <= 0.4;

  @override
  String toString() =>
      '$fieldName: "$value" (${(confidence * 100).toStringAsFixed(0)}%, valid: $isValid)';
}

/// Data posisi teks terdeteksi (untuk bounding box overlay)
class DetectedTextBlock {
  final String text;
  final Rect boundingBox;

  DetectedTextBlock({required this.text, required this.boundingBox});
}

/// Enhanced KK extraction result dengan confidence scoring
class KKExtractionResult {
  // === Data Fields dengan Confidence ===
  final FieldConfidence noKK;
  final FieldConfidence namaKepalaKeluarga;
  final FieldConfidence alamat;
  final FieldConfidence kodePos;
  final FieldConfidence kabupatenKota;
  final FieldConfidence provinsi;

  // === Quality Metadata ===
  final String rawText;
  final List<DetectedTextBlock> textBlocks;
  final double overallQuality; // 0.0 - 1.0 (quality check score)
  final double perspectiveCorrected; // confidence of document detection
  final DateTime extractedAt;

  // === Status ===
  final bool isSuccess;
  final String? extractionError;

  KKExtractionResult({
    required this.noKK,
    required this.namaKepalaKeluarga,
    required this.alamat,
    required this.kodePos,
    required this.kabupatenKota,
    required this.provinsi,
    required this.rawText,
    this.textBlocks = const [],
    this.overallQuality = 0.0,
    this.perspectiveCorrected = 0.0,
    this.extractionError,
  }) : isSuccess = _calculateSuccess(noKK, alamat, kodePos),
       extractedAt = DateTime.now();

  static bool _calculateSuccess(
    FieldConfidence noKK,
    FieldConfidence alamat,
    FieldConfidence kodePos,
  ) {
    // Success jika minimal satu field dengan confidence > 0.5 diekstrak
    return (noKK.value != null && noKK.confidence > 0.5) ||
        (alamat.value != null && alamat.confidence > 0.5) ||
        (kodePos.value != null && kodePos.confidence > 0.5);
  }

  /// Average confidence dari semua field yang punya value
  double get averageFieldConfidence {
    final fields = [
      noKK,
      namaKepalaKeluarga,
      alamat,
      kodePos,
      kabupatenKota,
      provinsi,
    ].where((f) => f.value != null).toList();

    if (fields.isEmpty) return 0.0;

    return fields.map((f) => f.confidence).reduce((a, b) => a + b) /
        fields.length;
  }

  /// List semua field dengan value
  List<FieldConfidence> get extractedFields {
    return [
      noKK,
      namaKepalaKeluarga,
      alamat,
      kodePos,
      kabupatenKota,
      provinsi,
    ].where((f) => f.value != null).toList();
  }

  /// List semua field yang perlu review (confidence < 0.7)
  List<FieldConfidence> get fieldsNeedingReview {
    return extractedFields.where((f) => f.confidence < 0.7).toList();
  }

  /// List semua validation errors
  List<String> get validationErrors {
    return extractedFields
        .where((f) => f.validationError != null)
        .map((f) => '${f.fieldName}: ${f.validationError}')
        .toList();
  }

  @override
  String toString() {
    return '''KKExtractionResult(
  ✓ NoKK: ${noKK.value} (${(noKK.confidence * 100).toInt()}%)
  ✓ Nama: ${namaKepalaKeluarga.value} (${(namaKepalaKeluarga.confidence * 100).toInt()}%)
  ✓ Alamat: ${alamat.value} (${(alamat.confidence * 100).toInt()}%)
  ✓ KodePos: ${kodePos.value} (${(kodePos.confidence * 100).toInt()}%)
  ✓ Kab: ${kabupatenKota.value} (${(kabupatenKota.confidence * 100).toInt()}%)
  ✓ Prov: ${provinsi.value} (${(provinsi.confidence * 100).toInt()}%)
  
  Quality: ${(overallQuality * 100).toInt()}%
  Perspective: ${(perspectiveCorrected * 100).toInt()}%
  Average Confidence: ${(averageFieldConfidence * 100).toInt()}%
  Success: $isSuccess
  Fields Needing Review: ${fieldsNeedingReview.length}
)''';
  }
}
