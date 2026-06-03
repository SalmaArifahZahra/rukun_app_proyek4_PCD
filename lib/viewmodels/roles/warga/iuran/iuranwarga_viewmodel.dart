import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/models/iuran/iuran_model.dart';
import 'package:rukun_app_proyek4/models/iuran/iuransaya_model.dart';
import 'package:rukun_app_proyek4/models/transaksi_model.dart';
import 'package:rukun_app_proyek4/repositories/iuran_repository.dart';

enum FilterStatus { semua, belumDibayar, diproses, dibayar, ditolak }

class IuranItem {
  final DateTime bulan;
  final Transaksi? transaksi;

  IuranItem({required this.bulan, this.transaksi});

  StatusPembayaran get status {
    if (transaksi == null) return StatusPembayaran.belumDibayar;
    return transaksi!.status;
  }
}

class IuranwargaViewmodel extends ChangeNotifier {
  final IuranRepository repository;

  IuranwargaViewmodel(this.repository);

  List<IuranSaya> _items = [];

  FilterStatus selectedStatus = FilterStatus.semua;
  IuranType selectedType = IuranType.reguler;

  bool isLoading = false;
  String? errorMessage;

  Future<void> loadIuranSaya() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _items = await repository.getIuranSaya();
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  List<IuranSaya> get data {
    return _items.where((item) {
      if (item.iuran.tipe != selectedType) return false;

      final trx = getLatestTransaksi(item);

      switch (selectedStatus) {
        case FilterStatus.semua:
          return true;

        case FilterStatus.belumDibayar:
          return trx == null || trx.status == StatusPembayaran.belumDibayar;

        case FilterStatus.diproses:
          return trx?.status == StatusPembayaran.diproses;

        case FilterStatus.dibayar:
          return trx?.status == StatusPembayaran.dibayar;

        case FilterStatus.ditolak:
          return trx?.status == StatusPembayaran.ditolak;
      }
    }).toList();
  }

  int get totalDibayar {
    return data.where((item) {
      return getStatusSummary(item) == StatusPembayaran.dibayar;
    }).length;
  }

  int get totalDiproses {
    return data.where((item) {
      return getStatusSummary(item) == StatusPembayaran.diproses;
    }).length;
  }

  int get totalBelum {
    return data.where((item) {
      return getStatusSummary(item) == StatusPembayaran.belumDibayar;
    }).length;
  }

  int get totalKeseluruhan => data.length;

  void setStatus(FilterStatus status) {
    selectedStatus = status;
    notifyListeners();
  }

  void setType(IuranType type) {
    selectedType = type;
    notifyListeners();
  }

  Transaksi? getLatestTransaksi(IuranSaya item) {
    if (item.transaksi.isEmpty) return null;

    Transaksi? latest;

    for (final t in item.transaksi) {
      final tanggal = t.waktuBayar ?? t.waktuDibuat;
      if (tanggal == null) continue;

      if (latest == null) {
        latest = t;
      } else {
        final latestDate = latest.waktuBayar ?? latest.waktuDibuat;
        if (latestDate == null) continue;

        if (tanggal.isAfter(latestDate)) {
          latest = t;
        }
      }
    }

    return latest;
  }

  List<IuranItem> generateHistory(IuranSaya item) {
    if (item.iuran.tipe == IuranType.insidentil) {
      return [
        IuranItem(
          bulan:
              item.transaksiTerbaru?.waktuBayar ??
              item.transaksiTerbaru?.waktuDibuat ??
              DateTime.now(),

          transaksi: item.transaksiTerbaru,
        ),
      ];
    }

    final start =
        item.iuran.waktuDibuat ??
        DateTime(DateTime.now().year, DateTime.now().month);
    final now = DateTime.now();

    final List<IuranItem> result = [];

    DateTime current = DateTime(start.year, start.month);

    while (!current.isAfter(DateTime(now.year, now.month))) {
      final trx = _findTransactionByMonth(item.transaksi, current);

      result.add(IuranItem(bulan: current, transaksi: trx));

      current = DateTime(current.year, current.month + 1);
    }

    return result;
  }

  Transaksi? _findTransactionByMonth(List<Transaksi> list, DateTime month) {
    for (final t in list) {
      final tanggal = t.waktuBayar ?? t.waktuDibuat;

      if (tanggal == null) continue;

      if (tanggal.year == month.year && tanggal.month == month.month) {
        return t;
      }
    }

    return null;
  }

  bool cekTunggakan(IuranSaya item) {
    final history = generateHistory(item);

    return history.any((e) {
      final status = e.status;
      return status == StatusPembayaran.belumDibayar ||
          status == StatusPembayaran.ditolak;
    });
  }

  StatusPembayaran getStatusSummary(IuranSaya item) {
    final trx = item.transaksiTerbaru;

    if (item.iuran.tipe == IuranType.insidentil) {
      return trx?.status ?? StatusPembayaran.belumDibayar;
    }

    final history = generateHistory(item);

    final adaBelumBayar = history.any(
      (e) =>
          e.transaksi == null ||
          e.status == StatusPembayaran.belumDibayar ||
          e.status == StatusPembayaran.ditolak,
    );

    return adaBelumBayar
        ? StatusPembayaran.belumDibayar
        : StatusPembayaran.dibayar;
  }

  Future<void> refresh() async {
    await loadIuranSaya();
    notifyListeners();
  }
}
