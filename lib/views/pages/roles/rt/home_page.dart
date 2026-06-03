import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/logout_dialog_utils.dart';
import 'package:rukun_app_proyek4/utils/rt_settings_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/auth_viewmodel.dart';
import 'package:rukun_app_proyek4/viewmodels/rt/rt_dashboard_viewmodel.dart';
import 'package:rukun_app_proyek4/viewmodels/export_data_viewmodel.dart';
import 'package:rukun_app_proyek4/views/pages/roles/rt/profile_page.dart';
import 'package:rukun_app_proyek4/views/pages/welcome_page.dart';

class RtHomePage extends StatefulWidget {
  const RtHomePage({super.key});

  @override
  State<RtHomePage> createState() => _RtHomePageState();
}

class _RtHomePageState extends State<RtHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RtDashboardViewModel>().fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final namaUser = authVM.currentUser?.warga?.nama ?? "Ketua RT";

    return Scaffold(
      backgroundColor: ColorsUtils.lightgray,

      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: namaUser,
        title: "",
        subtitle: "",
        showAvatar: true,
        showName: true,
        showGreeting: true,
        settingsWidget: RtSettingsUtils(
          onProfile: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RtProfilePage()),
            );
          },
          onExport: () async {
            final vm = context.read<ExportDataViewModel>();
            if (authVM.currentUser != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Memproses file Excel...")),
              );
              final success = await vm.exportDataKependudukan(authVM.currentUser!);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Berhasil mengekspor data!")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(vm.errorMessage ?? "Gagal mengekspor data"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
          onLogout: () async {
            final confirm = await LogoutDialogUtils.showLogoutDialog(context);

            if (confirm == true) {
              await authVM.logout();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomePage()),
                (route) => false,
              );
            }
          },
        ),
      ),

      body: Consumer<RtDashboardViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Error: ${viewModel.errorMessage}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (viewModel.dashboard == null) {
            return const Center(child: Text("Data belum tersedia"));
          }

          final int totalGender = viewModel.totalWanita + viewModel.totalPria;
          final double progressWanita =
              totalGender > 0 ? viewModel.totalWanita / totalGender : 0.0;

          return RefreshIndicator(
            onRefresh: viewModel.fetchDashboard,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. KAS CARD (GRADIENT)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [ColorsUtils.b300, ColorsUtils.b500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Saldo Kas RT",
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        "Rp ${NumberFormat('#,###', 'id_ID').format(viewModel.saldoKas.toInt())}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _kasInfo(
                            "Kas Masuk",
                            "+ Rp ${NumberFormat('#,###', 'id_ID').format(viewModel.kasMasuk.toInt())}",
                          ),
                          _kasInfo(
                            "Kas Keluar",
                            "- Rp ${NumberFormat('#,###', 'id_ID').format(viewModel.kasKeluar.toInt())}",
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Text("Diperbarui",
                                  style: TextStyle(
                                      color: Colors.white60, fontSize: 10)),
                              Text("Hari Ini",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // 2. STATS GRID (2x2)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.6,
                  children: [
                    _statCard("Total Penduduk", viewModel.totalPenduduk.toString()),
                    _statCard("Jumlah KK", viewModel.jumlahKk.toString()),
                    _statCard("Surat Pending", viewModel.suratPending.toString()),
                    _statCard("Surat Diproses", viewModel.suratDiproses.toString()),
                  ],
                ),
                const SizedBox(height: 30),

                // 3. DEMOGRAFI UMUM
                const Text("Demografi Umum",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.female, color: Colors.pink, size: 18),
                    Text(" Wanita (${viewModel.totalWanita})",
                        style: const TextStyle(fontSize: 13)),
                    const Spacer(),
                    Text("Pria (${viewModel.totalPria}) ",
                        style: const TextStyle(fontSize: 13)),
                    const Icon(Icons.male, color: ColorsUtils.b300, size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progressWanita,
                    minHeight: 10,
                    backgroundColor: ColorsUtils.b200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                  ),
                ),
                const SizedBox(height: 25),

                // 4. BERDASARKAN USIA
                const Text("Berdasarkan Usia",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _ageRow(Icons.child_care, "Anak", "(0-15 tahun)",
                    viewModel.totalAnak.toString()),
                _ageRow(Icons.accessibility_new, "Usia Produktif", "(15-64 tahun)",
                    viewModel.totalProduktif.toString()),
                _ageRow(Icons.elderly, "Lansia", "(>64 tahun)",
                    viewModel.totalLansia.toString()),
                const SizedBox(height: 30),

                // 5. KEGIATAN BERLANGSUNG
                Row(
                  children: const [
                    Icon(Icons.calendar_month, color: ColorsUtils.b300),
                    SizedBox(width: 10),
                    Text("Kegiatan Berlangsung",
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 15),

                if (viewModel.kegiatan.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: const Text("Belum ada kegiatan berlangsung"),
                  )
                else
                  ...viewModel.kegiatan.map((item) {
                    final now = DateTime.now();
                    final bool isBerlangsung = item.isBerlangsung;
                    final bool isUpcoming =
                        item.tanggalMulai.isAfter(now) && !isBerlangsung;

                    final String statusText =
                        isBerlangsung ? "BERLANGSUNG" : (isUpcoming ? "UPCOMING" : item.status.name.toUpperCase());
                    final Color statusColor =
                        isBerlangsung ? ColorsUtils.green : ColorsUtils.b300;

                    final String dateRange = item.tanggalSelesai != null
                        ? "${DateFormat('dd MMM yyyy', 'id_ID').format(item.tanggalMulai)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(item.tanggalSelesai!)}"
                        : DateFormat('dd MMM yyyy', 'id_ID').format(item.tanggalMulai);

                    return _kegiatanCard(
                      status: statusText,
                      statusColor: statusColor,
                      title: item.nama,
                      desc: item.deskripsi ?? "-",
                      date: dateRange,
                    );
                  }).toList(),

                const SizedBox(height: 80), // Jarak biar nggak nabrak bottom nav
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _kasInfo(String label, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        Text(amount,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: ColorsUtils.gray, fontSize: 13)),
          const SizedBox(height: 5),
          Text(value,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _ageRow(IconData icon, String label, String range, String count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: ColorsUtils.b300),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 5),
            Text(range, style: const TextStyle(color: ColorsUtils.gray, fontSize: 12)),
            const Spacer(),
            Text(count,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _kegiatanCard({
    required String status,
    required Color statusColor,
    required String title,
    required String desc,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(status,
                style: TextStyle(
                    color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(desc,
              style: const TextStyle(color: ColorsUtils.gray, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Text(date,
              style: const TextStyle(color: ColorsUtils.darkgray, fontSize: 12)),
        ],
      ),
    );
  }
}