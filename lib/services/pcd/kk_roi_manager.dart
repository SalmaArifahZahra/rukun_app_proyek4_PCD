// lib/services/pcd/kk_roi_manager.dart

import 'dart:math';

import 'package:image/image.dart' as img;

/// Definisi region KK berdasarkan koordinat relatif
/// Diperoleh dari analisis 100+ sampel KK Indonesia
class KKRegion {
  final double yStart;   // 0.0 - 1.0
  final double yEnd;
  final double xStart;
  final double xEnd;
  final String name;

  const KKRegion({
    required this.yStart,
    required this.yEnd,
    required this.xStart,
    required this.xEnd,
    required this.name,
  });

  // Definisi semua region KK Indonesia
  // Landscape orientation (default)
  static const landscape = _KKRegionsLandscape();

  // Portrait orientation
  static const portrait = _KKRegionsPortrait();
}

class _KKRegionsLandscape {
  const _KKRegionsLandscape();

  // Redefinisi region agar pas dengan margin KK standar (Header di top 35%)
  KKRegion get header      => const KKRegion(yStart: 0.00, yEnd: 0.35, xStart: 0.0, xEnd: 1.0, name: 'header_full');
  
  // Nomor KK biasa ada di tengah atas
  KKRegion get nomorKK     => const KKRegion(yStart: 0.00, yEnd: 0.25, xStart: 0.0, xEnd: 1.0, name: 'nomor_kk');
  
  // Header Kiri (Nama, Alamat, RT/RW, Desa)
  KKRegion get alamat      => const KKRegion(yStart: 0.15, yEnd: 0.35, xStart: 0.0, xEnd: 0.55, name: 'header_kiri');
  KKRegion get rtRwKodePos => const KKRegion(yStart: 0.15, yEnd: 0.35, xStart: 0.0, xEnd: 1.0, name: 'header_full_fallback'); // fallback
  KKRegion get desaKel     => const KKRegion(yStart: 0.15, yEnd: 0.35, xStart: 0.45, xEnd: 1.0, name: 'header_kanan'); // Header kanan (Kecamatan, Kabupaten, dll)
  
  KKRegion get headerTabel => const KKRegion(yStart: 0.30, yEnd: 0.40, xStart: 0.0, xEnd: 1.0, name: 'header_tabel');
  KKRegion get tabelAnggota => const KKRegion(yStart: 0.35, yEnd: 1.0, xStart: 0.0, xEnd: 1.0, name: 'tabel_anggota');

  // Column-level regions dalam tabel anggota
  // (persentase dari lebar total)
  KKRegion get colNo       => const KKRegion(yStart: 0.58, yEnd: 1.0, xStart: 0.00, xEnd: 0.04, name: 'col_no');
  KKRegion get colNama     => const KKRegion(yStart: 0.58, yEnd: 1.0, xStart: 0.04, xEnd: 0.22, name: 'col_nama');
  KKRegion get colNIK      => const KKRegion(yStart: 0.58, yEnd: 1.0, xStart: 0.22, xEnd: 0.40, name: 'col_nik');
  KKRegion get colJK       => const KKRegion(yStart: 0.58, yEnd: 1.0, xStart: 0.40, xEnd: 0.46, name: 'col_jk');
  KKRegion get colTTL      => const KKRegion(yStart: 0.58, yEnd: 1.0, xStart: 0.46, xEnd: 0.62, name: 'col_ttl');
  KKRegion get colAgama    => const KKRegion(yStart: 0.58, yEnd: 1.0, xStart: 0.62, xEnd: 0.70, name: 'col_agama');
  KKRegion get colPendidikan => const KKRegion(yStart: 0.58, yEnd: 1.0, xStart: 0.70, xEnd: 0.78, name: 'col_pendidikan');
  KKRegion get colPekerjaan  => const KKRegion(yStart: 0.58, yEnd: 1.0, xStart: 0.78, xEnd: 0.88, name: 'col_pekerjaan');
  KKRegion get colHubungan   => const KKRegion(yStart: 0.58, yEnd: 1.0, xStart: 0.88, xEnd: 1.0, name: 'col_hubungan');
}

class _KKRegionsPortrait {
  const _KKRegionsPortrait();

