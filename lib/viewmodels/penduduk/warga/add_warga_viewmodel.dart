import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rukun_app_proyek4/models/keluarga_model.dart';
import 'package:rukun_app_proyek4/models/warga_model.dart';
import 'package:rukun_app_proyek4/repositories/warga_repository.dart';
import 'package:rukun_app_proyek4/services/pcd/ktp_extraction_service.dart';

class AddWargaViewModel extends ChangeNotifier {
  final WargaRepository repo;

  bool isSaving = false;
  String? errorMessage;

  String nama = '';
  String nik = '';
  String tempatLahir = '';
  String noPaspor = '';
  String noKitap = '';
  String namaAyah = '';
  String namaIbu = '';

  String? jenisKelamin;
  String? agama;
  String? pendidikan;
  String? pekerjaan;
  String? golonganDarah;
  String? statusPerkawinan;
  String? kewarganegaraan;
  String? statusHubungan;

  String? negara;

  DateTime? tanggalLahir;
  DateTime? tanggalPerkawinan;

  // ── KTP Scan State ──
  bool isScanning = false;
  String? scanError;
  KTPExtractionResult? scanResult;
  String scanStatus = '';

  final int kkId;

  AddWargaViewModel({required this.repo, required this.kkId});

  // ── KTP Scan ──

  Future<void> scanKTP(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);

    if (picked == null) return;

    isScanning = true;
    scanError = null;
    scanStatus = 'Memproses gambar KTP...';
    notifyListeners();

    try {
      final service = KTPExtractionService();
      scanStatus = 'Menjalankan OCR...';
      notifyListeners();

      final result = await service.extractFromFile(File(picked.path));
      scanResult = result;

      if (result.isSuccess) {
        _applyExtractionResult(result);
        scanStatus = 'Ekstraksi KTP berhasil!';
      } else {
        scanStatus = 'Tidak dapat mengekstrak data dari gambar.';
        scanError = result.error ?? 'OCR tidak menemukan field KTP.';
      }
    } catch (e) {
      scanError = 'Gagal mengekstrak: ${e.toString().replaceAll("Exception: ", "")}';
      scanStatus = 'Ekstraksi gagal.';
    }

