import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/models/user_model.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/menucard_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/auth_viewmodel.dart';
import 'package:rukun_app_proyek4/views/pages/roles/warga/kegiatan/kegiatan_page.dart';
import 'package:rukun_app_proyek4/views/pages/roles/warga/iuran/iuran_page.dart';
import 'package:rukun_app_proyek4/views/pages/roles/warga/surat/pengajuan_surat_page.dart';

class WargaHomePage extends StatelessWidget {
  final User user;

  const WargaHomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final nama = authVM.currentUser?.warga?.nama ?? "-";

    final menus = [
      {
        "title": "Ajukan Surat",
        "subtitle": "Buat pengajuan surat",
        "image": "assets/images/add_surat.png",
        "builder": (BuildContext context) => PengajuanSuratPage(user: user),
      },
      {
        "title": "Iuran Saya",
        "subtitle": "Status & bukti pembayaran",
        "image": "assets/images/fee.png",
        "builder": (BuildContext context) => WargaIuranPage(user: user),
      },
      {
        "title": "Daftar Kegiatan",
        "subtitle": "Lihat daftar kegiatan yang sedang dilaksanakan",
        "image": "assets/images/history_surat.png",
        "builder": (BuildContext context) => const KegiatanPage(),
      },
    ];
    return Scaffold(
      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: nama,
        title: "",
        showName: true,
        showAvatar: true,
        showGreeting: true,
        trailing: IconButton(
          icon: const Icon(Icons.notifications_none, color: ColorsUtils.white),
          onPressed: () {},
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          const Text(
            "Menu Utama",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 12),
          ...menus.map((menu) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MenuCard(
                title: menu["title"] as String,
                subtitle: menu["subtitle"] as String,
                imagePath: menu["image"] as String,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          (menu["builder"] as Widget Function(BuildContext))(
                            context,
                          ),
                    ),
                  );
                },
              ),
            );
          }),

          const SizedBox(height: 24),
          const Text(
            "Aktivitas Terbaru",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text("Belum ada aktivitas")),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
