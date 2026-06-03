import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rukun_app_proyek4/models/pengajuan_surat_model.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/status_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/surat/surat_list_viewmodel.dart';
import 'package:rukun_app_proyek4/viewmodels/surat/surat_action_viewmodel.dart';
import 'package:rukun_app_proyek4/views/pages/surat/pdf_preview_page.dart';
import 'package:rukun_app_proyek4/views/pages/surat/utils/surat_permission.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart' as fp;

class TindakLanjutRtModal extends StatefulWidget {
  final PengajuanSurat surat;
  final String namaWarga;
  final bool readOnly;
  final SuratPermission permission;

  const TindakLanjutRtModal({
    super.key,
    required this.surat,
    required this.namaWarga,
    this.readOnly = false,
    required this.permission,
  });

  @override
  State<TindakLanjutRtModal> createState() => _TindakLanjutRtModalState();
}

class _TindakLanjutRtModalState extends State<TindakLanjutRtModal> {
  File? selectedFile;

  Future<void> pickFile() async {
    final result = await fp.FilePicker.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    setState(() {
      selectedFile = File(result.files.single.path!);
    });
  }

  void _showRejectDialog(
    BuildContext context,
    SuratActionViewModel actionVm,
    SuratListViewModel listVm,
  ) {
    final TextEditingController alasanController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Tolak Pengajuan"),
          content: TextField(
            controller: alasanController,
            decoration: const InputDecoration(
              hintText: "Masukkan alasan penolakan",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ColorsUtils.red),
              onPressed: () async {
                if (alasanController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Alasan wajib diisi")),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final success = await actionVm.tolakSurat(
                  id: widget.surat.id!,
                  catatan: alasanController.text.trim(),
                  listVm: listVm,
                );
                if (success && mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Tolak", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionVm = context.watch<SuratActionViewModel>();
    final listVm = context.watch<SuratListViewModel>();

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
            _header(),
            const SizedBox(height: 24),
            _userHeader(),
            const SizedBox(height: 24),
            _detail("Keperluan", widget.surat.keperluan),
            _detail("Keterangan", widget.surat.keterangan ?? '-'),
            const SizedBox(height: 20),

            _buildUploadSection(widget.permission, actionVm, listVm),
            _buildDocumentSection(),
            if (!widget.readOnly)
              _buildActionButtons(widget.permission, actionVm, listVm),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final status = widget.surat.status.ui;

    return Row(
      children: [
        const Expanded(
          child: Text(
            "Tindak Lanjut Surat",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

          decoration: BoxDecoration(
            color: status.color.withValues(alpha: 0.12),

            borderRadius: BorderRadius.circular(20),
          ),

          child: Text(
            status.label,

            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: status.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _userHeader() {
    return Row(
      children: [
        const CircleAvatar(radius: 22, child: Icon(Icons.person)),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                widget.namaWarga,

                style: const TextStyle(fontWeight: FontWeight.w600),
              ),

              const Text(
                "Warga Pengaju",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          SizedBox(
            width: 100,

            child: Text(
              title,

              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),

          Expanded(
            child: Text(
              value,

              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _uploadBox(BuildContext context) {
    return GestureDetector(
      onTap: pickFile,

      child: Container(
        width: double.infinity,
        height: 130,

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),

          border: Border.all(color: Colors.grey.shade300),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(Icons.upload_file, size: 38),

            const SizedBox(height: 10),

            Text(
              selectedFile == null
                  ? "Pilih File"
                  : selectedFile!.path.split("/").last,

              textAlign: TextAlign.center,

              style: const TextStyle(fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 6),

            Text(
              "PDF / DOC / DOCX",

              style: TextStyle(fontSize: 11, color: ColorsUtils.gray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection(
    SuratPermission permission,
    SuratActionViewModel actionVm,
    SuratListViewModel listVm,
  ) {
    if (permission.canUploadDraft || permission.canUploadSigned) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (permission.canUploadDraft) ...[
            const Text(
              "Langkah 1. Buat Draft Surat",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Pilih salah satu cara membuat draft surat:",
              style: TextStyle(fontSize: 12, color: ColorsUtils.gray),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final wargaData = listVm.getWarga(
                        widget.surat.wargaId ?? 0,
                      );
                      if (wargaData != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PdfPreviewPage(
                              surat: widget.surat,
                              warga: wargaData,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Data warga tidak ditemukan"),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text(
                      "Generate\nPDF",
                      textAlign: TextAlign.center,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final templateUrl = listVm.getTemplateUrl();
                      return OutlinedButton.icon(
                        onPressed: templateUrl == null
                            ? null
                            : () async {
                                final uri = Uri.parse(templateUrl);
                                if (!await launchUrl(
                                  uri,
                                  mode: LaunchMode.inAppBrowserView,
                                )) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Gagal membuka template"),
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: Icon(
                          Icons.download,
                          size: 18,
                          color: templateUrl == null
                              ? Colors.grey
                              : ColorsUtils.b300,
                        ),
                        label: Text(
                          templateUrl == null
                              ? "Belum ada\nTemplate"
                              : "Download\nTemplate",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: templateUrl == null
                                ? Colors.grey
                                : ColorsUtils.b300,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(
                            color: templateUrl == null
                                ? Colors.grey.shade300
                                : ColorsUtils.b300,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              "Langkah 2. Upload Draft Surat",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Upload draft surat yang sudah digenerate dan disimpan ke perangkat.",
              style: TextStyle(fontSize: 12, color: ColorsUtils.gray),
            ),
          ] else ...[
            const Text(
              "Upload Surat Bertanda Tangan",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: 14),
          _uploadBox(context),
          const SizedBox(height: 28),
        ],
      );
    }

    return const SizedBox();
  }

  Widget _buildDocumentSection() {
    if (widget.surat.docRef == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Dokumen Surat",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        InkWell(
          onTap: () async {
            final uri = Uri.parse(widget.surat.docRef!);
            if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Gagal membuka dokumen")),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.description),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.surat.docRef!.split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.open_in_new, size: 18),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildActionButtons(
    SuratPermission permission,
    SuratActionViewModel actionVm,
    SuratListViewModel listVm,
  ) {
    return Row(
      children: [
        if (permission.canAct) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showRejectDialog(context, actionVm, listVm),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorsUtils.red,
                side: BorderSide(color: ColorsUtils.red.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Tolak",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ] else ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text("Batal"),
            ),
          ),
        ],
        const SizedBox(width: 10),

        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: actionVm.isUploading
                ? null
                : () async {
                    if (selectedFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Pilih file terlebih dahulu"),
                        ),
                      );
                      return;
                    }

                    bool success = false;
                    if (permission.canUploadDraft) {
                      success = await actionVm.uploadDraftByRt(
                        id: widget.surat.id!,
                        file: selectedFile!,
                        listVm: listVm,
                      );
                    } else if (permission.canUploadSigned) {
                      success = await actionVm.uploadSignedByRw(
                        id: widget.surat.id!,
                        file: selectedFile!,
                        listVm: listVm,
                      );
                    }

                    if (success && context.mounted) {
                      Navigator.pop(context);
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Surat belum tersinkron atau upload gagal.",
                          ),
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsUtils.b300,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: actionVm.isUploading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    permission.canUploadDraft
                        ? "Kirim ke RW"
                        : "Selesaikan Surat",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}
