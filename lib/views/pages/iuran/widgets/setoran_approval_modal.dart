import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/utils/notification_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/iuran/iuran_rt_detail_viewmodel.dart';

class SetoranApprovalModal extends StatefulWidget {
  final String label;
  final DateTime month;
  final int iuranId;
  final int rtId;
  final int jumlahPembayar;
  final int totalPendapatan;
  final int saldoKasRt;
  final dynamic detailSetoran;

  const SetoranApprovalModal({
    super.key,
    required this.label,
    required this.month,
    required this.iuranId,
    required this.rtId,
    required this.jumlahPembayar,
    required this.totalPendapatan,
    required this.saldoKasRt,
    this.detailSetoran,
  });

  @override
  State<SetoranApprovalModal> createState() => _SetoranApprovalModalState();
}

class _SetoranApprovalModalState extends State<SetoranApprovalModal> {
  @override
  void initState() {
    super.initState();
    catatanController = TextEditingController();
  }

  @override
  void dispose() {
    catatanController.dispose();
    super.dispose();
  }

  bool _loadingApprove = false;
  bool _loadingReject = false;

  late TextEditingController catatanController;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<IuranRTDetailViewModel>();

    final String? documentUrl = widget.detailSetoran?.documentRef;

    final setoran = widget.detailSetoran;
    final status = setoran?.status;

    final isApproved = status == "Diterima";
    final isRejected = status == "Ditolak";
    final isPending = status == "Dikirim";
    // final isEmpty = setoran == null;

    Color statusColor() {
      if (isApproved) return Colors.green;
      if (isRejected) return Colors.red;
      if (isPending) return Colors.orange;
      return Colors.grey;
    }

    String statusText() {
      if (isApproved) return "DISETUJUI";
      if (isRejected) return "DITOLAK";
      if (isPending) return "MENUNGGU";
      return "BELUM SETOR";
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "Review Setoran ${widget.label}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // INFO CARD
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _info("Total Pembayar", "${widget.jumlahPembayar}"),
                  _info("Total Pendapatan", "Rp ${widget.totalPendapatan}"),
                  _info("Saldo Kas RT", "Rp ${widget.saldoKasRt}"),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // STATUS
            if (widget.detailSetoran != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isApproved
                      ? Colors.green.withOpacity(0.1)
                      : isRejected
                      ? Colors.red.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      isApproved
                          ? Icons.check_circle
                          : isRejected
                          ? Icons.cancel
                          : Icons.hourglass_bottom,
                      color: isApproved
                          ? Colors.green
                          : isRejected
                          ? Colors.red
                          : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Status: ${widget.detailSetoran.status}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // FOTO BUKTI
            if (documentUrl != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bukti Setoran",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      documentUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Text("Gagal memuat gambar"),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            if (widget.detailSetoran != null && !isApproved && !isRejected)
              TextField(
                controller: catatanController,
                decoration: const InputDecoration(
                  labelText: "Catatan (wajib jika ditolak)",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),

            const SizedBox(height: 16),

            if (isApproved || isRejected)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor(),
                    ),
                  ),
                ),
              )
            else if (setoran == null)
              const Center(child: Text("Belum ada setoran dari RT"))
            else
              Row(
                children: [
                  // ❌ REJECT
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loadingReject
                          ? null
                          : () async {
                              if (catatanController.text.trim().isEmpty) {
                                NotificationUtils.showError(
                                  context,
                                  "Catatan wajib diisi untuk penolakan",
                                );
                                return;
                              }

                              setState(() => _loadingReject = true);

                              final success = await vm.rejectSetoran(
                                setoran.id,
                                catatanController.text.trim(),
                              );

                              setState(() => _loadingReject = false);

                              if (success) {
                                Navigator.pop(context);
                              }
                            },
                      child: _loadingReject
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : const Text("Tolak"),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ✅ APPROVE
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loadingApprove
                          ? null
                          : () async {
                              setState(() => _loadingApprove = true);

                              final success = await vm.approveSetoran(
                                setoran.id,
                              );

                              setState(() => _loadingApprove = false);

                              if (success) Navigator.pop(context);
                            },
                      child: _loadingApprove
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : const Text("Approve"),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _info(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
