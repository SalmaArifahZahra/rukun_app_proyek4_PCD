import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rukun_app_proyek4/models/kegiatan_model.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:intl/intl.dart';

class DetailKegiatanModal extends StatelessWidget {
  final Kegiatan kegiatan;

  const DetailKegiatanModal({super.key, required this.kegiatan});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Tidak bisa membuka file");
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat("dd MMM yyyy").format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Detail Kegiatan",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                _statusBadge(),
              ],
            ),

            const SizedBox(height: 20),
            Text(
              kegiatan.nama,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),
            Text(
              kegiatan.deskripsi ?? "-",
              style: const TextStyle(height: 1.5),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  "${_formatDate(kegiatan.tanggalMulai)}"
                  "${kegiatan.tanggalSelesai != null ? " - ${_formatDate(kegiatan.tanggalSelesai!)}" : ""}",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              "Dokumen Kegiatan",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),
            _fileCard(
              title: "Download Dokumen",
              url: kegiatan.docReferensi,
              icon: Icons.description_outlined,
            ),

            const SizedBox(height: 24),
            const Text(
              "Foto Kegiatan",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),
            if (kegiatan.imgReferensi != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  kegiatan.imgReferensi!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: ColorsUtils.gray),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  "Belum ada foto kegiatan",
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fileCard({
    required String title,
    required String? url,
    required IconData icon,
  }) {
    final hasFile = url != null && url.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: ColorsUtils.gray),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon),

          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasFile ? title : "Tidak tersedia",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),

          if (hasFile)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: () => _openUrl(url),
            ),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ColorsUtils.b200.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        kegiatan.status.label,
        style: const TextStyle(
          color: ColorsUtils.b200,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
