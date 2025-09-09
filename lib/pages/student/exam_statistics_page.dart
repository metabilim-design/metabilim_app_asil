// lib/pages/student/exam_statistics_page.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/models/exam_result.dart';

class ExamStatisticsPage extends StatelessWidget {
  final List<StudentExamResult> examResults;
  final String title;

  const ExamStatisticsPage({
    super.key,
    required this.examResults,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    // Grafiği daha iyi göstermek için sınavları eski tarihten yeni tarihe sıralayalım
    final sortedResults = List<StudentExamResult>.from(examResults)..sort((a, b) => a.examName.compareTo(b.examName));

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.poppins()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    // X eksenine sınavların sıra numarasını yazıyoruz
                    return Text((value.toInt() + 1).toString(), style: const TextStyle(fontSize: 10));
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(sortedResults.length, (index) {
                  return FlSpot(index.toDouble(), sortedResults[index].totalNet);
                }),
                isCurved: true,
                color: Theme.of(context).primaryColor,
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}