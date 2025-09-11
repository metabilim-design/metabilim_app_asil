import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/models/user_model.dart';
import 'package:metabilim/services/firestore_service.dart';
import 'package:metabilim/pages/coach/coach_student_detail_page.dart';
import 'package:metabilim/pages/coach/coach_student_exam_list_page.dart'; // Deneme sonuçları sayfası

class CoachStudentListPage extends StatefulWidget {
  // --- YENİ ---
  // Hangi sekmeden gelindiğini tutacak olan değişken.
  final String navigationSource;

  const CoachStudentListPage({super.key, required this.navigationSource});

  @override
  State<CoachStudentListPage> createState() => _CoachStudentListPageState();
}

class _CoachStudentListPageState extends State<CoachStudentListPage> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<AppUser>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _firestoreService.getStudentsForCoach();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<AppUser>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Öğrenciler yüklenirken bir hata oluştu: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Henüz size atanmış bir öğrenci bulunmamaktadır.'));
          }

          final students = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text('${student.name} ${student.surname}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text(student.classId ?? 'Sınıf belirtilmemiş', style: GoogleFonts.poppins()),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // --- DEĞİŞİKLİK BURADA ---
                    // Gelen 'navigationSource' değerine göre yönlendirme yapılıyor.
                    if (widget.navigationSource == 'deneme') {
                      // Eğer "Deneme Sonuçları" sekmesindeysek, direkt sınav listesini aç.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CoachStudentExamListPage(student: student),
                        ),
                      );
                    } else {
                      // Diğer durumlarda (Öğrenciler sekmesi), normal detay sayfasını aç.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CoachStudentDetailPage(student: student),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}