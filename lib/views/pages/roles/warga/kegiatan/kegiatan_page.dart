import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/models/kegiatan_model.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/status_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/auth_viewmodel.dart';
import 'package:rukun_app_proyek4/viewmodels/roles/warga/kegiatan/kegiatan_viewmodel.dart';

class KegiatanPage extends StatelessWidget {
  const KegiatanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final nama = context.watch<AuthViewModel>().currentUser?.warga?.nama ?? "-";

    return ChangeNotifierProvider(
      create: (_) => KegiatanViewmodel(),

      child: Scaffold(
        backgroundColor: ColorsUtils.lightgray,

        appBar: AppBarUtils.buildAppBar(
          context: context,
          name: nama,
          title: "Daftar Kegiatan",
          subtitle: "Lihat data kegiatan warga",
          showName: false,
          showAvatar: false,
          showGreeting: false,
        ),

        body: Consumer<KegiatanViewmodel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.errorMessage != null) {
              return Center(child: Text(vm.errorMessage!));
            }

            return Column(
              children: [
                _statusFilter(vm),

                const SizedBox(height: 8),

                Expanded(child: _list(vm)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statusFilter(KegiatanViewmodel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),

      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,

        child: Row(
          children: [
            _chip(vm, "Semua", FilterKegiatanStatus.semua),

            _chip(vm, "Berlangsung", FilterKegiatanStatus.berlangsung),

            _chip(vm, "Segera", FilterKegiatanStatus.segera),

            _chip(vm, "Selesai", FilterKegiatanStatus.selesai),

            _chip(vm, "Dibatalkan", FilterKegiatanStatus.dibatalkan),
          ],
        ),
      ),
    );
  }

  Widget _chip(KegiatanViewmodel vm, String text, FilterKegiatanStatus status) {
    final selected = vm.selectedStatus == status;

    return GestureDetector(
      onTap: () => vm.setStatus(status),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),

        margin: const EdgeInsets.only(right: 10),

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

        decoration: BoxDecoration(
          color: selected ? ColorsUtils.b300 : Colors.grey.shade100,

          borderRadius: BorderRadius.circular(30),

          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),

        child: Text(
          text,

          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,

            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _list(KegiatanViewmodel vm) {
    if (vm.data.isEmpty) {
      return const Center(child: Text("Tidak ada kegiatan"));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),

      itemCount: vm.data.length,

      itemBuilder: (context, index) {
        return _card(vm.data[index]);
      },
    );
  }

  Widget _card(Kegiatan item) {
    final ui = item.uiStatus;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: ui.color.withOpacity(0.15)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),

            blurRadius: 12,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 6,
            height: 78,

            decoration: BoxDecoration(
              color: ui.color,

              borderRadius: BorderRadius.circular(20),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.nama,

                        style: const TextStyle(
                          fontWeight: FontWeight.bold,

                          fontSize: 16,
                        ),
                      ),
                    ),

                    _badge(ui),
                  ],
                ),

                const SizedBox(height: 6),

                if (item.deskripsi != null)
                  Text(
                    item.deskripsi!,

                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,

                      size: 15,

                      color: Colors.grey.shade600,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      _tanggal(item),

                      style: TextStyle(
                        color: Colors.grey.shade700,

                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Icon(
                      Icons.groups_rounded,

                      size: 16,

                      color: Colors.grey.shade600,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      item.level == KegiatanLevel.rt ? "RT" : "RW",

                      style: TextStyle(
                        color: Colors.grey.shade700,

                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(KegiatanUiStatus ui) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

      decoration: BoxDecoration(
        color: ui.color.withOpacity(0.15),

        borderRadius: BorderRadius.circular(30),
      ),

      child: Text(
        ui.label,

        style: TextStyle(
          color: ui.color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _tanggal(Kegiatan item) {
    final mulai = item.tanggalMulai;

    final selesai = item.tanggalSelesai;

    if (selesai == null) {
      return "${mulai.day} "
          "${_month(mulai.month)} "
          "${mulai.year}";
    }

    return "${mulai.day} "
        "${_month(mulai.month)} - "
        "${selesai.day} "
        "${_month(selesai.month)} "
        "${selesai.year}";
  }

  String _month(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return months[month];
  }
}
