import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/models/kegiatan_model.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/notification_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/kegiatan/kegiatan_viewmodel.dart';

class UploadBuktiKegiatanModal extends StatefulWidget {
  final Kegiatan kegiatan;

  const UploadBuktiKegiatanModal({
    super.key,
    required this.kegiatan,
  });

  @override
  State<UploadBuktiKegiatanModal> createState() =>
      _UploadBuktiKegiatanModalState();
}

class _UploadBuktiKegiatanModalState
    extends State<UploadBuktiKegiatanModal> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KegiatanViewModel>();
    final image = vm.getSelectedImage(widget.kegiatan.id!);

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
            const Text(
              "Upload Bukti Kegiatan",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),
            Text(
              widget.kegiatan.nama,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              "Foto Bukti",
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                await vm.pickImage(widget.kegiatan.id!);
              },

              child: Container(
                width: double.infinity,
                height: 220,

                decoration: BoxDecoration(
                  border: Border.all(color: ColorsUtils.gray),
                  borderRadius: BorderRadius.circular(16),
                ),

                child: image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.image_outlined,
                            size: 50,
                          ),

                          SizedBox(height: 12),

                          Text(
                            "Pilih Foto Bukti",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(image.path),
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      vm.clearFiles(widget.kegiatan.id!);

                      Navigator.pop(context);
                    },

                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorsUtils.red,
                      side: BorderSide(
                        color: ColorsUtils.red.withOpacity(0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    child: const Text(
                      "Batal",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            final error = vm.validateKegiatan(
                              fileKey: widget.kegiatan.id!,
                              mode: KegiatanValidationMode.uploadBukti,
                              nama: widget.kegiatan.nama,
                              deskripsi:
                                  widget.kegiatan.deskripsi ?? "",
                              tanggalMulai:
                                  widget.kegiatan.tanggalMulai,
                              tanggalSelesai:
                                  widget.kegiatan.tanggalSelesai,
                              kegiatan: widget.kegiatan,
                            );

                            if (error != null) {
                              NotificationUtils.showError(
                                context,
                                error,
                              );
                              return;
                            }

                            setState(() {
                              _isSubmitting = true;
                            });

                            try {
                              await vm.uploadBuktiKegiatan(
                                widget.kegiatan.id!,
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isSubmitting = false;
                                });
                              }
                            }

                            if (!context.mounted) return;

                            if (vm.errorMessage == null) {
                              NotificationUtils.showSuccess(
                                context,
                                "Bukti kegiatan berhasil diupload",
                              );

                              Navigator.pop(context);
                            } else {
                              NotificationUtils.showError(
                                context,
                                vm.errorMessage!,
                              );
                            }
                          },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsUtils.green,
                      foregroundColor: ColorsUtils.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ColorsUtils.white,
                            ),
                          )
                        : const Text(
                            "Upload",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}