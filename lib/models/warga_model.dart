import 'package:rukun_app_proyek4/models/keluarga_model.dart';

enum JenisKelamin {
  lakiLaki,
  perempuan;

  String get display {
    switch (this) {
      case JenisKelamin.lakiLaki:
        return 'Laki-Laki';
      case JenisKelamin.perempuan:
        return 'Perempuan';
    }
  }

  static JenisKelamin? from(String? value) {
    switch (value) {
      case 'lakiLaki':
      case 'Laki-Laki':
        return JenisKelamin.lakiLaki;
      case 'perempuan':
      case 'Perempuan':
        return JenisKelamin.perempuan;
      default:
        return null;
    }
  }
}

enum Agama {
  islam,
  kristen,
  katolik,
  hindu,
  buddha,
  konghucu;

  String get display {
    switch (this) {
      case Agama.islam:
        return 'Islam';
      case Agama.kristen:
        return 'Kristen';
      case Agama.katolik:
        return 'Katolik';
      case Agama.hindu:
        return 'Hindu';
      case Agama.buddha:
        return 'Buddha';
      case Agama.konghucu:
        return 'Konghucu';
    }
  }

  static Agama? from(String? value) {
    switch (value) {
      case 'islam':
      case 'Islam':
        return Agama.islam;
      case 'kristen':
      case 'Kristen':
        return Agama.kristen;
      case 'katolik':
      case 'Katolik':
        return Agama.katolik;
      case 'hindu':
      case 'Hindu':
        return Agama.hindu;
      case 'buddha':
      case 'Buddha':
        return Agama.buddha;
      case 'konghucu':
      case 'Konghucu':
        return Agama.konghucu;
      default:
        return null;
    }
  }
}

enum StatusPerkawinan {
  belumKawin,
  kawin,
  ceraiHidup,
  ceraiMati;

  String get display {
    switch (this) {
      case StatusPerkawinan.belumKawin:
        return 'Belum Kawin';
      case StatusPerkawinan.kawin:
        return 'Kawin';
      case StatusPerkawinan.ceraiHidup:
        return 'Cerai Hidup';
      case StatusPerkawinan.ceraiMati:
        return 'Cerai Mati';
    }
  }

  static StatusPerkawinan? from(String? value) {
    switch (value) {
      case 'belumKawin':
      case 'Belum Kawin':
        return StatusPerkawinan.belumKawin;
      case 'kawin':
      case 'Kawin':
        return StatusPerkawinan.kawin;
      case 'ceraiHidup':
      case 'Cerai Hidup':
        return StatusPerkawinan.ceraiHidup;
      case 'ceraiMati':
      case 'Cerai Mati':
        return StatusPerkawinan.ceraiMati;
      default:
        return null;
    }
  }
}

enum StatusHubungan {
  kepalaKeluarga,
  suami,
  istri,
  anak,
  menantu,
  cucu,
  orangTua,
  mertua,
  familiLain;

  String get display {
    switch (this) {
      case StatusHubungan.kepalaKeluarga:
        return 'Kepala Keluarga';
      case StatusHubungan.suami:
        return 'Suami';
      case StatusHubungan.istri:
        return 'Istri';
      case StatusHubungan.anak:
        return 'Anak';
      case StatusHubungan.menantu:
        return 'Menantu';
      case StatusHubungan.cucu:
        return 'Cucu';
      case StatusHubungan.orangTua:
        return 'Orang Tua';
      case StatusHubungan.mertua:
        return 'Mertua';
      case StatusHubungan.familiLain:
        return 'Famili Lain';
    }
  }

  static StatusHubungan? from(String? value) {
    switch (value) {
      case 'kepalaKeluarga':
      case 'Kepala Keluarga':
        return StatusHubungan.kepalaKeluarga;
      case 'suami':
      case 'Suami':
        return StatusHubungan.suami;
      case 'istri':
      case 'Istri':
        return StatusHubungan.istri;
      case 'anak':
      case 'Anak':
        return StatusHubungan.anak;
      case 'menantu':
      case 'Menantu':
        return StatusHubungan.menantu;
      case 'cucu':
      case 'Cucu':
        return StatusHubungan.cucu;
      case 'orangTua':
      case 'Orang Tua':
        return StatusHubungan.orangTua;
      case 'mertua':
      case 'Mertua':
        return StatusHubungan.mertua;
      case 'familiLain':
      case 'Famili Lain':
        return StatusHubungan.familiLain;
      default:
        return null;
    }
  }
}

