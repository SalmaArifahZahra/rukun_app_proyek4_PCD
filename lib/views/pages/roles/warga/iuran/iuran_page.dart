import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/models/iuran/iuran_model.dart';
import 'package:rukun_app_proyek4/models/iuran/iuransaya_model.dart';
import 'package:rukun_app_proyek4/models/user_model.dart';
import 'package:rukun_app_proyek4/repositories/iuran_repository.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/status_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/auth_viewmodel.dart';
import 'package:rukun_app_proyek4/viewmodels/roles/warga/iuran/iuranwarga_viewmodel.dart';
import 'package:rukun_app_proyek4/views/pages/roles/warga/iuran/detail_iuran_page.dart';

class WargaIuranPage extends StatefulWidget {
  final User user;

  const WargaIuranPage({super.key, required this.user});

  @override
  State<WargaIuranPage> createState() => _WargaIuranPageState();
}

class _WargaIuranPageState extends State<WargaIuranPage> {
  late IuranwargaViewmodel vm;

  @override
  void initState() {
    super.initState();

    vm = IuranwargaViewmodel(context.read<IuranRepository>());
    vm.loadIuranSaya();
  }

  @override
  Widget build(BuildContext context) {
    final nama = context.watch<AuthViewModel>().currentUser?.warga?.nama ?? "-";

    return ChangeNotifierProvider.value(
      value: vm,
      child: Scaffold(
        backgroundColor: ColorsUtils.white,

        appBar: AppBarUtils.buildAppBar(
          context: context,
          name: nama,
          title: "Iuran Saya",
          subtitle: "Kelola & lihat pembayaran",
          showName: false,
          showAvatar: false,
          showGreeting: false,
        ),

        body: Consumer<IuranwargaViewmodel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.errorMessage != null) {
              return Center(child: Text(vm.errorMessage!));
            }

            return Column(
              children: [
                _summary(vm),

                const SizedBox(height: 4),

                _typeToggle(vm),

                _statusFilter(vm),

                const SizedBox(height: 10),

                Expanded(child: _list(vm)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _summary(IuranwargaViewmodel vm) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [ColorsUtils.b300, ColorsUtils.b400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.blue.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(child: _summaryItem(vm.totalDibayar, "Dibayar")),

              Expanded(child: _summaryItem(vm.totalDiproses, "Diproses")),

              Expanded(child: _summaryItem(vm.totalBelum, "Belum")),

              Expanded(child: _summaryItem(vm.totalKeseluruhan, "Total")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(int value, String title) {
    return Column(
      children: [
        Text(
          "$value",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  Widget _typeToggle(IuranwargaViewmodel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: ColorsUtils.lightgray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _typeItem(vm, "Wajib", IuranType.reguler),
            _typeItem(vm, "Sedekah", IuranType.insidentil),
          ],
        ),
      ),
    );
  }

  Widget _typeItem(IuranwargaViewmodel vm, String text, IuranType type) {
    final selected = vm.selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => vm.setType(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? ColorsUtils.b400 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusFilter(IuranwargaViewmodel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip(vm, "Semua", FilterStatus.semua),
            _chip(vm, "Tagihan", FilterStatus.belumDibayar),
            _chip(vm, "Diproses", FilterStatus.diproses),
            _chip(vm, "Dibayar", FilterStatus.dibayar),
            _chip(vm, "Ditolak", FilterStatus.ditolak),
          ],
        ),
      ),
    );
  }

  Widget _chip(IuranwargaViewmodel vm, String text, FilterStatus status) {
    final selected = vm.selectedStatus == status;

    return GestureDetector(
      onTap: () => vm.setStatus(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? ColorsUtils.b300 : ColorsUtils.lightgray,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey.shade300,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.blue.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
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

  Widget _list(IuranwargaViewmodel vm) {
    if (vm.data.isEmpty) {
      return const Center(child: Text("Tidak ada data iuran"));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: vm.data.length,
      itemBuilder: (context, index) {
        return _card(context, vm, vm.data[index]);
      },
    );
  }

  Widget _card(BuildContext context, IuranwargaViewmodel vm, IuranSaya item) {
    final status = vm.getStatusSummary(item);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: context.read<IuranwargaViewmodel>(),
              child: DetailIuranPage(item: item, user: widget.user),
            ),
          ),
        );

        if (result == true) {
          context.read<IuranwargaViewmodel>().refresh();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorsUtils.white,
          borderRadius: BorderRadius.circular(22),
          // ignore: deprecated_member_use
          border: Border.all(color: status.color.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: ColorsUtils.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 70,
              decoration: BoxDecoration(
                color: status.color,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.iuran.nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (item.iuran.tipe == IuranType.reguler &&
                      (item.iuran.jumlah ?? 0) > 0)
                    Row(
                      children: [
                        Icon(
                          Icons.payments_rounded,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),

                        const SizedBox(width: 6),

                        Text(
                          "Rp ${item.iuran.jumlah}",
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    )
                  else
                    Text(
                      "Sukarela",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: status.color,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                status.label,
                style: const TextStyle(
                  color: ColorsUtils.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
