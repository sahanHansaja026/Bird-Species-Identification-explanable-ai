import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FeatureChart extends StatelessWidget {
  final Map<String, double> data;

  const FeatureChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: data.entries.map((e) {
          return BarChartGroupData(
            x: data.keys.toList().indexOf(e.key),
            barRods: [BarChartRodData(toY: e.value)],
          );
        }).toList(),
      ),
    );
  }
}
