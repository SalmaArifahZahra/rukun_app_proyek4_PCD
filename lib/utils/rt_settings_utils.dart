import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';

class RtSettingsUtils extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onProfile;
  final VoidCallback onExport;

  const RtSettingsUtils({
    super.key,
    required this.onLogout,
    required this.onProfile,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.settings, color: ColorsUtils.white),
      onSelected: (value) {
        switch (value) {
          case "profile":
            onProfile();
            break;
          case "export":
            onExport();
            break;
          case "logout":
            onLogout();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: "profile", child: Text("Info Akun")),
        const PopupMenuItem(value: "export", child: Text("Export Data")),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: "logout",
          child: Text("Keluar", style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
