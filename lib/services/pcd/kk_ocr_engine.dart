// lib/services/pcd/kk_ocr_engine.dart

import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class KKOCREngine {
  final TextRecognizer _recognizer = TextRecognizer(
      script: TextRecognitionScript.latin
  );

  /// OCR satu region image
  Future<String> recognizeRegion(img.Image region) async {
    // Convert img.Image to File for ML Kit
    // GUNAKAN IDENTIFIKATOR UNIK (microseconds + random) agar proses paralel tidak saling menimpa file
    final tempDir = await getTemporaryDirectory();
    final uniqueId = '${DateTime.now().microsecondsSinceEpoch}_${region.hashCode}';
    final tempFile = File('${tempDir.path}/temp_ocr_region_$uniqueId.jpg');
    
    await tempFile.writeAsBytes(img.encodeJpg(region));

    final inputImage = InputImage.fromFile(tempFile);
    
    try {
      final text = await _recognizer.processImage(inputImage);
      return text.text;
    } finally {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }

  /// Proses gambar secara langsung dari File (tanpa crop/memory Dart)
  /// Mengembalikan objek RecognizedText yang berisi TextBlock spasial
  Future<RecognizedText> processImageDirect(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    return await _recognizer.processImage(inputImage);
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}

// lib/services/pcd/kk_field_parser.dart

class KKFieldParser {

  // ── No. KK ────────────────────────────────────
  static ParseResult parseNomorKK(String rawText) {
    final cleaned = rawText.replaceAll('\n', ' ');

    final patterns = [
      // Prioritas 1: HARUS ada kata "KARTU KELUARGA" atau "No" sebelum angka (max jarak 80 karakter).
      // Memakai [0-9A-Za-z] agar kebal dari salah baca OCR parah (misal angka 6 dibaca huruf L)
      RegExp(r'(?:No\.?\s*(?:KK)?|KARTU\s*KELUARGA)[\s\S]{0,80}?((?:[0-9A-Za-z]\s*){16,})', caseSensitive: false),
      
      // Prioritas 2: Fallback jika kata KARTU KELUARGA rusak, ambil 16 angka pertama yang valid.
      RegExp(r'(?:[0-9OoIlLSZBgbCQD]\s*){16,}'),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(cleaned);
      for (final match in matches) {
        // Ambil grup 1 jika ada (Pattern 1), jika tidak ambil grup 0 (Pattern 2)
        final rawMatch = match.groupCount >= 1 && match.group(1) != null 
            ? match.group(1)! 
            : match.group(0)!;
            
        final cleanedMatch = rawMatch.replaceAll(RegExp(r'[\s\-]'), '');
        
        if (cleanedMatch.length >= 16) {
          // Sliding window: Ambil setiap 16 karakter berurutan
          for (int j = 0; j <= cleanedMatch.length - 16; j++) {
            final sub = cleanedMatch.substring(j, j + 16);
            final raw = _correctOCRDigits(sub);
            
            if (_isValidNomorKK(raw)) {
              return ParseResult(
                value: raw,
                confidence: 0.95,
                rawText: rawText,
              );
            }
          }
        }
      }
    }

    return ParseResult.failed('nomor_kk', rawText);
  }

  // ── Alamat ─────────────────────────────────────
  static ParseResult parseAlamat(String rawText) {
    final lines = rawText.split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Strategy 1: Cari baris setelah "Alamat" (OCR-tolerant)
    for (int i = 0; i < lines.length; i++) {
      // Fuzzy match: Alamat / Alam at / Alamaf / Aiamat (OCR error pada 'l'→'i', 'a'→'s', dll)
      if (RegExp(r'^A[1lI]?a[mn][a4][t7]\s*[:\.]?', caseSensitive: false).hasMatch(lines[i]) ||
          RegExp(r'^Alamat\s*[:\.]?', caseSensitive: false).hasMatch(lines[i])) {
        final same = lines[i].replaceFirst(
            RegExp(r'^A[1lI]?a[mn][a4][t7]\s*[:\.]?\s*', caseSensitive: false), ''
        ).trim();

        if (same.length > 3) {
          return ParseResult(value: _cleanAlamat(same), confidence: 0.90, rawText: rawText);
        }

        // Cek baris berikutnya (bisa multi-line)
        if (i + 1 < lines.length) {
          final next = lines[i+1].trim();
          if (!_isFieldLabel(next) && next.length > 3) {
            // Jika next line juga alamat, gabungkan (alamat panjang)
            if (i + 2 < lines.length && !_isFieldLabel(lines[i+2].trim()) &&
                _isContinuationOfAddress(next, lines[i+2].trim())) {
              return ParseResult(
                value: _cleanAlamat('$next ${lines[i+2].trim()}'),
                confidence: 0.85,
                rawText: rawText,
              );
            }
            return ParseResult(value: _cleanAlamat(next), confidence: 0.85, rawText: rawText);
          }
        }
      }
    }

    // Strategy 2: Cari pola alamat (expanded patterns)
    final alamatPattern = RegExp(
      r'(?:JL\.?|JALAN|GG\.?|GANG|DUSUN|DSN\.?|KP\.?|KAMPUNG|BLOK|'
      r'Ds\.?|Desa\s|Perum\.?|Perumahan|Komplek|Kompleks|Kav\.?|Kavling|'
      r'Link\.?|Lingkungan)\s+.+',
      caseSensitive: false,
    );

    for (final line in lines) {
      final match = alamatPattern.firstMatch(line);
      if (match != null) {
        return ParseResult(
          value: _cleanAlamat(match.group(0)!),
          confidence: 0.75,
          rawText: rawText,
        );
      }
    }

    // Strategy 3: Positional — cari baris sebelum RT/RW atau Desa/Kelurahan
    // Layout KK: Alamat di atas RT/RW
    for (int i = 0; i < lines.length; i++) {
      if (RegExp(r'^RT\s*[/\\]\s*RW', caseSensitive: false).hasMatch(lines[i]) ||
          RegExp(r'^(?:Desa|Kelurahan|Kel\.?)\s*[:\.]?', caseSensitive: false).hasMatch(lines[i])) {
        // Cek 1-2 baris sebelumnya
        for (int j = i - 1; j >= 0 && j >= i - 2; j--) {
          final candidate = lines[j].trim();
          if (candidate.length > 3 &&
              !_isFieldLabel(candidate) &&
              !_isOnlyDigits(candidate) &&
              _isAddressLine(candidate)) {
            return ParseResult(
              value: _cleanAlamat(candidate),
              confidence: 0.65,
              rawText: rawText,
            );
          }
        }
      }
    }

    return ParseResult.failed('alamat', rawText);
  }

  // ── Kode Pos ────────────────────────────────────
  static ParseResult parseKodePos(String rawText) {
    final patterns = [
      // "Kode Pos : 12345"
      RegExp(r'(?:Kode\s*Pos|KODE\s*POS)\s*[:\.\s]+([0-9A-Za-z]{5})(?![0-9A-Za-z])',
          caseSensitive: false),
      // "Pos\n12345" atau "Pos : 12345"
      RegExp(r'Pos\s*[:\.\n]+\s*([0-9A-Za-z]{5})(?![0-9A-Za-z])', caseSensitive: false),
      // Standalone 5 digit (bukan bagian dari No. KK atau NIK)
      RegExp(r'(?<![0-9A-Za-z])([1-9S][0-9A-Za-z]{4})(?![0-9A-Za-z])'),
    ];

    for (int i = 0; i < patterns.length; i++) {
      final match = patterns[i].firstMatch(rawText);
      if (match != null) {
        final kodePosRaw = match.group(1)!;
        final kodePos = _correctOCRDigits(kodePosRaw);
        if (_isValidKodePos(kodePos)) {
          return ParseResult(
            value: kodePos,
            confidence: i == 0 ? 0.95 : (i == 1 ? 0.85 : 0.65),
            rawText: rawText,
          );
        }
      }
    }

    return ParseResult.failed('kode_pos', rawText);
  }

  // ── RT/RW ───────────────────────────────────────
  static ParseResult parseRTRW(String rawText) {
    final patterns = [
      // Format "RT/RW : 002/001" atau "RT/RW 002/001"
      RegExp(r'RT\s*/\s*RW\s*[:\.]?\s*([0-9A-Za-z]{1,3})\s*[/\\]+\s*([0-9A-Za-z]{1,3})', caseSensitive: false),
      // Format terpisah "RT 002 RW 001"
      RegExp(r'RT\s*[:\.]?\s*([0-9A-Za-z]{1,3})\s*RW\s*[:\.]?\s*([0-9A-Za-z]{1,3})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(rawText);
      if (match != null) {
        final rtRaw = match.group(1)!;
        final rwRaw = match.group(2)!;
        return ParseResult(
          value: '${_correctOCRDigits(rtRaw).padLeft(3,'0')}/${_correctOCRDigits(rwRaw).padLeft(3,'0')}',
          confidence: 0.90,
          rawText: rawText,
        );
      }
    }

    return ParseResult.failed('rt_rw', rawText);
  }

  // ── Desa/Kelurahan ──────────────────────────────
  static ParseResult parseDesaKelurahan(String rawText) {
    final lines = rawText.split('\n').map((l) => l.trim()).toList();

    for (int i = 0; i < lines.length; i++) {
      final label = RegExp(
        r'(?:Desa/?Kelurahan|Desa/Kel|Desa|Kelurahan|Kel\.?)\s*[:\.]?\s*(.+)',
        caseSensitive: false,
      );
      final match = label.firstMatch(lines[i]);
      if (match != null && match.group(1)!.trim().length > 2) {
        // Bersihkan jika ada label RT/RW atau Kecamatan yang terikut
        var clean = _cleanText(match.group(1)!);
        clean = clean.split(RegExp(r'\s+Kecamatan', caseSensitive: false))[0].trim();
        
        return ParseResult(
          value: clean,
          confidence: 0.85,
          rawText: rawText,
        );
      }
    }
    return ParseResult.failed('desa_kelurahan', rawText);
  }

  // ── Kecamatan ───────────────────────────────────
  static ParseResult parseKecamatan(String rawText) {
    final pattern = RegExp(
      r'(?:Kecamatan|Kec\.?)\s*[:\.]?\s*(.+)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(rawText);
    if (match != null) {
      return ParseResult(
        value: _cleanText(match.group(1)!),
        confidence: 0.85,
        rawText: rawText,
      );
    }
    return ParseResult.failed('kecamatan', rawText);
  }

  // ── Parser Anggota Keluarga ─────────────────────
  static List<AnggotaResult> parseAnggotaKeluarga(String rawText) {
    final results = <AnggotaResult>[];
    final lines = rawText.split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    for (final line in lines) {
      // Skip header baris
      if (_isTableHeader(line)) continue;

      final anggota = _parseAnggotaLine(line);
      if (anggota != null) results.add(anggota);
    }

    return results;
  }

  static AnggotaResult? _parseAnggotaLine(String line) {
    // Format baris tabel KK:
    // [no] [nama] [NIK 16 digit] [JK] [TTL] [agama] [pendidikan] [pekerjaan] [hubungan]

    // Ekstrak NIK sebagai anchor
    final nikPattern = RegExp(r'\b(\d{16})\b');
    final nikMatch = nikPattern.firstMatch(_correctOCRDigits(line));

    if (nikMatch == null) return null;

    final nik = nikMatch.group(1)!;
    final nikPos = nikMatch.start;

    // Teks sebelum NIK → kandidat nama
    final beforeNik = line.substring(0, nikPos).trim();
    final namaParts = beforeNik.split(RegExp(r'\s+'));

    // Buang nomor urut di awal
    final startIdx = (namaParts.isNotEmpty && RegExp(r'^\d+$').hasMatch(namaParts.first)) ? 1 : 0;
    final nama = namaParts.skip(startIdx).join(' ').trim();

    // Teks setelah NIK → JK, TTL, dll
    final afterNik = line.substring(nikMatch.end).trim();
    final jk = _extractJenisKelamin(afterNik);
    final ttl = _extractTTL(afterNik);

    if (nik.isEmpty || nama.isEmpty) return null;

    return AnggotaResult(
      nama: _cleanText(nama),
      nik: nik,
      jenisKelamin: jk,
      tempatTanggalLahir: ttl,
      confidence: 0.75,
    );
  }

  static String? _extractJenisKelamin(String text) {
    if (RegExp(r'\bLAKI\b|\bL\b', caseSensitive: false).hasMatch(text)) return 'LAKI-LAKI';
    if (RegExp(r'\bPEREMPUAN\b|\bP\b', caseSensitive: false).hasMatch(text)) return 'PEREMPUAN';
    return null;
  }

  static String? _extractTTL(String text) {
    // Format: "KOTA, DD-MM-YYYY" atau "KOTA DD-MM-YYYY"
    final ttlPattern = RegExp(
      r'([A-Za-z\s]+)[,\s]+(\d{2}[\-/]\d{2}[\-/]\d{4})',
    );
    final match = ttlPattern.firstMatch(text);
    if (match != null) {
      return '${match.group(1)!.trim()}, ${match.group(2)!}';
    }
    return null;
  }

  // ── Utilities ───────────────────────────────────

  /// Koreksi karakter OCR yang tertukar dengan angka
  static String _correctOCRDigits(String input) {
    return input
        .replaceAll(RegExp(r'[OoDdQqC]'), '0')
        .replaceAll(RegExp(r'[IlL|!\]\[]'), '1') // Ditambahkan L kapital
        .replaceAll(RegExp(r'[Zz]'), '2')
        .replaceAll(RegExp(r'[Aa]'), '4')
        .replaceAll(RegExp(r'[Ss]'), '5')
        .replaceAll(RegExp(r'[Ggb]'), '6')
        .replaceAll(RegExp(r'[Tt]'), '7')
        .replaceAll(RegExp(r'[B]'), '8')
        .replaceAll(RegExp(r'[gP]'), '9'); // P kadang dibaca sebagai 9
  }

  static bool _isValidNomorKK(String s) {
    if (s.length != 16) return false;
    if (!RegExp(r'^\d{16}$').hasMatch(s)) return false;
    if (s.startsWith('0')) return false;
    return s.split('').toSet().length > 1;
  }

  static bool _isValidKodePos(String kodePos) {
    if (kodePos.length != 5) return false;
    if (!RegExp(r'^\d{5}$').hasMatch(kodePos)) return false;
    // Kode pos Indonesia: 10000–99999
    final code = int.tryParse(kodePos) ?? 0;
    return code >= 10000 && code <= 99999;
  }

  static bool _isFieldLabel(String text) {
    final labels = ['RT', 'RW', 'Desa', 'Kelurahan', 'Kecamatan',
      'Kabupaten', 'Kota', 'Provinsi', 'Kode Pos'];
    return labels.any((l) => text.toLowerCase().startsWith(l.toLowerCase()));
  }

  static bool _isTableHeader(String line) {
    final headerKeywords = ['No.', 'Nama', 'NIK', 'Jenis', 'Kelamin',
      'Tempat', 'Tanggal', 'Lahir', 'Agama'];
    int matches = headerKeywords.where((k) =>
        line.contains(k)).length;
    return matches >= 3;
  }

  static String _cleanAlamat(String raw) {
    return raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s\.\,\/\-\(\)\#\d]'), '')
        .trim();
  }

  /// Cek apakah baris terlihat seperti alamat
  static bool _isAddressLine(String line) {
    // Mengandung pola jalan/alamat
    if (RegExp(r'(?:JL\.?|JALAN|GG\.?|GANG|DUSUN|DSN\.?|KP\.?|KAMPUNG|BLOK|'
        r'Ds\.?|Perum\.?|Perumahan|Komplek|Kompleks|Kav\.?|Link\.?|Lingkungan)',
        caseSensitive: false).hasMatch(line)) {
      return true;
    }
    // Mengandung "No." diikuti angka
    if (RegExp(r'No\.?\s*\d', caseSensitive: false).hasMatch(line)) {
      return true;
    }
    // Kombinasi angka + teks (misal "12 Jl. Merdeka" atau "RT 003")
    if (RegExp(r'^\d+\s+[A-Za-z]').hasMatch(line)) {
      return true;
    }
    return false;
  }

  /// Cek apakah line2 adalah kelanjutan alamat dari line1
  static bool _isContinuationOfAddress(String line1, String line2) {
    // Jika line2 dimulai dengan huruf kecil, kemungkinan kelanjutan
    if (line2.isNotEmpty && line2[0] == line2[0].toLowerCase() && line2[0] != line2[0].toUpperCase()) {
      return true;
    }
    // Jika line2 mengandung pola lanjutan alamat (RT/RW, No, Blok)
    if (RegExp(r'^(?:RT|RW|No\.?|Blok)', caseSensitive: false).hasMatch(line2)) {
      return true;
    }
    return false;
  }

  static bool _isOnlyDigits(String text) {
    return RegExp(r'^\d+$').hasMatch(text.trim());
  }

  static String _cleanText(String raw) {
    return raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

// ── Data Classes ──────────────────────────────────

class ParseResult {
  final String? value;
  final double confidence;
  final String rawText;
  final String? error;

  ParseResult({
    required this.value,
    required this.confidence,
    required this.rawText,
    this.error,
  });

  factory ParseResult.failed(String field, String rawText) {
    return ParseResult(
      value: null,
      confidence: 0.0,
      rawText: rawText,
      error: '$field tidak ditemukan',
    );
  }

  bool get isFound => value != null && confidence > 0.0;
}

class AnggotaResult {
  final String nama;
  final String nik;
  final String? jenisKelamin;
  final String? tempatTanggalLahir;
  final double confidence;

  AnggotaResult({
    required this.nama,
    required this.nik,
    this.jenisKelamin,
    this.tempatTanggalLahir,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'nik': nik,
      'jenis_kelamin': jenisKelamin,
      'tempat_tanggal_lahir': tempatTanggalLahir,
      '_confidence': confidence,
    };
  }
}

// Letakkan ini di bawah class KKFieldParser di lib/services/pcd/kk_ocr_engine.dart

class LayoutAdaptiveParser {
  static ParseResult parseNomorKKAdaptive(String rawText) {
    final candidates = <ParseResult>[];

    // Strategi 1: Context-aware (ada label "No. KK")
    candidates.add(KKFieldParser.parseNomorKK(rawText));

    // Strategi 2: Cari semua sequence 16 digit
    final allSixteen = RegExp(r'\b\d{16}\b')
        .allMatches(_correctDigits(rawText))
        .map((m) => ParseResult(
      value: m.group(0),
      confidence: 0.70,
      rawText: rawText,
    ));
    candidates.addAll(allSixteen);

    // Strategi 3: OCR error correction (coba koreksi karakter)
    final ultraCorrected = _aggressiveOCRCorrection(rawText);
    candidates.add(KKFieldParser.parseNomorKK(ultraCorrected));

    // Pilih candidate dengan confidence tertinggi yang valid
    return candidates
        .where((c) => c.isFound && _isValidNomorKK(c.value!))
        .fold(ParseResult.failed('nomor_kk', rawText),
            (best, c) => c.confidence > best.confidence ? c : best);
  }

  static String _aggressiveOCRCorrection(String text) {
    return text
        .replaceAll(RegExp(r'[Oo]'), '0')
        .replaceAll(RegExp(r'[Il|]'), '1')
        .replaceAll('Z', '2')
        .replaceAll(RegExp(r'[Ss]'), '5')
        .replaceAll('G', '6')
        .replaceAll('B', '8')
        .replaceAll('g', '9');
  }

  static String _correctDigits(String text) {
    return text
        .replaceAll('O', '0').replaceAll('o', '0')
        .replaceAll('I', '1').replaceAll('l', '1')
        .replaceAll('S', '5');
  }

  static bool _isValidNomorKK(String s) {
    // FIX: String di Dart butuh .split('') sebelum diubah ke Set
    return s.length == 16 && RegExp(r'^\d{16}$').hasMatch(s)
        && s.split('').toSet().length > 1;
  }
}

