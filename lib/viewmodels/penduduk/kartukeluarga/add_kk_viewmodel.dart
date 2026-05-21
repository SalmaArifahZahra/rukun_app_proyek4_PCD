import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rukun_app_proyek4/models/keluarga_model.dart';
import 'package:rukun_app_proyek4/repositories/kk_repository.dart';
import 'package:rukun_app_proyek4/services/pcd/kk_extraction_result.dart';
import 'package:rukun_app_proyek4/services/pcd/kk_extraction_service.dart';
import 'package:rukun_app_proyek4/services/utils/cloudinary_service.dart';

class AddKKViewModel extends ChangeNotifier {
  final KKRepository kkRepository;
  final CloudinaryService cloudinaryService;
  final int rtId;
  File? fotoKK;

  AddKKViewModel({
    required this.kkRepository,
    required this.rtId,
    required this.cloudinaryService,
  });

  bool isSaving = false;
  bool isKKSaved = false;
  String? errorMessage;

  // ── PCD Extraction State ──
  bool isExtracting = false;
  String? extractionError;
  KKExtractionResult? extractionResult;
  String extractionStatus = '';

  Keluarga? kk;

  String noKK = '';
  String alamat = '';
  String kodePos = '';

  // Text controllers untuk sinkronisasi dua arah dengan form
  final noKKController = TextEditingController();
  final alamatController = TextEditingController();
  final kodePosController = TextEditingController();

  // ──────────────────────────────────────────────
  // Image Picking
  // ──────────────────────────────────────────────

  /// Pilih foto KK dari galeri
  Future<void> pickFotoKK() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      fotoKK = File(picked.path);
      notifyListeners();
    }
  }

  /// Ambil foto KK dari kamera
  Future<void> takeFotoKK() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (picked != null) {
      fotoKK = File(picked.path);
      notifyListeners();
    }
  }

  void setFotoKK(File file) {
    fotoKK = file;
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // PCD Extraction
  // ──────────────────────────────────────────────

  /// Scan KK: pilih gambar (kamera/galeri) lalu ekstrak data
  Future<void> scanKK(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);

    if (picked == null) return;

    fotoKK = File(picked.path);
    notifyListeners();

    // Mulai ekstraksi otomatis
    await _extractFromCurrentImage();
  }

  /// Jalankan ekstraksi PCD + OCR pada gambar yang sudah dipilih
  Future<void> _extractFromCurrentImage() async {
    if (fotoKK == null) return;

    isExtracting = true;
    extractionError = null;
    extractionStatus = 'Memproses gambar (PCD pipeline)...';
    notifyListeners();

    try {
      final service = KKExtractionService();
      extractionStatus = 'Menjalankan OCR...';
      notifyListeners();

      final result = await service.extractFromImage(fotoKK!);
      extractionResult = result;

      if (result.isSuccess) {
        // Auto-fill form fields
        _applyExtractionResult(result);
        extractionStatus = 'Ekstraksi berhasil!';
      } else {
        extractionStatus = 'Tidak dapat mengekstrak data dari gambar.';
        extractionError =
            'OCR tidak menemukan field KK. Coba ambil ulang dengan pencahayaan lebih baik.';
      }
    } catch (e) {
      extractionError =
          'Gagal mengekstrak: ${e.toString().replaceAll("Exception: ", "")}';
      extractionStatus = 'Ekstraksi gagal.';
    }

    isExtracting = false;
    notifyListeners();
  }

  /// Re-extract: coba ulang ekstraksi dari gambar yang sudah ada
  Future<void> retryExtraction() async {
    await _extractFromCurrentImage();
  }

  /// Terapkan hasil ekstraksi ke field form
  void _applyExtractionResult(KKExtractionResult result) {
    // New model: result.noKK adalah FieldConfidence object
    if (result.noKK.value != null) {
      noKK = result.noKK.value!;
      noKKController.text = result.noKK.value!;
    }
    if (result.alamat.value != null) {
      alamat = result.alamat.value!;
      alamatController.text = result.alamat.value!;
    }
    if (result.kodePos.value != null) {
      kodePos = result.kodePos.value!;
      kodePosController.text = result.kodePos.value!;
    }

    // Build detailed status message dengan confidence scores
    _buildDetailedExtractionStatus(result);
  }

  /// Build pesan status ekstraksi yang detail dengan confidence scores
  void _buildDetailedExtractionStatus(KKExtractionResult result) {
    final buffer = StringBuffer();

    buffer.writeln('✅ Ekstraksi Selesai');
    buffer.writeln('');
    buffer.writeln(
      '📊 Kualitas Gambar: ${(result.overallQuality * 100).toStringAsFixed(0)}%',
    );
    if (result.perspectiveCorrected > 0) {
      buffer.writeln(
        '📐 Koreksi Perspektif: ${(result.perspectiveCorrected * 100).toStringAsFixed(0)}%',
      );
    }
    buffer.writeln('');
    buffer.writeln('Confidence Scores:');

    // List hasil ekstraksi dengan confidence
    if (result.noKK.value != null) {
      buffer.writeln('  • No. KK: ${(result.noKK.confidence * 100).toInt()}%');
    }
    if (result.alamat.value != null) {
      buffer.writeln(
        '  • Alamat: ${(result.alamat.confidence * 100).toInt()}%',
      );
    }
    if (result.kodePos.value != null) {
      buffer.writeln(
        '  • Kode Pos: ${(result.kodePos.confidence * 100).toInt()}%',
      );
    }

    // Show fields needing review (confidence < 70%)
    if (result.fieldsNeedingReview.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('⚠️  Fields yang perlu review:');
      for (final field in result.fieldsNeedingReview) {
        buffer.writeln(
          '  • ${field.fieldName}: ${(field.confidence * 100).toInt()}%',
        );
      }
    }

    // Show validation errors jika ada
    if (result.validationErrors.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('❌ Validation Errors:');
      for (final error in result.validationErrors) {
        buffer.writeln('  • $error');
      }
    }

    extractionStatus = buffer.toString();
  }

  // ──────────────────────────────────────────────
  // Save
  // ──────────────────────────────────────────────

  Future<void> createKK() async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      String? fotoUrl;

      if (fotoKK != null) {
        fotoUrl = await cloudinaryService.uploadFile(
          fotoKK!,
          folder: 'kartukeluarga',
        );

        if (fotoUrl == null) {
          throw Exception("Gagal upload foto KK");
        }
      }

      final data = Keluarga(
        noKK: noKK,
        rtId: rtId,
        alamat: alamat,
        kodePos: kodePos,
        imgRef: fotoUrl,
      );

      await kkRepository.createKK(data);

      isKKSaved = true;
    } catch (e) {
      errorMessage = e.toString().replaceAll("Exception: ", "");
    }

    isSaving = false;
    notifyListeners();
  }

  @override
  void dispose() {
    noKKController.dispose();
    alamatController.dispose();
    kodePosController.dispose();
    super.dispose();
  }
}
