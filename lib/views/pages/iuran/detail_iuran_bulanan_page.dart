import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/models/iuran/iuran_model.dart';
import 'package:rukun_app_proyek4/models/iuran/keluarga_status_model.dart';
import 'package:rukun_app_proyek4/models/transaksi_model.dart';
import 'package:rukun_app_proyek4/models/user_model.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/notification_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/iuran/iuran_bulanan_detail_viewmodel.dart';

class DetailIuranBulananPage extends StatefulWidget {
  final int iuranId;
  final int rtId;
  final DateTime month;
  final User user;

  const DetailIuranBulananPage({
    super.key,
    required this.iuranId,
    required this.rtId,
    required this.month,
    required this.user,
  });

  @override
  State<DetailIuranBulananPage> createState() => _DetailIuranBulananPageState();
}

class _DetailIuranBulananPageState extends State<DetailIuranBulananPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<IuranBulananDetailViewModel>().fetchDetail(
        widget.iuranId,
        widget.rtId,
        widget.month,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(widget.month);

    return Scaffold(
      backgroundColor: ColorsUtils.lightgray,

      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: "",
        title: "Detail Bulan",
        subtitle: monthLabel,
        showName: false,
        showAvatar: false,
        showGreeting: false,
      ),

      body: Consumer<IuranBulananDetailViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.errorMessage != null) {
            return Center(child: Text(vm.errorMessage!));
          }

          final iuran = vm.iuran;
          final rt = vm.rtDetail;

          if (iuran == null || rt == null) {
            return const Center(child: Text("Data tidak ditemukan"));
          }

          final list = vm.getKeluargaStatus(widget.month, widget.iuranId);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryCard(iuran, vm.totalTerkumpul),

                const SizedBox(height: 16),

                _buildInfoGrid(iuran),

                const SizedBox(height: 16),

                _buildRtInfo(rt),

                const SizedBox(height: 16),

                _buildMonthCard(widget.month),

                const SizedBox(height: 16),

                _buildKKList(list),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(Iuran iuran, int terkumpul) {
    return _card(
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
              _badge(iuran.level.name.toUpperCase(), ColorsUtils.gray),
              const SizedBox(width: 8),
              _badge(iuran.tipe.name.toUpperCase(), ColorsUtils.green),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat(title: "Terkumpul", value: "Rp $terkumpul"),
              _MiniStat(title: "Iuran", value: "Rp ${iuran.jumlah}"),
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

  Widget _buildMonthCard(DateTime month) {
    final label = DateFormat('MMMM yyyy', 'id_ID').format(month);

    return _card(
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: ColorsUtils.b200),
          const SizedBox(width: 10),
          Text(
            "Periode: $label",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildKKList(List<KeluargaStatus> list) {
    final diprosesList = list
        .where((e) => e.status == StatusPembayaran.diproses)
        .toList();

    final selesaiList = list
        .where((e) => e.status != StatusPembayaran.diproses)
        .toList();

    final isRW = widget.user.pengurus?.level.toLowerCase() == "rw";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (diprosesList.isNotEmpty) ...[
          const Text(
            "Menunggu Persetujuan",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          const SizedBox(height: 12),

          ...diprosesList.map((k) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ColorsUtils.o100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColorsUtils.o100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          k.keluarga.noKK,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (k.idTransaksi != null && k.idTransaksi! < 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Sinkronisasi',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "STATUS: DIPROSES",
                    style: TextStyle(
                      color: ColorsUtils.o100,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text("Rp ${k.nominal}"),

                  Text(
                    "Tanggal Bayar: "
                    "${k.waktuBayar == null ? '-' : DateFormat('dd MMMM yyyy', 'id_ID').format(k.waktuBayar!)}",
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                child: InteractiveViewer(
                                  child: Image.network(
                                    k.imgBukti ?? '',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Text("Gagal memuat gambar"),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.image),
                          label: const Text("Lihat Bukti"),
                        ),
                      ),
                    ],
                  ),

                  if (!isRW) ...[
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorsUtils.red,
                              foregroundColor: ColorsUtils.white,
                            ),
                            onPressed: () {
                              final alasanController = TextEditingController();

                              showDialog(
                                context: context,
                                builder: (_) {
                                  return AlertDialog(
                                    title: const Text("Tolak Pembayaran"),

                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Masukkan alasan penolakan pembayaran.",
                                        ),

                                        const SizedBox(height: 14),

                                        TextField(
                                          controller: alasanController,
                                          maxLines: 3,
                                          decoration: InputDecoration(
                                            hintText:
                                                "Contoh: Bukti pembayaran tidak jelas",
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text("Cancel"),
                                      ),

                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: ColorsUtils.red,
                                          foregroundColor: ColorsUtils.white,
                                        ),
                                        onPressed: () async {
                                          final alasan = alasanController.text
                                              .trim();

                                          if (alasan.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Alasan penolakan wajib diisi",
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          final vm = context
                                              .read<
                                                IuranBulananDetailViewModel
                                              >();

                                          final success = await vm
                                              .updateStatusTransaksi(
                                                transaksiId: k.idTransaksi!,
                                                status: "Ditolak",
                                                catatan: alasan,
                                                iuranId: widget.iuranId,
                                                rtId: widget.rtId,
                                                month: widget.month,
                                              );

                                          if (context.mounted) {
                                            Navigator.pop(context);

                                            if (success) {
                                              NotificationUtils.showSuccess(
                                                context,
                                                "Pembayaran berhasil ditolak",
                                              );
                                            } else {
                                              NotificationUtils.showError(
                                                context,
                                                "Gagal menolak pembayaran",
                                              );
                                            }
                                          }
                                        },
                                        child: const Text("Tolak"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.close),
                            label: const Text("Tolak"),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorsUtils.green,
                              foregroundColor: ColorsUtils.white,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) {
                                  return AlertDialog(
                                    title: const Text("Terima Pembayaran"),

                                    content: const Text(
                                      "Apakah Anda yakin ingin menerima pembayaran ini?",
                                    ),

                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text("Cancel"),
                                      ),

                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: ColorsUtils.green,
                                          foregroundColor: ColorsUtils.white,
                                        ),
                                        onPressed: () async {
                                          final vm = context
                                              .read<
                                                IuranBulananDetailViewModel
                                              >();

                                          final success = await vm
                                              .updateStatusTransaksi(
                                                transaksiId: k.idTransaksi!,
                                                status: "Dibayar",
                                                iuranId: widget.iuranId,
                                                rtId: widget.rtId,
                                                month: widget.month,
                                              );

                                          if (context.mounted) {
                                            Navigator.pop(context);

                                            if (success) {
                                              NotificationUtils.showSuccess(
                                                context,
                                                "Pembayaran berhasil diterima",
                                              );
                                            } else {
                                              NotificationUtils.showError(
                                                context,
                                                "Gagal menerima pembayaran",
                                              );
                                            }
                                          }
                                        },
                                        child: const Text("Terima"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.check),
                            label: const Text("Terima"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          Container(
            height: 1,
            width: double.infinity,
            color: ColorsUtils.gray.withOpacity(0.5),
          ),

          const SizedBox(height: 24),
        ],

        const Text(
          "Daftar Keluarga RT",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),

        const SizedBox(height: 12),

        ...selesaiList.map((k) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ColorsUtils.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        k.keluarga.noKK,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (k.idTransaksi != null && k.idTransaksi! < 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Sinkronisasi',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  k.sudahBayar ? "LUNAS" : "BELUM",
                  style: TextStyle(
                    color: k.sudahBayar ? ColorsUtils.green : ColorsUtils.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                if (k.sudahBayar) ...[
                  Text("Rp ${k.nominal}"),

                  Text(
                    "Tanggal Bayar: "
                    "${k.waktuBayar == null ? '-' : DateFormat('dd MMMM yyyy', 'id_ID').format(k.waktuBayar!)}",
                  ),

                  Text("Disetujui oleh: ${k.disetujuiOleh ?? '-'}"),

                  const SizedBox(height: 10),

                  if (k.imgBukti != null && k.imgBukti!.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            child: InteractiveViewer(
                              child: Image.network(
                                k.imgBukti!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text("Gagal memuat gambar"),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.image),
                      label: const Text("Lihat Bukti"),
                    ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsUtils.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Widget _badge(String text, Color color) {
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
