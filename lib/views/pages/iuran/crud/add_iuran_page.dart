import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/models/user_model.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/models/iuran/iuran_model.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/notification_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/iuran/add_iuran_viewmodel.dart';

class AddIuranPage extends StatefulWidget {
  final User user;

  const AddIuranPage({super.key, required this.user});

  @override
  State<AddIuranPage> createState() => _AddIuranPageState();
}

class _AddIuranPageState extends State<AddIuranPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController namaController = TextEditingController();
  final TextEditingController jumlahController = TextEditingController();

  IuranType selectedType = IuranType.reguler;

  late String selectedLevel;

  @override
  void initState() {
    super.initState();

    selectedLevel = widget.user.pengurus?.level == "RT" ? "RT" : "RW";
  }

  bool get isKhusus => selectedType == IuranType.insidentil;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: "",
        title: "Tambah Iuran",
        subtitle: "Buat iuran baru untuk $selectedLevel",
        showName: false,
        showAvatar: false,
        showGreeting: false,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCard(
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: ColorsUtils.b200),
                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        "Anda membuat iuran untuk level $selectedLevel",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tipe Iuran",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        _buildTypeChip(IuranType.reguler, "Rutin"),
                        const SizedBox(width: 10),
                        _buildTypeChip(IuranType.insidentil, "Khusus"),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Nama Iuran",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: namaController,
                      decoration: const InputDecoration(
                        hintText: "Contoh: Iuran Kebersihan",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Wajib diisi" : null,
                    ),

                    const SizedBox(height: 16),

                    if (selectedType != IuranType.insidentil) ...[
                      const Text(
                        "Jumlah",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: jumlahController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: "Contoh: 50000",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          return v == null || v.isEmpty ? "Wajib diisi" : null;
                        },
                      ),

                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsUtils.b200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _submit,
                  child: const Text(
                    "Simpan Iuran",
                    style: TextStyle(color: ColorsUtils.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsUtils.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildTypeChip(IuranType type, String label) {
    final selected = selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = type;

          if (type == IuranType.insidentil) {
            jumlahController.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? ColorsUtils.b200 : ColorsUtils.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ColorsUtils.gray),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? ColorsUtils.white : ColorsUtils.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<AddIuranViewModel>();

    final jumlah = selectedType == IuranType.insidentil
        ? null
        : int.tryParse(jumlahController.text.trim());

    final success = await vm.createIuran(
      nama: namaController.text.trim(),
      jumlah: jumlah,
      level: selectedLevel,
      rw: widget.user.rw!,
      rt: selectedLevel == "RT" ? widget.user.rt! : null,
      tipe: selectedType,
    );

    if (!mounted) return;

    if (success) {
      NotificationUtils.showSuccess(context, "Iuran berhasil dibuat");
      Navigator.pop(context, true);
    } else {
      NotificationUtils.showError(
        context,
        vm.errorMessage ?? "Terjadi kesalahan",
      );
    }
  }
}
