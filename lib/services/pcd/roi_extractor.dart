import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Region yang bisa diextract dari dokumen KK (Top-level enum)
enum ROIRegion {
  header, // Top section: No. KK, Alamat, Kode Pos, Kab/Kota, Provinsi
  members, // Bottom section: Daftar anggota keluarga
  full, // Seluruh dokumen
}

/// Region of Interest (ROI) Extraction untuk Kartu Keluarga
///
/// Memotong dokumen KK berdasarkan area tertentu untuk ekstraksi
/// yang lebih efisien dan akurat
///
/// A4-Aware ROI Regions:
/// - Portrait A4 (210×297 mm): ratio 0.707
///   - Header: 0-45% (more info at top in portrait)
///   - Members: 45-100%
/// - Landscape A4 (297×210 mm): ratio 1.414
///   - Header: 0-40% (info spread, header at top)
///   - Members: 40-100%
class ROIExtractor {
  /// Calculate header region percentage berdasarkan aspect ratio A4
  ///
  /// KK A4 Aspect Ratios:
  /// - Portrait: ~0.707 (width < height) → header 45%
  /// - Landscape: ~1.414 (width > height) → header 40%
  /// - Square/other: ~1.0 → default 40%
  static double _calculateHeaderPercentage(int width, int height) {
    final aspectRatio = width / height;

    // A4 Landscape: ratio ~1.4
    if (aspectRatio > 1.2) {
      debugPrint(
        '📐 Detected LANDSCAPE A4 (ratio: ${aspectRatio.toStringAsFixed(3)}) → header 40%',
      );
      return 0.40;
    }

    // A4 Portrait: ratio ~0.7
    if (aspectRatio < 0.85) {
      debugPrint(
        '📐 Detected PORTRAIT A4 (ratio: ${aspectRatio.toStringAsFixed(3)}) → header 45%',
      );
      return 0.45;
    }

    // Default/Square
    debugPrint(
      '📐 Detected SQUARE/OTHER (ratio: ${aspectRatio.toStringAsFixed(3)}) → header 40%',
    );
    return 0.40;
  }

  /// Crop gambar berdasarkan region tertentu
  ///
  /// Returns: File cropped image untuk digunakan OCR
  ///
  /// Layout KK standar (A4-Aware):
  /// - Landscape: Header (0-40%), Members (40-100%)
  /// - Portrait: Header (0-45%), Members (45-100%)
  static Future<File> cropToRegion(
    img.Image source,
    ROIRegion region, {
    String tempDir = '',
  }) async {
    final height = source.height;
    final width = source.width;

    // Calculate adaptive header percentage based on aspect ratio
    final headerPercent = _calculateHeaderPercentage(width, height);

    late final int startY;
    late final int endY;
    late final String regionName;

    switch (region) {
      case ROIRegion.header:
        // Adaptive header based on A4 aspect ratio
        startY = 0;
        endY = (height * headerPercent).toInt();
        regionName = 'HEADER';

      case ROIRegion.members:
        // Bottom part untuk daftar anggota keluarga
        startY = (height * headerPercent).toInt();
        endY = height;
        regionName = 'MEMBERS';

      case ROIRegion.full:
        // Seluruh dokumen
        startY = 0;
        endY = height;
        regionName = 'FULL';
    }

    final cropHeight = endY - startY;
    debugPrint('╔═══════════════════════════════════════════╗');
    debugPrint('║ 📍 ROI CROPPING TO $regionName');
    debugPrint('║ Original: ${source.width}x${source.height}px');
    debugPrint('║ Cropped: ${source.width}x${cropHeight}px (Y: $startY-$endY)');
    debugPrint('╚═══════════════════════════════════════════╝');

    // Copy region tertentu
    final croppedImage = img.copyCrop(
      source,
      x: 0,
      y: startY,
      width: width,
      height: cropHeight,
    );

    // Simpan ke file temporary
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName =
        '${tempDir}/roi_${regionName.toLowerCase()}_$timestamp.jpg';
    final croppedFile = File(fileName);
    await croppedFile.writeAsBytes(img.encodeJpg(croppedImage, quality: 95));

    debugPrint('✓ Cropped image saved to: $fileName');

    return croppedFile;
  }

  /// Tentukan region mana yang diperlukan untuk field tertentu
  static ROIRegion determineRequiredRegion(List<String> fieldNames) {
    final Set<String> fields = fieldNames.toSet();

    debugPrint('🔍 Determining region for fields: $fields');

    // Jika hanya butuh field dari header saja
    final headerFields = {
      'noKK',
      'alamat',
      'kodePos',
      'kabupatenKota',
      'provinsi',
    };

    if (fields.every((f) => headerFields.contains(f))) {
      debugPrint('→ Region determined: HEADER (40%)');
      return ROIRegion.header;
    }

    // Jika butuh field dari members section
    final memberFields = {
      'nama',
      'hubunganKeluarga',
      'statusPerkawinan',
      'pekerjaan',
    };

    if (fields.every((f) => memberFields.contains(f))) {
      debugPrint('→ Region determined: MEMBERS (60%)');
      return ROIRegion.members;
    }

    // Default: scan seluruh dokumen
    debugPrint('→ Region determined: FULL (100%)');
    return ROIRegion.full;
  }

  /// Crop gambar ke header region untuk ekstraksi efisien
  ///
  /// Digunakan untuk: No. KK, Alamat, Kode Pos
  static Future<File> cropToHeaderRegion(
    img.Image source, {
    String tempDir = '',
  }) async {
    return cropToRegion(source, ROIRegion.header, tempDir: tempDir);
  }

  /// Crop gambar ke members region
  ///
  /// Digunakan untuk: Data anggota keluarga
  static Future<File> cropToMembersRegion(
    img.Image source, {
    String tempDir = '',
  }) async {
    return cropToRegion(source, ROIRegion.members, tempDir: tempDir);
  }

  /// Get region percentage dari tinggi dokumen
  static String getRegionInfo(ROIRegion region) {
    switch (region) {
      case ROIRegion.header:
        return 'Header Region (0-40% dari tinggi dokumen)';
      case ROIRegion.members:
        return 'Members Region (40-100% dari tinggi dokumen)';
      case ROIRegion.full:
        return 'Full Document (0-100%)';
    }
  }
}