enum Kewarganegaraan {
  wni,
  wna;

  String get display {
    switch (this) {
      case Kewarganegaraan.wni:
        return 'WNI';
      case Kewarganegaraan.wna:
        return 'WNA';
    }
  }

  static Kewarganegaraan? from(String? value) {
    switch (value) {
      case 'wni':
      case 'WNI':
        return Kewarganegaraan.wni;
      case 'wna':
      case 'WNA':
        return Kewarganegaraan.wna;
      default:
        return null;
    }
  }
}

class Warga {
  final int? id;
  final String nama;
  final String nik;
  final String? syncStatus;

  final JenisKelamin? jk;
  final String? tempatLahir;
  final DateTime? tglLahir;

  final Agama? agama;
  final String? pendidikan;
  final String? jenisPekerjaan;
  final String? golonganDarah;

  final StatusPerkawinan? statusPerkawinan;
  final DateTime? tglPerkawinan;

  final StatusHubungan? statusHubungan;
  final Kewarganegaraan? kewarganegaraan;
  final String? wnaNegara;

  final String? noPaspor;
  final String? noKitap;

  final String? namaAyah;
  final String? namaIbu;

  final Keluarga? keluarga;

  final DateTime? waktuDibuat;
  final DateTime? waktuDiubah;
  final DateTime? waktuDihapus;

  Warga({
    this.id,
    required this.nama,
    required this.nik,
    this.syncStatus,
    this.jk,
    this.tempatLahir,
    this.tglLahir,
    this.agama,
    this.pendidikan,
    this.jenisPekerjaan,
    this.golonganDarah,
    this.statusPerkawinan,
    this.tglPerkawinan,
    this.statusHubungan,
    this.kewarganegaraan,
    this.wnaNegara,
    this.noPaspor,
    this.noKitap,
    this.namaAyah,
    this.namaIbu,
    this.keluarga,
    this.waktuDibuat,
    this.waktuDiubah,
    this.waktuDihapus,
  });

  factory Warga.fromJson(Map<String, dynamic> json) {
    return Warga(
      id: json['id'] as int?,
      nama: json['nama'],
      nik: json['nik'],
      syncStatus: json['sync_status'] as String?,

      jk: _parseJenisKelamin(json['jk']),
      agama: _parseAgama(json['agama']),
      statusPerkawinan: _parseStatusKawin(json['status_perkawinan']),
      statusHubungan: _parseStatusHubungan(json['status_hubungan']),
      kewarganegaraan: _parseKwn(json['kewarganegaraan']),
      wnaNegara: json['wna_negara'],

      tempatLahir: json['tempat_lahir'],
      tglLahir: json['tgl_lahir'] != null
          ? DateTime.tryParse(json['tgl_lahir'])
          : null,

      pendidikan: json['pendidikan'],
      jenisPekerjaan: json['jenis_pekerjaan'],
      golonganDarah: json['golongan_darah'],

      tglPerkawinan: json['tgl_perkawinan'] != null
          ? DateTime.tryParse(json['tgl_perkawinan'])
          : null,

      noPaspor: json['no_paspor'],
      noKitap: json['no_kitap'],
      namaAyah: json['nama_ayah'],
      namaIbu: json['nama_ibu'],

      keluarga: json['keluarga'] != null
          ? Keluarga.fromJson(json['keluarga'])
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
      'nama': nama,
      'nik': nik,
      'sync_status': syncStatus,

      'jk': _jkToString(jk),
      'tempat_lahir': tempatLahir,
      'tgl_lahir': tglLahir != null
          ? "${tglLahir!.year.toString().padLeft(4, '0')}-${tglLahir!.month.toString().padLeft(2, '0')}-${tglLahir!.day.toString().padLeft(2, '0')}"
          : null,

      'agama': _agamaToString(agama),
      'pendidikan': pendidikan,
      'jenis_pekerjaan': jenisPekerjaan,
      'golongan_darah': golonganDarah,

      'status_perkawinan': _statusKawinToString(statusPerkawinan),
      'tgl_perkawinan': tglPerkawinan != null
          ? "${tglPerkawinan!.year.toString().padLeft(4, '0')}-${tglPerkawinan!.month.toString().padLeft(2, '0')}-${tglPerkawinan!.day.toString().padLeft(2, '0')}"
          : null,

      'status_hubungan': _statusHubunganToString(statusHubungan),
      'kewarganegaraan': _kwnToString(kewarganegaraan),
      'wna_negara': wnaNegara,

      'no_paspor': noPaspor,
      'no_kitap': noKitap,
      'nama_ayah': namaAyah,
      'nama_ibu': namaIbu,

      'keluarga_id': keluarga?.id,
    };
  }

