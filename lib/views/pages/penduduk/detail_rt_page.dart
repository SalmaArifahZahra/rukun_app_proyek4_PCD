import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/core/route_observer.dart';
import 'package:rukun_app_proyek4/models/keluarga_model.dart';
import 'package:rukun_app_proyek4/models/rt_model.dart';
import 'package:rukun_app_proyek4/models/rw_model.dart';
import 'package:rukun_app_proyek4/models/user_model.dart';
import 'package:rukun_app_proyek4/repositories/kk_repository.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/penduduk/kartukeluarga/add_kk_viewmodel.dart';
import 'package:rukun_app_proyek4/viewmodels/penduduk/detail_rt_viewmodel.dart';
import 'package:rukun_app_proyek4/viewmodels/export_data_viewmodel.dart';
import 'package:rukun_app_proyek4/views/pages/penduduk/crudkk/add_kk_page.dart';
import 'package:rukun_app_proyek4/views/pages/penduduk/detail_kk_page.dart';

class DetailRTPage extends StatefulWidget {
  final RtModel rt;
  final RwModel rw;
  final User currentUser;

  const DetailRTPage({
    super.key,
    required this.rt,
    required this.rw,
    required this.currentUser,
  });

  @override
  State<DetailRTPage> createState() => _DetailRTPageState();
}

class _DetailRTPageState extends State<DetailRTPage> with RouteAware {
  bool _isInitialized = false;

  @override
  void didPopNext() {
    final rtId = widget.rt.id;
    context.read<DetailRTViewmodel>().loadKK(rtId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    routeObserver.subscribe(this, ModalRoute.of(context)!);

    if (!_isInitialized) {
      _isInitialized = true;

      final rtId = widget.rt.id;
      context.read<DetailRTViewmodel>().init(rtId!);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;

    final rt = widget.rt.noRt;
    final rw = widget.rw.noRw;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: "",
        title: "Dashboard Kependudukan",
        subtitle: "Ringkasan data kependudukan",
        showName: false,
        showAvatar: false,
        showGreeting: false,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorsUtils.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: ColorsUtils.b50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_city,
                      color: ColorsUtils.b500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wilayah Aktif',
                        style: TextStyle(fontSize: 12, color: ColorsUtils.gray),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'RT $rt / RW $rw',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ColorsUtils.b400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Daftar Kartu Keluarga',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ColorsUtils.black800,
              ),
            ),

            const SizedBox(height: 12),

            _buildAddButton(context, user),

            const SizedBox(height: 12),

            Expanded(
              child: Consumer<DetailRTViewmodel>(
                builder: (context, vm, _) {
                  if (vm.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (vm.errorMessage != null) {
                    return Center(child: Text(vm.errorMessage!));
                  }

                  if (vm.kkList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text("Belum ada data KK"),
                          SizedBox(height: 8),
                          Text("Tekan + untuk menambah"),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: vm.kkList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final kk = vm.kkList[index];
                      return _buildKKCard(kk);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKKCard(Keluarga kk) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailKKPage(
              kkId: kk.id!,
              currentUserKKId: widget.currentUser.warga?.keluarga?.id,
              currentUserWargaId: widget.currentUser.wargaId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ColorsUtils.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.credit_card, size: 28, color: ColorsUtils.gray),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No. KK: ${kk.noKK}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: ColorsUtils.black800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kk.alamat ?? '-',
                    style: const TextStyle(
                      fontSize: 12,
                      color: ColorsUtils.gray,
                    ),
                  ),
                ],
              ),
            ),

            Consumer<ExportDataViewModel>(
              builder: (context, vm, child) {
                return IconButton(
                  icon: const Icon(Icons.download, color: ColorsUtils.b500),
                  tooltip: 'Export KK',
                  onPressed: vm.isExporting
                      ? null
                      : () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Memproses file Excel...")),
                          );
                          final success = await vm.exportDataPerKeluarga(kk);
                          if (context.mounted) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Berhasil mengekspor data KK!")),
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
                        },
                );
              },
            ),

            const Icon(Icons.chevron_right, color: ColorsUtils.gray),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, User user) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                create: (_) => AddKKViewModel(
                  kkRepository: context.read<KKRepository>(),
                  rtId: widget.rt.id!,
                ),
                child: const AddKKPage(),
              ),
            ),
          ).then((_) {
            final rtId = widget.rt.id;
            context.read<DetailRTViewmodel>().init(rtId!);
          });
        },
        icon: const Icon(Icons.add),
        label: const Text("Tambah Kartu Keluarga"),
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorsUtils.b500,
          side: BorderSide(color: ColorsUtils.b500, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
