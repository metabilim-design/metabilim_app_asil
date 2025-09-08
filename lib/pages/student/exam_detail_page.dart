// lib/pages/student/exam_detail_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/models/exam_result.dart';

class ExamDetailPage extends StatelessWidget {
  final StudentExamResult result;

  const ExamDetailPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(result.examName, style: GoogleFonts.poppins()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallStatsCard(),
            const SizedBox(height: 20),
            Text("Ders Raporu", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildLessonResultsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(result.fullName, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(result.className, style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade700)),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn("Puan", result.score.toStringAsFixed(2), Colors.blue.shade700),
                  _buildStatColumn("Toplam Net", result.totalNet.toStringAsFixed(2), Colors.green.shade700),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn("Genel Sıra", result.overallRank.toString(), Colors.orange.shade700),
                  _buildStatColumn("Sınıf Sıra", result.classRank.toString(), Colors.purple.shade700),
                ],
              ),
            ],
          )
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildLessonResultsTable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: DataTable(
        columnSpacing: 30,
        headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
        columns: const [
          DataColumn(label: Text('Ders', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('D', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
          DataColumn(label: Text('Y', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
          DataColumn(label: Text('Net', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        ],
        rows: result.lessonResults.map((lesson) {
          return DataRow(cells: [
            DataCell(Text(lesson.lessonName, style: GoogleFonts.poppins())),
            DataCell(Text(lesson.correct.toStringAsFixed(0), style: GoogleFonts.poppins(color: Colors.green.shade800, fontWeight: FontWeight.w600))),
            DataCell(Text(lesson.wrong.toStringAsFixed(0), style: GoogleFonts.poppins(color: Colors.red.shade800, fontWeight: FontWeight.w600))),
            DataCell(Text(lesson.net.toStringAsFixed(2), style: GoogleFonts.poppins(fontWeight: FontWeight.bold))),
          ]);
        }).toList(),
      ),
    );
  }
}