import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'image_quality_checker.dart';
import 'kk_ocr_engine.dart';

/// Service untuk mengekstrak data KTP dari gambar.
///
/// Pipeline:
/// 1. Quality Check (blur, brightness)
/// 2. OCR Full Image via ML Kit
/// 3. Parse field KTP dengan KTPFieldParser
/// 4. Return hasil terstruktur dengan confidence scoring
class KTPExtractionService {
  final _ocrEngine = KKOCREngine();

  Future<KTPExtractionResult> extractFromFile(File imageFile) async {
    final stopwatch = Stopwatch()..start();

    try {
      // 1. Check Image Quality
      final bytes = await imageFile.readAsBytes();
      final original = img.decodeImage(bytes);
      ImageQualityResult? quality;

      if (original != null) {
        quality = await ImageQualityChecker.checkQuality(original);
      }

      // 2. OCR Full Image
      final recognizedText = await _ocrEngine.processImageDirect(imageFile);
      final fullText = recognizedText.blocks.map((b) => b.text).join('\n');

      debugPrint('\n===== RAW OCR (KTP) =====\n$fullText\n========================\n');

      // 3. Parse fields
      final nikResult = KTPFieldParser.parseNIK(fullText);
      final namaResult = KTPFieldParser.parseNama(fullText);
      final tempatLahirResult = KTPFieldParser.parseTempatLahir(fullText);
      final tanggalLahirResult = KTPFieldParser.parseTanggalLahir(fullText);
      final jenisKelaminResult = KTPFieldParser.parseJenisKelamin(fullText);
      final golonganDarahResult = KTPFieldParser.parseGolonganDarah(fullText);
      final agamaResult = KTPFieldParser.parseAgama(fullText);
      final statusKawinResult = KTPFieldParser.parseStatusPerkawinan(fullText);
      final pekerjaanResult = KTPFieldParser.parsePekerjaan(fullText);
      final kewarganegaraanResult = KTPFieldParser.parseKewarganegaraan(fullText);
      final alamatResult = KTPFieldParser.parseAlamat(fullText);
      final rtRwResult = KTPFieldParser.parseRTRW(fullText);
      final kelResult = KTPFieldParser.parseKelurahan(fullText);
      final kecResult = KTPFieldParser.parseKecamatan(fullText);

      stopwatch.stop();

      return KTPExtractionResult(
        nik: nikResult,
        nama: namaResult,
        tempatLahir: tempatLahirResult,
        tanggalLahir: tanggalLahirResult,
        jenisKelamin: jenisKelaminResult,
        golonganDarah: golonganDarahResult,
        agama: agamaResult,
        statusPerkawinan: statusKawinResult,
        pekerjaan: pekerjaanResult,
        kewarganegaraan: kewarganegaraanResult,
        alamat: alamatResult,
        rtRw: rtRwResult,
        kelurahan: kelResult,
        kecamatan: kecResult,
        rawText: fullText,
        qualityScore: quality?.overallQuality ?? 0.8,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e, st) {
      debugPrint('KTP Extraction error: $e\n$st');
      return KTPExtractionResult.error(
        error: e.toString(),
        duration: stopwatch.elapsedMilliseconds,
      );
    }
  }

  Future<void> dispose() async {
    await _ocrEngine.dispose();
  }
}

/// Parser untuk field-field KTP Indonesia
class KTPFieldParser {
  // ── NIK (16 digit) ──────────────────────────────
  static KTPFieldResult parseNIK(String rawText) {
    final patterns = [
      // "NIK : 3201234567890001" or "NIK 3201234567890001"
      RegExp(r'NIK\s*[:\.\s]*(\d{16})', caseSensitive: false),
      // Fallback: any 16-digit sequence
      RegExp(r'\b(\d{16})\b'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(rawText);
      if (match != null) {
        final nik = _correctOCRDigits(match.group(1)!);
        if (_isValidNIK(nik)) {
          return KTPFieldResult(
            value: nik,
            confidence: 0.95,
            rawText: rawText,
          );
        }
      }
    }

    return KTPFieldResult.failed('nik', rawText);
  }

  // ── Nama ─────────────────────────────────────────
  static KTPFieldResult parseNama(String rawText) {
    final lines = rawText.split('\n').map((l) => l.trim()).toList();

    for (int i = 0; i < lines.length; i++) {
      // Match "Nama" or "Nama :" or "Nama Lengkap"
      if (RegExp(r'^Nama\s*[:\.]?', caseSensitive: false).hasMatch(lines[i])) {
        // Try same line first
        final sameLine = lines[i].replaceFirst(
          RegExp(r'^Nama\s*[:\.]?\s*', caseSensitive: false), ''
        ).trim();

        if (sameLine.length > 2 && !_isFieldLabel(sameLine)) {
          return KTPFieldResult(
            value: _cleanName(sameLine),
            confidence: 0.90,
            rawText: rawText,
          );
        }

        // Check next line
        if (i + 1 < lines.length) {
          final next = lines[i + 1].trim();
          if (next.length > 2 && !_isFieldLabel(next)) {
            return KTPFieldResult(
              value: _cleanName(next),
              confidence: 0.85,
              rawText: rawText,
            );
          }
        }
      }
    }

    return KTPFieldResult.failed('nama', rawText);
  }

  // ── Tempat Lahir ─────────────────────────────────
  static KTPFieldResult parseTempatLahir(String rawText) {
    // Format: "KOTA JAKARTA, 17-08-1945" -> tempat = "KOTA JAKARTA"
    final pattern = RegExp(
      r'(?:Tempat/?Tgl\s*Lahir|TTL)\s*[:\.\s]*(.+?)[,\s]+\d{2}[\-/]\d{2}[\-/]\d{4}',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(rawText);
    if (match != null) {
      return KTPFieldResult(
        value: _cleanText(match.group(1)!),
        confidence: 0.85,
        rawText: rawText,
      );
    }

    // Fallback: text before date pattern
    final lines = rawText.split('\n').map((l) => l.trim()).toList();
    final datePattern = RegExp(r'\d{2}[\-/]\d{2}[\-/]\d{4}');

    for (final line in lines) {
      if (datePattern.hasMatch(line)) {
        final parts = line.split(datePattern);
        if (parts.isNotEmpty && parts.first.trim().isNotEmpty) {
          final candidate = parts.first.trim().replaceAll(RegExp(r'[,\s]+$'), '');
          if (candidate.length > 2) {
            return KTPFieldResult(
              value: _cleanText(candidate),
              confidence: 0.70,
              rawText: rawText,
            );
          }
        }
      }
    }

    return KTPFieldResult.failed('tempat_lahir', rawText);
  }

  // ── Tanggal Lahir ────────────────────────────────
  static KTPFieldResult parseTanggalLahir(String rawText) {
    // Format: DD-MM-YYYY or DD/MM/YYYY
    final pattern = RegExp(r'(\d{2}[\-/]\d{2}[\-/]\d{4})');
    final match = pattern.firstMatch(rawText);
    if (match != null) {
      final dateStr = match.group(1)!;
      // Convert to DateTime
      final normalized = dateStr.replaceAll('/', '-');
      final parts = normalized.split('-');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null &&
            day >= 1 && day <= 31 && month >= 1 && month <= 12 && year >= 1900) {
          return KTPFieldResult(
            value: dateStr,
            confidence: 0.90,
            rawText: rawText,
          );
        }
      }
    }

    return KTPFieldResult.failed('tanggal_lahir', rawText);
  }

