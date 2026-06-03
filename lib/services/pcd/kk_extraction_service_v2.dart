// lib/services/pcd/kk_extraction_service_v2.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'image_quality_checker.dart';
import 'kk_ocr_engine.dart';
import 'kk_preprocessor.dart';
import 'kk_roi_manager.dart';

class KKExtractionServiceV2 {
  final _ocrEngine = KKOCREngine();

  Future<KKExtractionOutputV2> extractFromFile(File imageFile) async {
    final stopwatch = Stopwatch()..start();

    try {
      // 1. Check Image Quality
      final bytes = await imageFile.readAsBytes();
      final original = img.decodeImage(bytes);
      ImageQualityResult? quality;

      if (original != null) {
        quality = await ImageQualityChecker.checkQuality(original);
      }

      // 2. OCR Full Image (primary source for most fields)
      final recognizedText = await _ocrEngine.processImageDirect(imageFile);

      // 3. Parse fields from full-image OCR blocks
      ParseResult alamatResult = ParseResult.failed('alamat', '');
      ParseResult? rtRwResult;
      ParseResult? desaResult;
      ParseResult? kodePosResult;
      ParseResult? kecResult;

      final blocks = recognizedText.blocks.toList()
        ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

      final fullText = blocks.map((b) => b.text).join('\n');

      debugPrint('\n\n===== RAW OCR (FULL IMAGE) =====\n$fullText\n================================\n\n');

      final nomorKKResult = KKFieldParser.parseNomorKK(fullText);

      // Parse per-block (untuk field yang sensitif posisi)
      for (final block in blocks) {
        final text = block.text;

        if (!alamatResult.isFound) {
          final res = KKFieldParser.parseAlamat(text);
          if (res.isFound) alamatResult = res;
        }
        if (rtRwResult == null || !rtRwResult.isFound) {
          final res = KKFieldParser.parseRTRW(text);
          if (res.isFound) rtRwResult = res;
        }
        if (desaResult == null || !desaResult.isFound) {
          final res = KKFieldParser.parseDesaKelurahan(text);
          if (res.isFound) desaResult = res;
        }
        if (kodePosResult == null || !kodePosResult.isFound) {
          final res = KKFieldParser.parseKodePos(text);
          if (res.isFound) kodePosResult = res;
        }
        if (kecResult == null || !kecResult.isFound) {
          final res = KKFieldParser.parseKecamatan(text);
          if (res.isFound) kecResult = res;
        }
      }

      // 4. ROI Header Extraction + Preprocessing (kualitas lebih baik)
      if (original != null) {
        try {
          final headerText = await _extractHeaderRegion(original);
          if (headerText.isNotEmpty) {
            debugPrint('\n===== HEADER ROI (PREPROCESSED) =====\n$headerText\n=====================================\n');

            // Alamat: header-first (kualitas lebih baik), fallback ke full-image
            if (!alamatResult.isFound) {
              final headerAlamat = KKFieldParser.parseAlamat(headerText);
              if (headerAlamat.isFound) alamatResult = headerAlamat;
            }

            // Field lain: ambil yang confidence lebih tinggi
            final headerRTRW = KKFieldParser.parseRTRW(headerText);
            if (headerRTRW.isFound && (rtRwResult == null || !rtRwResult.isFound || headerRTRW.confidence > rtRwResult.confidence)) {
              rtRwResult = headerRTRW;
            }
            final headerDesa = KKFieldParser.parseDesaKelurahan(headerText);
            if (headerDesa.isFound && (desaResult == null || !desaResult.isFound || headerDesa.confidence > desaResult.confidence)) {
              desaResult = headerDesa;
            }
            final headerKodePos = KKFieldParser.parseKodePos(headerText);
            if (headerKodePos.isFound && (kodePosResult == null || !kodePosResult.isFound || headerKodePos.confidence > kodePosResult.confidence)) {
              kodePosResult = headerKodePos;
            }
            final headerKec = KKFieldParser.parseKecamatan(headerText);
            if (headerKec.isFound && (kecResult == null || !kecResult.isFound || headerKec.confidence > kecResult.confidence)) {
              kecResult = headerKec;
            }
          }
        } catch (e) {
          debugPrint('Header ROI extraction failed (non-fatal): $e');
        }
      }

      // 5. Fallback: coba parse alamat dari fullText (jika block-level gagal)
      if (!alamatResult.isFound) {
        alamatResult = KKFieldParser.parseAlamat(fullText);
      }

      stopwatch.stop();

      return KKExtractionOutputV2(
        nomorKK: nomorKKResult,
        alamat: alamatResult,
        kodePos: kodePosResult ?? ParseResult.failed('kode_pos', ''),
        rtRw: rtRwResult ?? ParseResult.failed('rt_rw', ''),
        desaKelurahan: desaResult ?? ParseResult.failed('desa_kelurahan', ''),
        kecamatan: kecResult ?? ParseResult.failed('kecamatan', ''),
        anggotaKeluarga: [],
        qualityScore: quality?.overallQuality ?? 0.8,
        perspectiveScore: 1.0,
        orientation: KKOrientation.landscape,
        processingTimeMs: stopwatch.elapsedMilliseconds,
        warnings: quality?.warnings ?? [],
      );

    } catch (e, st) {
      debugPrint('KKExtraction error: $e\n$st');
      return KKExtractionOutputV2.error(
        error: e.toString(),
        duration: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Crop header region, preprocess (CLAHE + unsharp mask), lalu OCR.
  Future<String> _extractHeaderRegion(img.Image original) async {
    final orientation = KKROIManager.detectOrientation(original);
    final region = orientation == KKOrientation.landscape
        ? const KKRegion(yStart: 0.05, yEnd: 0.40, xStart: 0.0, xEnd: 1.0, name: 'header')
        : const KKRegion(yStart: 0.05, yEnd: 0.30, xStart: 0.0, xEnd: 1.0, name: 'header');

    final cropped = KKROIManager.cropRegionWithPadding(original, region, paddingPercent: 0.02);
    final preprocessed = KKPreprocessor.process(cropped, PreprocessMode.forOCRHeader);

    return await _ocrEngine.recognizeRegion(preprocessed);
  }

  void dispose() => _ocrEngine.dispose();
}

// ── Output Model ──────────────────────────────────

class KKExtractionOutputV2 {
  final ParseResult? nomorKK;
  final ParseResult? alamat;
  final ParseResult? kodePos;
  final ParseResult? rtRw;
  final ParseResult? desaKelurahan;
  final ParseResult? kecamatan;
  final List<AnggotaResult> anggotaKeluarga;

  final double qualityScore;
  final double perspectiveScore;
  final KKOrientation? orientation;
  final int processingTimeMs;
  final List<String> warnings;
  final String? error;

  KKExtractionOutputV2({
    this.nomorKK,
    this.alamat,
    this.kodePos,
    this.rtRw,
    this.desaKelurahan,
    this.kecamatan,
    this.anggotaKeluarga = const [],
    this.qualityScore = 0,
    this.perspectiveScore = 0,
    this.orientation,
    this.processingTimeMs = 0,
    this.warnings = const [],
    this.error,
  });

  factory KKExtractionOutputV2.poor({
    required List<String> warnings,
    required int duration,
  }) => KKExtractionOutputV2(
    warnings: warnings,
    processingTimeMs: duration,
    error: 'Kualitas gambar tidak memadai',
  );

  factory KKExtractionOutputV2.error({
    required String error,
    required int duration,
  }) => KKExtractionOutputV2(
    error: error,
    processingTimeMs: duration,
  );

  bool get isSuccess => error == null && (nomorKK?.isFound == true || alamat?.isFound == true);

  /// Output ke format JSON standar
  Map<String, dynamic> toJson() {
    return {
      'nomor_kk': nomorKK?.value,
      'alamat': alamat?.value,
      'kode_pos': kodePos?.value,
      'rt_rw': rtRw?.value,
      'desa_kelurahan': desaKelurahan?.value,
      'kecamatan': kecamatan?.value,
      'header_kk': null, // akan diisi dari header OCR
      'anggota_keluarga': anggotaKeluarga.map((a) => a.toJson()).toList(),
      '_meta': {
        'quality_score': qualityScore,
        'perspective_score': perspectiveScore,
        'orientation': orientation?.name,
        'processing_time_ms': processingTimeMs,
        'warnings': warnings,
        'success': isSuccess,
      },
      '_confidence': {
        'nomor_kk': nomorKK?.confidence,
        'alamat': alamat?.confidence,
        'kode_pos': kodePos?.confidence,
      },
    };
  }
}