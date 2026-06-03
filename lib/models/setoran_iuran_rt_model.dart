class SetoranStatus {
  static const dikirim = 'Dikirim';
  static const ditolak = 'Ditolak';
  static const diterima = 'Diterima';

  static String? from(String? value) {
    switch (value) {
      case 'Dikirim':
      case 'dikirim':
        return dikirim;
      case 'Ditolak':
      case 'ditolak':
        return ditolak;
      case 'Diterima':
      case 'diterima':
        return diterima;
      default:
        return null;
    }
  }
}

class SetoranIuranRt {
  final int? id;

  final int iuranId;
  final int rtId;

  final DateTime periodeBulan;

  final int totalPembayar;
  final int jumlahSetoran;

  final String? documentRef;
  final String? status;
  final String? catatan;

  final DateTime? waktuDibuat;
  final DateTime? waktuDiubah;
  final DateTime? waktuDihapus;

  SetoranIuranRt({
    this.id,
    required this.iuranId,
    required this.rtId,
    required this.periodeBulan,
    required this.totalPembayar,
    required this.jumlahSetoran,
    this.documentRef,
    this.status,
    this.catatan,
    this.waktuDibuat,
    this.waktuDiubah,
    this.waktuDihapus,
  });

  factory SetoranIuranRt.fromJson(Map<String, dynamic> json) {
    return SetoranIuranRt(
      id: json['id'] as int?,

      iuranId: json['iuran_id'],
      rtId: json['rt_id'],

      periodeBulan: DateTime.parse(json['periode_bulan']),

      totalPembayar: json['total_pembayar'],
      jumlahSetoran: json['jumlah_setoran'],

      documentRef: json['document_ref'],
      status: json['status'],
      catatan: json['catatan'],

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
      'iuran_id': iuranId,
      'rt_id': rtId,
      'periode_bulan': periodeBulan.toIso8601String(),
      'total_pembayar': totalPembayar,
      'jumlah_setoran': jumlahSetoran,
      'document_ref': documentRef,
      'status': status,
      'catatan': catatan,
    };
  }

  SetoranIuranRt copyWith({
    int? id,
    int? iuranId,
    int? rtId,
    DateTime? periodeBulan,
    int? totalPembayar,
    int? jumlahSetoran,
    String? documentRef,
    String? status,
    String? catatan,
    DateTime? waktuDibuat,
    DateTime? waktuDiubah,
    DateTime? waktuDihapus,
  }) {
    return SetoranIuranRt(
      id: id ?? this.id,
      iuranId: iuranId ?? this.iuranId,
      rtId: rtId ?? this.rtId,
      periodeBulan: periodeBulan ?? this.periodeBulan,
      totalPembayar: totalPembayar ?? this.totalPembayar,
      jumlahSetoran: jumlahSetoran ?? this.jumlahSetoran,
      documentRef: documentRef ?? this.documentRef,
      status: status ?? this.status,
      catatan: catatan ?? this.catatan,
      waktuDibuat: waktuDibuat ?? this.waktuDibuat,
      waktuDiubah: waktuDiubah ?? this.waktuDiubah,
      waktuDihapus: waktuDihapus ?? this.waktuDihapus,
    );
  }
}
