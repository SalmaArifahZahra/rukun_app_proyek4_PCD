import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:rukun_app_proyek4/models/kegiatan_model.dart';
import 'package:rukun_app_proyek4/models/user_model.dart';
import 'package:rukun_app_proyek4/repositories/kegiatan_repository.dart';
import 'package:rukun_app_proyek4/services/utils/cloudinary_service.dart';

enum KegiatanFilterStatus { semua, dibuat, dibatalkan, selesai }

enum KegiatanValidationMode { create, uploadBukti, edit }

class KegiatanViewModel extends ChangeNotifier {
  static const int createKey = -1;
  final KegiatanRepository repository;
  final CloudinaryService cloudinaryService;

  KegiatanViewModel(this.repository, this.cloudinaryService);

  User? _currentUser;
  User? get currentUser => _currentUser;
  List<Kegiatan> _allKegiatan = [];

  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;

  final Map<int, File?> _selectedImages = {};
  final Map<int, File?> _selectedDocuments = {};

  File? getSelectedImage(int kegiatanId) {
    return _selectedImages[kegiatanId];
  }

  File? getSelectedDocument(int kegiatanId) {
    return _selectedDocuments[kegiatanId];
  }

  KegiatanLevel selectedLevel = KegiatanLevel.rw;
  KegiatanFilterStatus selectedStatus = KegiatanFilterStatus.semua;

  String _searchQuery = "";

  bool canCreateOnCurrentLevel() {
    final level = _currentUser?.pengurus?.level;

    if (level == null) return false;

    if (selectedLevel == KegiatanLevel.rw) {
      return level.toUpperCase() == "RW";
    }

    if (selectedLevel == KegiatanLevel.rt) {
      return level.toUpperCase() == "RT";
    }

    return false;
  }

