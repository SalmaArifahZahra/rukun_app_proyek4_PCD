import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/auth_viewmodel.dart';
import 'package:rukun_app_proyek4/viewmodels/export_data_viewmodel.dart';

class ExportPage extends StatelessWidget {
  const ExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final nama = user?.warga?.nama ?? "-";

    return Scaffold(
      backgroundColor: ColorsUtils.lightgray,
      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: nama,
        title: "Export Laporan",
        subtitle: "Unduh Data Laporan",
        showName: false,
        showAvatar: false,
        showGreeting: false,
      ),
      body: Consumer<ExportDataViewModel>(
        builder: (context, vm, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Pilih Data untuk Diekspor",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                _buildExportCard(
                  title: "Data Kependudukan (Excel)",
                  subtitle: "Berisi seluruh data Kartu Keluarga dan Warga.",
                  icon: Icons.table_view_outlined,
                  isExporting: vm.isExporting,
                  onTap: () async {
                    if (user != null) {
                      final success = await vm.exportDataKependudukan(user);
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isExporting,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isExporting ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: ColorsUtils.b50,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: ColorsUtils.b500),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              if (isExporting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.download, color: ColorsUtils.b500),
            ],
          ),
        ),
      ),
    );
  }
}
