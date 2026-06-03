import 'package:rukun_app_proyek4/models/kegiatan_model.dart';
import 'package:rukun_app_proyek4/models/rt_model.dart';
import 'package:rukun_app_proyek4/models/rw_model.dart';

class DashboardModel {
  final RtModel? rt;
  final RwModel? rw;
  final int totalPenduduk;

  final GenderStat gender;
  final AgeDistribution ageDistribution;

  final int jumlahKk;
  final int? jumlahRt;

  final List<PendudukPerRT>? pendudukPerRt;

  final StatusSurat statusSurat;
  final List<Kegiatan> kegiatan;

  final KasSummary? kas;

  DashboardModel({
    this.rt,
    this.rw,
    required this.totalPenduduk,
    required this.gender,
    required this.ageDistribution,
    required this.jumlahKk,
    this.jumlahRt,
    this.pendudukPerRt,
    required this.statusSurat,
    required this.kegiatan,
    this.kas,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      rt: json['rt'] != null ? RtModel.fromJson(json['rt']) : null,
      rw: json['rw'] != null ? RwModel.fromJson(json['rw']) : null,

      totalPenduduk: (json['total_penduduk'] as num?)?.toInt() ?? 0,
      jumlahKk: (json['jumlah_kk'] as num?)?.toInt() ?? 0,

      gender: GenderStat.fromJson(json['gender'] ?? {}),

      ageDistribution: AgeDistribution.fromJson(json['age_distribution'] ?? {}),

      jumlahRt: json['jumlah_rt'] != null
          ? (json['jumlah_rt'] as num).toInt()
          : null,

      pendudukPerRt: (json['penduduk_per_rt'] as List?)
          ?.map((e) => PendudukPerRT.fromJson(e as Map<String, dynamic>))
          .toList(),

      statusSurat: StatusSurat.fromJson(json['status_surat'] ?? {}),

      kegiatan: (json['kegiatan'] as List? ?? [])
          .map((e) => Kegiatan.fromJson(e))
          .toList(),

      kas: json['kas'] != null ? KasSummary.fromJson(json['kas']) : null,
    );
  }
}

class GenderStat {
  final int pria;
  final int wanita;

  GenderStat({required this.pria, required this.wanita});

  factory GenderStat.fromJson(Map<String, dynamic> json) {
    return GenderStat(pria: json['pria'] ?? 0, wanita: json['wanita'] ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'pria': pria, 'wanita': wanita};
  }
}

class AgeDistribution {
  final int anak;
  final int produktif;
  final int lansia;

  AgeDistribution({
    required this.anak,
    required this.produktif,
    required this.lansia,
  });

  factory AgeDistribution.fromJson(Map<String, dynamic> json) {
    return AgeDistribution(
      anak: json['anak'] ?? 0,
      produktif: json['produktif'] ?? 0,
      lansia: json['lansia'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'anak': anak, 'produktif': produktif, 'lansia': lansia};
  }
}

class StatusSurat {
  final int total;
  final int diajukan;
  final int disetujui;
  final int selesai;
  final int ditolak;

  StatusSurat({
    required this.total,
    required this.diajukan,
    required this.disetujui,
    required this.selesai,
    required this.ditolak,
  });

  factory StatusSurat.fromJson(Map<String, dynamic> json) {
    return StatusSurat(
      total: json['total'] ?? 0,
      diajukan: json['diajukan'] ?? 0,
      disetujui: json['disetujui'] ?? 0,
      selesai: json['selesai'] ?? 0,
      ditolak: json['ditolak'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'diajukan': diajukan,
      'disetujui': disetujui,
      'selesai': selesai,
      'ditolak': ditolak,
    };
  }
}

class PendudukPerRT {
  final int rtId;
  final String noRt;
  final int totalWarga;

  PendudukPerRT({
    required this.rtId,
    required this.noRt,
    required this.totalWarga,
  });

  factory PendudukPerRT.fromJson(Map<String, dynamic> json) {
    return PendudukPerRT(
      rtId: json['rt_id'] ?? 0,
      noRt: json['no_rt'] ?? '',
      totalWarga: json['total_warga'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'rt_id': rtId, 'no_rt': noRt, 'total_warga': totalWarga};
  }
}

class KasSummary {
  final int totalMasuk;
  final int totalKeluar;

  KasSummary({required this.totalMasuk, required this.totalKeluar});

  factory KasSummary.fromJson(Map<String, dynamic> json) {
    return KasSummary(
      totalMasuk: (json['total_masuk'] as num?)?.toInt() ?? 0,
      totalKeluar: (json['total_keluar'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'total_masuk': totalMasuk, 'total_keluar': totalKeluar};
  }

  int get saldoBersih => totalMasuk - totalKeluar;
}
