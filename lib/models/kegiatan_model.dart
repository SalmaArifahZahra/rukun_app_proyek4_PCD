import 'package:rukun_app_proyek4/models/rt_model.dart';
import 'package:rukun_app_proyek4/models/rw_model.dart';

enum KegiatanLevel { rt, rw }

enum KegiatanStatus { dibuat, dibatalkan, selesai }

extension KegiatanStatusX on KegiatanStatus {
  String get label {
    switch (this) {
      case KegiatanStatus.dibuat:
        return "Dibuat";
      case KegiatanStatus.dibatalkan:
        return "Dibatalkan";
      case KegiatanStatus.selesai:
        return "Selesai";
    }
  }
}

class Kegiatan {
  final int? id;
  final String nama;
  final String? deskripsi;
  final DateTime tanggalMulai;
  final DateTime? tanggalSelesai;
  final KegiatanLevel level;
  final int? rtId;
  final int? rwId;
  final KegiatanStatus status;
  final String? imgReferensi;
  final String? docReferensi;
  final DateTime? waktuDibuat;
  final DateTime? waktuDiubah;
  final DateTime? waktuDihapus;
  final RtModel? rt;
  final RwModel? rw;

  Kegiatan({
    this.id,
    required this.nama,
    this.deskripsi,
    required this.tanggalMulai,
    this.tanggalSelesai,
    required this.level,
    this.rtId,
    this.rwId,
    required this.status,
    this.imgReferensi,
    this.docReferensi,
    this.waktuDibuat,
    this.waktuDiubah,
    this.waktuDihapus,
    this.rt,
    this.rw,
  });

  factory Kegiatan.fromJson(Map<String, dynamic> json) {
    return Kegiatan(
      id: json['id'],
      nama: json['nama'],
      deskripsi: json['deskripsi'],
      tanggalMulai: DateTime.parse(json['tanggal_mulai']),
      tanggalSelesai: json['tanggal_selesai'] != null
          ? DateTime.parse(json['tanggal_selesai'])
          : null,
      level: _level(json['level']),
      rtId: json['rt_id'],
      rwId: json['rw_id'],
      status: _status(json['status']),
      imgReferensi: json['img_referensi'],
      docReferensi: json['doc_referensi'],
      waktuDibuat: json['waktu_dibuat'] != null
          ? DateTime.parse(json['waktu_dibuat'])
          : null,
      waktuDiubah: json['waktu_diubah'] != null
          ? DateTime.parse(json['waktu_diubah'])
          : null,
      waktuDihapus: json['waktu_dihapus'] != null
          ? DateTime.parse(json['waktu_dihapus'])
          : null,
      rt: json['rt'] != null ? RtModel.fromJson(json['rt']) : null,
      rw: json['rw'] != null ? RwModel.fromJson(json['rw']) : null,
    );
  }

  Map<String, dynamic> toJson({bool includeNull = false}) {
    final data = {
      'nama': nama,
      'deskripsi': deskripsi,
      'tanggal_mulai': tanggalMulai.toIso8601String(),
      'tanggal_selesai': tanggalSelesai?.toIso8601String(),
      'level': level == KegiatanLevel.rt ? 'RT' : 'RW',
      'rt_id': rtId,
      'rw_id': rwId,
      'status': _statusToString(status),
    };

    if (includeNull) {
      data['img_referensi'] = imgReferensi;
      data['doc_referensi'] = docReferensi;
    } else {
      if (imgReferensi != null) data['img_referensi'] = imgReferensi;
      if (docReferensi != null) data['doc_referensi'] = docReferensi;
    }

    if (id != null) data['id'] = id;

    return data;
  }

  bool get isBerlangsung {
    final now = DateTime.now();
    if (status != KegiatanStatus.dibuat) return false;
    if (tanggalSelesai == null) return now.isAfter(tanggalMulai);
    return now.isAfter(tanggalMulai) && now.isBefore(tanggalSelesai!);
  }

  static KegiatanLevel _level(String v) {
    switch (v.toUpperCase()) {
      case "RT":
        return KegiatanLevel.rt;
      case "RW":
        return KegiatanLevel.rw;
      default:
        return KegiatanLevel.rw;
    }
  }

  static KegiatanStatus _status(String v) {
    switch (v.toLowerCase()) {
      case "dibuat":
        return KegiatanStatus.dibuat;
      case "dibatalkan":
      case "ditunda":
        return KegiatanStatus.dibatalkan;
      case "selesai":
        return KegiatanStatus.selesai;
      default:
        return KegiatanStatus.dibuat;
    }
  }

  static String _statusToString(KegiatanStatus status) {
    switch (status) {
      case KegiatanStatus.dibuat:
        return "Dibuat";
      case KegiatanStatus.dibatalkan:
        return "Dibatalkan";
      case KegiatanStatus.selesai:
        return "Selesai";
    }
  }
}
