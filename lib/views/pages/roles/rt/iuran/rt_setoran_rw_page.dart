import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/models/transaksi_model.dart';
import 'package:rukun_app_proyek4/models/user_model.dart';
import 'package:rukun_app_proyek4/repositories/iuran_repository.dart';
import 'package:rukun_app_proyek4/services/utils/cloudinary_service.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/notification_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/auth_viewmodel.dart';
import 'package:rukun_app_proyek4/viewmodels/iuran/iuran_rt_detail_viewmodel.dart';
import 'package:rukun_app_proyek4/viewmodels/roles/rt/rt_upload_setoran_rw_viewmodel.dart';

class RTSetoranRWPage extends StatelessWidget {
  final int iuranId;
  final int rtId;
  final User user;

  const RTSetoranRWPage({
    super.key,
    required this.iuranId,
    required this.rtId,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final nama = context.watch<AuthViewModel>().currentUser?.warga?.nama ?? "-";

    final detailVm = context.watch<IuranRTDetailViewModel>();

    final bulanIni = DateTime.now();

    final transaksiBulan = detailVm.transaksi.where((t) {
      final waktu = t.waktuBayar;

      if (waktu == null) return false;

      return waktu.month == bulanIni.month &&
          waktu.year == bulanIni.year &&
          t.status == StatusPembayaran.dibayar;
    }).toList();

    final totalSetoran = transaksiBulan.fold<int>(
      0,
      (sum, item) => sum + (item.jumlah ?? 0),
    );

    final totalKK = detailVm.rtDetail?.totalKeluarga ?? 0;

    final semuaSudahBayar = transaksiBulan.length >= totalKK && totalKK > 0;

    return ChangeNotifierProvider(
      create: (_) => RTUploadSetoranRWViewModel(
        repository: context.read<IuranRepository>(),
        cloudinaryService: context.read<CloudinaryService>(),
      ),
      child: _Content(
        nama: nama,
        bulanIni: bulanIni,
        transaksiBulan: transaksiBulan,
        totalKK: totalKK,
        totalSetoran: totalSetoran,
        semuaSudahBayar: semuaSudahBayar,
        iuranId: iuranId,
      ),
    );
  }
}

class _Content extends StatefulWidget {
  final String nama;
  final DateTime bulanIni;
  final List<Transaksi> transaksiBulan;
  final int totalKK;
  final int totalSetoran;
  final bool semuaSudahBayar;
  final int iuranId;

  const _Content({
    required this.nama,
    required this.bulanIni,
    required this.transaksiBulan,
    required this.totalKK,
    required this.totalSetoran,
    required this.semuaSudahBayar,
    required this.iuranId,
  });

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RTUploadSetoranRWViewModel>();

    return Scaffold(
      backgroundColor: ColorsUtils.lightgray,

      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: widget.nama,
        title: "Laporan & Setoran Iuran",
        subtitle: "Setoran iuran RT ke RW",
        showName: false,
        showAvatar: false,
        showGreeting: false,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryCard(),

            const SizedBox(height: 20),

            if (!widget.semuaSudahBayar) _warningCard(),

            if (widget.semuaSudahBayar) ...[
              _infoCard(),

              const SizedBox(height: 20),

              _uploadSection(vm),

              const SizedBox(height: 28),

              _buttonSection(vm),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('MMMM yyyy', 'id_ID').format(widget.bulanIni),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 14),

          Text(
            "Rp ${widget.totalSetoran}",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ColorsUtils.green,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Pembayar: ${widget.transaksiBulan.length}/${widget.totalKK} KK",
          ),
        ],
      ),
    );
  }

  Widget _warningCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        "Belum semua KK melakukan pembayaran. "
        "Setoran ke RW belum dapat dilakukan.",
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        "Upload bukti transfer setoran RT ke RW "
        "dengan jelas dan nominal sesuai.",
        style: TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _uploadSection(RTUploadSetoranRWViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Bukti Transfer *",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        const SizedBox(height: 8),

        GestureDetector(
          onTap: vm.pickBukti,
          child: Container(
            width: double.infinity,
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
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

                      Text("Format JPG / PNG", style: TextStyle(fontSize: 11)),
                    ],
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(vm.buktiFile!.path),
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
              "Bukti transfer wajib diupload",
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buttonSection(RTUploadSetoranRWViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Batal"),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: ElevatedButton.icon(
            onPressed: vm.isLoading
                ? null
                : () async {
                    if (vm.buktiFile == null) {
                      NotificationUtils.showError(
                        context,
                        "Bukti transfer wajib diupload",
                      );
                      return;
                    }

                    final success = await vm.submit(
                      iuranId: widget.iuranId,
                      nominal: widget.totalSetoran,
                    );

                    if (!mounted) return;

                    if (success) {
                      NotificationUtils.showSuccess(
                        context,
                        "Setoran berhasil dikirim",
                      );

                      Navigator.pop(context, true);
                    } else {
                      NotificationUtils.showError(
                        context,
                        vm.errorMessage ?? "Gagal upload setoran",
                      );
                    }
                  },
            icon: const Icon(Icons.send),
            label: Text(vm.isLoading ? "Mengirim..." : "Kirim Setoran"),
          ),
        ),
      ],
    );
  }
}
