// lib/services/pcd/performance_optimizer.dart

import 'dart:io';

import 'package:flutter/foundation.dart';

import 'kk_extraction_service_v2.dart';

class OCRPerformanceOptimizer {

  /// Pilih resolusi optimal berdasarkan:
  /// - Tipe field (header butuh lebih rendah dari tabel)
  /// - RAM tersedia
  /// - Waktu target
  static int getOptimalWidth(OCRTargetType targetType) {
    switch (targetType) {
      case OCRTargetType.headerOnly:
        return 800;   // ~50ms processing
      case OCRTargetType.fullDocument:
        return 1200;  // ~150ms processing
      case OCRTargetType.tableHighRes:
        return 1600;  // ~300ms processing
    }
  }

  /// Jalankan heavy processing di isolate terpisah
  static Future<KKExtractionOutputV2> extractInIsolate(File imageFile) async {
    return await compute(_extractIsolated, imageFile.path);
  }

  static Future<KKExtractionOutputV2> _extractIsolated(String filePath) async {
    final service = KKExtractionServiceV2();
    return await service.extractFromFile(File(filePath));
  }

  /// Cache management: simpan hasil deteksi untuk menghindari re-process
  static final _cache = <String, KKExtractionOutputV2>{};

  static KKExtractionOutputV2? getCached(String imageHash) {
    return _cache[imageHash];
  }

  static void cache(String imageHash, KKExtractionOutputV2 result) {
    if (_cache.length > 10) _cache.clear(); // Simple eviction
    _cache[imageHash] = result;
  }
}

enum OCRTargetType { headerOnly, fullDocument, tableHighRes }