  // ── Jenis Kelamin ────────────────────────────────
  static KTPFieldResult parseJenisKelamin(String rawText) {
    if (RegExp(r'\bLAKI[\-\s]LAKI\b|\bLAKI\b', caseSensitive: false).hasMatch(rawText)) {
      return KTPFieldResult(value: 'Laki-Laki', confidence: 0.95, rawText: rawText);
    }
    if (RegExp(r'\bPEREMPUAN\b', caseSensitive: false).hasMatch(rawText)) {
      return KTPFieldResult(value: 'Perempuan', confidence: 0.95, rawText: rawText);
    }

    // Check "Jenis Kelamin : L" or "Jenis Kelamin : LAKI-LAKI"
    final pattern = RegExp(
      r'Jenis\s*Kelamin\s*[:\.]?\s*(LAKI[\-\s]LAKI|PEREMPUAN|L|P)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(rawText);
    if (match != null) {
      final val = match.group(1)!.toUpperCase();
      if (val == 'L' || val.contains('LAKI')) {
        return KTPFieldResult(value: 'Laki-Laki', confidence: 0.90, rawText: rawText);
      }
      if (val == 'P' || val.contains('PEREMPUAN')) {
        return KTPFieldResult(value: 'Perempuan', confidence: 0.90, rawText: rawText);
      }
    }

    return KTPFieldResult.failed('jenis_kelamin', rawText);
  }

  // ── Golongan Darah ───────────────────────────────
  static KTPFieldResult parseGolonganDarah(String rawText) {
    final pattern = RegExp(
      r'Gol(?:ongan)?\s*Darah\s*[:\.]?\s*(A|B|AB|O)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(rawText);
    if (match != null) {
      return KTPFieldResult(
        value: match.group(1)!.toUpperCase(),
        confidence: 0.90,
        rawText: rawText,
      );
    }

    return KTPFieldResult.failed('golongan_darah', rawText);
  }

  // ── Agama ────────────────────────────────────────
  static KTPFieldResult parseAgama(String rawText) {
    final agamaList = ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'];

    final pattern = RegExp(
      r'Agama\s*[:\.]?\s*(.+)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(rawText);
    if (match != null) {
      final raw = _cleanText(match.group(1)!);
      // Find best match from agama list
      for (final a in agamaList) {
        if (raw.toLowerCase().contains(a.toLowerCase())) {
          return KTPFieldResult(value: a, confidence: 0.90, rawText: rawText);
        }
      }
    }

    return KTPFieldResult.failed('agama', rawText);
  }

  // ── Status Perkawinan ────────────────────────────
  static KTPFieldResult parseStatusPerkawinan(String rawText) {
    final statusList = [
      'Belum Kawin', 'Kawin', 'Cerai Hidup', 'Cerai Mati'
    ];

    final pattern = RegExp(
      r'Status\s*(?:Perkawinan|Kawin)\s*[:\.]?\s*(.+)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(rawText);
    if (match != null) {
      final raw = _cleanText(match.group(1)!);
      for (final s in statusList) {
        if (raw.toLowerCase().contains(s.toLowerCase())) {
          return KTPFieldResult(value: s, confidence: 0.90, rawText: rawText);
        }
      }
    }

    return KTPFieldResult.failed('status_perkawinan', rawText);
  }

  // ── Pekerjaan ────────────────────────────────────
  static KTPFieldResult parsePekerjaan(String rawText) {
    final pattern = RegExp(
      r'Pekerjaan\s*[:\.]?\s*(.+)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(rawText);
    if (match != null) {
      final value = _cleanText(match.group(1)!);
      if (value.length > 1 && !_isFieldLabel(value)) {
        return KTPFieldResult(value: value, confidence: 0.85, rawText: rawText);
      }
    }

    return KTPFieldResult.failed('pekerjaan', rawText);
  }

  // ── Kewarganegaraan ──────────────────────────────
  static KTPFieldResult parseKewarganegaraan(String rawText) {
    if (RegExp(r'\bWNI\b', caseSensitive: false).hasMatch(rawText)) {
      return KTPFieldResult(value: 'WNI', confidence: 0.95, rawText: rawText);
    }
    if (RegExp(r'\bWNA\b', caseSensitive: false).hasMatch(rawText)) {
      return KTPFieldResult(value: 'WNA', confidence: 0.95, rawText: rawText);
    }

    final pattern = RegExp(
      r'Kewarganegaraan\s*[:\.]?\s*(WNI|WNA)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(rawText);
    if (match != null) {
      return KTPFieldResult(
        value: match.group(1)!.toUpperCase(),
        confidence: 0.90,
        rawText: rawText,
      );
    }

    return KTPFieldResult.failed('kewarganegaraan', rawText);
  }

  // ── Alamat ───────────────────────────────────────
  static KTPFieldResult parseAlamat(String rawText) {
    final lines = rawText.split('\n').map((l) => l.trim()).toList();

    for (int i = 0; i < lines.length; i++) {
      if (RegExp(r'^Alamat\s*[:\.]?', caseSensitive: false).hasMatch(lines[i])) {
        final same = lines[i].replaceFirst(
          RegExp(r'^Alamat\s*[:\.]?\s*', caseSensitive: false), ''
        ).trim();

        if (same.length > 3) {
          return KTPFieldResult(value: _cleanAlamat(same), confidence: 0.90, rawText: rawText);
        }

        if (i + 1 < lines.length) {
          final next = lines[i + 1].trim();
          if (next.length > 3 && !_isFieldLabel(next)) {
            return KTPFieldResult(value: _cleanAlamat(next), confidence: 0.85, rawText: rawText);
          }
        }
      }
    }

    return KTPFieldResult.failed('alamat', rawText);
  }

  // ── RT/RW ────────────────────────────────────────
  static KTPFieldResult parseRTRW(String rawText) {
    final patterns = [
      RegExp(r'RT\s*/\s*RW\s*[:\.]?\s*(\d{1,3})\s*/\s*(\d{1,3})', caseSensitive: false),
      RegExp(r'RT\s*[:\.]?\s*(\d{1,3})\s*RW\s*[:\.]?\s*(\d{1,3})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(rawText);
      if (match != null) {
        final rt = _correctOCRDigits(match.group(1)!).padLeft(3, '0');
        final rw = _correctOCRDigits(match.group(2)!).padLeft(3, '0');
        return KTPFieldResult(
          value: '$rt/$rw',
          confidence: 0.90,
          rawText: rawText,
        );
      }
    }

    return KTPFieldResult.failed('rt_rw', rawText);
  }

  // ── Kelurahan ────────────────────────────────────
  static KTPFieldResult parseKelurahan(String rawText) {
    final pattern = RegExp(
      r'(?:Kelurahan|Kel\.?)\s*[:\.]?\s*(.+)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(rawText);
    if (match != null) {
      return KTPFieldResult(
        value: _cleanText(match.group(1)!),
        confidence: 0.85,
        rawText: rawText,
      );
    }

    return KTPFieldResult.failed('kelurahan', rawText);
  }

  // ── Kecamatan ────────────────────────────────────
  static KTPFieldResult parseKecamatan(String rawText) {
    final pattern = RegExp(
      r'(?:Kecamatan|Kec\.?)\s*[:\.]?\s*(.+)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(rawText);
    if (match != null) {
      return KTPFieldResult(
        value: _cleanText(match.group(1)!),
        confidence: 0.85,
        rawText: rawText,
      );
    }

    return KTPFieldResult.failed('kecamatan', rawText);
  }

  // ── Utilities ────────────────────────────────────

  static String _correctOCRDigits(String input) {
    return input
        .replaceAll(RegExp(r'[OoDdQqC]'), '0')
        .replaceAll(RegExp(r'[IlL|!\]\[]'), '1')
        .replaceAll(RegExp(r'[Zz]'), '2')
        .replaceAll(RegExp(r'[Aa]'), '4')
        .replaceAll(RegExp(r'[Ss]'), '5')
        .replaceAll(RegExp(r'[Ggb]'), '6')
        .replaceAll(RegExp(r'[Tt]'), '7')
        .replaceAll(RegExp(r'[B]'), '8')
        .replaceAll(RegExp(r'[gP]'), '9');
  }

  static bool _isValidNIK(String s) {
    if (s.length != 16) return false;
    if (!RegExp(r'^\d{16}$').hasMatch(s)) return false;
    if (s.startsWith('0')) return false;
    return s.split('').toSet().length > 1;
  }

  static bool _isFieldLabel(String text) {
    final labels = ['RT', 'RW', 'Desa', 'Kelurahan', 'Kecamatan',
      'Kabupaten', 'Kota', 'Provinsi', 'Kode Pos', 'Jenis Kelamin',
      'Agama', 'Status', 'Pekerjaan', 'Golongan Darah', 'Kewarganegaraan'];
    return labels.any((l) => text.toLowerCase().startsWith(l.toLowerCase()));
  }

  static String _cleanName(String raw) {
    return raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^a-zA-Z\s\.]'), '')
        .trim();
  }

  static String _cleanText(String raw) {
    return raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _cleanAlamat(String raw) {
    return raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s\.\,\/\-\(\)\#\d]'), '')
        .trim();
  }
}

// ── Result Models ──────────────────────────────────

class KTPFieldResult {
  final String? value;
  final double confidence;
  final String rawText;
  final String? error;

  KTPFieldResult({
    required this.value,
    required this.confidence,
    required this.rawText,
    this.error,
  });

  factory KTPFieldResult.failed(String field, String rawText) {
    return KTPFieldResult(
      value: null,
      confidence: 0.0,
      rawText: rawText,
      error: '$field tidak ditemukan',
    );
  }

  bool get isFound => value != null && confidence > 0.0;
}

class KTPExtractionResult {
  final KTPFieldResult nik;
  final KTPFieldResult nama;
  final KTPFieldResult tempatLahir;
  final KTPFieldResult tanggalLahir;
  final KTPFieldResult jenisKelamin;
  final KTPFieldResult golonganDarah;
  final KTPFieldResult agama;
  final KTPFieldResult statusPerkawinan;
  final KTPFieldResult pekerjaan;
  final KTPFieldResult kewarganegaraan;
  final KTPFieldResult alamat;
  final KTPFieldResult rtRw;
  final KTPFieldResult kelurahan;
  final KTPFieldResult kecamatan;
  final String rawText;
  final double qualityScore;
  final int processingTimeMs;
  final String? error;

  KTPExtractionResult({
    required this.nik,
    required this.nama,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.jenisKelamin,
    required this.golonganDarah,
    required this.agama,
    required this.statusPerkawinan,
    required this.pekerjaan,
    required this.kewarganegaraan,
    required this.alamat,
    required this.rtRw,
    required this.kelurahan,
    required this.kecamatan,
    required this.rawText,
    required this.qualityScore,
    required this.processingTimeMs,
    this.error,
  });

  factory KTPExtractionResult.error({
    required String error,
    required int duration,
  }) {
    return KTPExtractionResult(
      nik: KTPFieldResult.failed('nik', ''),
      nama: KTPFieldResult.failed('nama', ''),
      tempatLahir: KTPFieldResult.failed('tempat_lahir', ''),
      tanggalLahir: KTPFieldResult.failed('tanggal_lahir', ''),
      jenisKelamin: KTPFieldResult.failed('jenis_kelamin', ''),
      golonganDarah: KTPFieldResult.failed('golongan_darah', ''),
      agama: KTPFieldResult.failed('agama', ''),
      statusPerkawinan: KTPFieldResult.failed('status_perkawinan', ''),
      pekerjaan: KTPFieldResult.failed('pekerjaan', ''),
      kewarganegaraan: KTPFieldResult.failed('kewarganegaraan', ''),
      alamat: KTPFieldResult.failed('alamat', ''),
      rtRw: KTPFieldResult.failed('rt_rw', ''),
      kelurahan: KTPFieldResult.failed('kelurahan', ''),
      kecamatan: KTPFieldResult.failed('kecamatan', ''),
      rawText: '',
      qualityScore: 0.0,
      processingTimeMs: duration,
      error: error,
    );
  }

  bool get isSuccess => error == null && nik.isFound;
}
