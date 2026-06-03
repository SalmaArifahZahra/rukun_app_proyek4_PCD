import 'package:rukun_app_proyek4/models/keluarga_model.dart';
import 'package:rukun_app_proyek4/models/pengurus_model.dart';
import 'package:rukun_app_proyek4/models/rt_model.dart';
import 'package:rukun_app_proyek4/models/rw_model.dart';
import 'package:rukun_app_proyek4/models/warga_model.dart';

class User {
  final int id;
  final int wargaId;
  final bool? isAdmin;
  final Warga? warga;
  final Keluarga? keluarga;
  final RtModel? rt;
  final RwModel? rw;
  final Pengurus? pengurus;
  final DateTime? waktuDibuat;
  final DateTime? waktuDiubah;
  final DateTime? waktuDihapus;

  User({
    required this.id,
    required this.wargaId,
    this.isAdmin,
    this.warga,
    this.keluarga,
    this.rt,
    this.rw,
    this.pengurus,
    this.waktuDibuat,
    this.waktuDiubah,
    this.waktuDihapus,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      wargaId: json['warga_id'],
      isAdmin: json['is_admin'],
      warga: json['warga'] != null ? Warga.fromJson(json['warga']) : null,
      keluarga: json['keluarga'] != null
          ? Keluarga.fromJson(json['keluarga'])
          : null,
      rt: json['rt'] != null ? RtModel.fromJson(json['rt']) : null,
      rw: json['rw'] != null ? RwModel.fromJson(json['rw']) : null,
      pengurus: json['pengurus'] != null
          ? Pengurus.fromJson(json['pengurus'])
          : null,

      waktuDibuat: json['waktu_dibuat'] != null
          ? DateTime.parse(json['waktu_dibuat'])
          : null,
      waktuDiubah: json['waktu_diubah'] != null
          ? DateTime.parse(json['waktu_diubah'])
          : null,
      waktuDihapus: json['waktu_dihapus'] != null
          ? DateTime.parse(json['waktu_dihapus'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'warga_id': wargaId, 'is_admin': isAdmin};
  }

  @override
  String toString() {
    return '''
User(
  id: $id,
  wargaId: $wargaId,
  isAdmin: $isAdmin,
  nama: ${warga?.nama},
  rw: ${rw?.id},
  rt: ${rt?.id},
  pengurus: ${pengurus?.level}
)
''';
  }
}
