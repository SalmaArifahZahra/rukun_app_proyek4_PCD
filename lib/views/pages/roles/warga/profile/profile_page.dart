import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/utils/avatar_utils.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/logout_dialog_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/auth_viewmodel.dart';
import 'package:rukun_app_proyek4/viewmodels/roles/warga/profile/kelola_profile_viewmodel.dart';
import 'package:rukun_app_proyek4/views/pages/roles/warga/profile/data_kk_page.dart';
import 'package:rukun_app_proyek4/views/pages/roles/warga/profile/warga_profile_page.dart';
import 'package:rukun_app_proyek4/views/pages/roles/warga/profile/kontak_pengurus_page.dart';
import 'package:rukun_app_proyek4/views/pages/welcome_page.dart';

class WargaProfilePage extends StatelessWidget {
  const WargaProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    final warga = authVM.currentUser;

    final nama = warga?.warga?.nama ?? "-";
    final nik = warga?.warga?.nik ?? "-";

    return Scaffold(
      backgroundColor: ColorsUtils.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, bottom: 30),
                decoration: const BoxDecoration(color: ColorsUtils.b400),
                child: Column(
                  children: [
                    buildAvatar(nama),

                    const SizedBox(height: 12),

                    Text(
                      nama,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ColorsUtils.white,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "NIK. $nik",
                      style: const TextStyle(color: ColorsUtils.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 70),

              buildMenuCard(
                icon: Icons.group,
                title: "Data Kartu Keluarga",
                subtitle: "Informasi identitas dan anggota keluarga",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DataWargaPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              buildMenuCard(
                icon: Icons.manage_accounts,
                title: "Akun Saya",
                subtitle: "Kelola profile dan ubah kata sandi",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => KelolaProfileViewModel(),
                        child: const KelolaProfilePage(),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              buildMenuCard(
                icon: Icons.support_agent,
                title: "Kontak Pengurus",
                subtitle: "Informasi kontak pengurus RT/RW",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const KontakPengurusPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              buildMenuCard(
                icon: Icons.logout_rounded,
                title: "Keluar",
                subtitle: "Logout dari aplikasi",
                iconColor: Colors.red,
                iconBg: Colors.red.shade50,
                onTap: () async {
                  final confirm = await LogoutDialogUtils.showLogoutDialog(
                    context,
                  );

                  if (confirm == true) {
                    await authVM.logout();

                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WelcomePage(),
                        ),
                        (route) => false,
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = Colors.blue,
    Color? iconBg,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg ?? Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }
}
