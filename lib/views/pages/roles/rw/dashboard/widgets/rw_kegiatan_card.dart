import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rukun_app_proyek4/models/kegiatan_model.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';

class RwKegiatanCard extends StatelessWidget {
  final Kegiatan kegiatan;

  const RwKegiatanCard({super.key, required this.kegiatan});

  @override
  Widget build(BuildContext context) {
    final tanggalMulai = DateFormat(
      'dd MMM yyyy',
      'id_ID',
    ).format(kegiatan.tanggalMulai);

    final tanggalSelesai = kegiatan.tanggalSelesai != null
        ? DateFormat('dd MMM yyyy', 'id_ID').format(kegiatan.tanggalSelesai!)
        : null;

    final tanggalText = tanggalSelesai != null
        ? "$tanggalMulai - $tanggalSelesai"
        : tanggalMulai;

    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: ColorsUtils.white,
        borderRadius: BorderRadius.circular(24),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

            decoration: BoxDecoration(
              color: _statusBgColor(kegiatan.status),
              borderRadius: BorderRadius.circular(30),
            ),

            child: Text(
              _statusText(kegiatan.status),

              style: TextStyle(
                color: _statusTextColor(kegiatan.status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 15),
          Text(
            kegiatan.nama,

            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),

          const SizedBox(height: 10),
          Text(
            kegiatan.deskripsi ?? "Tidak ada deskripsi kegiatan.",

            style: const TextStyle(color: ColorsUtils.gray, height: 1.5),
          ),

          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 18,
                color: ColorsUtils.gray,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  tanggalText,

                  style: const TextStyle(color: ColorsUtils.gray),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  String _statusText(KegiatanStatus status) {
    switch (status) {
      case KegiatanStatus.dibuat:
        return "Berlangsung";

      case KegiatanStatus.dibatalkan:
        return "Dibatalkan";

      case KegiatanStatus.selesai:
        return "Selesai";
    }
  }

  Color _statusBgColor(KegiatanStatus status) {
    switch (status) {
      case KegiatanStatus.dibuat:
        return Colors.teal.withOpacity(0.12);

      case KegiatanStatus.dibatalkan:
        return Colors.red.withOpacity(0.12);

      case KegiatanStatus.selesai:
        return Colors.blue.withOpacity(0.12);
    }
  }


  Color _statusTextColor(KegiatanStatus status) {
    switch (status) {
      case KegiatanStatus.dibuat:
        return Colors.teal;

      case KegiatanStatus.dibatalkan:
        return Colors.red;

      case KegiatanStatus.selesai:
        return Colors.blue;
    }
  }
}
