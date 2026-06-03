import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:rukun_app_proyek4/models/kegiatan_model.dart';

enum KegiatanFilterStatus { semua, dibuat, dibatalkan, selesai }

class KegiatanRtViewModel extends ChangeNotifier {
  File? buktiImage;
  File? dokumenFile;

  bool isUploading = false;
  KegiatanLevel selectedLevel = KegiatanLevel.rt;
  KegiatanFilterStatus selectedStatus = KegiatanFilterStatus.semua;

  //dummy data kegiatan RT
  final List<Kegiatan> _allData = [
    Kegiatan(
      id: 1,
      nama: "Kerja Bakti RT 04",
      deskripsi: "Pembersihan saluran air dan lingkungan sekitar RT 04",
      tanggalMulai: DateTime.now().add(const Duration(days: 1)),
      tanggalSelesai: DateTime.now().add(const Duration(days: 1)),
      level: KegiatanLevel.rt,
      rtId: 4,
      rwId: 2,
      status: KegiatanStatus.dibuat,
      docReferensi: "proposal_rt04.pdf",
    ),

    Kegiatan(
      id: 2,
      nama: "Posyandu RT 04",
      deskripsi: "Pemeriksaan kesehatan lansia dan balita khusus RT 04",
      tanggalMulai: DateTime.now().subtract(const Duration(days: 4)),
      tanggalSelesai: DateTime.now().subtract(const Duration(days: 4)),
      level: KegiatanLevel.rt,
      rtId: 4,
      rwId: 2,
      status: KegiatanStatus.selesai,
      docReferensi: "laporan_posyandu.pdf",
      imgReferensi: "foto_posyandu.png",
    ),

    Kegiatan(
      id: 3,
      nama: "Rapat Bulanan Warga RT",
      deskripsi: "Membahas keuangan kas RT dan jadwal ronda",
      tanggalMulai: DateTime.now().subtract(const Duration(days: 1)),
      tanggalSelesai: DateTime.now().subtract(const Duration(days: 1)),
      level: KegiatanLevel.rt,
      rtId: 4,
      rwId: 2,
      status: KegiatanStatus.dibatalkan,
      docReferensi: "undangan_rapat.pdf",
    ),

    Kegiatan(
      id: 4,
      nama: "Pelatihan UMKM Warga Cermat (RW)",
      deskripsi:
          "Pelatihan pengembangan usaha warga RW untuk meningkatkan pemasukan UMKM lokal",
      tanggalMulai: DateTime.now().add(const Duration(days: 3)),
      tanggalSelesai: DateTime.now().add(const Duration(days: 5)),
      level: KegiatanLevel.rw,
      rwId: 2,
      status: KegiatanStatus.dibuat,
      docReferensi: "proposal_umkm.pdf",
    ),
  ];

