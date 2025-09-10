// lib/pages/coach/coach_student_detail_page.dart - YENİ DOSYA

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/models/user_model.dart';
import 'package:metabilim/pages/coach/coach_student_exam_list_page.dart';
import 'package:metabilim/pages/mentor/student_attendance_page.dart';
import 'package:metabilim/pages/coach/weekly_check_view_page.dart'; // AZ SONRA OLUŞTURACAĞIMIZ YENİ SAYFA

class CoachStudentDetailPage extends StatelessWidget {
  final AppUser student;

  const CoachStudentDetailPage({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${student.name} ${student.surname}', style: GoogleFonts.poppins()),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.1, // Kartların en-boy oranını ayarladık
        children: [
          _buildFeatureCard(
            context: context,
            icon: Icons.checklist_rtl,
            label: 'Haftalık Program',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeeklyCheckViewPage(
                    studentId: student.uid,
                    studentName: '${student.name} ${student.surname}',
                  ),
                ),
              );
            },
          ),
          _buildFeatureCard(
            context: context,
            icon: Icons.bar_chart_outlined,
            label: 'Deneme Sonuçları',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CoachStudentExamListPage(student: student),
                ),
              );
            },
          ),
          _buildFeatureCard(
            context: context,
            icon: Icons.fact_check_outlined,
            label: 'Yoklama Durumu',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentAttendancePage(
                    studentId: student.uid,
                    studentName: '${student.name} ${student.surname}',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 50,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}