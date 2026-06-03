import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:rukun_app_proyek4/models/pengajuan_surat_model.dart';
import 'package:rukun_app_proyek4/models/warga_model.dart';

class PdfGeneratorService {
  static Future<Uint8List> generateDraftSurat(
      PengajuanSurat surat, Warga warga) async {
    final pdf = pw.Document();

    final kecamatan = "................";
    final kelurahan = "................";
    final rtName = surat.rt?.noRt ?? "......";
    final rwName = "......";
    final kota = "BANDUNG";
    
    final tglLahir = warga.tglLahir != null 
        ? "${warga.tglLahir!.day}/${warga.tglLahir!.month}/${warga.tglLahir!.year}"
        : "................";
    final tmpLahir = warga.tempatLahir ?? "................";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(50),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _kopRow("KECAMATAN", kecamatan),
                      _kopRow("KELURAHAN", kelurahan),
                      pw.Text("RT. $rtName RW. $rwName", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("KOTA $kota", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ]
                  )
                ]
              ),
              
              pw.SizedBox(height: 30),
              
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text("SURAT KETERANGAN", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline, fontSize: 16)),
                    pw.Text("No: ........................"),
                  ]
                )
              ),
              
              pw.SizedBox(height: 30),
              
              pw.Text("Yang bertanda tangan di bawah ini, Ketua RT. $rtName / RW. $rwName"),
              pw.SizedBox(height: 5),
              pw.Text("Kelurahan $kelurahan, Kecamatan $kecamatan, menerangkan dengan sebenarnya bahwa :"),
              
              pw.SizedBox(height: 20),
              
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 0),
                child: pw.Column(
                  children: [
                    _biodataRow("Nama", warga.nama),
                    _biodataRow("Tempat & Tanggal Lahir", "$tmpLahir, $tglLahir"),
                    _biodataRow("Jenis Kelamin", warga.jk?.display ?? "................"),
                    _biodataRow("Status Perkawinan", warga.statusPerkawinan?.display ?? "................"),
                    _biodataRow("No. KTP / KK", "${warga.nik} / ${warga.keluarga?.noKK ?? "................"}"),
                    _biodataRow("Kewarganegaraan", warga.kewarganegaraan?.display ?? "................"),
                    _biodataRow("Agama", warga.agama?.display ?? "................"),
                    _biodataRow("Pekerjaan", warga.jenisPekerjaan ?? "................"),
                    _biodataRow("Alamat", "RT. $rtName RW. $rwName Kel. $kelurahan"),
                    _biodataRow("Keperluan", "Sebagai persyaratan untuk keperluan\n${surat.keperluan}\n${surat.keterangan ?? ""}"),
                  ]
                )
              ),
              
              pw.SizedBox(height: 30),
              
              pw.Text("Demikian surat ini dibuat untuk dapat dipergunakan sebagaimana mestinya."),
              
              pw.SizedBox(height: 50),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("No. ........................."),
                      pw.Text("Mengetahui Ketua", style: pw.TextStyle(decoration: pw.TextDecoration.underline)),
                      pw.Text("RW. $rwName"),
                      pw.SizedBox(height: 60),
                      pw.Text("(.........................)")
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text("................, ........................."),
                      pw.Text("Ketua", style: pw.TextStyle(decoration: pw.TextDecoration.underline)),
                      pw.Text("RT. $rtName RW. $rwName"),
                      pw.SizedBox(height: 60),
                      pw.Text("(.........................)")
                    ]
                  )
                ]
              )
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _kopRow(String title, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(width: 80, child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        pw.Text(" : ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ]
    );
  }

  static pw.Widget _biodataRow(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 140, child: pw.Text(title)),
          pw.Text(" : "),
          pw.Expanded(child: pw.Text(value)),
        ]
      )
    );
  }
}
