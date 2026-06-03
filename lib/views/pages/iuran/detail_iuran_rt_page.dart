import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/models/iuran/iuran_model.dart';
import 'package:rukun_app_proyek4/models/transaksi_model.dart';
import 'package:rukun_app_proyek4/models/user_model.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/iuran/iuran_rt_detail_viewmodel.dart';
import 'package:rukun_app_proyek4/views/pages/iuran/detail_iuran_bulanan_page.dart';
import 'package:rukun_app_proyek4/views/pages/iuran/widgets/setoran_approval_modal.dart';
import 'package:rukun_app_proyek4/views/pages/iuran/widgets/setoran_form_modal.dart';

class IuranRTDetailPage extends StatefulWidget {
  final int iuranId;
  final int rtId;
  final User user;
  final bool showSetoranButton;

  const IuranRTDetailPage({
    super.key,
    required this.iuranId,
    required this.rtId,
    required this.user,
    this.showSetoranButton = false,
  });

  @override
  State<IuranRTDetailPage> createState() => _IuranRTDetailPageState();
}

class _IuranRTDetailPageState extends State<IuranRTDetailPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final vm = context.read<IuranRTDetailViewModel>();

      await vm.fetchDetail(widget.iuranId, widget.rtId);

      final iuran = vm.iuran;
      if (iuran == null) return;

      final startDate = iuran.waktuDibuat ?? DateTime.now();
      final months = generateMonths(startDate);

      for (final month in months) {
        await vm.loadSetoranPeriode(widget.iuranId, widget.rtId, month);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsUtils.lightgray,
      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: "",
        title: "Detail Iuran RT",
        subtitle: "Status iuran & periode bulan",
        showName: false,
        showAvatar: false,
        showGreeting: false,
      ),
      body: Consumer<IuranRTDetailViewModel>(
        builder: (context, vm, _) {
          final iuran = vm.iuran;
          final level = widget.user.pengurus?.level.toLowerCase();
          final isRTUser = level == "rt";
          final isRWUser = level == "rw";

          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.errorMessage != null) {
            return Center(child: Text(vm.errorMessage!));
          }

          if (iuran == null) {
            return const Center(child: Text("Data tidak ditemukan"));
          }

          final rt = vm.rtDetail;

          final transaksi = vm.transaksi;

          final startDate = iuran.waktuDibuat ?? DateTime.now();
          final months = generateMonths(startDate);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryCard(iuran: iuran, terkumpul: vm.totalTerkumpul),
                const SizedBox(height: 16),
                _buildInfoGrid(iuran),
                const SizedBox(height: 16),
                if (rt != null) _buildRtInfo(rt),
                const SizedBox(height: 16),

                _buildMonthlyList(
                  months,
                  transaksi,
                  rt?.totalKeluarga ?? 0,
                  rt?.id ?? 0,
                  iuran.id ?? 0,
                  isRTUser,
                  isRWUser,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({required Iuran iuran, required int terkumpul}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsUtils.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            iuran.nama,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBadge(iuran.level.name.toUpperCase(), ColorsUtils.gray),
              const SizedBox(width: 8),
              _buildBadge(iuran.tipe.name.toUpperCase(), ColorsUtils.green),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat(title: "Total Terkumpul", value: "Rp.$terkumpul"),
              _MiniStat(title: "Biaya Iuran", value: "Rp.${iuran.jumlah}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(Iuran iuran) {
    String waktuDibuatText() {
      if (iuran.waktuDibuat == null) return "-";
      return DateFormat('dd MMMM yyyy', 'id_ID').format(iuran.waktuDibuat!);
    }

    String tipeText() {
      if (iuran.tipe == IuranType.insidentil) {
        return "Iuran bersifat insidentil, sekali bayar dan seikhlasnya";
      }
      return "Iuran bersifat reguler dan dibayarkan secara berkala";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsUtils.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Informasi Iuran",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.event, text: "Dibuat: ${waktuDibuatText()}"),
          _InfoRow(icon: Icons.info, text: tipeText()),
        ],
      ),
    );
  }

  Widget _buildRtInfo(dynamic rt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsUtils.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Informasi RT",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.home_work_outlined,
            text: "RT ${rt.noRt ?? '-'}",
          ),
          _InfoRow(icon: Icons.person, text: "Ketua: ${rt.ketua ?? '-'}"),
          _InfoRow(
            icon: Icons.account_balance_wallet_outlined,
            text: "Bendahara: ${rt.bendahara ?? '-'}",
          ),
          _InfoRow(
            icon: Icons.groups_outlined,
            text: "Total Keluarga: ${rt.totalKeluarga ?? 0}",
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyList(
    List<DateTime> months,
    List<Transaksi> transaksi,
    int totalKeluarga,
    int rtId,
    int iuranId,
    bool isRTUser,
    bool isRWUser,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Periode Iuran",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...months.map((month) {
          final label = DateFormat('MMMM yyyy', 'id_ID').format(month);
          final vm = context.read<IuranRTDetailViewModel>();

          final transaksiBulan = transaksi.where((t) {
            final tDate = t.waktuBayar;
            if (tDate == null) return false;

            return tDate.year == month.year &&
                tDate.month == month.month &&
                t.status == StatusPembayaran.dibayar;
          }).toList();

          final jumlahPembayar = transaksiBulan.length;

          final totalPendapatan = transaksiBulan.fold<int>(
            0,
            (sum, item) => sum + (item.jumlah ?? 0),
          );

          final progress = "$jumlahPembayar/$totalKeluarga";

          final key = vm.periodeKey(iuranId, rtId, month);
          final setoran = vm.setoranPerPeriode[key];

          final status = setoran?.status;
          final isLocalPending = setoran?.id != null && (setoran!.id! < 0);
          final isBelumSetor = setoran == null;
          final isPending = status == "Dikirim";
          final isApproved = status == "Diterima";
          final isRejected = status == "Ditolak";

          Color statusColor() {
            if (isApproved) return Colors.green;
            if (isPending) return Colors.orange;
            if (isRejected) return Colors.red;
            return Colors.red;
          }

          String statusText() {
            if (isApproved) return "DISETUJUI";
            if (isPending) return "SUDAH SETOR";
            if (isRejected) return "DITOLAK";
            return "BELUM SETOR";
          }

          return InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailIuranBulananPage(
                    iuranId: iuranId,
                    rtId: rtId,
                    month: month,
                    user: widget.user,
                  ),
                ),
              );

              if (context.mounted) {
                context.read<IuranRTDetailViewModel>().fetchDetail(
                  widget.iuranId,
                  widget.rtId,
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ColorsUtils.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Progress: $progress"),
                      Text(
                        "Rp $totalPendapatan",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor(),
                          ),
                        ),
                      ),
                      if (isLocalPending) ...[
                        const SizedBox(width: 8),
                        _buildBadge('Sinkronisasi', Colors.orange),
                      ],
                    ],
                  ),

                  const SizedBox(height: 10),
                  if (isRTUser || isRWUser)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(
                          isBelumSetor
                              ? Icons.account_balance_wallet
                              : isPending
                              ? Icons.hourglass_bottom
                              : Icons.visibility,
                        ),

                        label: Text(
                          isBelumSetor
                              ? (isRWUser ? "Review Setoran" : "Setor ke RW")
                              : isPending
                              ? (isRWUser
                                    ? "Review Setoran"
                                    : "Menunggu Approval")
                              : (isRWUser
                                    ? "Lihat & Approval"
                                    : "Lihat Detail"),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final vm = context.read<IuranRTDetailViewModel>();

                          if (isRWUser) {
                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => SetoranApprovalModal(
                                label: label,
                                month: month,
                                iuranId: iuranId,
                                rtId: rtId,
                                jumlahPembayar: jumlahPembayar,
                                totalPendapatan: totalPendapatan,
                                saldoKasRt: vm.saldoKasRt,
                                detailSetoran: setoran,
                              ),
                            );
                            return;
                          }

                          // RT FLOW
                          if (!isBelumSetor) {
                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => SetoranFormModal(
                                isDetail: true,
                                label: label,
                                month: month,
                                iuranId: iuranId,
                                rtId: rtId,
                                jumlahPembayar: jumlahPembayar,
                                totalPendapatan: totalPendapatan,
                                saldoKasRt: vm.saldoKasRt,
                                detailSetoran: setoran,
                              ),
                            );
                            return;
                          }

                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => SetoranFormModal(
                              isDetail: false,
                              label: label,
                              month: month,
                              iuranId: iuranId,
                              rtId: rtId,
                              jumlahPembayar: jumlahPembayar,
                              totalPendapatan: totalPendapatan,
                              saldoKasRt: vm.saldoKasRt,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<DateTime> generateMonths(DateTime start) {
    final now = DateTime.now();
    final months = <DateTime>[];

    var current = DateTime(start.year, start.month);

    while (current.isBefore(DateTime(now.year, now.month + 1))) {
      months.add(current);
      current = DateTime(current.year, current.month + 1);
    }

    return months;
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;

  const _MiniStat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: ColorsUtils.b200),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
