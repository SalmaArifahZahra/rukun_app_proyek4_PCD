import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/models/iuran/iuran_model.dart';
import 'package:rukun_app_proyek4/models/iuran/iuransaya_model.dart';
import 'package:rukun_app_proyek4/models/user_model.dart';
import 'package:rukun_app_proyek4/repositories/iuran_repository.dart';
import 'package:rukun_app_proyek4/services/utils/cloudinary_service.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/utils/notification_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/roles/warga/iuran/iuranwarga_viewmodel.dart';
import 'package:rukun_app_proyek4/viewmodels/roles/warga/iuran/upload_iuran_viewmodel.dart';

class WargaUploadIuranPage extends StatelessWidget {
  final IuranSaya item;
  final User user;
  final IuranItem selectedItem;

  const WargaUploadIuranPage({
    super.key,
    required this.item,
    required this.user,
    required this.selectedItem,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UploadIuranViewModel(
        item: item,
        keluargaId: user.keluarga!.id!,
        selectedItem: selectedItem,
        cloudinaryService: context.read<CloudinaryService>(),
        iuranRepository: context.read<IuranRepository>(),
      ),
      child: const _UploadView(),
    );
  }
}

class _UploadView extends StatefulWidget {
  const _UploadView();

  @override
  State<_UploadView> createState() => _UploadViewState();
}

class _UploadViewState extends State<_UploadView> {
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UploadIuranViewModel>();
    final item = vm.item;
    final isSedekah = item.iuran.tipe == IuranType.insidentil;

    return Scaffold(
      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: "",
        title: "Upload Iuran",
        subtitle: "Upload bukti pembayaran",
        showName: false,
        showAvatar: false,
        showGreeting: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              _infoCard(),

              const SizedBox(height: 16),

              // jml
              if (isSedekah)
                _inputWrapper(
                  title: "Jumlah Dibayar",
                  isRequired: true,
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    onChanged: vm.setJumlah,
                    decoration: const InputDecoration(
                      hintText: "Masukkan jumlah",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Jumlah wajib diisi";
                      }

                      if (int.tryParse(value) == null) {
                        return "Harus berupa angka";
                      }

                      return null;
                    },
                  ),
                )
              else
                _inputWrapper(
                  title: "Jumlah Dibayar",
                  child: TextFormField(
                    initialValue: "Rp ${item.iuran.jumlah ?? 0}",
                    enabled: false,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

              // file bukti
              _inputWrapper(
                title: "Bukti Pembayaran",
                isRequired: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: vm.pickBukti,
                      child: Container(
                        width: double.infinity,
                        height: 170,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue),
                          color: vm.buktiFile == null
                              ? const Color(0xFFF9FAFB)
                              : Colors.transparent,
                        ),
                        child: vm.buktiFile == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.upload_file, size: 40),
                                  SizedBox(height: 8),
                                  Text("Upload Bukti Transfer"),
                                  SizedBox(height: 4),
                                  Text(
                                    "Format JPG/PNG",
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ],
                              )
                            : Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      vm.buktiFile!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    if (vm.buktiFile == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          "Bukti wajib diupload",
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _button(context, vm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        "Upload bukti transfer dengan jelas (nama & nominal terlihat)",
        style: TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _inputWrapper({
    required String title,
    required Widget child,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black,
              ),
              children: isRequired
                  ? const [
                      TextSpan(
                        text: " *",
                        style: TextStyle(color: Colors.red),
                      ),
                    ]
                  : [],
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _button(BuildContext context, UploadIuranViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: vm.isLoading
                ? null
                : () async {
                    // validasi form
                    if (!formKey.currentState!.validate()) return;

                    // validasi bukti file
                    if (vm.buktiFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Bukti pembayaran wajib diupload"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    await vm.submit();

                    if (vm.errorMessage != null) {
                      NotificationUtils.showError(context, vm.errorMessage!);
                    } else if (vm.isSuccess) {
                      NotificationUtils.showSuccess(context, "Berhasil upload");

                      Navigator.pop(context, true);
                    }
                  },
            icon: const Icon(Icons.send),
            label: Text(vm.isLoading ? "Mengirim..." : "Kirim Bukti"),
          ),
        ),
      ],
    );
  }
}
