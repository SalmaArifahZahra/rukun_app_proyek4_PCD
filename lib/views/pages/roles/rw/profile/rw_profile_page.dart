import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/auth_viewmodel.dart';

class RwProfilePage extends StatelessWidget {
  const RwProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final nama = context.watch<AuthViewModel>().currentUser?.warga?.nama ?? "-";

    return Scaffold(
      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: nama,
        title: "Detail Profile",
        subtitle: "Ubah Kata Sandi anda",
        showName: false,
        showAvatar: false,
        showGreeting: false,
      ),
      body: const Center(child: Text("Halaman Profile RW")),
    );
  }
}
