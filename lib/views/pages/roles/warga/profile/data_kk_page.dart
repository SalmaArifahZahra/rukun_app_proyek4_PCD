import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/auth_viewmodel.dart';
import 'package:rukun_app_proyek4/viewmodels/roles/warga/profile/data_kk_viewmodel.dart';

class DataWargaPage extends StatefulWidget {
  const DataWargaPage({super.key});

  @override
  State<DataWargaPage> createState() => _DataWargaPageState();
}

class _DataWargaPageState extends State<DataWargaPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final authVM = context.read<AuthViewModel>();
      final vm = context.read<DataKKViewModel>();

      final warga = authVM.currentUser?.warga;
      final keluargaId = warga?.keluarga?.id;

      if (warga != null && keluargaId != null) {
        await vm.loadData(keluargaId: keluargaId, wargaLogin: warga);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nama = context.watch<AuthViewModel>().currentUser?.warga?.nama ?? "-";

    final vm = context.watch<DataKKViewModel>();
    final currentWarga = vm.currentWarga;

    if (vm.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: ColorsUtils.lightgray,
      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: nama,
        title: "Detail Kartu Keluarga",
        subtitle: "Lihat Detail identitas dan data anggota keluarga",
        showName: false,
        showAvatar: false,
        showGreeting: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: ColorsUtils.b400,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: ColorsUtils.b200,
                          child: Text(
                            currentWarga?.nama.substring(0, 1) ?? "?",
                            style: const TextStyle(
                              fontSize: 28,
                              color: ColorsUtils.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        Text(
                          currentWarga?.nama ?? "-",
                          style: const TextStyle(
                            color: ColorsUtils.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          currentWarga?.statusHubungan?.display ?? "-",
                          style: const TextStyle(
                            color: ColorsUtils.white,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: ColorsUtils.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildField("NIK", currentWarga?.nik),
                        _buildField(
                          "Golongan Darah",
                          currentWarga?.golonganDarah,
                        ),
                        _buildField("Tempat Lahir", currentWarga?.tempatLahir),
                        _buildField(
                          "Tgl Lahir",
                          currentWarga?.tglLahir?.toString().split(' ')[0],
                        ),
                        _buildField("Jenis Kelamin", currentWarga?.jk?.display),
                        _buildField("Agama", currentWarga?.agama?.display),
                        _buildField("Pendidikan", currentWarga?.pendidikan),
                        _buildField(
                          "Status Perkawinan",
                          currentWarga?.statusPerkawinan?.display,
                        ),
                        _buildField(
                          "Kewarganegaraan",
                          currentWarga?.kewarganegaraan?.display,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              title: "Data Orang Tua",
              children: [
                _buildField("Nama Ayah", currentWarga?.namaAyah),
                _buildField("Nama Ibu", currentWarga?.namaIbu),
              ],
            ),

            const SizedBox(height: 20),
            _buildSectionCard(
              title: "Data Identitas",
              children: [
                _buildField("No. KK", vm.keluarga?.noKK),
                _buildField("No. Kitap", "-"),
                _buildField("No. Paspor", "-"),
                _buildField("Kode Pos", vm.keluarga?.kodePos),
              ],
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  "Anggota Keluarga | ${vm.anggotaKeluarga.length} Jiwa",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            ...vm.anggotaKeluarga.map(
              (warga) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ColorsUtils.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 85,
                      decoration: BoxDecoration(
                        color: ColorsUtils.b400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  warga.nama,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              Text(
                                warga.statusHubungan?.display ?? "-",
                                style: TextStyle(
                                  color: ColorsUtils.b400,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          Text(
                            "NIK. ${warga.nik}",
                            style: const TextStyle(
                              color: ColorsUtils.gray,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: _miniInfo(
                                  "Jenis Kelamin",
                                  warga.jk?.display,
                                ),
                              ),

                              Expanded(
                                child: _miniInfo("Nama Ayah", warga.namaAyah),
                              ),

                              Expanded(
                                child: _miniInfo("Nama Ibu", warga.namaIbu),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: ColorsUtils.b400,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: ColorsUtils.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: ColorsUtils.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Wrap(spacing: 12, runSpacing: 12, children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String title, String? value) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 38,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),

          const SizedBox(height: 6),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: ColorsUtils.lightgray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value ?? "-",
              style: const TextStyle(color: ColorsUtils.gray, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(String title, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 10, color: ColorsUtils.gray),
        ),

        const SizedBox(height: 2),

        Text(
          value ?? "-",
          style: const TextStyle(fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
