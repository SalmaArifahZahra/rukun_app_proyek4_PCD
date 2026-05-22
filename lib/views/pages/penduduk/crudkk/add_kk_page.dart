import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/notification_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/penduduk/kartukeluarga/add_kk_viewmodel.dart';
import 'package:rukun_app_proyek4/services/pcd/kk_ocr_engine.dart';

class AddKKPage extends StatelessWidget {
  const AddKKPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddKKViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: "",
        title: "Tambah Kartu Keluarga",
        subtitle: "Halaman tambah kartu keluarga baru",
        showName: false,
        showAvatar: false,
        showGreeting: false,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),

          const SizedBox(height: 16),

          // ── Tombol Scan KK (PCD) ──
          _buildScanSection(context, vm),

          const SizedBox(height: 16),

          // ── Extraction Feedback ──
          if (vm.isExtracting ||
              vm.extractionResult != null ||
              vm.extractionError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildExtractionFeedback(vm),
            ),

          _buildFormCard(vm),

          const SizedBox(height: 16),

          _buildSaveButton(context, vm),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
            child: const Icon(Icons.credit_card, color: ColorsUtils.b500),
          ),
          const SizedBox(width: 16),

          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tambah Data",
                style: TextStyle(fontSize: 12, color: ColorsUtils.gray),
              ),
              SizedBox(height: 4),
              Text(
                "Kartu Keluarga",
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
    );
  }

  // ──────────────────────────────────────────────
  // Scan KK Section (PCD Feature)
  // ──────────────────────────────────────────────

  Widget _buildScanSection(BuildContext context, AddKKViewModel vm) {
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorsUtils.b50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.document_scanner_outlined,
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
                      "Scan Kartu Keluarga",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorsUtils.b400,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Ambil foto KK untuk auto-fill data",
                      style: TextStyle(fontSize: 11, color: ColorsUtils.gray),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Dua tombol: Kamera & Galeri
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
    required AddKKViewModel vm,
    required IconData icon,
    required String label,
    required ImageSource source,
  }) {
    return ElevatedButton.icon(
      onPressed: vm.isExtracting ? null : () => vm.scanKK(source),
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

  // ──────────────────────────────────────────────
  // Extraction Feedback
  // ──────────────────────────────────────────────

  Widget _buildExtractionFeedback(AddKKViewModel vm) {
    // Sedang memproses
    if (vm.isExtracting) {
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
                vm.extractionStatus,
                style: const TextStyle(fontSize: 13, color: ColorsUtils.b400),
              ),
            ),
          ],
        ),
      );
    }

    // Error
    if (vm.extractionError != null) {
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
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFEF4444),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vm.extractionError!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: vm.retryExtraction,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text("Coba Lagi", style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Sukses
    if (vm.extractionResult != null && vm.extractionResult!.isSuccess) {
      final r = vm.extractionResult!;
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
                  "Data berhasil diekstrak!",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildExtractedField("No. KK", r.nomorKK),
            _buildExtractedField("Alamat", r.alamat),
            _buildExtractedField("Kode Pos", r.kodePos),
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

  Widget _buildExtractedField(String label, ParseResult? fieldResult) {
    final value = fieldResult?.value;
    final confidence = fieldResult?.confidence ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A)),
            ),
          ),
          const Text(
            ": ",
            style: TextStyle(fontSize: 11, color: Color(0xFF16A34A)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value ?? "—",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: value != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: value != null
                        ? const Color(0xFF166534)
                        : const Color(0xFF86EFAC),
                  ),
                ),
                if (value != null)
                  Text(
                    "Confidence: ${(confidence * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFFA3A3A3),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Form
  // ──────────────────────────────────────────────

  Widget _buildFormCard(AddKKViewModel vm) {
    return _buildCard(
      header: _buildSectionHeader('Data Kartu Keluarga', Icons.home_outlined),
      child: Column(
        children: [
          TextField(
            controller: vm.noKKController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'No KK'),
            onChanged: (value) => vm.noKK = value,
          ),

          const SizedBox(height: 12),

          TextField(
            controller: vm.alamatController,
            decoration: const InputDecoration(labelText: 'Alamat'),
            onChanged: (value) => vm.alamat = value,
          ),

          const SizedBox(height: 12),

          TextField(
            controller: vm.kodePosController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Kode Pos'),
            onChanged: (value) => vm.kodePos = value,
          ),

          const SizedBox(height: 16),

          _buildFotoKK(vm),
        ],
      ),
    );
  }

  Widget _buildFotoKK(AddKKViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Foto Kartu Keluarga",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 10),

        GestureDetector(
          onTap: vm.pickFotoKK,
          child: Container(
            width: double.infinity,
            height: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorsUtils.b500),
              color: vm.fotoKK == null
                  ? const Color(0xFFF9FAFB)
                  : Colors.transparent,
            ),
            child: vm.fotoKK == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file, size: 40),
                      SizedBox(height: 8),
                      Text("Upload Foto KK"),
                      SizedBox(height: 4),
                      Text("Format JPG/PNG", style: TextStyle(fontSize: 11)),
                    ],
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          vm.fotoKK!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // overlay edit
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context, AddKKViewModel vm) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: vm.isSaving
            ? null
            : () async {
                await vm.createKK();

                if (vm.errorMessage != null) {
                  NotificationUtils.showError(context, vm.errorMessage!);
                } else {
                  NotificationUtils.showSuccess(
                    context,
                    "Kartu Keluarga berhasil disimpan",
                  );
                  Navigator.pop(context);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsUtils.b500,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: vm.isSaving
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Simpan Kartu Keluarga',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildCard({required Widget header, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          header,
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(children: [Icon(icon), const SizedBox(width: 8), Text(title)]),
    );
  }
}
