// lib/pages/mentor/student_list_page.dart - GÜNCELLENMİŞ VE HATALARI DÜZELTİLMİŞ TAM KOD

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/models/user_model.dart';
import 'package:metabilim/pages/mentor/student_detail_page.dart';
import 'package:metabilim/pages/mentor/check_homework_page.dart';

class StudentListPage extends StatelessWidget {
  final String classId;
  final String purpose;

  const StudentListPage({super.key, required this.classId, required this.purpose});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          purpose == 'homeworkCheck' ? 'Öğrenci Seç' : 'Öğrenciler',
          style: GoogleFonts.poppins(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
        // --- HATA 1 BURADAYDI, DÜZELTİLDİ ---
        // 'classId' yerine veritabanındaki doğru alan adı olan 'class' kullanıldı.
            .where('class', isEqualTo: classId)
        // --- HATA 2 BURADAYDI, DÜZELTİLDİ ---
        // 'student' yerine veritabanındaki doğru değer olan 'Ogrenci' kullanıldı.
            .where('role', isEqualTo: 'Ogrenci')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Bu sınıfta öğrenci bulunamadı.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          var studentDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: studentDocs.length,
            itemBuilder: (context, index) {
              var studentData = studentDocs[index].data() as Map<String, dynamic>;
              var student = AppUser.fromMap(studentData, studentDocs[index].id);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(student.name.isNotEmpty ? student.name[0] : '?'),
                  ),
                  title: Text('${student.name} ${student.surname}', style: GoogleFonts.poppins()),
                  onTap: () {
                    if (purpose == 'homeworkCheck') {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => CheckHomeworkPage(
                          studentId: student.uid,
                          studentName: '${student.name} ${student.surname}',
                        ),
                      ));
                    } else {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => StudentDetailPage(
                          studentId: student.uid,
                          studentName: '${student.name} ${student.surname}',
                        ),
                      ));
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