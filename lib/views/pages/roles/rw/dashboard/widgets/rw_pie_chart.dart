import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/roles/rw/dashboard/rw_dashboard_viewmodel.dart';

class RwPieChart extends StatefulWidget {
  const RwPieChart({super.key});

  @override
  State<RwPieChart> createState() => _RwPieChartState();
}

class _RwPieChartState extends State<RwPieChart> {
  int touchedIndex = -1;

  final List<Color> sectionColors = [
    ColorsUtils.skyblue,
    ColorsUtils.green,
    ColorsUtils.o100,
    ColorsUtils.red,
    ColorsUtils.b200,
    Colors.teal,
    Colors.purple,
    Colors.orange,
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardRwViewModel>();

    final data = vm.pendudukPerRt;

    if (data.isEmpty) {
      return const Center(child: Text("Data RT belum tersedia"));
    }

    return SizedBox(
      height: 240,

      child: Padding(
        padding: const EdgeInsets.only(right: 45),

        child: PieChart(
          duration: const Duration(milliseconds: 250),

          curve: Curves.easeOut,

          PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 42,

            pieTouchData: PieTouchData(
              touchCallback: (event, response) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      response == null ||
                      response.touchedSection == null) {
                    touchedIndex = -1;
                    return;
                  }

                  touchedIndex = response.touchedSection!.touchedSectionIndex;
                });
              },
            ),

            sections: List.generate(data.length, (i) {
              final item = data[i];

              final isTouched = i == touchedIndex;

              return PieChartSectionData(
                value: item.totalWarga.toDouble(),

                color: sectionColors[i % sectionColors.length],

                title: item.noRt,

                radius: isTouched ? 58 : 50,

                titleStyle: TextStyle(
                  fontSize: isTouched ? 14 : 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),

                badgeWidget: isTouched
                    ? _buildTooltip(
                        item.noRt,
                        item.totalWarga,
                        sectionColors[i % sectionColors.length],
                      )
                    : null,

                badgePositionPercentageOffset: 1.35,
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildTooltip(String rt, int total, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),

      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(14),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          Container(
            width: 10,
            height: 10,

            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),

          const SizedBox(height: 6),

          Text(
            "RT $rt",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),

          const SizedBox(height: 2),

          Text(
            "$total Warga",
            style: const TextStyle(fontSize: 11, color: ColorsUtils.gray),
          ),
        ],
      ),
    );
  }
}
