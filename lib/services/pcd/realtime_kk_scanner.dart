// lib/services/pcd/realtime_kk_scanner.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'document_detector_v2.dart';

// NOTE: CameraImage memerlukan package camera.
// Jika belum ditambahkan di pubspec.yaml, tambahkan:
// camera: ^0.11.0
// Untuk sementara, kita definisikan typedef agar tidak error compile.
// Uncomment import di bawah dan hapus typedef saat package camera sudah ada:
// import 'package:camera/camera.dart';

/// Placeholder class untuk CameraImage jika package camera belum di-install.
/// Hapus class ini dan uncomment import camera di atas saat siap pakai.
class CameraImage {
  final int width;
  final int height;
  final List<CameraPlane> planes;
  CameraImage({required this.width, required this.height, required this.planes});
}

class CameraPlane {
  final List<int> bytes;
  final int bytesPerRow;
  final int? bytesPerPixel;
  CameraPlane({required this.bytes, required this.bytesPerRow, this.bytesPerPixel});
}

/// Scanner realtime dengan frame skipping dan debounce
class RealtimeKKScanner {

  // Konfigurasi
  static const _processEveryNFrames = 5;    // Process 1 dari 5 frame
  static const _minTimeBetweenScansMs = 800; // Debounce 800ms
  static const _minDocumentConfidence = 0.6;

  int _frameCount = 0;
  DateTime _lastScan = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isProcessing = false;

  final _controller = StreamController<RealtimeScanResult>.broadcast();
  Stream<RealtimeScanResult> get results => _controller.stream;

  /// Call ini dari camera preview callback
  Future<void> processFrame(CameraImage cameraImage) async {
    _frameCount++;

    // Frame skipping
    if (_frameCount % _processEveryNFrames != 0) return;

    // Debounce
    final now = DateTime.now();
    if (now.difference(_lastScan).inMilliseconds < _minTimeBetweenScansMs) return;

    // Skip jika masih processing
    if (_isProcessing) return;

    _isProcessing = true;
    _lastScan = now;

    try {
      // Convert CameraImage ke img.Image (isolate untuk tidak block UI)
      final image = await _convertCameraImage(cameraImage);

      // Document detection saja (cepat, ~50ms)
      final quad = await DocumentDetectorV2.detect(image);

      if (quad == null) {
        _controller.add(RealtimeScanResult.noDocument());
        return;
      }

      final confidence = quad.calculateScore(image.width, image.height);

      if (confidence < _minDocumentConfidence) {
        _controller.add(RealtimeScanResult.lowConfidence(confidence));
        return;
      }

      // Dokumen terdeteksi dengan cukup baik → kirim feedback ke UI
      _controller.add(RealtimeScanResult.documentFound(quad, confidence));

      // Auto-capture jika confidence sangat tinggi
      if (confidence > 0.85) {
        _controller.add(RealtimeScanResult.readyToCapture(quad, confidence));
      }

    } finally {
      _isProcessing = false;
    }
  }

  /// Convert CameraImage (YUV420) ke img.Image
  Future<img.Image> _convertCameraImage(CameraImage cameraImage) async {
    return await compute(_convertInIsolate, cameraImage);
  }

  static img.Image _convertInIsolate(CameraImage cameraImage) {
    // YUV420 → RGB conversion
    final width = cameraImage.width;
    final height = cameraImage.height;
    final result = img.Image(width: width, height: height);

    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2) * uPlane.bytesPerPixel!;
        final yIndex = y * yPlane.bytesPerRow + x;

        final yVal = yPlane.bytes[yIndex];
        final uVal = uPlane.bytes[uvIndex];
        final vVal = vPlane.bytes[uvIndex];

        // YUV → RGB
        int r = (yVal + 1.402 * (vVal - 128)).round().clamp(0, 255);
        int g = (yVal - 0.344 * (uVal - 128) - 0.714 * (vVal - 128)).round().clamp(0, 255);
        int b = (yVal + 1.772 * (uVal - 128)).round().clamp(0, 255);

        result.setPixelRgb(x, y, r, g, b);
      }
    }

    return result;
  }

  void dispose() => _controller.close();
}

class RealtimeScanResult {
  final RealtimeScanStatus status;
  final DocumentQuad? quad;
  final double confidence;
  final String? message;

  RealtimeScanResult({
    required this.status,
    this.quad,
    this.confidence = 0,
    this.message,
  });

  factory RealtimeScanResult.noDocument() => RealtimeScanResult(
    status: RealtimeScanStatus.noDocument,
    message: 'Arahkan kamera ke Kartu Keluarga',
  );

  factory RealtimeScanResult.lowConfidence(double conf) => RealtimeScanResult(
    status: RealtimeScanStatus.lowConfidence,
    confidence: conf,
    message: 'Perbaiki posisi dan pencahayaan',
  );

  factory RealtimeScanResult.documentFound(DocumentQuad quad, double conf) =>
      RealtimeScanResult(
        status: RealtimeScanStatus.documentFound,
        quad: quad,
        confidence: conf,
        message: 'KK terdeteksi, tahan posisi...',
      );

  factory RealtimeScanResult.readyToCapture(DocumentQuad quad, double conf) =>
      RealtimeScanResult(
        status: RealtimeScanStatus.readyToCapture,
        quad: quad,
        confidence: conf,
        message: 'Siap mengambil gambar!',
      );
}

enum RealtimeScanStatus {
  noDocument,
  lowConfidence,
  documentFound,
  readyToCapture,
}