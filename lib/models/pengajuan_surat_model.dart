import 'package:rukun_app_proyek4/models/rt_model.dart';

enum SuratStatus { diajukan, disetujui, ditolak, selesai }

extension SuratStatusX on SuratStatus {
  String get value {
    switch (this) {
      case SuratStatus.diajukan:
        return "Diajukan";
      case SuratStatus.disetujui:
        return "Disetujui";
      case SuratStatus.ditolak:
        return "Ditolak";
      case SuratStatus.selesai:
        return "Selesai";
    }
  }
}

class PengajuanSurat {
  final int? id;
  final int? wargaId;
  final int? rtId;
  final String keperluan;
  final String? keterangan;
  final SuratStatus status;
  final String? docRef;
  final String? catatan;
  final int? disetujuiOleh;
  final DateTime? waktuDisetujui;
  final bool isSigned;
  final String? syncStatus;
  final int? clientTempId;
  final DateTime? waktuDibuat;
  final DateTime? waktuDiubah;
  final DateTime? waktuDihapus;
  final RtModel? rt;

  const PengajuanSurat({
    this.id,
    this.wargaId,
    this.rtId,
    required this.keperluan,
    this.keterangan,
    this.status = SuratStatus.diajukan,
    this.disetujuiOleh,
    this.docRef,
    this.catatan,
    this.waktuDisetujui,
    this.isSigned = false,
    this.syncStatus,
    this.clientTempId,
    this.waktuDibuat,
    this.waktuDiubah,
    this.waktuDihapus,
    this.rt,
  });

  PengajuanSurat copyWith({
    int? id,
    int? wargaId,
    int? rtId,
    String? keperluan,
    String? keterangan,
    SuratStatus? status,
    String? docRef,
    String? catatan,
    int? disetujuiOleh,
    DateTime? waktuDisetujui,
    bool? isSigned,
    String? syncStatus,
    int? clientTempId,
    DateTime? waktuDibuat,
    DateTime? waktuDiubah,
    DateTime? waktuDihapus,
    RtModel? rt,
  }) {
    return PengajuanSurat(
      id: id ?? this.id,
      wargaId: wargaId ?? this.wargaId,
      rtId: rtId ?? this.rtId,
      keperluan: keperluan ?? this.keperluan,
      keterangan: keterangan ?? this.keterangan,
      status: status ?? this.status,
      docRef: docRef ?? this.docRef,
      catatan: catatan ?? this.catatan,
      disetujuiOleh: disetujuiOleh ?? this.disetujuiOleh,
      waktuDisetujui: waktuDisetujui ?? this.waktuDisetujui,
      isSigned: isSigned ?? this.isSigned,
      syncStatus: syncStatus ?? this.syncStatus,
      clientTempId: clientTempId ?? this.clientTempId,
      waktuDibuat: waktuDibuat ?? this.waktuDibuat,
      waktuDiubah: waktuDiubah ?? this.waktuDiubah,
      waktuDihapus: waktuDihapus ?? this.waktuDihapus,
      rt: rt ?? this.rt,
    );
  }

  factory PengajuanSurat.fromJson(Map<String, dynamic> json) {
    return PengajuanSurat(
      id: json['id'],
      wargaId: json['warga_id'],
      rtId: json['rt_id'],
      keperluan: json['keperluan'],
      keterangan: json['keterangan'],
      status: _status(json['status']),
      docRef: json['doc_referensi'],
      catatan: json['catatan'],
      disetujuiOleh: json['disetujui_oleh'],
      waktuDisetujui: json['waktu_disetujui'] != null
          ? DateTime.parse(json['waktu_disetujui'])
          : null,
      isSigned: json['is_signed'] ?? false,
      syncStatus: json['sync_status'] as String?,
      clientTempId: (json['client_temp_id'] as num?)?.toInt(),
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'warga_id': wargaId,
      'rt_id': rtId,
      'keperluan': keperluan,
      'keterangan': keterangan,
      'status': _statusToString(status),
      'doc_referensi': docRef,
      'catatan': catatan,
      'disetujui_oleh': disetujuiOleh,
      'waktu_disetujui': waktuDisetujui?.toIso8601String(),
      'is_signed': isSigned,
      'sync_status': syncStatus,
      'client_temp_id': clientTempId,
      'waktu_dibuat': waktuDibuat?.toIso8601String(),
      'waktu_diubah': waktuDiubah?.toIso8601String(),
      'waktu_dihapus': waktuDihapus?.toIso8601String(),
    };
  }

  static SuratStatus _status(String? v) {
    switch (v?.toLowerCase()) {
      case "disetujui":
        return SuratStatus.disetujui;

      case "ditolak":
        return SuratStatus.ditolak;

      case "selesai":
        return SuratStatus.selesai;

      default:
        return SuratStatus.diajukan;
    }
  }

  static String _statusToString(SuratStatus status) {
    switch (status) {
      case SuratStatus.diajukan:
        return "Diajukan";

      case SuratStatus.disetujui:
        return "Disetujui";

      case SuratStatus.ditolak:
        return "Ditolak";

      case SuratStatus.selesai:
        return "Selesai";
    }
  }

  bool get isPendingSync => syncStatus == 'pending';
}
