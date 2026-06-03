class RtModel {
  final int? id;
  final String noRt;
  final int rwId;
  final int saldoKas;

  final String? ketua;
  final String? bendahara;
  final int? totalKeluarga;

  final DateTime? waktuDibuat;
  final DateTime? waktuDiubah;
  final DateTime? waktuDihapus;

  RtModel({
    this.id,
    required this.noRt,
    required this.rwId,
    required this.saldoKas,
    this.ketua,
    this.bendahara,
    this.totalKeluarga,
    this.waktuDibuat,
    this.waktuDiubah,
    this.waktuDihapus,
  });

  factory RtModel.fromJson(Map<String, dynamic> json) {
    return RtModel(
      id: json['id'],
      noRt: json['no_rt'],
      rwId: json['rw_id'],
      saldoKas: json['saldo_kas'],

      ketua: json['ketua'],
      bendahara: json['bendahara'],

      totalKeluarga: json['total_keluarga'] != null
          ? int.tryParse(json['total_keluarga'].toString())
          : null,

      waktuDibuat: json['waktu_dibuat'] != null
          ? DateTime.tryParse(json['waktu_dibuat'])
          : null,

      waktuDiubah: json['waktu_diubah'] != null
          ? DateTime.tryParse(json['waktu_diubah'])
          : null,

      waktuDihapus: json['waktu_dihapus'] != null
          ? DateTime.tryParse(json['waktu_dihapus'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'no_rt': noRt,
      'rw_id': rwId,
      'saldo_kas': saldoKas,
      'ketua': ketua,
      'bendahara': bendahara,
      'total_keluarga': totalKeluarga,
    };
  }
}
