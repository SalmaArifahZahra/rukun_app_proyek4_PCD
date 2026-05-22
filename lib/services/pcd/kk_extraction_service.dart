import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

import 'document_detection_service.dart';
import 'image_quality_checker.dart';
import 'kk_extraction_result.dart';
import 'roi_extractor.dart';

/// Service untuk mengekstrak data Kartu Keluarga dari gambar.
///
/// Pipeline (Enhanced):
/// 0. Quality Check — blur detection, brightness check
/// 1. Document Detection — deteksi corner & perspective correction
/// 2. Pre-processing gambar (PCD pipeline di Isolate)
/// 3. OCR menggunakan Google ML Kit Text Recognition
/// 4. Parsing field dengan confidence scoring
/// 5. Validation — check format & return hasil terstruktur
/// 6. ROI Extraction (Optional) — crop ke region spesifik untuk ekstraksi cepat
class KKExtractionService {
  /// Mengekstrak data KK dari file gambar dengan semua enhancement
  ///
  /// Pipeline:
  /// 1. Check image quality (blur, brightness, contrast)
  /// 2. Detect document corners & apply perspective correction
  /// 3. Apply PCD preprocessing
  /// 4. Run OCR dual-pass
  /// 5. Extract fields dengan confidence scoring
  /// 6. Validate hasil
  Future<KKExtractionResult> extractFromImage(File imageFile) async {
    debugPrint('╔══════════════════════════════════════════════════════════╗');
    debugPrint('║  MULAI EKSTRAKSI KK - Enhanced with Document Detection   ║');
    debugPrint('╚══════════════════════════════════════════════════════════╝');

    // ── STEP 0: Quality Check ──
    debugPrint('\n📊 [STEP 0] Checking image quality...');
    final imageBytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);

    if (decodedImage == null) {
      return KKExtractionResult(
        noKK: FieldConfidence(
          fieldName: 'noKK',
          value: null,
          confidence: 0.0,
          validationError: 'Gagal decode gambar. Format harus JPG/PNG.',
        ),
        namaKepalaKeluarga: FieldConfidence(
          fieldName: 'namaKepalaKeluarga',
          value: null,
          confidence: 0.0,
        ),
        alamat: FieldConfidence(
          fieldName: 'alamat',
          value: null,
          confidence: 0.0,
        ),
        kodePos: FieldConfidence(
          fieldName: 'kodePos',
          value: null,
          confidence: 0.0,
        ),
        kabupatenKota: FieldConfidence(
          fieldName: 'kabupatenKota',
          value: null,
          confidence: 0.0,
        ),
        provinsi: FieldConfidence(
          fieldName: 'provinsi',
          value: null,
          confidence: 0.0,
        ),
        rawText: '',
        extractionError: 'Gagal decode gambar',
      );
    }

    final qualityResult = await ImageQualityChecker.checkQuality(decodedImage);
    debugPrint('✓ Quality: ${qualityResult.toString()}');
    debugPrint(
      '✓ Recommendation: ${ImageQualityChecker.getRecommendation(qualityResult)}',
    );

    // ── STEP 1: Document Detection & Perspective Correction ──
    debugPrint('\n🔍 [STEP 1] Detecting document corners...');
    var processedImage = decodedImage;
    double perspectiveConfidence = 0.0;

    try {
      final corners = await DocumentDetectionService.detectDocumentCorners(
        decodedImage,
      );
      if (corners != null && corners.confidence > 0.5) {
        debugPrint(
          '✓ Corners detected with confidence: ${(corners.confidence * 100).toStringAsFixed(1)}%',
        );
        debugPrint(
          '  ├─ Top-Left: (${corners.topLeft.dx}, ${corners.topLeft.dy})',
        );
        debugPrint(
          '  ├─ Top-Right: (${corners.topRight.dx}, ${corners.topRight.dy})',
        );
        debugPrint(
          '  ├─ Bottom-Left: (${corners.bottomLeft.dx}, ${corners.bottomLeft.dy})',
        );
        debugPrint(
          '  └─ Bottom-Right: (${corners.bottomRight.dx}, ${corners.bottomRight.dy})',
        );

        // Apply perspective correction
        processedImage = DocumentDetectionService.correctPerspective(
          decodedImage,
          corners,
        );
        perspectiveConfidence = corners.confidence;
        debugPrint('✓ Perspective correction applied');
      } else {
        debugPrint(
          '⚠️  Document corners not detected clearly. Using original image.',
        );
        perspectiveConfidence = 0.0;
      }
    } catch (e) {
      debugPrint(
        '⚠️  Document detection error: $e. Continuing with original image.',
      );
    }

