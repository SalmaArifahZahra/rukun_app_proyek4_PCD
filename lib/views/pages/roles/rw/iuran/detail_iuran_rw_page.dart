import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/models/iuran/iuran_model.dart';
import 'package:rukun_app_proyek4/models/user_model.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/roles/rw/iuran/detail_iuran_rw_viewmodel.dart';
import 'package:rukun_app_proyek4/views/pages/iuran/detail_iuran_rt_page.dart';

class IuranRWDetailPage extends StatefulWidget {
  final int id;
  final User user;

  const IuranRWDetailPage({super.key, required this.id, required this.user});

  @override
  State<IuranRWDetailPage> createState() => _IuranRWDetailPageState();
}

class _IuranRWDetailPageState extends State<IuranRWDetailPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<IuranRWDetailViewModel>().fetchDetail(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: "",
        title: "Detail Iuran",
        subtitle: "Informasi iuran & status RT",
        showName: false,
        showAvatar: false,
        showGreeting: false,
      ),

      body: Consumer<IuranRWDetailViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.errorMessage != null) {
            return Center(child: Text(vm.errorMessage!));
          }

          final detail = vm.detail;
          if (detail == null) {
            return const Center(child: Text("Data tidak ditemukan"));
          }

          final summary = detail.summary;
          final rtList = detail.rtList;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryCard(
                  total: detail.iuran.jumlah ?? 0,
                  terkumpul: summary['total_terkumpul'] ?? 0,
                  iuran: detail.iuran,
                ),

                const SizedBox(height: 16),

                _buildInfoGrid(detail.iuran),

                const SizedBox(height: 16),

                _buildRtSection(rtList),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required int total,
    required int terkumpul,
    required Iuran iuran,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
              _buildBadge(iuran.level.name.toUpperCase(), Colors.grey),

              const SizedBox(width: 8),

              _buildBadge(iuran.tipe.name.toUpperCase(), Colors.green),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat(title: "Total Terkumpul", value: "Rp.$terkumpul"),
              _MiniStat(title: "Biaya Iuran", value: "Rp.$total"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(Iuran iuran) {
    String waktuDibuatText() {
      if (iuran.waktuDibuat == null) return "null";

      return DateFormat('dd MMMM yyyy', 'id_ID').format(iuran.waktuDibuat!);
    }

    String tipeText() {
      if (iuran.tipe == IuranType.insidentil) {
        return "Iuran bersifat insidentil, sekali bayar dan seikhlasnya";
      }

      return "Iuran bersifat reguler dan dibayarkan secara berkala";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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

  Widget _buildRtSection(List rtList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Status RT",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        ...rtList.map((rt) {
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IuranRTDetailPage(
                    iuranId: widget.id,
                    rtId: rt.rtId,
                    user: widget.user,
                    showSetoranButton: false,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "RT ${rt.noRt}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text("Ketua: ${rt.ketua}"),
                  Text("Bendahara: ${rt.bendahara}"),

                  const SizedBox(height: 10),

                  Text(
                    "Total Terkumpul: Rp.${rt.totalBayar}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 8),

          Expanded(
            child: Text(text, softWrap: true, overflow: TextOverflow.visible),
          ),
        ],
      ),
    );
  }
}
