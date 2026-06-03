import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/models/keluarga_model.dart';
import 'package:rukun_app_proyek4/repositories/warga_repository.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/notification_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/penduduk/kartukeluarga/detail_kk_viewmodel.dart';
import 'package:rukun_app_proyek4/viewmodels/penduduk/warga/add_warga_viewmodel.dart';
import 'package:rukun_app_proyek4/views/pages/penduduk/crudwarga/add_warga_page.dart';
import 'package:rukun_app_proyek4/views/pages/penduduk/crudkk/edit_kk_page.dart';
import 'package:rukun_app_proyek4/views/pages/penduduk/detail_warga_page.dart';

class DetailKKPage extends StatelessWidget {
  final int kkId;
  final int? currentUserKKId;
  final int? currentUserWargaId;

  const DetailKKPage({
    super.key,
    required this.kkId,
    this.currentUserKKId,
    this.currentUserWargaId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DetailKKViewModel(
        repo: context.read(),
        wargaRepo: context.read(),
        kkId: kkId,
      )..fetchDetail(),
      child: _DetailKKView(
        currentUserKKId: currentUserKKId,
        currentUserWargaId: currentUserWargaId,
      ),
    );
  }
}

class _DetailKKView extends StatelessWidget {
  final int? currentUserKKId;
  final int? currentUserWargaId;

  const _DetailKKView({this.currentUserKKId, this.currentUserWargaId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: "",
        title: "Detail Kartu Keluarga",
        subtitle: "Ringkasan data detail kartu keluarga",
        showName: false,
        showAvatar: false,
        showGreeting: false,
      ),

      body: Consumer<DetailKKViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.kk == null) {
            return const Center(child: Text("Data KK tidak ditemukan"));
          }

          final kk = vm.kk!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeaderCard(kk),
              const SizedBox(height: 16),
              _buildInfoCard(context, kk, vm),
              const SizedBox(height: 16),
              _buildAnggotaCard(context, kk, vm),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(Keluarga kk) {
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
            child: const Icon(Icons.credit_card, color: ColorsUtils.b500),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Kartu Keluarga",
                  style: TextStyle(fontSize: 12, color: ColorsUtils.gray),
                ),
                const SizedBox(height: 4),
                Text(
                  // kk.noKK ?? "-",
                  kk.noKK,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ColorsUtils.b400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    Keluarga kk,
    DetailKKViewModel vm,
  ) {
    final isOwnKK = kk.id == currentUserKKId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsUtils.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Informasi KK",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: ColorsUtils.black800,
            ),
          ),

          const SizedBox(height: 16),

          _buildInfoItem(Icons.home_outlined, "Alamat", kk.alamat ?? "-"),
          _buildInfoItem(Icons.map_outlined, "Desa/Kelurahan", kk.desa ?? "-"),
          _buildInfoItem(Icons.location_city_outlined, "Kecamatan", kk.kecamatan ?? "-"),
          _buildInfoItem(
            Icons.markunread_mailbox_outlined,
            "Kode Pos",
            kk.kodePos ?? "-",
          ),

          const SizedBox(height: 16),

          if ((kk.imgRef ?? '').isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showImagePreview(context, kk.imgRef!);
                },
                icon: const Icon(Icons.image_outlined),
                label: const Text("Lihat Foto KK"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorsUtils.b500,
                  side: BorderSide(color: ColorsUtils.b500),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditKKPage(idKK: kk.id!),
                      ),
                    );

                    if (result == true && context.mounted) {
                      try {
                        await context.read<DetailKKViewModel>().fetchDetail();

                        NotificationUtils.showSuccess(
                          context,
                          "Data KK berhasil diperbarui",
                        );
                      } catch (e) {
                        NotificationUtils.showError(
                          context,
                          "Gagal memuat ulang data KK",
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text("Edit KK"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorsUtils.b500,
                    side: const BorderSide(color: ColorsUtils.b500),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isOwnKK || vm.isDeleting
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Hapus KK"),
                              content: const Text(
                                "Apakah Anda yakin ingin menghapus kartu keluarga ini?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, false);
                                  },
                                  child: const Text("Batal"),
                                ),

                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context, true);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text("Hapus"),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            final success = await vm.deleteKK();

                            if (!context.mounted) return;

                            if (success) {
                              NotificationUtils.showSuccess(
                                context,
                                "Kartu Keluarga berhasil dihapus",
                              );

                              Navigator.pop(context, true);
                            } else {
                              NotificationUtils.showError(
                                context,
                                vm.error ?? "Gagal menghapus KK",
                              );
                            }
                          }
                        },
                  icon: vm.isDeleting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_outline),
                  label: Text(
                    isOwnKK
                        ? "KK Sendiri"
                        : vm.isDeleting
                        ? "Menghapus..."
                        : "Hapus",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ColorsUtils.gray),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: ColorsUtils.gray),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnggotaCard(
    BuildContext context,
    Keluarga kk,
    DetailKKViewModel vm,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsUtils.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Anggota Keluarga",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),

          const SizedBox(height: 12),

          if (vm.anggota.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                onChanged: vm.setSearch,
                decoration: InputDecoration(
                  hintText: 'Cari nama warga...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: ColorsUtils.b50),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: ColorsUtils.b500),
                  ),
                ),
              ),
            ),

          if (vm.isLoadingAnggota)
            const Center(child: CircularProgressIndicator())
          else if (vm.anggotaError != null)
            Text(vm.anggotaError!)
          else if (vm.anggota.isEmpty)
            _buildEmptyState(context, kk, vm)
          else if (vm.filteredAnggota.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Warga tidak ditemukan',
                  style: TextStyle(color: ColorsUtils.gray),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vm.filteredAnggota.length,
              itemBuilder: (context, i) {
                final warga = vm.filteredAnggota[i];

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailWargaPage(
                            wargaId: warga.id!,
                            currentUserWargaId: currentUserWargaId,
                          ),
                        ),
                      );

                      if (result == true && context.mounted) {
                        await vm.fetchAnggota();
                      }
                    },
                    leading: const CircleAvatar(
                      backgroundColor: ColorsUtils.b50,
                      child: Icon(Icons.person, color: ColorsUtils.b500),
                    ),
                    title: Text(warga.nama),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(warga.nik, style: const TextStyle(fontSize: 12)),
                        if (warga.isPendingSync) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                            child: const Text(
                              'Menunggu sinkron',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) => AddWargaViewModel(
                        repo: context.read<WargaRepository>(),
                        kkId: vm.kkId,
                      ),
                      child: AddWargaPage(keluarga: kk),
                    ),
                  ),
                );

                if (result == true) {
                  vm.fetchAnggota();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text("Tambah Anggota"),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    Keluarga kk,
    DetailKKViewModel vm,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorsUtils.b50),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: ColorsUtils.b50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.group_outlined,
              size: 32,
              color: ColorsUtils.b500,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "Belum Ada Anggota",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),

          const SizedBox(height: 4),

          const Text(
            "Tambahkan anggota keluarga untuk mulai mengelola data penduduk.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: ColorsUtils.gray),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) => AddWargaViewModel(
                        repo: context.read<WargaRepository>(),
                        kkId: vm.kkId,
                      ),
                      child: AddWargaPage(keluarga: kk),
                    ),
                  ),
                );

                vm.fetchAnggota();
              },
              icon: const Icon(Icons.add),
              label: const Text("Tambah Anggota"),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsUtils.b500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
