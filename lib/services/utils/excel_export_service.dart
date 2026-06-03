import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:rukun_app_proyek4/models/keluarga_model.dart';
import 'package:rukun_app_proyek4/models/warga_model.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:intl/intl.dart';

class ExcelExportService {
  /// Export data kependudukan ke Excel (.xlsx) dan buka filenya
  Future<void> exportDataKependudukan({
    required List<Keluarga> listKk,
    required List<Warga> listWarga,
    required String scopeName,
  }) async {
    // 1. Buat Workbook Excel
    final Workbook workbook = Workbook();

    // 2. Buat Sheet 1: Data KK
    final Worksheet sheetKk = workbook.worksheets[0];
    sheetKk.name = 'Data Kartu Keluarga';
    
    // Header KK
    final headerKk = ['No.', 'No KK', 'RT ID', 'Alamat', 'Kode Pos'];
    for (int i = 0; i < headerKk.length; i++) {
      final cell = sheetKk.getRangeByIndex(1, i + 1);
      cell.setText(headerKk[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#E0E0E0';
    }

    // Isi Data KK
    for (int i = 0; i < listKk.length; i++) {
      final kk = listKk[i];
      sheetKk.getRangeByIndex(i + 2, 1).setNumber((i + 1).toDouble());
      sheetKk.getRangeByIndex(i + 2, 2).setText(kk.noKK);
      sheetKk.getRangeByIndex(i + 2, 3).setNumber(kk.rtId.toDouble());
      sheetKk.getRangeByIndex(i + 2, 4).setText(kk.alamat ?? '-');
      sheetKk.getRangeByIndex(i + 2, 5).setText(kk.kodePos ?? '-');
    }

    // Auto-fit kolom KK
    for (int i = 1; i <= headerKk.length; i++) {
      sheetKk.autoFitColumn(i);
    }

    // 3. Buat Sheet 2: Data Warga
    final Worksheet sheetWarga = workbook.worksheets.addWithName('Data Warga');
    
    // Header Warga
    final headerWarga = [
      'No.', 
      'No KK', 
      'Status Hubungan',
      'NIK', 
      'Nama Lengkap', 
      'Jenis Kelamin', 
      'Tempat Lahir', 
      'Tanggal Lahir', 
      'Agama',
      'Pendidikan',
      'Pekerjaan',
      'Status Perkawinan'
    ];

    for (int i = 0; i < headerWarga.length; i++) {
      final cell = sheetWarga.getRangeByIndex(1, i + 1);
      cell.setText(headerWarga[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#E0E0E0';
    }

    // Isi Data Warga
    for (int i = 0; i < listWarga.length; i++) {
      final w = listWarga[i];
      final kkRef = w.keluarga?.noKK ?? '-';
      
      String tglLahirStr = '-';
      if (w.tglLahir != null) {
        tglLahirStr = DateFormat('dd/MM/yyyy').format(w.tglLahir!);
      }

      sheetWarga.getRangeByIndex(i + 2, 1).setNumber((i + 1).toDouble());
      sheetWarga.getRangeByIndex(i + 2, 2).setText(kkRef);
      sheetWarga.getRangeByIndex(i + 2, 3).setText(w.statusHubungan != null ? w.statusHubungan!.display : '-');
      sheetWarga.getRangeByIndex(i + 2, 4).setText(w.nik);
      sheetWarga.getRangeByIndex(i + 2, 5).setText(w.nama);
      sheetWarga.getRangeByIndex(i + 2, 6).setText(w.jk != null ? w.jk!.display : '-');
      sheetWarga.getRangeByIndex(i + 2, 7).setText(w.tempatLahir ?? '-');
      sheetWarga.getRangeByIndex(i + 2, 8).setText(tglLahirStr);
      sheetWarga.getRangeByIndex(i + 2, 9).setText(w.agama != null ? w.agama!.display : '-');
      sheetWarga.getRangeByIndex(i + 2, 10).setText(w.pendidikan ?? '-');
      sheetWarga.getRangeByIndex(i + 2, 11).setText(w.jenisPekerjaan ?? '-');
      sheetWarga.getRangeByIndex(i + 2, 12).setText(w.statusPerkawinan != null ? w.statusPerkawinan!.display : '-');
    }

    // Auto-fit kolom Warga
    for (int i = 1; i <= headerWarga.length; i++) {
      sheetWarga.autoFitColumn(i);
    }

    // 4. Simpan File ke Device
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final Directory dir = await getApplicationDocumentsDirectory();
    final String dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final String fileName = 'Data_Kependudukan_${scopeName}_$dateStr.xlsx';
    final String path = '${dir.path}/$fileName';

    final File file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    // 5. Buka File
    await OpenFilex.open(path);
  }
}
