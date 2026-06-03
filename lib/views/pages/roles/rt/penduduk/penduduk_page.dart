import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/models/user_model.dart';
import 'package:rukun_app_proyek4/utils/notification_utils.dart';
import 'package:rukun_app_proyek4/views/pages/penduduk/detail_rt_page.dart';

class RtPendudukPage extends StatelessWidget {
  final User user;

  const RtPendudukPage({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final rt = user.rt;
    final rw = user.rw;

    if (rt == null || rw == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationUtils.showError(
          context,
          'Data RT / RW tidak ditemukan',
        );

        Navigator.pop(context);
      });

      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return DetailRTPage(
      rt: rt,
      rw: rw,
      currentUser: user,
    );
  }
}