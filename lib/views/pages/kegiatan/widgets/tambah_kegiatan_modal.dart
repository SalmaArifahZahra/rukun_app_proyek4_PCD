import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/models/kegiatan_model.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/notification_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/kegiatan/kegiatan_viewmodel.dart';

class TambahKegiatanModal extends StatefulWidget {
  final Kegiatan? kegiatan;

  const TambahKegiatanModal({super.key, this.kegiatan});

  @override
  State<TambahKegiatanModal> createState() => _TambahKegiatanModalState();
}

class _TambahKegiatanModalState extends State<TambahKegiatanModal> {
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final k = widget.kegiatan;

    if (k != null) {
      namaController.text = k.nama;
      deskripsiController.text = k.deskripsi ?? "";
      tanggalMulai = k.tanggalMulai;
      tanggalSelesai = k.tanggalSelesai;
    }
  }

  final _formKey = GlobalKey<FormState>();

  final namaController = TextEditingController();
  final deskripsiController = TextEditingController();

  DateTime? tanggalMulai;
  DateTime? tanggalSelesai;

  bool tanggalMulaiError = false;
  bool tanggalSelesaiError = false;
  bool dokumenError = false;

  @override
  void dispose() {
    namaController.dispose();
    deskripsiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KegiatanViewModel>();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.kegiatan == null ? "Tambah Kegiatan" : "Edit Kegiatan",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              _textField(
                label: "Nama Kegiatan",
                controller: namaController,
                hint: "Masukkan nama kegiatan",
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Nama kegiatan wajib diisi";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              _textField(
                label: "Deskripsi Kegiatan",
                controller: deskripsiController,
                hint: "Masukkan deskripsi kegiatan",
                maxLines: 5,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Deskripsi wajib diisi";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _dateField(
                      context: context,
                      label: "Tanggal Mulai",
                      value: tanggalMulai != null
                          ? _formatDate(tanggalMulai!)
                          : "Pilih tanggal",
                      isError: tanggalMulaiError,
                      errorText: "Tanggal mulai wajib diisi",
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2035),
                        );

                        if (picked != null) {
                          setState(() {
                            tanggalMulai = picked;
                            tanggalMulaiError = false;
                          });
                        }
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _dateField(
                      context: context,
                      label: "Tanggal Selesai",
                      value: tanggalSelesai != null
                          ? _formatDate(tanggalSelesai!)
                          : "Pilih tanggal",
                      isError: tanggalSelesaiError,
                      errorText: "Tanggal selesai wajib diisi",
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tanggalMulai ?? DateTime.now(),
                          firstDate: tanggalMulai ?? DateTime.now(),
                          lastDate: DateTime(2035),
                        );

                        if (picked != null) {
                          setState(() {
                            tanggalSelesai = picked;
                            tanggalSelesaiError = false;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                "Dokumen Pendukung",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 12),

              _documentBox(vm),

              if (dokumenError)
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    "Dokumen wajib diupload",
                    style: TextStyle(color: ColorsUtils.red, fontSize: 12),
                  ),
                ),

              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
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
                              final isValid = _formKey.currentState!.validate();

                              setState(() {
                                tanggalMulaiError = tanggalMulai == null;
                                tanggalSelesaiError = tanggalSelesai == null;
                              });

                              if (!isValid) return;

                              final vm = context.read<KegiatanViewModel>();

                              final isEdit = widget.kegiatan != null;

                              final error = vm.validateKegiatan(
                                fileKey: KegiatanViewModel.createKey,
                                mode: isEdit
                                    ? KegiatanValidationMode.edit
                                    : KegiatanValidationMode.create,
                                nama: namaController.text,
                                deskripsi: deskripsiController.text,
                                tanggalMulai: tanggalMulai,
                                tanggalSelesai: tanggalSelesai,
                              );

                              if (error != null) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(error)));
                                return;
                              }

                              setState(() => _isSubmitting = true);

                              bool success;

                              try {
                                if (isEdit) {
                                  success = await vm.updateKegiatan(
                                    id: widget.kegiatan!.id!,
                                    data: {
                                      "nama": namaController.text.trim(),
                                      "deskripsi": deskripsiController.text
                                          .trim(),
                                      "tanggal_mulai": tanggalMulai!
                                          .toIso8601String(),
                                      "tanggal_selesai": tanggalSelesai
                                          ?.toIso8601String(),
                                    },
                                  );
                                } else {
                                  success = await vm.createKegiatan(
                                    nama: namaController.text.trim(),
                                    deskripsi: deskripsiController.text.trim(),
                                    tanggalMulai: tanggalMulai!,
                                    tanggalSelesai: tanggalSelesai!,
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isSubmitting = false);
                                }
                              }

                              if (!context.mounted) return;

                              if (success) {
                                NotificationUtils.showSuccess(
                                  context,
                                  isEdit
                                      ? "Kegiatan berhasil diupdate"
                                      : "Kegiatan berhasil ditambahkan",
                                );

                                Navigator.pop(context);
                              } else {
                                NotificationUtils.showError(
                                  context,
                                  vm.errorMessage ?? "Terjadi kesalahan",
                                );
                              }
                            },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsUtils.green,
                        foregroundColor: Colors.white,
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
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Simpan",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,

          decoration: InputDecoration(
            hintText: hint,

            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _dateField({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isError,
    required String errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),

        const SizedBox(height: 8),

        GestureDetector(
          onTap: onTap,

          child: AbsorbPointer(
            child: TextFormField(
              controller: TextEditingController(text: value),

              decoration: InputDecoration(
                errorText: isError ? errorText : null,

                suffixIcon: const Icon(Icons.calendar_today),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _documentBox(KegiatanViewModel vm) {
    final fileName =
        vm
            .getSelectedDocument(KegiatanViewModel.createKey)
            ?.path
            .split("/")
            .last ??
        "Upload dokumen kegiatan";

    return GestureDetector(
      onTap: () => vm.pickDocument(KegiatanViewModel.createKey),

      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          border: Border.all(
            color: dokumenError ? ColorsUtils.red : ColorsUtils.gray,
          ),

          borderRadius: BorderRadius.circular(14),
        ),

        child: Row(
          children: [
            const Icon(Icons.description_outlined),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                fileName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),

            const Icon(Icons.upload_file_rounded),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