    isScanning = false;
    notifyListeners();
  }

  Future<void> retryScan() async {
    scanResult = null;
    scanError = null;
    notifyListeners();
  }

  void _applyExtractionResult(KTPExtractionResult result) {
    if (result.nik?.value != null) {
      nik = result.nik!.value!;
    }
    if (result.nama?.value != null) {
      nama = result.nama!.value!;
    }
    if (result.tempatLahir?.value != null) {
      tempatLahir = result.tempatLahir!.value!;
    }
    if (result.tanggalLahir?.value != null) {
      // Parse DD-MM-YYYY to DateTime
      final dateStr = result.tanggalLahir!.value!;
      final normalized = dateStr.replaceAll('/', '-');
      final parts = normalized.split('-');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          tanggalLahir = DateTime(year, month, day);
        }
      }
    }
    if (result.jenisKelamin?.value != null) {
      jenisKelamin = result.jenisKelamin!.value!;
    }
    if (result.golonganDarah?.value != null) {
      golonganDarah = result.golonganDarah!.value!;
    }
    if (result.agama?.value != null) {
      agama = result.agama!.value!;
    }
    if (result.statusPerkawinan?.value != null) {
      statusPerkawinan = result.statusPerkawinan!.value!;
    }
    if (result.pekerjaan?.value != null) {
      pekerjaan = result.pekerjaan!.value!;
    }
    if (result.kewarganegaraan?.value != null) {
      kewarganegaraan = result.kewarganegaraan!.value!;
    }
  }

  // ── Setters ──

  void setNama(String v) => _set(() => nama = v);
  void setNik(String v) => _set(() => nik = v);
  void setTempatLahir(String v) => _set(() => tempatLahir = v);

  void setJenisKelamin(String? v) => _set(() => jenisKelamin = v);
  void setAgama(String? v) => _set(() => agama = v);
  void setPendidikan(String? v) => _set(() => pendidikan = v);
  void setPekerjaan(String? v) => _set(() => pekerjaan = v);
  void setGolDarah(String? v) => _set(() => golonganDarah = v);
  void setStatusPerkawinan(String? v) => _set(() => statusPerkawinan = v);
  void setStatusHubungan(String? v) => _set(() => statusHubungan = v);

  void setKewarganegaraan(String? v) {
    kewarganegaraan = v;

    if (v != 'WNA') {
      negara = null;
    }

    notifyListeners();
  }

  void setNegara(String v) => _set(() => negara = v);

  void setTanggalLahir(DateTime v) => _set(() => tanggalLahir = v);
  void setTanggalPerkawinan(DateTime v) => _set(() => tanggalPerkawinan = v);

  void _set(Function fn) {
    fn();
    notifyListeners();
  }

  bool _validate() {
    if (nama.isEmpty) return _error("Nama wajib diisi");
    if (nik.isEmpty) return _error("NIK wajib diisi");
    if (jenisKelamin == null) return _error("Jenis kelamin wajib dipilih");

    return true;
  }

  bool _error(String msg) {
    errorMessage = msg;
    return false;
  }

  JenisKelamin? _jkEnum() {
    switch (jenisKelamin) {
      case 'Laki-Laki':
        return JenisKelamin.lakiLaki;
      case 'Perempuan':
        return JenisKelamin.perempuan;
    }
    return null;
  }

  Agama? _agamaEnum() {
    switch (agama) {
      case 'Islam':
        return Agama.islam;
      case 'Kristen':
        return Agama.kristen;
      case 'Katolik':
        return Agama.katolik;
      case 'Hindu':
        return Agama.hindu;
      case 'Buddha':
        return Agama.buddha;
      case 'Konghucu':
        return Agama.konghucu;
    }
    return null;
  }

  StatusPerkawinan? _statusKawinEnum() {
    switch (statusPerkawinan) {
      case 'Belum Kawin':
        return StatusPerkawinan.belumKawin;
      case 'Kawin':
        return StatusPerkawinan.kawin;
      case 'Cerai Hidup':
        return StatusPerkawinan.ceraiHidup;
      case 'Cerai Mati':
        return StatusPerkawinan.ceraiMati;
    }
    return null;
  }

  StatusHubungan? _statusHubunganEnum() {
    switch (statusHubungan) {
      case 'Kepala Keluarga':
        return StatusHubungan.kepalaKeluarga;
      case 'Suami':
        return StatusHubungan.suami;
      case 'Istri':
        return StatusHubungan.istri;
      case 'Anak':
        return StatusHubungan.anak;
      case 'Menantu':
        return StatusHubungan.menantu;
      case 'Cucu':
        return StatusHubungan.cucu;
      case 'Orang Tua':
        return StatusHubungan.orangTua;
      case 'Mertua':
        return StatusHubungan.mertua;
      case 'Famili Lain':
        return StatusHubungan.familiLain;
    }
    return null;
  }

  Kewarganegaraan? _kwnEnum() {
    switch (kewarganegaraan) {
      case 'WNI':
        return Kewarganegaraan.wni;
      case 'WNA':
        return Kewarganegaraan.wna;
    }
    return null;
  }

  String? _nullable(String v) {
    return v.trim().isEmpty ? null : v;
  }

  Future<bool> saveWarga(Keluarga kel) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (!_validate()) throw Exception(errorMessage);

      final warga = Warga(
        nama: nama,
        nik: nik,
        jk: _jkEnum(),
        tempatLahir: _nullable(tempatLahir),
        tglLahir: tanggalLahir,
        agama: _agamaEnum(),
        pendidikan: _nullable(pendidikan ?? ''),
        jenisPekerjaan: _nullable(pekerjaan ?? ''),
        golonganDarah: _nullable(golonganDarah ?? ''),
        statusPerkawinan: _statusKawinEnum(),
        tglPerkawinan: tanggalPerkawinan,
        statusHubungan: _statusHubunganEnum(),
        kewarganegaraan: _kwnEnum(),
        wnaNegara: _nullable(negara ?? ''),
        noPaspor: _nullable(noPaspor),
        noKitap: _nullable(noKitap),
        namaAyah: _nullable(namaAyah),
        namaIbu: _nullable(namaIbu),
        keluarga: kel,
      );

      await repo.createWarga(warga);

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
