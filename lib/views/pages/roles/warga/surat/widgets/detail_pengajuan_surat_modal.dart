import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/models/pengajuan_surat_model.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/status_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailPengajuanSuratModal extends StatelessWidget {
  final PengajuanSurat item;

  const DetailPengajuanSuratModal({super.key, required this.item});
  String _getFileName(String? url) {
    if (url == null || url.isEmpty) return "-";
    return Uri.parse(url).pathSegments.last;
  }

  @override
  Widget build(BuildContext context) {
    final ui = item.status.ui;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),

      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Detail Pengajuan Surat",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ui.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ui.label,
                    style: TextStyle(
                      color: ui.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _field(title: "Keperluan", value: item.keperluan),

            const SizedBox(height: 16),
            _field(
              title: "Keterangan",
              value: item.keterangan ?? '-',
              maxLines: 4,
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _field(
                    title: "Tanggal Pengajuan",
                    value: item.waktuDibuat != null
                        ? _formatDate(item.waktuDibuat!)
                        : "-",
                  ),
                ),

                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    title: "Disetujui",
                    value: item.waktuDisetujui != null
                        ? _formatDate(item.waktuDisetujui!)
                        : "-",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              "Dokumen Pendukung",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ColorsUtils.b300,
                borderRadius: BorderRadius.circular(14),
              ),

              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: ColorsUtils.white),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      _getFileName(item.docRef),
                      style: const TextStyle(
                        color: ColorsUtils.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  ElevatedButton.icon(
                    onPressed: () async {
                      final url = item.docRef;
                      if (url == null || url.isEmpty) return;

                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsUtils.white,
                      foregroundColor: ColorsUtils.b200,
                    ),

                    icon: const Icon(Icons.download, size: 16),

                    label: const Text("Unduh"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String title,
    required String value,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),

        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ColorsUtils.lightgray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorsUtils.lightgray),
          ),
          child: Text(value, maxLines: maxLines),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    return "${d.day}/${d.month}/${d.year}";
  }
}
