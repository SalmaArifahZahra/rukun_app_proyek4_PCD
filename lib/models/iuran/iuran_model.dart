import 'package:rukun_app_proyek4/models/rt_model.dart';
import 'package:rukun_app_proyek4/models/rw_model.dart';
import 'package:rukun_app_proyek4/models/transaksi_model.dart';

enum IuranLevel { rt, rw }

enum IuranType { reguler, insidentil }

class Iuran {
  final int? id;
  final String nama;
  final int? jumlah;
  final IuranLevel level;
  final RtModel? rt;
  final RwModel? rw;
  final IuranType tipe;
  final bool? isActive;
  final String? syncStatus;
  final int? clientTempId;
  final DateTime? waktuDibuat;
  final DateTime? waktuDiubah;
  final DateTime? waktuDihapus;
  final int? totalTerkumpul;
  final List<Transaksi>? transaksi;

  Iuran({
    this.id,
    required this.nama,
    this.jumlah,
    required this.level,
    this.rt,
    this.rw,
    required this.tipe,
    this.isActive,
    this.syncStatus,
    this.clientTempId,
    this.waktuDibuat,
    this.waktuDiubah,
    this.waktuDihapus,
    this.totalTerkumpul,
    this.transaksi,
  });

  factory Iuran.fromJson(Map<String, dynamic> json) {
    return Iuran(
      id: json['id'],
      nama: json['nama']?.toString() ?? '',
      jumlah: json['jumlah'] != null
          ? int.tryParse(json['jumlah'].toString())
          : null,
      level: _level(json['level']),
      rt: json['rt'] != null ? RtModel.fromJson(json['rt']) : null,
      rw: json['rw'] != null ? RwModel.fromJson(json['rw']) : null,
      tipe: _type(json['tipe']),
      isActive: json['is_active'],
      syncStatus: json['sync_status'] as String?,
      clientTempId: (json['client_temp_id'] as num?)?.toInt(),
      waktuDibuat: json['waktu_dibuat'] != null
          ? DateTime.tryParse(json['waktu_dibuat'].toString())
          : null,
      waktuDiubah: json['waktu_diubah'] != null
          ? DateTime.tryParse(json['waktu_diubah'].toString())
          : null,
      waktuDihapus: json['waktu_dihapus'] != null
          ? DateTime.tryParse(json['waktu_dihapus'].toString())
          : null,
      totalTerkumpul: json['total_terkumpul'],
      transaksi: json['transaksi'] != null
          ? (json['transaksi'] as List)
                .map((e) => Transaksi.fromJson(e))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'nama': nama,
      'jumlah': jumlah,
      'level': level == IuranLevel.rt ? 'RT' : 'RW',
      'rt_id': rt?.id,
      'rw_id': rw?.id,
      'tipe': tipe.name,
      'is_active': isActive,
      'sync_status': syncStatus,
      'client_temp_id': clientTempId,
    };

    if (id != null) {
      data['id'] = id;
    }

    if (rt != null) {
      data['rt'] = rt!.toJson();
    }

    if (rw != null) {
      data['rw'] = rw!.toJson();
    }

    return data;
  }

  static IuranLevel _level(dynamic v) {
    final value = v?.toString().toUpperCase();
    if (value == "RT") return IuranLevel.rt;
    return IuranLevel.rw;
  }

  static IuranType _type(dynamic v) {
    final value = v?.toString().toLowerCase();
    if (value == "reguler") return IuranType.reguler;
    return IuranType.insidentil;
  }

  bool get isPendingSync => syncStatus == 'pending';
}
