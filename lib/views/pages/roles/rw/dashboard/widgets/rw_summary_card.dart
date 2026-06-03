import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';

class RwSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const RwSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: ColorsUtils.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Expanded(
                child: Text(
                  title,

                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(color: ColorsUtils.gray, fontSize: 12),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(8),

                decoration: BoxDecoration(
                  color: ColorsUtils.b50,
                  borderRadius: BorderRadius.circular(8),
                ),

                child: Icon(icon, size: 16, color: ColorsUtils.b200),
              ),
            ],
          ),

          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,

            child: Text(
              value,

              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            subtitle,

            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(color: ColorsUtils.gray, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
