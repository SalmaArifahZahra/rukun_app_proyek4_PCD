enum KasLevel {
  rt,
  rw;

  String get display {
    switch (this) {
      case KasLevel.rt:
        return 'RT';
      case KasLevel.rw:
        return 'RW';
    }
  }

  static KasLevel? from(String? value) {
    switch (value) {
      case 'RT':
      case 'rt':
        return KasLevel.rt;
      case 'RW':
      case 'rw':
        return KasLevel.rw;
      default:
        return null;
    }
  }
}

enum KasTipe {
  masuk,
  keluar;

  String get display {
    switch (this) {
      case KasTipe.masuk:
        return 'Masuk';
      case KasTipe.keluar:
        return 'Keluar';
    }
  }

  static KasTipe? from(String? value) {
    switch (value) {
      case 'masuk':
      case 'Masuk':
        return KasTipe.masuk;
      case 'keluar':
      case 'Keluar':
        return KasTipe.keluar;
      default:
        return null;
    }
  }
}

class KasMutasi {
  final int? id;

  final KasLevel? level;
  final int? rtId;
  final int? rwId;

  final KasTipe? tipe;
  final int? nominal;

  final String? keterangan;

  final DateTime? waktuDibuat;
  final DateTime? waktuDiubah;
  final DateTime? waktuDihapus;

  KasMutasi({
    this.id,
    this.level,
    this.rtId,
    this.rwId,
    this.tipe,
    this.nominal,
    this.keterangan,
    this.waktuDibuat,
    this.waktuDiubah,
    this.waktuDihapus,
  });

  factory KasMutasi.fromJson(Map<String, dynamic> json) {
    return KasMutasi(
      id: json['id'] as int?,
      level: KasLevel.from(json['level']),
      tipe: KasTipe.from(json['tipe']),
      rtId: json['rt_id'],
      rwId: json['rw_id'],
      nominal: json['nominal'],
      keterangan: json['keterangan'],

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
      'level': level?.display == 'RT' || level?.display == 'RW'
          ? level?.display
          : null,
      'rt_id': rtId,
      'rw_id': rwId,
      'tipe': tipe?.name,
      'nominal': nominal,
      'keterangan': keterangan,
    };
  }
}
