import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/models/kegiatan_model.dart';
import 'package:rukun_app_proyek4/models/pengajuan_surat_model.dart';
import 'package:rukun_app_proyek4/models/transaksi_model.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';

extension PembayaranUiStatus on StatusPembayaran {
  String get label {
    switch (this) {
      case StatusPembayaran.belumDibayar:
        return "Belum Dibayar";

      case StatusPembayaran.diproses:
        return "Diproses";

      case StatusPembayaran.dibayar:
        return "Dibayar";

      case StatusPembayaran.ditolak:
        return "Ditolak";
    }
  }

  Color get color {
    switch (this) {
      case StatusPembayaran.belumDibayar:
        return ColorsUtils.yellow;

      case StatusPembayaran.diproses:
        return Colors.blue;

      case StatusPembayaran.dibayar:
        return ColorsUtils.g100;

      case StatusPembayaran.ditolak:
        return ColorsUtils.red;
    }
  }

  String get value {
    switch (this) {
      case StatusPembayaran.belumDibayar:
        return "Belum Dibayar";

      case StatusPembayaran.diproses:
        return "Diproses";

      case StatusPembayaran.dibayar:
        return "Dibayar";

      case StatusPembayaran.ditolak:
        return "Ditolak";
    }
  }

  static StatusPembayaran fromString(String? value) {
    switch (value) {
      case "Diproses":
        return StatusPembayaran.diproses;

      case "Dibayar":
        return StatusPembayaran.dibayar;

      case "Ditolak":
        return StatusPembayaran.ditolak;

      case "Belum Dibayar":
      default:
        return StatusPembayaran.belumDibayar;
    }
  }
}

class SuratUiStatus {
  final String label;
  final Color color;

  const SuratUiStatus({required this.label, required this.color});
}

extension SuratStatusExtention on SuratStatus {
  SuratUiStatus get ui {
    switch (this) {
      case SuratStatus.diajukan:
        return const SuratUiStatus(label: "Diajukan", color: ColorsUtils.o100);

      case SuratStatus.disetujui:
        return const SuratUiStatus(label: "Disetujui", color: ColorsUtils.b200);

      case SuratStatus.ditolak:
        return const SuratUiStatus(label: "Ditolak", color: ColorsUtils.red);

      case SuratStatus.selesai:
        return const SuratUiStatus(label: "Selesai", color: ColorsUtils.g100);
    }
  }
}

enum FilterKegiatanStatus { semua, berlangsung, segera, selesai, dibatalkan }

class KegiatanUiStatus {
  final String label;
  final Color color;
  final FilterKegiatanStatus type;

  const KegiatanUiStatus({
    required this.label,
    required this.color,
    required this.type,
  });
}

extension KegiatanUiExtension on Kegiatan {
  KegiatanUiStatus get uiStatus {
    final now = DateTime.now();

    final selesai = tanggalSelesai ?? tanggalMulai;

    if (status == KegiatanStatus.dibatalkan) {
      return const KegiatanUiStatus(
        label: "Dibatalkan",
        color: ColorsUtils.red,
        type: FilterKegiatanStatus.dibatalkan,
      );
    }

    if (status == KegiatanStatus.selesai) {
      return const KegiatanUiStatus(
        label: "Selesai",
        color: ColorsUtils.g100,
        type: FilterKegiatanStatus.selesai,
      );
    }

    final isBerlangsung = now.isAfter(tanggalMulai) && now.isBefore(selesai);

    if (isBerlangsung) {
      return const KegiatanUiStatus(
        label: "Berlangsung",
        color: ColorsUtils.b200,
        type: FilterKegiatanStatus.berlangsung,
      );
    }

    if (now.isBefore(tanggalMulai)) {
      return const KegiatanUiStatus(
        label: "Segera",
        color: ColorsUtils.o100,
        type: FilterKegiatanStatus.segera,
      );
    }

    return const KegiatanUiStatus(
      label: "Selesai",
      color: ColorsUtils.g100,
      type: FilterKegiatanStatus.selesai,
    );
  }
}