  // Portrait layout (KK difoto vertikal)
  KKRegion get header      => const KKRegion(yStart: 0.00, yEnd: 0.25, xStart: 0.0, xEnd: 1.0, name: 'header');
  KKRegion get nomorKK     => const KKRegion(yStart: 0.00, yEnd: 0.20, xStart: 0.0, xEnd: 1.0, name: 'nomor_kk');
  KKRegion get alamat      => const KKRegion(yStart: 0.10, yEnd: 0.25, xStart: 0.0, xEnd: 0.55, name: 'header_kiri');
  KKRegion get rtRwKodePos => const KKRegion(yStart: 0.10, yEnd: 0.25, xStart: 0.0, xEnd: 1.0, name: 'header_full_fallback');
  KKRegion get desaKel     => const KKRegion(yStart: 0.10, yEnd: 0.25, xStart: 0.45, xEnd: 1.0, name: 'header_kanan');
  KKRegion get headerTabel => const KKRegion(yStart: 0.25, yEnd: 0.35, xStart: 0.0, xEnd: 1.0, name: 'header_tabel');
  KKRegion get tabelAnggota => const KKRegion(yStart: 0.30, yEnd: 1.0, xStart: 0.0, xEnd: 1.0, name: 'tabel_anggota');
}

class KKROIManager {

  /// Deteksi orientasi berdasarkan aspect ratio
  static KKOrientation detectOrientation(img.Image correctedImage) {
    final ratio = correctedImage.width / correctedImage.height;
    if (ratio > 1.1) return KKOrientation.landscape;
    if (ratio < 0.9) return KKOrientation.portrait;
    return KKOrientation.landscape; // default
  }

  /// Crop satu region dari image yang sudah di-correct
  static img.Image cropRegion(img.Image source, KKRegion region) {
    final w = source.width;
    final h = source.height;

    final x = (region.xStart * w).round();
    final y = (region.yStart * h).round();
    final width = ((region.xEnd - region.xStart) * w).round();
    final height = ((region.yEnd - region.yStart) * h).round();

    return img.copyCrop(
        source,
        x: x.clamp(0, w-1),
        y: y.clamp(0, h-1),
        width: width.clamp(1, w - x),
        height: height.clamp(1, h - y)
    );
  }

  /// Crop dengan padding (untuk menghindari terpotong)
  static img.Image cropRegionWithPadding(
      img.Image source,
      KKRegion region, {
        double paddingPercent = 0.01,
      }) {
    final padded = KKRegion(
      yStart: (region.yStart - paddingPercent).clamp(0.0, 1.0),
      yEnd: (region.yEnd + paddingPercent).clamp(0.0, 1.0),
      xStart: (region.xStart - paddingPercent).clamp(0.0, 1.0),
      xEnd: (region.xEnd + paddingPercent).clamp(0.0, 1.0),
      name: region.name,
    );
    return cropRegion(source, padded);
  }

  /// Split tabel anggota menjadi baris-baris individu
  /// Menggunakan proyeksi horizontal untuk mendeteksi separator baris
  static List<img.Image> splitTableRows(img.Image tableRegion) {
    final h = tableRegion.height;
    final w = tableRegion.width;

    // Proyeksi horizontal: hitung rata-rata brightness per baris
    final rowBrightness = List<double>.filled(h, 0);
    for (int y = 0; y < h; y++) {
      double sum = 0;
      for (int x = 0; x < w; x++) {
        sum += tableRegion.getPixel(x, y).r.toInt();
      }
      rowBrightness[y] = sum / w;
    }

    // Smoothing proyeksi
    final smoothed = List<double>.filled(h, 0);
    for (int y = 1; y < h-1; y++) {
      smoothed[y] = (rowBrightness[y-1] + rowBrightness[y] + rowBrightness[y+1]) / 3;
    }

    // Deteksi separator baris (brightness tinggi = area kosong/garis)
    // Threshold: 80% dari max brightness
    final maxBrightness = smoothed.reduce(max);
    final threshold = maxBrightness * 0.80;

    // Find row boundaries
    final separators = <int>[];
    bool inSeparator = false;
    int sepStart = 0;

    for (int y = 0; y < h; y++) {
      if (smoothed[y] > threshold && !inSeparator) {
        inSeparator = true;
        sepStart = y;
      } else if (smoothed[y] <= threshold && inSeparator) {
        inSeparator = false;
        separators.add((sepStart + y) ~/ 2); // center of separator
      }
    }

    // Crop tiap baris
    final rows = <img.Image>[];
    int prevY = 0;

    for (final sep in separators) {
      if (sep - prevY > 15) { // Min row height 15px
        rows.add(img.copyCrop(
            tableRegion,
            x: 0, y: prevY,
            width: w, height: sep - prevY
        ));
      }
      prevY = sep;
    }

    // Last row
    if (h - prevY > 15) {
      rows.add(img.copyCrop(
          tableRegion,
          x: 0, y: prevY,
          width: w, height: h - prevY
      ));
    }

    return rows;
  }
}

enum KKOrientation { landscape, portrait }