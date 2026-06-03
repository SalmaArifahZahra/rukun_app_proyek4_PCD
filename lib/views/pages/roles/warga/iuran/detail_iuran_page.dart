import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/models/iuran/iuran_model.dart';
import 'package:rukun_app_proyek4/models/iuran/iuransaya_model.dart';
import 'package:rukun_app_proyek4/models/transaksi_model.dart';
import 'package:rukun_app_proyek4/models/user_model.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/status_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/roles/warga/iuran/iuranwarga_viewmodel.dart';
import 'package:rukun_app_proyek4/views/pages/roles/warga/iuran/warga_upload_iuran_page.dart';

class DetailIuranPage extends StatefulWidget {
  final IuranSaya item;
  final User user;

  const DetailIuranPage({super.key, required this.item, required this.user});

  @override
  State<DetailIuranPage> createState() => _DetailIuranPageState();
}

class _DetailIuranPageState extends State<DetailIuranPage> {
  late List<IuranItem> history;

  @override
  void initState() {
    super.initState();

    final vm = context.read<IuranwargaViewmodel>();
    history = vm.generateHistory(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsUtils.white,
      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: "",
        title: widget.item.iuran.nama,
        subtitle: "Detail & riwayat pembayaran iuran",
        showName: false,
        showAvatar: false,
        showGreeting: false,
      ),

      body: Column(
        children: [
          _IuranHeader(item: widget.item),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const _SectionTitle(title: "Riwayat Pembayaran"),

                const SizedBox(height: 14),

                ...history.map(
                  (data) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _MonthlyIuranCard(
                      item: widget.item,
                      data: data,
                      user: widget.user,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IuranHeader extends StatelessWidget {
  final IuranSaya item;

  const _IuranHeader({required this.item});

  bool get _isWajib => item.iuran.tipe == IuranType.reguler;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [ColorsUtils.b300, ColorsUtils.b500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorsUtils.b75.withOpacity(0.20),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.iuran.nama,
            style: const TextStyle(
              color: ColorsUtils.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          if (_isWajib && (item.iuran.jumlah ?? 0) > 0)
            Row(
              children: [
                const Icon(
                  Icons.payments_rounded,
                  color: ColorsUtils.white,
                  size: 18,
                ),

                const SizedBox(width: 6),

                Text(
                  "Rp ${item.iuran.jumlah}",
                  style: const TextStyle(
                    color: ColorsUtils.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else
            const Text(
              "Sukarela",
              style: TextStyle(
                color: ColorsUtils.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 20,
          decoration: BoxDecoration(
            color: ColorsUtils.b300,
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _MonthlyIuranCard extends StatelessWidget {
  final IuranSaya item;
  final IuranItem data;
  final User user;

  const _MonthlyIuranCard({
    required this.item,
    required this.data,
    required this.user,
  });

  bool _canUpload(StatusPembayaran status) {
    return status == StatusPembayaran.belumDibayar ||
        status == StatusPembayaran.ditolak;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsUtils.white,
        borderRadius: BorderRadius.circular(22),
        // ignore: deprecated_member_use
        border: Border.all(color: data.status.color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: ColorsUtils.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _MonthIndicator(date: data.bulan),

              const SizedBox(width: 14),

              Expanded(child: _MonthlyInfo(data: data)),

              const SizedBox(width: 10),

              _StatusBadge(status: data.status),
            ],
          ),
          if (_isProcessed(data.status))
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                "Menunggu verifikasi RT/RW",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 10),
          if (_canUpload(data.status)) ...[
            const SizedBox(height: 16),

            const Divider(height: 1),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _goToUpload(context, user, data),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: data.status == StatusPembayaran.ditolak
                      ? Colors.orange
                      : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(
                  data.status == StatusPembayaran.ditolak
                      ? Icons.refresh_rounded
                      : Icons.upload_file_rounded,
                ),
                label: Text(
                  data.status == StatusPembayaran.ditolak
                      ? "Upload Ulang Bukti Pembayaran"
                      : "Upload Bukti Pembayaran",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _goToUpload(
    BuildContext context,
    User user,
    IuranItem data,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            WargaUploadIuranPage(item: item, user: user, selectedItem: data),
      ),
    );

    if (result == true) {
      Navigator.pop(context, true);
    }
  }
}

bool _isProcessed(StatusPembayaran status) {
  return status == StatusPembayaran.diproses;
}

class _MonthIndicator extends StatelessWidget {
  final DateTime date;

  const _MonthIndicator({required this.date});

  @override
  Widget build(BuildContext context) {
    final month = date.month.toString().padLeft(2, '0');

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            month,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            "${date.year}",
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _MonthlyInfo extends StatelessWidget {
  final IuranItem data;

  const _MonthlyInfo({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _monthName(data.bulan.month),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 6),

        Text(
          _statusDescription(data.status),
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }

  String _statusDescription(StatusPembayaran status) {
    switch (status) {
      case StatusPembayaran.dibayar:
        return "Pembayaran berhasil diverifikasi";

      case StatusPembayaran.diproses:
        return "Pembayaran sedang diverifikasi admin";

      case StatusPembayaran.ditolak:
        return "Pembayaran ditolak, silakan upload ulang";

      case StatusPembayaran.belumDibayar:
        return "Belum melakukan pembayaran";
    }
  }
}

String _monthName(int month) {
  const months = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  return months[month];
}

class _StatusBadge extends StatelessWidget {
  final StatusPembayaran status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
