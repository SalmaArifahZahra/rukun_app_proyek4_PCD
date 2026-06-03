import 'package:rukun_app_proyek4/models/transaksi_model.dart';
import 'package:rukun_app_proyek4/utils/status_utils.dart';

class RTSetoranRW {
  final int? id;
  final int iuranId;
  final int rtId;
  final int nominal;
  final String? buktiUrl;
  final StatusPembayaran status;
  final DateTime? waktuUpload;
  final String? catatan;

  RTSetoranRW({
    this.id,
    required this.iuranId,
    required this.rtId,
    required this.nominal,
    this.buktiUrl,
    required this.status,
    this.waktuUpload,
    this.catatan,
  });

  factory RTSetoranRW.fromJson(Map<String, dynamic> json) {
    return RTSetoranRW(
      id: json['id'],
      iuranId: json['iuran_id'],
      rtId: json['rt_id'],
      nominal: json['nominal'],
      buktiUrl: json['bukti_url'],
      status: PembayaranUiStatus.fromString(json['status']),
      waktuUpload: json['waktu_upload'] != null
          ? DateTime.parse(json['waktu_upload'])
          : null,
      catatan: json['catatan'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "iuran_id": iuranId,
      "rt_id": rtId,
      "nominal": nominal,
      "bukti_url": buktiUrl,
      'status': status.value,
      "catatan": catatan,
    };
  }
}
