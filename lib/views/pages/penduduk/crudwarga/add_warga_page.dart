import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/models/keluarga_model.dart';
import 'package:rukun_app_proyek4/services/pcd/ktp_extraction_service.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/notification_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/penduduk/warga/add_warga_viewmodel.dart';

class AddWargaPage extends StatelessWidget {
  final Keluarga keluarga;

  const AddWargaPage({super.key, required this.keluarga});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddWargaViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: "",
        title: "Tambah Data Warga",
        subtitle: "Halaman tambah data warga baru",
        showName: false,
        showAvatar: false,
        showGreeting: false,
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
        children: [
          _header(),

          const SizedBox(height: 16),

          // ── Scan KTP Section ──
          _buildScanSection(context, vm),

          const SizedBox(height: 16),

          // ── Extraction Feedback ──
          if (vm.isScanning ||
              vm.scanResult != null ||
              vm.scanError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildExtractionFeedback(vm),
            ),

          _buildSection(
            'Data Pribadi',
            Icons.person_outline,
            _dataPribadi(context, vm),
          ),
          _buildSection(
            'Data Identitas',
            Icons.badge_outlined,
            _dataIdentitas(vm),
          ),
          _buildSection(
            'Status Perkawinan',
            Icons.favorite_border,
            _dataPerkawinan(context, vm),
          ),
          _buildSection(
            'Kewarganegaraan',
            Icons.public,
            _dataKewarganegaraan(vm),
          ),
          _buildSection(
            'Data Keluarga',
            Icons.family_restroom,
            _dataKeluarga(vm),
          ),
        ],
      ),

      bottomNavigationBar: _bottomBar(context, vm),
    );
  }

  Widget _header() {
    return Container(
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
            child: const Icon(Icons.person_add, color: ColorsUtils.b500),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Lengkapi data warga dengan benar sesuai dokumen resmi',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Scan KTP Section ──

  Widget _buildScanSection(BuildContext context, AddWargaViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorsUtils.b100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorsUtils.b50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: ColorsUtils.b500,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Scan KTP",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorsUtils.b400,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Ambil foto KTP untuk auto-fill data warga",
                      style: TextStyle(fontSize: 11, color: ColorsUtils.gray),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildScanButton(
                  context: context,
                  vm: vm,
                  icon: Icons.camera_alt_outlined,
                  label: "Kamera",
                  source: ImageSource.camera,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScanButton(
                  context: context,
                  vm: vm,
                  icon: Icons.photo_library_outlined,
                  label: "Galeri",
                  source: ImageSource.gallery,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton({
    required BuildContext context,
    required AddWargaViewModel vm,
    required IconData icon,
    required String label,
    required ImageSource source,
  }) {
    return ElevatedButton.icon(
      onPressed: vm.isScanning ? null : () => vm.scanKTP(source),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorsUtils.b500,
        foregroundColor: Colors.white,
        disabledBackgroundColor: ColorsUtils.b100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  // ── Extraction Feedback ──

  Widget _buildExtractionFeedback(AddWargaViewModel vm) {
    if (vm.isScanning) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorsUtils.b50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorsUtils.b100),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ColorsUtils.b500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                vm.scanStatus,
                style: const TextStyle(fontSize: 13, color: ColorsUtils.b400),
              ),
            ),
          ],
        ),
      );
    }

    if (vm.scanError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vm.scanError!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: vm.retryScan,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text("Coba Lagi", style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (vm.scanResult != null && vm.scanResult!.isSuccess) {
      final r = vm.scanResult!;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 18),
                SizedBox(width: 8),
                Text(
                  "KTP berhasil diekstrak!",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildExtractedField("NIK", r.nik),
            _buildExtractedField("Nama", r.nama),
            _buildExtractedField("TTL", r.tempatLahir, extra: r.tanggalLahir?.value),
            _buildExtractedField("JK", r.jenisKelamin),
            _buildExtractedField("Gol. Darah", r.golonganDarah),
            _buildExtractedField("Agama", r.agama),
            _buildExtractedField("Status", r.statusPerkawinan),
            _buildExtractedField("Pekerjaan", r.pekerjaan),
            _buildExtractedField("KWN", r.kewarganegaraan),
            const SizedBox(height: 4),
            const Text(
              "* Silakan periksa & koreksi jika diperlukan",
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF16A34A),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildExtractedField(String label, KTPFieldResult? fieldResult, {String? extra}) {
    final value = extra ?? fieldResult?.value;
    final confidence = fieldResult?.confidence ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A)),
            ),
          ),
          const Text(": ", style: TextStyle(fontSize: 11, color: Color(0xFF16A34A))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value ?? "-",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
                    color: value != null ? const Color(0xFF166534) : const Color(0xFF86EFAC),
                  ),
                ),
                if (value != null)
                  Text(
                    "Confidence: ${(confidence * 100).toInt()}%",
                    style: const TextStyle(fontSize: 9, color: Color(0xFFA3A3A3)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ColorsUtils.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: ColorsUtils.b500),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _dataPribadi(BuildContext context, AddWargaViewModel vm) {
    return Column(
      children: [
        _textField('Nama Lengkap', onChanged: vm.setNama),
        _textField('NIK', keyboard: TextInputType.number, onChanged: vm.setNik),

        _dropdown(
          'Jenis Kelamin',
          ['Laki-Laki', 'Perempuan'],
          value: vm.jenisKelamin,
          onChanged: vm.setJenisKelamin,
        ),

        Row(
          children: [
            Expanded(
              child: _textField('Tempat Lahir', onChanged: vm.setTempatLahir),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dateField(
                context,
                'Tanggal Lahir',
                vm.tanggalLahir,
                vm.setTanggalLahir,
              ),
            ),
          ],
        ),
      ].withSpacing(),
    );
  }

  Widget _dataIdentitas(AddWargaViewModel vm) {
    return Column(
      children: [
        _dropdown(
          'Agama',
          ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'],
          value: vm.agama,
          onChanged: vm.setAgama,
        ),

        _dropdown(
          'Pendidikan',
          ['SD', 'SMP', 'SMA', 'D3', 'S1', 'S2', 'S3'],
          value: vm.pendidikan,
          onChanged: vm.setPendidikan,
        ),

        _textField('Pekerjaan', onChanged: vm.setPekerjaan),

        _dropdown(
          'Golongan Darah',
          ['A', 'B', 'AB', 'O'],
          value: vm.golonganDarah,
          onChanged: vm.setGolDarah,
        ),
      ].withSpacing(),
    );
  }

  Widget _dataPerkawinan(BuildContext context, AddWargaViewModel vm) {
    return Column(
      children: [
        _dropdown(
          'Status Perkawinan',
          ['Belum Kawin', 'Kawin', 'Cerai Hidup', 'Cerai Mati'],
          value: vm.statusPerkawinan,
          onChanged: vm.setStatusPerkawinan,
        ),

        _dateField(
          context,
          'Tanggal Perkawinan',
          vm.tanggalPerkawinan,
          vm.setTanggalPerkawinan,
        ),
      ].withSpacing(),
    );
  }

  Widget _dataKewarganegaraan(AddWargaViewModel vm) {
    return Column(
      children: [
        _dropdown(
          'Kewarganegaraan',
          ['WNI', 'WNA'],
          value: vm.kewarganegaraan,
          onChanged: vm.setKewarganegaraan,
        ),

        if (vm.kewarganegaraan == 'WNA')
          _textField('Negara Asal', onChanged: vm.setNegara),

        _textField('No. Paspor'),
        _textField('No. KITAP'),
      ].withSpacing(),
    );
  }

  Widget _dataKeluarga(AddWargaViewModel vm) {
    return Column(
      children: [
        _dropdown(
          'Status Hubungan',
          [
            'Kepala Keluarga',
            'Suami',
            'Istri',
            'Anak',
            'Orang Tua',
            'Cucu',
            'Cicit',
            'Menantu',
            'Mertua',
            'Famili Lain',
          ],
          value: vm.statusHubungan,
          onChanged: vm.setStatusHubungan,
        ),

        _textField('Nama Ayah', onChanged: (v) => vm.namaAyah = v),
        _textField('Nama Ibu', onChanged: (v) => vm.namaIbu = v),
      ].withSpacing(),
    );
  }

  Widget _dateField(
    BuildContext context,
    String label,
    DateTime? value,
    Function(DateTime) onPick,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),

        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );

            if (picked != null) {
              onPick(picked);
            }
          },

          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDDE3ED)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null
                        ? 'Pilih tanggal'
                        : "${value.day}/${value.month}/${value.year}",
                  ),
                ),
                const Icon(Icons.calendar_today_outlined, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(BuildContext context, AddWargaViewModel vm) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: ColorsUtils.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: ElevatedButton(
          onPressed: vm.isSaving
              ? null
              : () async {
                  await vm.saveWarga(keluarga);

                  if (vm.errorMessage != null) {
                    NotificationUtils.showError(context, vm.errorMessage!);
                  } else {
                    NotificationUtils.showSuccess(
                      context,
                      "Warga berhasil disimpan",
                    );

                    Navigator.pop(context, true);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorsUtils.b500,
            foregroundColor: ColorsUtils.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Simpan Data Warga',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  InputDecoration _input() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDE3ED)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDE3ED)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ColorsUtils.b500, width: 1.5),
      ),
      filled: true,
      fillColor: ColorsUtils.white,
    );
  }

  Widget _dropdown(
    String label,
    List<String> items, {
    String? value,
    Function(String?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: items.contains(value) ? value : null,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          decoration: _input(),
          hint: Text('Pilih $label'),
        ),
      ],
    );
  }

  Widget _textField(
    String label, {
    TextInputType keyboard = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextField(
          keyboardType: keyboard,
          onChanged: onChanged,
          decoration: _input(),
        ),
      ],
    );
  }
}

extension Spacing on List<Widget> {
  List<Widget> withSpacing([double space = 14]) {
    return expand((widget) => [widget, SizedBox(height: space)]).toList()
      ..removeLast();
  }
}
