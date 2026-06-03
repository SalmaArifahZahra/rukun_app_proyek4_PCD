import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/models/dashboard_model.dart';
import 'package:rukun_app_proyek4/models/kegiatan_model.dart';
import 'package:rukun_app_proyek4/repositories/dashboard_repository.dart';

class RtDashboardViewModel extends ChangeNotifier {
  final DashboardRepository repository;

  RtDashboardViewModel(this.repository);

  DashboardModel? dashboard;

  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchDashboard() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      dashboard = await repository.getDashboardRT();
    } catch (e) {
      errorMessage = e.toString();
      debugPrint("ERROR DASHBOARD RT: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  double get saldoKas => (dashboard?.rt?.saldoKas ?? 0).toDouble();
  double get kasMasuk => (dashboard?.kas?.totalMasuk ?? 0).toDouble();
  double get kasKeluar => (dashboard?.kas?.totalKeluar ?? 0).toDouble();

  // Convenience getters
  int get totalPenduduk => dashboard?.totalPenduduk ?? 0;
  int get jumlahKk => dashboard?.jumlahKk ?? 0;
  int get totalSurat => dashboard?.statusSurat.total ?? 0;
  int get suratPending => dashboard?.statusSurat.diajukan ?? 0;
  int get suratDiproses => dashboard?.statusSurat.disetujui ?? 0;
  int get totalPria => dashboard?.gender.pria ?? 0;
  int get totalWanita => dashboard?.gender.wanita ?? 0;
  int get totalAnak => dashboard?.ageDistribution.anak ?? 0;
  int get totalProduktif => dashboard?.ageDistribution.produktif ?? 0;
  int get totalLansia => dashboard?.ageDistribution.lansia ?? 0;

  List<Kegiatan> get kegiatan => dashboard?.kegiatan ?? [];
}
