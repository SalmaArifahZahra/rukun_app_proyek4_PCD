import 'package:rukun_app_proyek4/models/rt_model.dart';

class RwModel {
  final int? id;
  final String noRw;
  final String kelurahanDesa;
  final String kecamatan;
  final String kabupatenKota;
  final String provinsi;
  final int saldoKas;

  final DateTime? waktuDibuat;
  final DateTime? waktuDiubah;
  final DateTime? waktuDihapus;
  final List<RtModel>? rtList;

  RwModel({
    this.id,
    required this.noRw,
    required this.kelurahanDesa,
    required this.kecamatan,
    required this.kabupatenKota,
    required this.provinsi,
    required this.saldoKas,
    this.waktuDibuat,
    this.waktuDiubah,
    this.waktuDihapus,
    this.rtList
  });

  factory RwModel.fromJson(Map<String, dynamic> json) {
    return RwModel(
      id: json['id'] as int?,
      noRw: json['no_rw'],
      kelurahanDesa: json['kelurahan_desa'],
      kecamatan: json['kecamatan'],
      kabupatenKota: json['kabupaten_kota'],
      provinsi: json['provinsi'],
      saldoKas: json['saldo_kas'],

      waktuDibuat: json['waktu_dibuat'] != null
          ? DateTime.tryParse(json['waktu_dibuat'])
          : null,
      waktuDiubah: json['waktu_diubah'] != null
          ? DateTime.parse(json['waktu_diubah'])
          : null,
      waktuDihapus: json['waktu_dihapus'] != null
          ? DateTime.parse(json['waktu_dihapus'])
          : null,
      rtList:
          (json['rt_list'] as List<dynamic>?)
              ?.map((e) => RtModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'no_rw': noRw,
      'kelurahan_desa': kelurahanDesa,
      'kecamatan': kecamatan,
      'kabupaten_kota': kabupatenKota,
      'provinsi': provinsi,
    };
  }
}