  bool get isPendingSync => syncStatus == 'pending';

  static JenisKelamin? _parseJenisKelamin(String? value) {
    switch (value) {
      case "Laki-Laki":
        return JenisKelamin.lakiLaki;
      case "Perempuan":
        return JenisKelamin.perempuan;
      default:
        return null;
    }
  }

  static Agama? _parseAgama(String? value) {
    switch (value) {
      case "Islam":
        return Agama.islam;
      case "Kristen":
        return Agama.kristen;
      case "Katolik":
        return Agama.katolik;
      case "Hindu":
        return Agama.hindu;
      case "Buddha":
        return Agama.buddha;
      case "Konghucu":
        return Agama.konghucu;
      default:
        return null;
    }
  }

  static StatusPerkawinan? _parseStatusKawin(String? value) {
    switch (value) {
      case "Belum Kawin":
        return StatusPerkawinan.belumKawin;
      case "Kawin":
        return StatusPerkawinan.kawin;
      case "Cerai Hidup":
        return StatusPerkawinan.ceraiHidup;
      case "Cerai Mati":
        return StatusPerkawinan.ceraiMati;
      default:
        return null;
    }
  }

  static StatusHubungan? _parseStatusHubungan(String? value) {
    switch (value) {
      case "Kepala Keluarga":
        return StatusHubungan.kepalaKeluarga;
      case "Suami":
        return StatusHubungan.suami;
      case "Istri":
        return StatusHubungan.istri;
      case "Anak":
        return StatusHubungan.anak;
      case "Menantu":
        return StatusHubungan.menantu;
      case "Cucu":
        return StatusHubungan.cucu;
      case "Orang Tua":
        return StatusHubungan.orangTua;
      case "Mertua":
        return StatusHubungan.mertua;
      case "Famili Lain":
        return StatusHubungan.familiLain;
      default:
        return null;
    }
  }

  static Kewarganegaraan? _parseKwn(String? value) {
    switch (value) {
      case "WNI":
        return Kewarganegaraan.wni;
      case "WNA":
        return Kewarganegaraan.wna;
      default:
        return null;
    }
  }

  static String? _jkToString(JenisKelamin? value) {
    switch (value) {
      case JenisKelamin.lakiLaki:
        return "Laki-Laki";
      case JenisKelamin.perempuan:
        return "Perempuan";
      default:
        return null;
    }
  }

  static String? _agamaToString(Agama? value) {
    switch (value) {
      case Agama.islam:
        return "Islam";
      case Agama.kristen:
        return "Kristen";
      case Agama.katolik:
        return "Katolik";
      case Agama.hindu:
        return "Hindu";
      case Agama.buddha:
        return "Buddha";
      case Agama.konghucu:
        return "Konghucu";
      default:
        return null;
    }
  }

  static String? _statusKawinToString(StatusPerkawinan? value) {
    switch (value) {
      case StatusPerkawinan.belumKawin:
        return "Belum Kawin";
      case StatusPerkawinan.kawin:
        return "Kawin";
      case StatusPerkawinan.ceraiHidup:
        return "Cerai Hidup";
      case StatusPerkawinan.ceraiMati:
        return "Cerai Mati";
      default:
        return null;
    }
  }

  static String? _statusHubunganToString(StatusHubungan? value) {
    switch (value) {
      case StatusHubungan.kepalaKeluarga:
        return "Kepala Keluarga";
      case StatusHubungan.suami:
        return "Suami";
      case StatusHubungan.istri:
        return "Istri";
      case StatusHubungan.anak:
        return "Anak";
      case StatusHubungan.menantu:
        return "Menantu";
      case StatusHubungan.cucu:
        return "Cucu";
      case StatusHubungan.orangTua:
        return "Orang Tua";
      case StatusHubungan.mertua:
        return "Mertua";
      case StatusHubungan.familiLain:
        return "Famili Lain";
      default:
        return null;
    }
  }

  static String? _kwnToString(Kewarganegaraan? value) {
    switch (value) {
      case Kewarganegaraan.wni:
        return "WNI";
      case Kewarganegaraan.wna:
        return "WNA";
      default:
        return null;
    }
  }
}
