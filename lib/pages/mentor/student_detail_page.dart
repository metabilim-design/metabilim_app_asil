import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metabilim/models/user_model.dart'; // AppUser modelimizi dahil ediyoruz
import 'package:metabilim/pages/coach/coach_student_exam_list_page.dart'; // YENİ: Deneme sonuçları sayfasını dahil ediyoruz
import 'package:metabilim/pages/mentor/homework_check_page.dart';
import 'package:metabilim/pages/mentor/student_attendance_page.dart';
import 'package:metabilim/pages/mentor/student_schedule_page.dart';

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
  // Bu Future, öğrencinin tüm bilgilerini veritabanından çekecek
  late Future<AppUser?> _studentFuture;

  @override
  void initState() {
    super.initState();
    // Sayfa ilk açıldığında öğrenci verisini çekme işlemini başlatıyoruz
    _studentFuture = _fetchStudent();
  }

  // Veritabanından AppUser nesnesini çeken fonksiyon
  Future<AppUser?> _fetchStudent() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.studentId).get();
      if (doc.exists) {
        // user_model.dart dosyasındaki 'fromMap' metodunu kullanarak AppUser nesnesi oluşturuyoruz
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
      // FutureBuilder ile, veri çekilene kadar bekleyip sonra ekranı çiziyoruz
      body: FutureBuilder<AppUser?>(
        future: _studentFuture,
        builder: (context, snapshot) {
          // Veri henüz gelmediyse, yükleniyor animasyonu göster
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Hata oluştuysa veya öğrenci bulunamadıysa, hata mesajı göster
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Öğrenci bilgileri yüklenemedi.'));
          }

          // Veri başarıyla geldiyse, student nesnesini al
          final student = snapshot.data!;

          // Kartları ve arayüzü oluştur
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
                      builder: (context) => StudentSchedulePage(
                        studentId: student.uid,
                        studentName: '${student.name} ${student.surname}',
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
              // --- DEĞİŞİKLİK BURADA ---
              _buildFeatureCard(
                context: context,
                icon: Icons.bar_chart_outlined,
                label: 'Deneme Sonuçları', // Eskiden 'İstatistikleri' idi
                onTap: () {
                  // Artık elimizde tam bir 'student' nesnesi var, onu diğer sayfaya yolluyoruz
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
                icon: Icons.edit_note_outlined,
                label: 'Ödev Kontrol',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeworkCheckPage(
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

  // Kartları oluşturan yardımcı fonksiyon (hiçbir değişiklik yok)
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