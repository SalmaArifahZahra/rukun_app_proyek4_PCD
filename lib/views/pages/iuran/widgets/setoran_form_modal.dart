import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/models/setoran_iuran_rt_model.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/iuran/iuran_rt_detail_viewmodel.dart';

class SetoranFormModal extends StatefulWidget {
  final String label;
  final DateTime month;

  final int iuranId;
  final int rtId;

  final int jumlahPembayar;
  final int totalPendapatan;
  final int saldoKasRt;

  final bool isDetail;
  final SetoranIuranRt? detailSetoran;

  const SetoranFormModal({
    super.key,
    required this.label,
    required this.month,
    required this.iuranId,
    required this.rtId,
    required this.jumlahPembayar,
    required this.totalPendapatan,
    required this.saldoKasRt,
    this.isDetail = false,
    this.detailSetoran,
  });

  @override
  State<SetoranFormModal> createState() => _SetoranFormModalState();
}

class _SetoranFormModalState extends State<SetoranFormModal> {
  late TextEditingController jumlahController;

  @override
  void initState() {
    super.initState();

    jumlahController = TextEditingController(
      text: widget.isDetail
          ? (widget.detailSetoran?.jumlahSetoran.toString() ?? '')
          : widget.totalPendapatan.toString(),
    );
  }

  @override
  void dispose() {
    jumlahController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDetail = widget.isDetail;
    final vm = context.watch<IuranRTDetailViewModel>();

    final fileName = isDetail
        ? widget.detailSetoran?.documentRef?.split('/').last
        : vm.buktiSetoran?.path.split('/').last;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          vm.resetSetoranForm();

          jumlahController.clear();
        }
      },
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                /// HEADER
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade300],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isDetail ? "Detail Setoran RT" : "Setoran RT ke RW",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (!isDetail) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Saldo Kas RT",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                "Rp ${NumberFormat('#,###', 'id_ID').format(widget.saldoKasRt)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 16),

                /// PERIODE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Periode: ${widget.label}",
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                if (isDetail) ...[
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.detailSetoran != null
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.detailSetoran != null
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.detailSetoran != null
                              ? Icons.check_circle
                              : Icons.info_outline,
                          color: widget.detailSetoran != null
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.detailSetoran?.waktuDibuat !=
                                  null) ...[
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                    'id_ID',
                                  ).format(widget.detailSetoran!.waktuDibuat!),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Text(
                                widget.detailSetoran != null
                                    ? "SUDAH DISETOR"
                                    : "BELUM DISETOR",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: widget.detailSetoran != null
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              if (widget.detailSetoran != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  "Rp ${widget.detailSetoran!.jumlahSetoran}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                /// TOTAL PENDAPATAN
                if (!isDetail) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up, color: Colors.green),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Total Pendapatan"),
                            Text(
                              "Rp ${NumberFormat('#,###', 'id_ID').format(widget.totalPendapatan)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 16),

                /// JUMLAH SETORAN
                TextField(
                  controller: jumlahController,
                  readOnly: isDetail,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Jumlah Setoran",
                    prefixIcon: Icon(Icons.payments),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  "Bukti Setoran",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 10),

                GestureDetector(
                  onTap: isDetail
                      ? null
                      : () async {
                          await vm.pickBuktiSetoran();
                        },
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade300),
                    ),

                    child: isDetail
                        ? (widget.detailSetoran?.documentRef != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    widget.detailSetoran!.documentRef!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 40,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.image_not_supported),
                                ))
                        : (vm.buktiSetoran == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cloud_upload_outlined, size: 40),
                                    SizedBox(height: 8),
                                    Text("Upload Bukti Setoran"),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(vm.buktiSetoran!.path),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )),
                  ),
                ),

                if (fileName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      fileName,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),

                const SizedBox(height: 20),

                if (!isDetail)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsUtils.b300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final setoran = SetoranIuranRt(
                          iuranId: widget.iuranId,
                          rtId: widget.rtId,
                          periodeBulan: DateTime(
                            widget.month.year,
                            widget.month.month,
                            1,
                          ),
                          totalPembayar: widget.jumlahPembayar,
                          jumlahSetoran:
                              int.tryParse(jumlahController.text) ??
                              widget.totalPendapatan,
                          documentRef: null,
                          status: SetoranStatus.dikirim,
                        );

                        final localPath = vm.buktiSetoran?.path;

                        await context
                            .read<IuranRTDetailViewModel>()
                            .createSetoran(
                              setoran,
                              localDocumentPath: localPath,
                            );

                        await vm.resetSetoranForm();

                        jumlahController.clear();

                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        "Kirim Setoran",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                if (isDetail)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tutup"),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
