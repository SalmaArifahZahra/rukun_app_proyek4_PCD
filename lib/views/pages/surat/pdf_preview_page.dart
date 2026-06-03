import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:rukun_app_proyek4/models/pengajuan_surat_model.dart';
import 'package:rukun_app_proyek4/models/warga_model.dart';
import 'package:rukun_app_proyek4/services/utils/pdf_generator_service.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';

class PdfPreviewPage extends StatelessWidget {
  final PengajuanSurat surat;
  final Warga warga;

  const PdfPreviewPage({
    super.key,
    required this.surat,
    required this.warga,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsUtils.lightgray,
      appBar: AppBar(
        title: const Text("Preview Draft Surat"),
        backgroundColor: ColorsUtils.white,
        foregroundColor: ColorsUtils.black,
        elevation: 0,
      ),
      body: PdfPreview(
        build: (format) => PdfGeneratorService.generateDraftSurat(surat, warga),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }
}