    // ── STEP 2: OCR (dengan PCD preprocessing fallback) ──
    debugPrint('\n🔄 [STEP 2] Running OCR...');
    final ocrResult = await _runOCRWithBlocks(imageFile, processedImage);

    debugPrint('═══════════════════════════════════════');
    debugPrint('📄 RAW OCR TEXT:');
    debugPrint(ocrResult.text);
    debugPrint('═══════════════════════════════════════');

    // ── STEP 3: Extract Fields dengan Confidence Scoring ──
    debugPrint('\n📋 [STEP 3] Extracting fields with confidence scoring...');
    final result = _extractFieldsWithConfidence(
      ocrResult.text,
      blocks: ocrResult.blocks,
      qualityScore: qualityResult.overallQuality,
      perspectiveScore: perspectiveConfidence,
    );

    debugPrint('\n✅ EXTRACTION COMPLETE:');
    debugPrint(result.toString());

    return result;
  }

  /// Ekstraksi data KK dengan ROI (Region of Interest) - CEPAT
  ///
  /// Hanya scan header region (0-40% dari dokumen) untuk:
  /// - No. KK
  /// - Alamat
  /// - Kode Pos
  ///
  /// Lebih cepat 60% dari full scan karena hanya process top area
  Future<KKExtractionResult> extractFromImageWithROI(File imageFile) async {
    debugPrint('╔══════════════════════════════════════════════════════════╗');
    debugPrint('║  EKSTRAKSI KK - ROI Mode (Header Only - CEPAT)           ║');
    debugPrint('╚══════════════════════════════════════════════════════════╝');

    final imageBytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);

    if (decodedImage == null) {
      return KKExtractionResult(
        noKK: FieldConfidence(
          fieldName: 'noKK',
          value: null,
          confidence: 0.0,
          validationError: 'Gagal decode gambar',
        ),
        namaKepalaKeluarga: FieldConfidence(
          fieldName: 'namaKepalaKeluarga',
          value: null,
          confidence: 0.0,
        ),
        alamat: FieldConfidence(
          fieldName: 'alamat',
          value: null,
          confidence: 0.0,
        ),
        kodePos: FieldConfidence(
          fieldName: 'kodePos',
          value: null,
          confidence: 0.0,
        ),
        kabupatenKota: FieldConfidence(
          fieldName: 'kabupatenKota',
          value: null,
          confidence: 0.0,
        ),
        provinsi: FieldConfidence(
          fieldName: 'provinsi',
          value: null,
          confidence: 0.0,
        ),
        rawText: '',
        extractionError: 'Gagal decode gambar',
      );
    }

    // ── STEP 0: Crop ke header region (0-40%) ──
    debugPrint('\n✂️  [STEP 0] Cropping to header region...');
    final tempDir = imageFile.parent.path;
    final headerFile = await ROIExtractor.cropToHeaderRegion(
      decodedImage,
      tempDir: tempDir,
    );

    // ── STEP 1: Quality check (header region saja) ──
    debugPrint('\n📊 [STEP 1] Checking image quality (header region)...');
    final headerBytes = await headerFile.readAsBytes();
    final headerImage = img.decodeImage(headerBytes);

    if (headerImage == null) {
      try {
        await headerFile.delete();
      } catch (_) {}
      return KKExtractionResult(
        noKK: FieldConfidence(fieldName: 'noKK', value: null, confidence: 0.0),
        namaKepalaKeluarga: FieldConfidence(
          fieldName: 'namaKepalaKeluarga',
          value: null,
          confidence: 0.0,
        ),
        alamat: FieldConfidence(
          fieldName: 'alamat',
          value: null,
          confidence: 0.0,
        ),
        kodePos: FieldConfidence(
          fieldName: 'kodePos',
          value: null,
          confidence: 0.0,
        ),
        kabupatenKota: FieldConfidence(
          fieldName: 'kabupatenKota',
          value: null,
          confidence: 0.0,
        ),
        provinsi: FieldConfidence(
          fieldName: 'provinsi',
          value: null,
          confidence: 0.0,
        ),
        rawText: '',
        extractionError: 'Gagal memproses header region',
      );
    }

    final qualityResult = await ImageQualityChecker.checkQuality(headerImage);
    debugPrint('✓ Quality: ${qualityResult.toString()}');

    // ── STEP 2: Run OCR pada header region ──
    debugPrint('\n🤖 [STEP 2] Running OCR on header region...');
    final startTime = DateTime.now();

    final ocrResult = await _runOCRWithBlocks(headerFile, headerImage);

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime).inMilliseconds;
    debugPrint('✓ OCR completed in ${duration}ms');

    debugPrint('═══════════════════════════════════════');
    debugPrint('📄 RAW OCR TEXT (Header):');
    debugPrint(ocrResult.text);
    debugPrint('═══════════════════════════════════════');

    // ── STEP 3: Extract hanya 3 field utama ──
    debugPrint('\n📋 [STEP 3] Extracting header fields...');
    final noKKData = _extractNoKKWithConfidence(ocrResult.text);
    final alamatData = _extractAlamatWithConfidence(ocrResult.text);
    final kodePosData = _extractKodePosWithConfidence(ocrResult.text);

    final result = KKExtractionResult(
      noKK: noKKData,
      namaKepalaKeluarga: FieldConfidence(
        fieldName: 'namaKepalaKeluarga',
        value: null,
        confidence: 0.0,
      ),
      alamat: alamatData,
      kodePos: kodePosData,
      kabupatenKota: FieldConfidence(
        fieldName: 'kabupatenKota',
        value: null,
        confidence: 0.0,
      ),
      provinsi: FieldConfidence(
        fieldName: 'provinsi',
        value: null,
        confidence: 0.0,
      ),
      rawText: ocrResult.text,
      textBlocks: ocrResult.blocks,
      overallQuality: qualityResult.overallQuality,
      perspectiveCorrected: 0.0,
      extractionError: null,
    );

    debugPrint('\n✅ EXTRACTION COMPLETE (ROI Mode):');
    debugPrint(result.toString());
    debugPrint('⏱️  Faster than full scan (header-only processing)');

    // Cleanup
    try {
      await headerFile.delete();
    } catch (_) {}

    return result;
  }

  // ──────────────────────────────────────────────
  // Step 2: OCR (ML Kit Text Recognition)
  // ──────────────────────────────────────────────

  /// Menjalankan OCR dan mengembalikan teks + posisi block untuk bounding box.
  Future<_OcrResult> _runOCRWithBlocks(
    File originalFile,
    img.Image preprocessedImage,
  ) async {
    final inputImage = InputImage.fromFile(originalFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);

      // Kumpulkan text blocks dengan posisi untuk FR-03 overlay
      final blocks = <DetectedTextBlock>[];
      for (final block in recognizedText.blocks) {
        final boundingBox = block.boundingBox;
        blocks.add(
          DetectedTextBlock(text: block.text, boundingBox: boundingBox),
        );
      }

      return _OcrResult(text: recognizedText.text, blocks: blocks);
    } finally {
      await textRecognizer.close();
    }
  }

  // ──────────────────────────────────────────────
  // Step 3: Field Extraction with Confidence Scoring
  // ──────────────────────────────────────────────

  /// Ekstrak semua field KK dari teks OCR dengan confidence scoring
  KKExtractionResult _extractFieldsWithConfidence(
    String rawText, {
    List<DetectedTextBlock> blocks = const [],
    double qualityScore = 0.0,
    double perspectiveScore = 0.0,
  }) {
    // Ekstrak setiap field
    final noKKData = _extractNoKKWithConfidence(rawText);
    final namaData = _extractNamaWithConfidence(rawText);
    final alamatData = _extractAlamatWithConfidence(rawText);
    final kodePosData = _extractKodePosWithConfidence(rawText);
    final kabKotaData = _extractKabupatenKotaWithConfidence(rawText);
    final provinsiData = _extractProvinsiWithConfidence(rawText);

    return KKExtractionResult(
      noKK: noKKData,
      namaKepalaKeluarga: namaData,
      alamat: alamatData,
      kodePos: kodePosData,
      kabupatenKota: kabKotaData,
      provinsi: provinsiData,
      rawText: rawText,
      textBlocks: blocks,
      overallQuality: qualityScore,
      perspectiveCorrected: perspectiveScore,
      extractionError: null,
    );
  }

  /// Koreksi karakter OCR yang sering tertukar dengan angka.
  /// Contoh: L/l → 1, O/o → 0, I → 1, S/s → 5, G → 6, Z → 2
  String _fixOcrDigits(String input) {
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final c = input[i];
      switch (c) {
        case 'O' || 'o' || 'Q' || 'D':
          buffer.write('0');
        case 'I' || 'i' || 'l' || 'L' || '|':
          buffer.write('1');
        case 'Z' || 'z':
          buffer.write('2');
        case 'S' || 's':
          buffer.write('5');
        case 'G':
          buffer.write('6');
        case 'B':
          buffer.write('8');
        case 'g':
          buffer.write('9');
        default:
          if (RegExp(r'\d').hasMatch(c)) {
            buffer.write(c);
          }
        // skip non-digit, non-confusable characters
      }
    }
    return buffer.toString();
  }

  // ──────────────────────────────────────────────
  // Field Extraction with Confidence - No. KK
  // ──────────────────────────────────────────────

  /// Ekstrak No. KK dengan confidence scoring
  FieldConfidence _extractNoKKWithConfidence(String text) {
    final patterns = [
      RegExp(
        r'No\.?\s*(?:KK|Kartu\s*Keluarga)\s*[:\.\s]*([0-9A-Za-z]{16})',
        caseSensitive: false,
      ),
      RegExp(r'No\.?\s*[:\.\s]*([0-9A-Za-z]{16})', caseSensitive: false),
      RegExp(r'(?:^|\s)(\d{16})(?:\s|$)', multiLine: true),
    ];

    double confidence = 0.0;
    String? result;
    String? error;

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final raw = match.group(1)!;
        final fixed = _fixOcrDigits(raw);

        if (fixed.length == 16) {
          result = fixed;
          // Confidence: lebih tinggi jika pattern lebih spesifik
          confidence = pattern == patterns[0]
              ? 0.95
              : (pattern == patterns[1] ? 0.85 : 0.70);
          debugPrint(
            '🔍 No. KK: "$raw" → "$fixed" (confidence: ${(confidence * 100).toInt()}%)',
          );
          break;
        }
      }
    }

    if (result == null) {
      error = 'No. KK tidak ditemukan atau format salah (harusnya 16 digit)';
    } else if (!_isValidNoKK(result)) {
      error = 'Format No. KK tidak sesuai standar Indonesia';
      confidence *= 0.5; // Reduce confidence jika format tidak valid
    }

    return FieldConfidence(
      fieldName: 'noKK',
      value: result,
      confidence: confidence,
      validationError: error,
    );
  }

  /// Validasi format No. KK Indonesia
  /// Format: XX.XXXX.XXXXX.XXXX (16 digit)
  bool _isValidNoKK(String noKK) {
    if (noKK.length != 16) return false;
    // All characters must be digit
    return RegExp(r'^\d{16}$').hasMatch(noKK);
  }

  // ──────────────────────────────────────────────
  // Field Extraction with Confidence - Alamat
  // ──────────────────────────────────────────────

  /// Ekstrak Alamat dengan confidence scoring (A4 Layout Aware)
  FieldConfidence _extractAlamatWithConfidence(String text) {
    double confidence = 0.0;
    String? result;

    // Pattern 1: Setelah "Alamat" label - handles newline flexible
    final pattern1 = RegExp(
      r'Alamat\s*[:\.]?\s*\n?\s*(.+?)(?=\s*(?:RT\s*\/|RW|Kel(?:urahan)?|Desa|Kec(?:amatan)?|Kab(?:upaten)?|Kota|Provinsi|Kode\s*Pos|No\s*RT|\n\n|$))',
      caseSensitive: false,
      multiLine: true,
      dotAll: false,
    );
    var match = pattern1.firstMatch(text);
    if (match != null) {
      var value = match.group(1)?.trim();
      if (value != null && value.isNotEmpty) {
        value = value.replaceAll(RegExp(r'[:\.\s\n]+$'), '').trim();
        if (value.length > 150) {
          value = value.substring(0, 150).trim();
        }
        // Skip jika hanya label (No, RT, RW, dll)
        if (!RegExp(
          r'^(No|RT|RW|Desa|Kel)$',
          caseSensitive: false,
        ).hasMatch(value)) {
          result = value;
          confidence = 0.90;
          debugPrint(
            '🔍 Alamat (direct): "$result" (confidence: ${(confidence * 100).toInt()}%)',
          );
          return FieldConfidence(
            fieldName: 'alamat',
            value: result,
            confidence: confidence,
          );
        }
      }
    }

    // Pattern 2: Cari nama jalan spesifik (JL, Jalan, GG, dll)
    final pattern2 = RegExp(
      r'(?:^|\s|\n)((?:JL|Jl|JALAN|Jalan|DUKUH|Dukuh|KAMPUNG|Kampung|KP|GG|Gang|Gangg)\s*\.?\s+[^\n]+?)(?=\s*(?:RT|RW|Kel|Desa|Kec|Kab|Kota|Provinsi|No\s*RT|Kode|\n\n|$))',
      caseSensitive: false,
      multiLine: true,
    );
    match = pattern2.firstMatch(text);
    if (match != null) {
      var value = match.group(1)?.trim();
      if (value != null && value.isNotEmpty && value.length > 2) {
        if (value.length > 150) {
          value = value.substring(0, 150).trim();
        }
        result = value;
        confidence = 0.75;
        debugPrint(
          '🔍 Alamat (jalan): "$result" (confidence: ${(confidence * 100).toInt()}%)',
        );
        return FieldConfidence(
          fieldName: 'alamat',
          value: result,
          confidence: confidence,
        );
      }
    }

    return FieldConfidence(
      fieldName: 'alamat',
      value: null,
      confidence: 0.0,
      validationError: 'Alamat tidak ditemukan',
    );
  }

  // ──────────────────────────────────────────────
  // Field Extraction with Confidence - Kode Pos
  // ──────────────────────────────────────────────

  /// Ekstrak Kode Pos dengan confidence scoring (A4 Layout Aware)
  FieldConfidence _extractKodePosWithConfidence(String text) {
    double confidence = 0.0;
    String? result;

    // Pattern 1: Langsung setelah "Kode Pos" dengan flexible newline
    // Handles: "Kode Pos: 12130" atau "Kode Pos\n: 12130" atau "Kode Pos\n12130"
    final pattern1 = RegExp(
      r'Kode\s*Pos\s*[:\.]?\s*\n?\s*[:\.]?\s*(\d{5})',
      caseSensitive: false,
      multiLine: true,
    );
    var match = pattern1.firstMatch(text);
    if (match != null) {
      result = match.group(1)!;
      confidence = 0.95;
      debugPrint(
        '🔍 Kode Pos (direct): "$result" (confidence: ${(confidence * 100).toInt()}%)',
      );
      return FieldConfidence(
        fieldName: 'kodePos',
        value: result,
        confidence: confidence,
      );
    }

    // Pattern 2: Nearby search setelah "Kode Pos" terdeteksi
    final labelMatch = RegExp(
      r'Kode\s*Pos',
      caseSensitive: false,
    ).firstMatch(text);
    if (labelMatch != null) {
      final searchStart = labelMatch.end;
      final searchEnd = (searchStart + 100).clamp(0, text.length);
      final nearbyText = text.substring(searchStart, searchEnd);

      final digitsMatch = RegExp(
        r'(?<!\d)(\d{5})(?!\d)',
      ).firstMatch(nearbyText);
      if (digitsMatch != null) {
        final candidate = digitsMatch.group(1)!;
        if (candidate[0] != '0') {
          result = candidate;
          confidence = 0.90;
          debugPrint(
            '🔍 Kode Pos (nearby): "$result" (confidence: ${(confidence * 100).toInt()}%)',
          );
          return FieldConfidence(
            fieldName: 'kodePos',
            value: result,
            confidence: confidence,
          );
        }
      }
    }

    // Pattern 3: Fallback - cari pattern "Pos" saja
    final pattern3 = RegExp(
      r'Pos\s*[:\.]?\s*\n?\s*[:\.]?\s*(\d{5})',
      caseSensitive: false,
      multiLine: true,
    );
    match = pattern3.firstMatch(text);
    if (match != null) {
      result = match.group(1)!;
      if (result[0] != '0') {
        confidence = 0.80;
        debugPrint(
          '🔍 Kode Pos (Pos label): "$result" (confidence: ${(confidence * 100).toInt()}%)',
        );
        return FieldConfidence(
          fieldName: 'kodePos',
          value: result,
          confidence: confidence,
        );
      }
    }

    return FieldConfidence(
      fieldName: 'kodePos',
      value: null,
      confidence: 0.0,
      validationError: 'Kode Pos tidak ditemukan',
    );
  }

  // ──────────────────────────────────────────────
  // Field Extraction with Confidence - Nama Kepala Keluarga
  // ──────────────────────────────────────────────

  /// Ekstrak Nama Kepala Keluarga dengan confidence scoring
  FieldConfidence _extractNamaWithConfidence(String text) {
    final patterns = [
      RegExp(r'Nama\s*Kepala\s*Keluarga\s*[:\.]\s*(.+)', caseSensitive: false),
      RegExp(
        r'Kepala\s*Keluarga\s*[:\.]\s*([A-Z][A-Z\s]+)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        var result = match.group(1)?.trim();
        if (result != null && result.length >= 3) {
          result = result.replaceAll(RegExp(r'[^A-Za-z\s]'), '').trim();
          if (result.isNotEmpty) {
            final confidence = pattern == patterns[0] ? 0.90 : 0.75;
            debugPrint(
              '🔍 Nama Kepala Keluarga: "$result" (confidence: ${(confidence * 100).toInt()}%)',
            );
            return FieldConfidence(
              fieldName: 'namaKepalaKeluarga',
              value: result,
              confidence: confidence,
            );
          }
        }
      }
    }

    return FieldConfidence(
      fieldName: 'namaKepalaKeluarga',
      value: null,
      confidence: 0.0,
      validationError: 'Nama Kepala Keluarga tidak ditemukan',
    );
  }

  // ──────────────────────────────────────────────
  // Field Extraction with Confidence - Kabupaten/Kota
  // ──────────────────────────────────────────────

  /// Ekstrak Kabupaten/Kota dengan confidence scoring
  FieldConfidence _extractKabupatenKotaWithConfidence(String text) {
    final patterns = [
      RegExp(r'Kabupaten\s*/\s*Kota\s*[:\.]\s*(.+)', caseSensitive: false),
      RegExp(
        r'(?:Kab(?:upaten)?|Kota)\s*[:\.\s]+([A-Z][A-Z\s]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'aten\s*(?:/\s*)?Kota\s*[:\.\s]+([A-Z][A-Z\s]+)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        var result = match.group(1)?.trim();
        if (result != null && result.length >= 3) {
          final confidence = pattern == patterns[0] ? 0.85 : 0.70;
          debugPrint(
            '🔍 Kabupaten/Kota: "$result" (confidence: ${(confidence * 100).toInt()}%)',
          );
          return FieldConfidence(
            fieldName: 'kabupatenKota',
            value: result,
            confidence: confidence,
          );
        }
      }
    }

    return FieldConfidence(
      fieldName: 'kabupatenKota',
      value: null,
      confidence: 0.0,
      validationError: 'Kabupaten/Kota tidak ditemukan',
    );
  }

  // ──────────────────────────────────────────────
  // Field Extraction with Confidence - Provinsi
  // ──────────────────────────────────────────────

  /// Ekstrak Provinsi dengan confidence scoring
  FieldConfidence _extractProvinsiWithConfidence(String text) {
    final patterns = [
      RegExp(r'Provin?s?i?\s*[:\.\s]+([A-Z][A-Z\s]+)', caseSensitive: false),
      RegExp(r'Prov?[a-z]*\s*[:\.\s]+([A-Z][A-Z\s]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        var result = match.group(1)?.trim();
        if (result != null && result.length >= 3) {
          final confidence = pattern == patterns[0] ? 0.85 : 0.65;
          debugPrint(
            '🔍 Provinsi: "$result" (confidence: ${(confidence * 100).toInt()}%)',
          );
          return FieldConfidence(
            fieldName: 'provinsi',
            value: result,
            confidence: confidence,
          );
        }
      }
    }

    return FieldConfidence(
      fieldName: 'provinsi',
      value: null,
      confidence: 0.0,
      validationError: 'Provinsi tidak ditemukan',
    );
  }
}

/// Helper class untuk hasil OCR dengan blocks
class _OcrResult {
  final String text;
  final List<DetectedTextBlock> blocks;
  _OcrResult({required this.text, required this.blocks});
}
