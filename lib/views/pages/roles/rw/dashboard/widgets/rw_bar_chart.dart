import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/roles/rw/dashboard/rw_dashboard_viewmodel.dart';

class RwBarChart extends StatelessWidget {
  const RwBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardRwViewModel>();

    final data = [vm.anak, vm.produktif, vm.lansia];

    final maxValue = data.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 220,

      child: BarChart(
        BarChartData(
          maxY: (maxValue + 20).toDouble(),
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),

            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),

            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),

            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,

                getTitlesWidget: (value, meta) {
                  final labels = ["Anak", "Produktif", "Lansia"];

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),

                    child: Text(
                      labels[value.toInt()],

                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          barGroups: [
            _bar(0, vm.anak.toDouble(), ColorsUtils.yellow),
            _bar(1, vm.produktif.toDouble(), ColorsUtils.green),
            _bar(2, vm.lansia.toDouble(), ColorsUtils.b200),
          ],
        ),
      ),
    );
  }


  BarChartGroupData _bar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,

      barRods: [
        BarChartRodData(
          toY: y,
          width: 22,
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }
}
