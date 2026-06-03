import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/models/pengajuan_surat_model.dart';
import 'package:rukun_app_proyek4/models/user_model.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/auth_viewmodel.dart';
import 'package:rukun_app_proyek4/viewmodels/roles/warga/surat/pengajuan_surat_viewmodel.dart';

class TambahSuratPage extends StatefulWidget {
  final User user;
  final PengajuanSurat? surat;
  final bool isEdit;

  const TambahSuratPage({
    super.key,
    required this.user,
    this.surat,
    this.isEdit = false,
  });

  @override
  State<TambahSuratPage> createState() => _TambahSuratPageState();
}

class _TambahSuratPageState extends State<TambahSuratPage> {
  final _formKey = GlobalKey<FormState>();

  final keperluanController = TextEditingController();
  final keteranganController = TextEditingController();

  @override
  void dispose() {
    keperluanController.dispose();
    keteranganController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    if (widget.isEdit && widget.surat != null) {
      keperluanController.text = widget.surat!.keperluan;

      keteranganController.text = widget.surat!.keterangan ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PengajuanSuratViewModel>();

    final authVM = context.watch<AuthViewModel>();

    final nama = authVM.currentUser?.warga?.nama ?? "-";

    return Scaffold(
      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: nama,
        title: "Pengajuan Surat",
        subtitle: "Ajukan surat anda",
        showName: false,
        showAvatar: false,
        showGreeting: false,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Form(
          key: _formKey,

          autovalidateMode: AutovalidateMode.onUserInteraction,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              _infoBox(),

              const SizedBox(height: 20),
              const Text(
                "Data Diri Pemohon",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),

              const SizedBox(height: 10),
              _dataCard(authVM),

              _buildField(
                title: "Keperluan",
                isRequired: true,

                child: TextFormField(
                  controller: keperluanController,

                  decoration: InputDecoration(
                    hintText: "Contoh: Untuk melamar pekerjaan",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Keperluan wajib diisi";
                    }

                    if (v.trim().length < 5) {
                      return "Minimal 5 karakter";
                    }

                    return null;
                  },
                ),
              ),

              _buildField(
                title: "Keterangan Tambahan",
                isRequired: true,

                child: TextFormField(
                  controller: keteranganController,
                  maxLines: 5,

                  decoration: InputDecoration(
                    hintText: "Tambahkan informasi tambahan",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Keterangan wajib diisi";
                    }

                    return null;
                  },
                ),
              ),

              const SizedBox(height: 24),
              vm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Batal"),
                          ),
                        ),

                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submit,

                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorsUtils.b100,

                              padding: const EdgeInsets.symmetric(vertical: 14),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),

                            child: Text(
                              widget.isEdit
                                  ? "Simpan Perubahan"
                                  : "Ajukan Surat",
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap lengkapi semua field")),
      );
      return;
    }

    final vm = context.read<PengajuanSuratViewModel>();

    final data = PengajuanSurat(
      wargaId: widget.user.wargaId,
      rtId: widget.user.rt?.id ?? widget.user.keluarga?.rtId,
      keperluan: keperluanController.text.trim(),
      keterangan: keteranganController.text.trim(),
      status: SuratStatus.diajukan,
    );

    debugPrint("=== SUBMIT SURAT PAYLOAD ===");
    debugPrint(data.toJson().toString());

    bool success;

    if (widget.isEdit && widget.surat?.id != null) {
      success = await vm.updateSurat(widget.surat!.id!, data);
    } else {
      success = await vm.submit(data);
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
    }
  }

  Widget _infoBox() {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: ColorsUtils.b50,
        borderRadius: BorderRadius.circular(12),
      ),

      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(Icons.info_outline, color: ColorsUtils.b200),

          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Pengajuan akan diproses oleh pengurus. Jika koneksi putus, pengajuan tetap disimpan dan disinkronkan saat online.",
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String title,
    required Widget child,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        RichText(
          text: TextSpan(
            text: title,

            style: const TextStyle(
              color: ColorsUtils.black,
              fontWeight: FontWeight.w600,
            ),

            children: isRequired
                ? const [
                    TextSpan(
                      text: " *",
                      style: TextStyle(color: ColorsUtils.red),
                    ),
                  ]
                : [],
          ),
        ),

        const SizedBox(height: 6),

        child,

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _dataCard(AuthViewModel authVM) {
    final warga = authVM.currentUser?.warga;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: ColorsUtils.lightgray,
        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: ColorsUtils.lightgray),
      ),

      child: Column(
        children: [
          _row("Nama", warga?.nama ?? "-"),

          _row("NIK", warga?.nik ?? "-"),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          SizedBox(
            width: 100,

            child: Text(label, style: const TextStyle(color: ColorsUtils.gray)),
          ),

          Expanded(
            child: Text(
              value,

              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
