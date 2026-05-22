// lib/services/pcd/kk_extraction_service_v2.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'document_detector_v2.dart';
import 'image_quality_checker.dart';
import 'kk_ocr_engine.dart';
import 'kk_preprocessor.dart';
import 'kk_roi_manager.dart';
import 'perspective_corrector.dart';

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
        // HAPUS ROTASI MANUAL: Dart copyRotate bisa membuat gambar menjadi Upside-Down.
        // Google ML Kit sudah secara otomatis membaca EXIF orientation dari kamera 
        // sehingga teks akan selalu dibaca dengan urutan yang benar (Top to Bottom).
      }

      // 2. OCR Full Image Direct (Zero-Crop Block Analysis)
      // Kirim file ASLI langsung ke ML Kit.
      final recognizedText = await _ocrEngine.processImageDirect(imageFile);

      // 3. Ekstrak data dari TextBlocks untuk menghindari pencampuran kolom
      ParseResult? nomorKKResult;
      ParseResult? alamatResult;
      ParseResult? rtRwResult;
      ParseResult? desaResult;
      ParseResult? kodePosResult;
      ParseResult? kecResult;

      // Urutkan blok teks dari atas ke bawah berdasarkan BoundingBox (Penting!)
      final blocks = recognizedText.blocks.toList()
        ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

      // Gabungkan semua teks dari atas ke bawah untuk pencarian global (Foolproof No. KK)
      final fullText = blocks.map((b) => b.text).join('\n');
      
      debugPrint('\n\n===== HASIL BACA MESIN (RAW OCR) =====\n$fullText\n======================================\n\n');
      
      // Nomor KK PASTI adalah 16 digit pertama yang muncul di dokumen (karena di atas tabel)
      nomorKKResult = KKFieldParser.parseNomorKK(fullText);

      // Loop semua block yang terdeteksi untuk field lainnya
      for (final block in blocks) {
        final text = block.text;

        // Coba parsing setiap field dari block ini
        if (alamatResult == null || !alamatResult.isFound) {
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

      // 4. Return Hasil Ekstraksi
      stopwatch.stop();

      return KKExtractionOutputV2(
        nomorKK: nomorKKResult ?? ParseResult.failed('nomor_kk', ''),
        alamat: alamatResult ?? ParseResult.failed('alamat', ''),
        kodePos: kodePosResult ?? ParseResult.failed('kode_pos', ''),
        rtRw: rtRwResult ?? ParseResult.failed('rt_rw', ''),
        desaKelurahan: desaResult ?? ParseResult.failed('desa_kelurahan', ''),
        kecamatan: kecResult ?? ParseResult.failed('kecamatan', ''),
        anggotaKeluarga: [], // Tabel dimatikan dulu untuk performa
        qualityScore: quality?.overallQuality ?? 0.8,
        perspectiveScore: 1.0, // Bypass perspective
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