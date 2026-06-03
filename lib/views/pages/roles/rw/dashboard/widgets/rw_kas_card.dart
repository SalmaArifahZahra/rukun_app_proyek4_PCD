import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rukun_app_proyek4/models/rw_model.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';

class RwKasCard extends StatelessWidget {
  final double saldo;
  final double masuk;
  final double keluar;
  final RwModel rw;

  const RwKasCard({
    super.key,
    required this.saldo,
    required this.masuk,
    required this.keluar,
    required this.rw,
  });

  String rupiah(double value) {
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),

        gradient: const LinearGradient(
          colors: [ColorsUtils.b200, ColorsUtils.b300],
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            "Saldo Kas RW ${rw.noRw}",
            style: TextStyle(color: ColorsUtils.white, fontSize: 13),
          ),

          const SizedBox(height: 8),

          Text(
            rupiah(saldo),
            style: const TextStyle(
              color: ColorsUtils.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              _item("Kas Masuk", rupiah(masuk), ColorsUtils.green),

              _item("Kas Keluar", "- ${rupiah(keluar)}", ColorsUtils.red),

              _item("Diperbarui", "20 Apr 2026", ColorsUtils.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _item(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          title,
          style: const TextStyle(color: ColorsUtils.white, fontSize: 11),
        ),

        const SizedBox(height: 6),

        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
