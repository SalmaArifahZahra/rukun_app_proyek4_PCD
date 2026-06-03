import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/auth_viewmodel.dart';

class KontakPengurusPage extends StatelessWidget {
  const KontakPengurusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final nama = context.watch<AuthViewModel>().currentUser?.warga?.nama ?? "-";

    return Scaffold(
      backgroundColor: ColorsUtils.lightgray,

      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: nama,
        title: "Kontak Pengurus",
        subtitle: "Informasi Kontak Pengurus",
        showName: false,
        showAvatar: false,
        showGreeting: false,
      ),

      body: Align(
        alignment: const Alignment(0, -0.3),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    decoration: BoxDecoration(
                      color: ColorsUtils.b400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          "Hubungi RT/RW di Lingkungan Anda",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ColorsUtils.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Silakan hubungi pengurus apabila membutuhkan bantuan.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: ColorsUtils.white),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    top: -30,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ColorsUtils.white, 
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: ColorsUtils.white.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.support_agent,
                        color: ColorsUtils.b400,
                        size: 34,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorsUtils.b400,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ColorsUtils.white),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: ColorsUtils.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Pastikan menghubungi pengurus pada jam yang sesuai kecuali dalam keadaan darurat.",
                        style: TextStyle(
                          color: ColorsUtils.white,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
