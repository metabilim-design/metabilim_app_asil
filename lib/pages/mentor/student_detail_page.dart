// lib/pages/mentor/student_detail_page.dart - GÜNCELLENMİŞ TAM KOD

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metabilim/models/user_model.dart';
import 'package:metabilim/pages/coach/coach_student_exam_list_page.dart';
// YENİ: Yeni ödev kontrol sayfasını import ediyoruz
import 'package:metabilim/pages/mentor/check_homework_page.dart';
import 'package:metabilim/pages/mentor/student_attendance_page.dart';
import 'package:metabilim/pages/student/dashboard_page.dart';

class StudentDetailPage extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentDetailPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  late Future<AppUser?> _studentFuture;

  @override
  void initState() {
    super.initState();
    _studentFuture = _fetchStudent();
  }

  Future<AppUser?> _fetchStudent() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.studentId).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print("Öğrenci verisi çekilirken hata: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentName, style: GoogleFonts.poppins()),
      ),
      body: FutureBuilder<AppUser?>(
        future: _studentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Öğrenci bilgileri yüklenemedi.'));
          }

          final student = snapshot.data!;

          return GridView.count(
            crossAxisCount: 2,
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
                      builder: (context) => DashboardPage(
                        studentId: student.uid,
                        studentName: '${student.name} ${student.surname}',
                        parentName: 'Mentor',
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
              // --- DEĞİŞİKLİK BURADA ---
              _buildFeatureCard(
                context: context,
                icon: Icons.edit_note_outlined,
                label: 'Ödev Kontrol',
                onTap: () {
                  // Artık yeni ve gelişmiş ödev kontrol sayfasına yönlendiriyoruz
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckHomeworkPage(
                        studentId: student.uid,
                        studentName: '${student.name} ${student.surname}',
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
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