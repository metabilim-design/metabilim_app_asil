import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/mentor/homework_check_page.dart';
import 'package:metabilim/pages/mentor/student_attendance_page.dart';
import 'package:metabilim/pages/mentor/student_schedule_page.dart';

class StudentDetailPage extends StatelessWidget {
  final String studentId;
  final String studentName;

  // Constructor ile öğrenci bilgilerini alıyoruz
  const StudentDetailPage({
    super.key,
    required this.studentId,
    required this.studentName
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // AppBar başlığını öğrencinin adına göre dinamik yapıyoruz
        title: Text(studentName, style: GoogleFonts.poppins()),
      ),
      body: GridView.count(
        crossAxisCount: 2, // Yan yana 2 kart olacak
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
          _buildFeatureCard(
            context: context,
            icon: Icons.calendar_month_outlined,
            label: 'Öğrenci Programı',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentSchedulePage(
                    studentId: studentId,
                    studentName: studentName,
                  ),
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
                    studentId: studentId,
                    studentName: studentName,
                  ),
                ),
              );
            },
          ),
          _buildFeatureCard(
            context: context,
            icon: Icons.bar_chart_outlined,
            label: 'Deneme İstatistikleri',
            onTap: () {
              // TODO: Deneme istatistikleri sayfası açılacak
              print('Deneme İstatistikleri tıklandı');
            },
          ),
          _buildFeatureCard(
            context: context,
            icon: Icons.edit_note_outlined,
            label: 'Ödev Kontrol',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeworkCheckPage(
                    studentId: studentId,
                    studentName: studentName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Kartları oluşturan yardımcı fonksiyon
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
              color: Theme.of(context).colorScheme.primary, // Ana tema rengi
            ),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}