import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/repositories/kk_repository.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/notification_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/penduduk/kartukeluarga/edit_kk_viewmodel.dart';

class EditKKPage extends StatelessWidget {
  final int idKK;

  const EditKKPage({super.key, required this.idKK});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditKKViewModel(
        kkRepository: context.read<KKRepository>(),
        idKK: idKK,
      ),
      child: const _EditKKView(),
    );
  }
}

class _EditKKView extends StatelessWidget {
  const _EditKKView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditKKViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: "",
        title: "Edit Kartu Keluarga",
        subtitle: "Halaman ubah kartu keluarga",
        showName: false,
        showAvatar: false,
        showGreeting: false,
      ),

      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(),

                const SizedBox(height: 16),

                _buildFormCard(context, vm),

                const SizedBox(height: 16),

                _buildSaveButton(context, vm),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsUtils.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: ColorsUtils.b50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit_document, color: ColorsUtils.b500),
          ),

          const SizedBox(width: 16),

          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Edit Data",
                style: TextStyle(fontSize: 12, color: ColorsUtils.gray),
              ),

              SizedBox(height: 4),

              Text(
                "Kartu Keluarga",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ColorsUtils.b400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, EditKKViewModel vm) {
    return _buildCard(
      header: _buildSectionHeader('Data Kartu Keluarga', Icons.home_outlined),
      child: Column(
        children: [
          TextFormField(
            initialValue: vm.noKK,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'No KK'),
            onChanged: (value) => vm.noKK = value,
          ),

          const SizedBox(height: 12),

          TextFormField(
            initialValue: vm.alamat,
            decoration: const InputDecoration(labelText: 'Alamat'),
            onChanged: (value) => vm.alamat = value,
          ),

          const SizedBox(height: 12),

          TextFormField(
            initialValue: vm.desa,
            decoration: const InputDecoration(labelText: 'Desa/Kelurahan'),
            onChanged: (value) => vm.desa = value,
          ),

          const SizedBox(height: 12),

          TextFormField(
            initialValue: vm.kecamatan,
            decoration: const InputDecoration(labelText: 'Kecamatan'),
            onChanged: (value) => vm.kecamatan = value,
          ),

          const SizedBox(height: 12),

          TextFormField(
            initialValue: vm.kodePos,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Kode Pos'),
            onChanged: (value) => vm.kodePos = value,
          ),

          const SizedBox(height: 16),

          _buildFotoKK(context, vm),
        ],
      ),
    );
  }

  Widget _buildFotoKK(BuildContext context, EditKKViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Foto Kartu Keluarga",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: vm.fotoKKUrl == null
                    ? null
                    : () {
                        showDialog(
                          context: context,
                          builder: (_) {
                            return Dialog(
                              backgroundColor: Colors.transparent,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: InteractiveViewer(
                                  child: Image.network(
                                    vm.fotoKKUrl!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                icon: const Icon(Icons.visibility_outlined),
                label: const Text("Preview"),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: ElevatedButton.icon(
                onPressed: vm.pickFotoKK,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsUtils.b500,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.upload),
                label: const Text("Upload Baru"),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorsUtils.b500),
            color: const Color(0xFFF9FAFB),
          ),
          child: vm.fotoKK != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        vm.fotoKK!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),

                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Foto Baru",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : vm.fotoKKUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    vm.fotoKKUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_outlined, size: 40),
                    SizedBox(height: 8),
                    Text("Belum ada foto KK"),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context, EditKKViewModel vm) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: vm.isSaving
            ? null
            : () async {
                await vm.updateKK();

                if (vm.errorMessage != null) {
                  NotificationUtils.showError(context, vm.errorMessage!);
                } else {
                  NotificationUtils.showSuccess(
                    context,
                    "Kartu Keluarga berhasil diperbarui",
                  );

                  Navigator.pop(context, true);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsUtils.b500,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: vm.isSaving
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Simpan Perubahan',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildCard({required Widget header, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          header,

          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(children: [Icon(icon), const SizedBox(width: 8), Text(title)]),
    );
  }
}
