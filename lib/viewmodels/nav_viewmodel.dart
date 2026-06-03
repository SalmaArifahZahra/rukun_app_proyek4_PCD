import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/models/user_model.dart';
import 'package:rukun_app_proyek4/views/pages/kegiatan/kegiatan_page.dart';

// pages RW
import 'package:rukun_app_proyek4/views/pages/roles/rw/dashboard/rw_dashboard.dart';
import 'package:rukun_app_proyek4/views/pages/iuran/iuran_page.dart';
import 'package:rukun_app_proyek4/views/pages/roles/rw/penduduk/penduduk_page.dart';

// pages RT
import 'package:rukun_app_proyek4/views/pages/roles/rt/home_page.dart';
import 'package:rukun_app_proyek4/views/pages/roles/rt/penduduk/penduduk_page.dart';
import 'package:rukun_app_proyek4/views/pages/surat/surat_page.dart';

// pages Warga
import 'package:rukun_app_proyek4/views/pages/roles/warga/home_page.dart';
import 'package:rukun_app_proyek4/views/pages/roles/warga/iuran/iuran_page.dart';
import 'package:rukun_app_proyek4/views/pages/roles/warga/profile/profile_page.dart';
import 'package:rukun_app_proyek4/views/pages/roles/warga/surat/pengajuan_surat_page.dart';

class NavItem {
  final IconData icon;
  final String label;
  final Widget page;

  NavItem({required this.icon, required this.label, required this.page});
}

class NavViewModel {
  List<NavItem> getNavItems(User user) {
    // RW
    if (user.pengurus?.level == "RW") {
      return [
        NavItem(icon: Icons.home, label: "Home", page: const RwDashboard()),
        NavItem(
          icon: Icons.groups,
          label: "Penduduk",
          page: RWPendudukPage(user: user),
        ),
        NavItem(
          icon: Icons.payments,
          label: "Iuran",
          page: PengurusIuranPage(user: user),
        ),
        NavItem(
          icon: Icons.description,
          label: "Surat",
          page: SuratPage(user: user),
        ),
        NavItem(
          icon: Icons.event,
          label: "Kegiatan",
          page: const KegiatanPage(),
        ),
      ];
    }

    // RT
    if (user.pengurus?.level == "RT") {
      return [
        NavItem(icon: Icons.home, label: "Home", page: const RtHomePage()),
        NavItem(
          icon: Icons.groups,
          label: "Penduduk",
          page: RtPendudukPage(user: user),
        ),
        NavItem(
          icon: Icons.payments,
          label: "Iuran",
          page: PengurusIuranPage(user: user),
        ),
        NavItem(
          icon: Icons.description,
          label: "Surat",
          page: SuratPage(user: user),
        ),
        NavItem(
          icon: Icons.event,
          label: "Kegiatan",
          page: KegiatanPage(),
        ),
      ];
    }

    // Warga
    return [
      NavItem(
        icon: Icons.home,
        label: "Home",
        page: WargaHomePage(user: user),
      ),
      NavItem(
        icon: Icons.upload_file,
        label: "Upload",
        page: WargaIuranPage(user: user),
      ),
      NavItem(
        icon: Icons.description,
        label: "Surat",
        page: PengajuanSuratPage(user: user),
      ),
      NavItem(icon: Icons.person, label: "Profile", page: WargaProfilePage()),
    ];
  }
}