  Future<void> fetchKegiatan() async {
    try {
      _setLoading(true);
      clearError();

      _allKegiatan = await repository.getAllKegiatan();
    } catch (e) {
      _setError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    await fetchKegiatan();
  }

  List<Kegiatan> get kegiatanList {
    final user = _currentUser;
    final userLevel = user?.pengurus?.level.toUpperCase();
    final userRtId = user?.rt?.id;

    return _allKegiatan
        .where((kegiatan) {
          final matchLevel = kegiatan.level == selectedLevel;

          final matchStatus = switch (selectedStatus) {
            KegiatanFilterStatus.semua => true,
            KegiatanFilterStatus.dibuat =>
              kegiatan.status == KegiatanStatus.dibuat,
            KegiatanFilterStatus.dibatalkan =>
              kegiatan.status == KegiatanStatus.dibatalkan,
            KegiatanFilterStatus.selesai =>
              kegiatan.status == KegiatanStatus.selesai,
          };

          final query = _searchQuery.toLowerCase();
          final matchSearch =
              kegiatan.nama.toLowerCase().contains(query) ||
              (kegiatan.deskripsi ?? "").toLowerCase().contains(query);

          bool matchUser = true;

          if (selectedLevel == KegiatanLevel.rt) {
            if (userLevel == "RT") {
              matchUser = kegiatan.rtId == userRtId;
            } else if (userLevel == "RW") {
              matchUser = true;
            } else {
              matchUser = false;
            }
          }

          return matchLevel && matchStatus && matchSearch && matchUser;
        })
        .toList()
        .reversed
        .toList();
  }

  List<Kegiatan> get filteredKegiatan {
    final currentRtId = _currentUser?.rt?.id;

    return _allKegiatan.where((kegiatan) {
      if (selectedLevel != kegiatan.level) {
        return false;
      }

      if (selectedLevel == KegiatanLevel.rt) {
        return kegiatan.rtId == currentRtId;
      }

      return true;
    }).toList();
  }

  void setLevel(KegiatanLevel level) {
    selectedLevel = level;
    notifyListeners();
  }

  void setStatus(KegiatanFilterStatus status) {
    selectedStatus = status;
    notifyListeners();
  }

  void setCurrentUser(User user) {
    _currentUser = user;
  }

  void setSearch(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  String _buildDokumenFolder() {
    if (_currentUser == null) {
      throw Exception("User belum login");
    }

    final rwId = _currentUser?.rw?.id;

    if (rwId == null) {
      throw Exception("RW ID tidak ditemukan");
    }

    if (selectedLevel == KegiatanLevel.rw) {
      return 'kegiatan/dokumen/norw/$rwId';
    }

    final rtId = _currentUser?.rt?.id;

    if (rtId == null) {
      throw Exception("RT ID tidak ditemukan");
    }

    return 'kegiatan/dokumen/norw/$rwId/nort/$rtId';
  }

  Future<bool> createKegiatan({
    required String nama,
    required String deskripsi,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final document = _selectedDocuments[createKey];

      if (document == null) {
        throw Exception("Dokumen wajib diupload");
      }

      if (_currentUser == null) {
        throw Exception("User belum login");
      }

      final folder = _buildDokumenFolder();

      final docUrl = await cloudinaryService.uploadFile(
        document,
        folder: folder,
      );

      if (docUrl == null) {
        throw Exception("Upload dokumen gagal");
      }

      final rwId = _currentUser?.rw?.id;

      if (rwId == null) {
        throw Exception("RW ID tidak ditemukan");
      }

      final rtId = selectedLevel == KegiatanLevel.rt
          ? _currentUser?.rt?.id
          : null;

      if (selectedLevel == KegiatanLevel.rt && rtId == null) {
        throw Exception("RT ID tidak ditemukan");
      }

      final kegiatan = Kegiatan(
        nama: nama.trim(),
        deskripsi: deskripsi.trim(),
        tanggalMulai: tanggalMulai,
        tanggalSelesai: tanggalSelesai,
        level: selectedLevel,
        status: KegiatanStatus.dibuat,
        rtId: rtId,
        rwId: rwId,
        docReferensi: docUrl,
        imgReferensi: null,
      );

      await repository.createKegiatan(kegiatan);

      clearFiles(createKey);
      await fetchKegiatan();

      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setUploading(bool value) {
    _isUploading = value;
    notifyListeners();
  }

  void _setError(dynamic e) {
    if (e == null) {
      _errorMessage = null;
    } else {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> updateKegiatan({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final document = _selectedDocuments[id];

      if (document != null) {
        final documentUrl = await cloudinaryService.uploadFile(
          document,
          folder: 'kegiatan/dokumen',
        );

        if (documentUrl == null) {
          throw Exception("Upload dokumen gagal");
        }

        data['doc_referensi'] = documentUrl;
      }

      await repository.updateKegiatan(id, data);

      clearFiles(id);
      await fetchKegiatan();

      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> batalkanKegiatan(int id) async {
    try {
      _setLoading(true);
      clearError();

      await repository.updateKegiatan(id, {"status": "Dibatalkan"});

      await fetchKegiatan();

      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteKegiatan(int id) async {
    try {
      await repository.deleteKegiatan(id);
      await fetchKegiatan();
    } catch (e) {
      _setError(e);
      notifyListeners();
    }
  }

  Future<void> uploadBuktiKegiatan(int kegiatanId) async {
    try {
      _setUploading(true);
      clearError();

      final image = _selectedImages[kegiatanId];

      if (image == null) {
        throw Exception("Foto bukti wajib diupload");
      }

      final url = await cloudinaryService.uploadFile(
        image,
        folder: 'kegiatan/$kegiatanId',
      );

      if (url == null) {
        throw Exception("Upload gambar gagal");
      }

      await repository.updateKegiatan(kegiatanId, {
        "img_referensi": url,
        "status": "Selesai",
      });

      clearFiles(kegiatanId);

      await fetchKegiatan();
    } catch (e) {
      _setError(e);
    } finally {
      _setUploading(false);
    }
  }

  void clearUpload(int kegiatanId) {
    _selectedImages.remove(kegiatanId);
    _selectedDocuments.remove(kegiatanId);

    notifyListeners();
  }

  bool canDelete(Kegiatan k) {
    return !isReadonly(k) && k.status == KegiatanStatus.selesai;
  }

  bool isReadonly(Kegiatan k) {
    final level = _currentUser?.pengurus?.level.toUpperCase();

    if (level == "RW") {
      return k.level == KegiatanLevel.rt;
    }

    if (level == "RT") {
      return k.level == KegiatanLevel.rw;
    }

    return true;
  }

  bool canEdit(Kegiatan k) {
    return !isReadonly(k) &&
        k.status == KegiatanStatus.dibuat &&
        k.tanggalMulai.isAfter(DateTime.now());
  }

  bool canCancel(Kegiatan k) => canEdit(k);

  bool canUploadBukti(Kegiatan k) {
    final selesai = k.tanggalSelesai ?? k.tanggalMulai;

    final sudahLewatTanggal = DateTime.now().isAfter(selesai);

    return !isReadonly(k) &&
        sudahLewatTanggal &&
        k.status == KegiatanStatus.dibuat &&
        k.imgReferensi == null;
  }

  bool isMenungguBukti(Kegiatan k) {
    final selesai = k.tanggalSelesai ?? k.tanggalMulai;

    return DateTime.now().isAfter(selesai) &&
        k.status == KegiatanStatus.dibuat &&
        k.imgReferensi == null;
  }

  bool isOngoing(Kegiatan k) {
    final now = DateTime.now();
    final end = k.tanggalSelesai ?? k.tanggalMulai;

    return k.status == KegiatanStatus.dibuat &&
        now.isAfter(k.tanggalMulai) &&
        now.isBefore(end);
  }

  int get totalSemua => filteredKegiatan.length;

  int get totalDibuat =>
      filteredKegiatan.where((e) => e.status == KegiatanStatus.dibuat).length;

  int get totalSelesai =>
      filteredKegiatan.where((e) => e.status == KegiatanStatus.selesai).length;

  int get totalDibatalkan => filteredKegiatan
      .where((e) => e.status == KegiatanStatus.dibatalkan)
      .length;

  String formatTanggal(Kegiatan k) {
    final start = DateFormat("dd MMM yyyy").format(k.tanggalMulai);

    final end = k.tanggalSelesai != null
        ? DateFormat("dd MMM yyyy").format(k.tanggalSelesai!)
        : null;

    return end == null ? start : "$start - $end";
  }

  Future<void> pickImage(int kegiatanId) async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    _selectedImages[kegiatanId] = File(picked.path);

    notifyListeners();
  }

  Future<void> pickDocument(int kegiatanId) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result == null) return;

    final path = result.files.single.path;

    if (path == null) return;

    _selectedDocuments[kegiatanId] = File(path);

    notifyListeners();
  }

  void clearFiles(int kegiatanId) {
    _selectedImages.remove(kegiatanId);
    _selectedDocuments.remove(kegiatanId);

    notifyListeners();
  }

  String? validateKegiatan({
    required int fileKey,
    required KegiatanValidationMode mode,
    required String nama,
    required String deskripsi,
    required DateTime? tanggalMulai,
    required DateTime? tanggalSelesai,

    Kegiatan? kegiatan,
  }) {
    if (nama.trim().isEmpty) {
      return "Nama kegiatan wajib diisi";
    }

    if (deskripsi.trim().isEmpty) {
      return "Deskripsi wajib diisi";
    }

    if (mode == KegiatanValidationMode.create ||
        mode == KegiatanValidationMode.edit) {
      if (tanggalMulai == null) {
        return "Tanggal mulai wajib diisi";
      }

      if (tanggalSelesai == null) {
        return "Tanggal selesai wajib diisi";
      }

      if (tanggalSelesai.isBefore(tanggalMulai)) {
        return "Tanggal selesai tidak boleh sebelum tanggal mulai";
      }
    }

    if (mode == KegiatanValidationMode.create) {
      if (_selectedDocuments[fileKey] == null) {
        return "Dokumen pendukung wajib diupload";
      }
    }

    if (mode == KegiatanValidationMode.uploadBukti) {
      if (kegiatan == null) {
        return "Data kegiatan tidak valid";
      }

      final selesai = kegiatan.tanggalSelesai ?? kegiatan.tanggalMulai;

      if (!DateTime.now().isAfter(selesai)) {
        return "Kegiatan belum selesai";
      }

      if (_selectedImages[fileKey] == null) {
        return "Foto bukti wajib diupload";
      }

      if (kegiatan.imgReferensi != null) {
        return "Bukti sudah pernah diupload";
      }
    }

    return null;
  }
}
