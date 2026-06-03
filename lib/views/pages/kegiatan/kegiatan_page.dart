import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/models/kegiatan_model.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/notification_utils.dart';
import 'package:rukun_app_proyek4/utils/status_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/auth_viewmodel.dart';
import 'package:rukun_app_proyek4/viewmodels/kegiatan/kegiatan_viewmodel.dart';
import 'package:rukun_app_proyek4/views/pages/kegiatan/widgets/detail_kegiatan_modal.dart';
import 'package:rukun_app_proyek4/views/pages/kegiatan/widgets/tambah_kegiatan_modal.dart';
import 'package:rukun_app_proyek4/views/pages/kegiatan/widgets/upload_bukti_kegiatan_modal.dart';

class KegiatanPage extends StatefulWidget {
  const KegiatanPage({super.key});

  @override
  State<KegiatanPage> createState() => _KegiatanPageState();
}

class _KegiatanPageState extends State<KegiatanPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final authVm = context.read<AuthViewModel>();
      final kegiatanVm = context.read<KegiatanViewModel>();

      final user = authVm.currentUser;

      if (user != null) {
        kegiatanVm.setCurrentUser(user);
      }

      await kegiatanVm.fetchKegiatan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nama = context.watch<AuthViewModel>().currentUser?.warga?.nama ?? "-";

    return Scaffold(
      backgroundColor: ColorsUtils.lightgray,

      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: nama,
        title: "Detail Kegiatan",
        subtitle: "Buat Kegiatan anda Sekarang",
        showName: false,
        showAvatar: false,
        showGreeting: false,
      ),

      body: Consumer<KegiatanViewModel>(
        builder: (context, vm, _) {
          return RefreshIndicator(
            onRefresh: vm.refresh,

            child: Column(
              children: [
                _summary(vm),

                _levelSwitcher(vm),

                _statusFilter(vm),

                _buildSearch(vm),

                _headerKegiatan(context, vm),

                Expanded(
                  child: vm.kegiatanList.isEmpty
                      ? const Center(child: Text("Belum ada kegiatan"))
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),

                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),

                          itemCount: vm.kegiatanList.length,

                          itemBuilder: (_, i) {
                            final kegiatan = vm.kegiatanList[i];

                            return Column(
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(22),
                                  onTap: () => _openDetail(context, kegiatan),
                                  child: _card(context, vm, kegiatan),
                                ),

                                if (i == vm.kegiatanList.length - 1)
                                  const SizedBox(height: 40),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearch(KegiatanViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),

      child: TextField(
        onChanged: vm.setSearch,

        decoration: InputDecoration(
          hintText: "Cari kegiatan...",

          prefixIcon: const Icon(Icons.search),

          filled: true,
          fillColor: ColorsUtils.white,

          contentPadding: const EdgeInsets.symmetric(vertical: 0),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _headerKegiatan(BuildContext context, KegiatanViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),

      child: SizedBox(
        height: 48,

        child: Row(
          children: [
            const Expanded(
              child: Text(
                "Daftar Kegiatan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            if (vm.canCreateOnCurrentLevel())
              ElevatedButton(
                onPressed: () {
                  _openCreate(context);
                },

                style:
                    ElevatedButton.styleFrom(
                      backgroundColor: ColorsUtils.lightgray,
                      foregroundColor: ColorsUtils.black,

                      elevation: 0,

                      shadowColor: ColorsUtils.transparent,
                      surfaceTintColor: ColorsUtils.transparent,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),

                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ).copyWith(
                      overlayColor: WidgetStatePropertyAll(
                        ColorsUtils.transparent,
                      ),
                    ),

                child: const Text(
                  "+ Tambah",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summary(KegiatanViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(16),

      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              total: vm.totalDibuat,
              title: "Dibuat",
              color: ColorsUtils.skyblue,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: _summaryCard(
              total: vm.totalSelesai,
              title: "Selesai",
              color: ColorsUtils.g100,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: _summaryCard(
              total: vm.totalDibatalkan,
              title: "Dibatalkan",
              color: ColorsUtils.red,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: _summaryCard(
              total: vm.totalSemua,
              title: "Total",
              color: ColorsUtils.o100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required int total,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),

      decoration: BoxDecoration(
        color: ColorsUtils.white,
        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: ColorsUtils.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        children: [
          Text(
            "$total",

            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            textAlign: TextAlign.center,

            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _levelSwitcher(KegiatanViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),

      child: Row(
        children: [
          Expanded(
            child: _levelButton(
              selected: vm.selectedLevel == KegiatanLevel.rw,
              label: "RW",
              onTap: () => vm.setLevel(KegiatanLevel.rw),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: _levelButton(
              selected: vm.selectedLevel == KegiatanLevel.rt,
              label: "RT",
              onTap: () => vm.setLevel(KegiatanLevel.rt),
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelButton({
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),

        padding: const EdgeInsets.symmetric(vertical: 14),

        decoration: BoxDecoration(
          color: selected ? ColorsUtils.b300 : ColorsUtils.white,
          borderRadius: BorderRadius.circular(16),
        ),

        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? ColorsUtils.white : ColorsUtils.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusFilter(KegiatanViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),

      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,

        child: Row(
          children: [
            _chip(vm, "Semua", KegiatanFilterStatus.semua),

            _chip(vm, "Dibuat", KegiatanFilterStatus.dibuat),

            _chip(vm, "Dibatalkan", KegiatanFilterStatus.dibatalkan),

            _chip(vm, "Selesai", KegiatanFilterStatus.selesai),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    KegiatanViewModel vm,
    String label,
    KegiatanFilterStatus status,
  ) {
    final selected = vm.selectedStatus == status;

    return GestureDetector(
      onTap: () => vm.setStatus(status),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),

        margin: const EdgeInsets.only(right: 10, top: 8, bottom: 8),

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

        decoration: BoxDecoration(
          color: selected ? ColorsUtils.b300 : ColorsUtils.white,

          borderRadius: BorderRadius.circular(30),

          border: Border.all(
            color: selected ? ColorsUtils.b300 : ColorsUtils.lightgray,
          ),

          boxShadow: [
            BoxShadow(
              color: ColorsUtils.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Text(
          label,

          style: TextStyle(
            color: selected ? ColorsUtils.white : ColorsUtils.black,

            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, KegiatanViewModel vm, Kegiatan kegiatan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: ColorsUtils.white,
        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: ColorsUtils.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kegiatan.nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    if (kegiatan.level == KegiatanLevel.rt &&
                        kegiatan.rt?.noRt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          "RT ${kegiatan.rt?.noRt}",
                          style: TextStyle(
                            fontSize: 12,
                            color: ColorsUtils.slateGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              Row(
                children: [
                  _badge(kegiatan),

                  if (vm.canDelete(kegiatan)) ...[
                    const SizedBox(width: 8),

                    InkWell(
                      borderRadius: BorderRadius.circular(30),

                      onTap: () async {
                        showDialog(
                          context: context,

                          builder: (_) {
                            return AlertDialog(
                              title: const Text("Hapus Kegiatan"),

                              content: const Text(
                                "Kegiatan selesai akan dihapus. Apakah anda yakin?",
                              ),

                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },

                                  child: const Text("Batal"),
                                ),

                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorsUtils.red,
                                    foregroundColor: ColorsUtils.white,
                                  ),

                                  onPressed: () async {
                                    Navigator.pop(context);

                                    try {
                                      await vm.deleteKegiatan(kegiatan.id!);

                                      if (!context.mounted) return;

                                      NotificationUtils.showSuccess(
                                        context,
                                        "Kegiatan berhasil dihapus",
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;

                                      NotificationUtils.showError(
                                        context,
                                        vm.errorMessage ??
                                            "Gagal menghapus kegiatan",
                                      );
                                    }
                                  },

                                  icon: const Icon(Icons.delete_outline),

                                  label: const Text("Hapus"),
                                ),
                              ],
                            );
                          },
                        );
                      },

                      child: Container(
                        padding: const EdgeInsets.all(8),

                        decoration: BoxDecoration(
                          color: ColorsUtils.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: ColorsUtils.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: ColorsUtils.slateGray,
              ),

              const SizedBox(width: 8),
              Text(
                vm.formatTanggal(kegiatan),
                style: TextStyle(
                  color: ColorsUtils.slateGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Text(kegiatan.deskripsi ?? "-", style: const TextStyle(height: 1.5)),

          const SizedBox(height: 20),

          if (vm.isReadonly(kegiatan)) ...[
            Row(
              children: [
                Expanded(
                  child: _fullButton(
                    label: "Lihat Kegiatan",
                    onTap: () {
                      _openDetail(context, kegiatan);
                    },
                  ),
                ),
              ],
            ),
          ] else if (vm.canUploadBukti(kegiatan)) ...[
            Row(
              children: [
                Expanded(
                  child: _fullButton(
                    label: "Upload Bukti Kegiatan",
                    onTap: () {
                      _openUploadBukti(context, kegiatan);
                    },
                  ),
                ),
              ],
            ),
          ] else if (vm.isOngoing(kegiatan)) ...[
            Container(
              width: double.infinity,

              padding: const EdgeInsets.symmetric(vertical: 14),

              decoration: BoxDecoration(
                color: ColorsUtils.o100.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),

              child: const Center(
                child: Text(
                  "Kegiatan Sedang Berlangsung",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ColorsUtils.o100,
                  ),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                if (vm.canCancel(kegiatan))
                  Expanded(
                    child: _outlineButton(
                      label: "Batalkan",
                      color: ColorsUtils.red,
                      onTap: () async {
                        showDialog(
                          context: context,
                          builder: (_) {
                            return AlertDialog(
                              title: const Text("Batalkan Kegiatan"),
                              content: const Text(
                                "Apakah anda yakin ingin membatalkan kegiatan ini?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Tidak"),
                                ),

                                ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(context);

                                    final vm = context
                                        .read<KegiatanViewModel>();

                                    final success = await vm.batalkanKegiatan(
                                      kegiatan.id!,
                                    );

                                    if (!context.mounted) return;

                                    if (success) {
                                      NotificationUtils.showSuccess(
                                        context,
                                        "Kegiatan berhasil dibatalkan",
                                      );
                                    } else {
                                      NotificationUtils.showError(
                                        context,
                                        vm.errorMessage ??
                                            "Gagal membatalkan kegiatan",
                                      );
                                    }
                                  },
                                  child: const Text("Ya"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),

                if (vm.canCancel(kegiatan)) const SizedBox(width: 12),

                Expanded(
                  child: _fullButton(
                    label: vm.canEdit(kegiatan)
                        ? "Edit Kegiatan"
                        : "Lihat Kegiatan",

                    onTap: () {
                      if (vm.canEdit(kegiatan)) {
                        _openEdit(context, kegiatan);
                      } else {
                        _openDetail(context, kegiatan);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _badge(Kegiatan kegiatan) {
    final ui = kegiatan.uiStatus;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

      decoration: BoxDecoration(
        color: ui.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
      ),

      child: Text(
        ui.label,
        style: TextStyle(color: ui.color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,

      style: OutlinedButton.styleFrom(
        foregroundColor: color,

        side: BorderSide(color: color),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

        padding: const EdgeInsets.symmetric(vertical: 14),
      ),

      child: Text(label),
    );
  }

  Widget _fullButton({required String label, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,

      style: ElevatedButton.styleFrom(
        backgroundColor: ColorsUtils.b300,
        foregroundColor: ColorsUtils.white,

        elevation: 0,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

        padding: const EdgeInsets.symmetric(vertical: 14),
      ),

      child: Text(label),
    );
  }

  void _openDetail(BuildContext context, Kegiatan kegiatan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,

      backgroundColor: ColorsUtils.white,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),

      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.92,

          child: DetailKegiatanModal(kegiatan: kegiatan),
        );
      },
    );
  }

  void _openCreate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,

      backgroundColor: ColorsUtils.white,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),

      builder: (_) {
        return const FractionallySizedBox(
          heightFactor: 0.92,
          child: TambahKegiatanModal(),
        );
      },
    );
  }
}

void _openUploadBukti(BuildContext context, Kegiatan kegiatan) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: ColorsUtils.white,

    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),

    builder: (_) {
      return FractionallySizedBox(
        heightFactor: 0.75,
        child: UploadBuktiKegiatanModal(kegiatan: kegiatan),
      );
    },
  );
}

void _openEdit(BuildContext context, Kegiatan kegiatan) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: ColorsUtils.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return FractionallySizedBox(
        heightFactor: 0.92,
        child: TambahKegiatanModal(kegiatan: kegiatan),
      );
    },
  );
}
