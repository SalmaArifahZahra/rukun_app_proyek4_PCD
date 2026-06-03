import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/models/rt_model.dart';
import 'package:rukun_app_proyek4/models/user_model.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/roles/rw/penduduk/penduduk_rw_viewmodel.dart';
import 'package:rukun_app_proyek4/views/pages/penduduk/detail_rt_page.dart';

class RWPendudukPage extends StatefulWidget {
  final User user;

  const RWPendudukPage({super.key, required this.user});

  @override
  State<RWPendudukPage> createState() => _RWPendudukPageState();
}

class _RWPendudukPageState extends State<RWPendudukPage> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _isInitialized = true;

      final rwId = widget.user.rw?.id;

      if (rwId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<RWPendudukViewmodel>().init(rwId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rw = widget.user.rw?.noRw ?? '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: "",
        title: "Dashboard Kependudukan RW",
        subtitle: "Daftar RT dalam wilayah RW",
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
                      const Text(
                        'Wilayah Aktif',
                        style: TextStyle(fontSize: 12, color: ColorsUtils.gray),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RW $rw',
                        style: const TextStyle(
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
              'Daftar RT',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ColorsUtils.black800,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Consumer<RWPendudukViewmodel>(
                builder: (context, vm, _) {
                  if (vm.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (vm.errorMessage != null) {
                    return Center(child: Text(vm.errorMessage!));
                  }

                  if (vm.rtList.isEmpty) {
                    return const Center(child: Text('Belum ada data RT'));
                  }

                  return ListView.separated(
                    itemCount: vm.rtList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final rt = vm.rtList[index];
                      return _buildRTCard(rt);
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

  Widget _buildRTCard(RtModel rt) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailRTPage(
              rt: rt,
              rw: widget.user.rw!,
              currentUser: widget.user,
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
            const Icon(Icons.groups, size: 28, color: ColorsUtils.gray),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RT ${rt.noRt}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: ColorsUtils.black800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RT ${rt.noRt}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: ColorsUtils.gray,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: ColorsUtils.gray),
          ],
        ),
      ),
    );
  }
}