  List<Kegiatan> get data {
    return _allData.where((e) {
      final sameLevel = e.level == selectedLevel;

      bool sameStatus = true;

      switch (selectedStatus) {
        case KegiatanFilterStatus.semua:
          sameStatus = true;
          break;

        case KegiatanFilterStatus.dibuat:
          sameStatus = e.status == KegiatanStatus.dibuat;
          break;

        case KegiatanFilterStatus.dibatalkan:
          sameStatus = e.status == KegiatanStatus.dibatalkan;
          break;

        case KegiatanFilterStatus.selesai:
          sameStatus = e.status == KegiatanStatus.selesai;
          break;
      }

      final nama = e.nama.toLowerCase();

      final deskripsi = (e.deskripsi ?? "").toLowerCase();

      final q = _search.toLowerCase();

      final matchSearch = nama.contains(q) || deskripsi.contains(q);

      return sameLevel && sameStatus && matchSearch;
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

  bool isReadonly(Kegiatan kegiatan) {
    return kegiatan.level == KegiatanLevel.rw;
  }

  bool canEdit(Kegiatan kegiatan) {
    if (isReadonly(kegiatan)) return false;

    return kegiatan.status == KegiatanStatus.dibuat &&
        kegiatan.tanggalMulai.isAfter(DateTime.now());
  }

  bool canCancel(Kegiatan kegiatan) {
    return canEdit(kegiatan);
  }

  bool canUploadBukti(Kegiatan kegiatan) {
    if (isReadonly(kegiatan)) return false;

    final selesai = kegiatan.tanggalSelesai ?? kegiatan.tanggalMulai;

    final sudahSelesai = DateTime.now().isAfter(selesai);

    return sudahSelesai &&
        kegiatan.status == KegiatanStatus.selesai &&
        kegiatan.imgReferensi == null;
  }

  bool isFinished(Kegiatan kegiatan) {
    return kegiatan.status == KegiatanStatus.selesai;
  }

  int get totalSemua => _allData.length;

  int get totalDibuat =>
      data.where((e) => e.status == KegiatanStatus.dibuat).length;

  int get totalDibatalkan =>
      data.where((e) => e.status == KegiatanStatus.dibatalkan).length;

  int get totalSelesai =>
      data.where((e) => e.status == KegiatanStatus.selesai).length;

  Future<void> refresh() async {
    await Future.delayed(const Duration(milliseconds: 700));

    notifyListeners();
  }

  String _search = "";

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  bool isOngoing(Kegiatan kegiatan) {
    final now = DateTime.now();

    final selesai = kegiatan.tanggalSelesai ?? kegiatan.tanggalMulai;

    return kegiatan.status == KegiatanStatus.dibuat &&
        now.isAfter(kegiatan.tanggalMulai) &&
        now.isBefore(selesai);
  }

  void updateKegiatan({
    required int id,
    required String nama,
    required String deskripsi,
    required DateTime tanggalMulai,
    DateTime? tanggalSelesai,
  }) {
    final index = _allData.indexWhere((e) => e.id == id);

    if (index == -1) return;

    final old = _allData[index];

    _allData[index] = Kegiatan(
      id: old.id,
      nama: nama,
      deskripsi: deskripsi,
      tanggalMulai: tanggalMulai,
      tanggalSelesai: tanggalSelesai,
      level: old.level,
      rtId: old.rtId,
      rwId: old.rwId,
      status: old.status,
      docReferensi: dokumenFile?.path.split("/").last ?? old.docReferensi,
      imgReferensi: buktiImage?.path.split("/").last ?? old.imgReferensi,
    );

    notifyListeners();
  }

  Future<void> uploadDummyBukti(int id) async {
    if (buktiImage == null) return;

    isUploading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    final index = _allData.indexWhere((e) => e.id == id);

    if (index == -1) {
      isUploading = false;
      notifyListeners();
      return;
    }

    final kegiatan = _allData[index];

    _allData[index] = Kegiatan(
      id: kegiatan.id,
      nama: kegiatan.nama,
      deskripsi: kegiatan.deskripsi,
      tanggalMulai: kegiatan.tanggalMulai,
      tanggalSelesai: kegiatan.tanggalSelesai,
      level: kegiatan.level,
      rtId: kegiatan.rtId,
      rwId: kegiatan.rwId,
      status: kegiatan.status,
      docReferensi: dokumenFile?.path.split("/").last ?? kegiatan.docReferensi,
      imgReferensi: buktiImage?.path.split("/").last ?? kegiatan.imgReferensi,
    );

    clearUpload();

    isUploading = false;

    notifyListeners();
  }

  void createKegiatan({
    required String nama,
    required String deskripsi,
    required DateTime tanggalMulai,
    DateTime? tanggalSelesai,
  }) {
    final kegiatan = Kegiatan(
      id: _allData.length + 1,
      nama: nama,
      deskripsi: deskripsi,
      tanggalMulai: tanggalMulai,
      tanggalSelesai: tanggalSelesai,
      level: KegiatanLevel.rt,
      rtId: 4,
      rwId: 2,
      status: KegiatanStatus.dibuat,
      docReferensi: dokumenFile?.path.split("/").last,
      imgReferensi: buktiImage?.path.split("/").last,
      waktuDibuat: DateTime.now(),
    );

    _allData.insert(0, kegiatan);

    notifyListeners();
  }

  String? validateCreateKegiatan({
    required String nama,
    required String deskripsi,
    required DateTime? tanggalMulai,
    required DateTime? tanggalSelesai,
  }) {
    if (nama.trim().isEmpty) {
      return "Nama kegiatan wajib diisi";
    }

    if (deskripsi.trim().isEmpty) {
      return "Deskripsi wajib diisi";
    }

    if (tanggalMulai == null) {
      return "Tanggal mulai wajib diisi";
    }

    if (tanggalSelesai == null) {
      return "Tanggal selesai wajib diisi";
    }

    if (dokumenFile == null) {
      return "Dokumen pendukung wajib diupload";
    }

    if (tanggalSelesai.isBefore(tanggalMulai)) {
      return "Tanggal selesai tidak boleh sebelum tanggal mulai";
    }

    return null;
  }

  String? validateEditKegiatan({
    required Kegiatan kegiatan,
    required String nama,
    required String deskripsi,
    required DateTime? tanggalMulai,
    required DateTime? tanggalSelesai,
    required bool wajibFoto,
  }) {
    if (nama.trim().isEmpty) {
      return "Nama kegiatan wajib diisi";
    }

    if (deskripsi.trim().isEmpty) {
      return "Deskripsi wajib diisi";
    }

    if (tanggalMulai == null) {
      return "Tanggal mulai wajib diisi";
    }

    if (tanggalSelesai == null) {
      return "Tanggal selesai wajib diisi";
    }

    final hasDokumen = dokumenFile != null || kegiatan.docReferensi != null;

    if (!hasDokumen) {
      return "Dokumen pendukung wajib diupload";
    }

    if (tanggalSelesai.isBefore(tanggalMulai)) {
      return "Tanggal selesai tidak boleh sebelum tanggal mulai";
    }

    final hasFoto = buktiImage != null || kegiatan.imgReferensi != null;

    if (wajibFoto && !hasFoto) {
      return "Foto kegiatan wajib diupload";
    }

    return null;
  }

  String formatTanggalRange(Kegiatan kegiatan) {
    final mulai = DateFormat("dd MMM yyyy").format(kegiatan.tanggalMulai);

    final selesai = kegiatan.tanggalSelesai != null
        ? DateFormat("dd MMM yyyy").format(kegiatan.tanggalSelesai!)
        : null;

    if (selesai == null) {
      return mulai;
    }

    return "$mulai - $selesai";
  }

  Future<void> pickBuktiImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    buktiImage = File(picked.path);

    notifyListeners();
  }

  Future<void> pickDokumenFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result == null) return;

    dokumenFile = File(result.files.single.path!);

    notifyListeners();
  }

  void clearUpload() {
    buktiImage = null;
    dokumenFile = null;

    notifyListeners();
  }
}
