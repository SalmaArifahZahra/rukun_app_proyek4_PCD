class Keluarga {
  final int? id;
  final String noKK;
  final int rtId;
  final String? alamat;
  final String? kodePos;
  final String? desa;
  final String? kecamatan;
  final String? imgRef;
  final DateTime? waktuDibuat;
  final DateTime? waktuDiubah;
  final DateTime? waktuDihapus;

  Keluarga({
    this.id,
    required this.noKK,
    required this.rtId,
    this.alamat,
    this.kodePos,
    this.desa,
    this.kecamatan,
    this.imgRef,
    this.waktuDibuat,
    this.waktuDiubah,
    this.waktuDihapus,
  });

  factory Keluarga.fromJson(Map<String, dynamic> json) {
    return Keluarga(
      id: json['id'] as int?,
      noKK: json['no_kk'] ?? '',
      rtId: json['rt_id'] ?? 0,
      alamat: json['alamat'],
      kodePos: json['kode_pos'],
      desa: json['desa'],
      kecamatan: json['kecamatan'],
      imgRef: json['img_referensi'],
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
      'no_kk': noKK,
      'rt_id': rtId,
      'alamat': alamat,
      'kode_pos': kodePos,
      'desa': desa,
      'kecamatan': kecamatan,
      'img_referensi': imgRef,
    };
  }

  Keluarga copyWith({
    int? id,
    String? noKK,
    int? rtId,
    String? alamat,
    String? kodePos,
    String? desa,
    String? kecamatan,
    String? imgRef,
  }) {
    return Keluarga(
      id: id ?? this.id,
      noKK: noKK ?? this.noKK,
      rtId: rtId ?? this.rtId,
      alamat: alamat ?? this.alamat,
      kodePos: kodePos ?? this.kodePos,
      desa: desa ?? this.desa,
      kecamatan: kecamatan ?? this.kecamatan,
      imgRef: imgRef ?? this.imgRef,
    );
  }
}
