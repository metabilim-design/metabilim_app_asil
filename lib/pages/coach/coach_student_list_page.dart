import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/mentor/student_status_tile.dart';

class CoachStudentListPage extends StatefulWidget {
  const CoachStudentListPage({super.key});

  @override
  State<CoachStudentListPage> createState() => _CoachStudentListPageState();
}

class _CoachStudentListPageState extends State<CoachStudentListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    // Giriş yapmış olan eğitim koçunun ID'sini al
    final String? coachId = _auth.currentUser?.uid;

    if (coachId == null) {
      return const Center(child: Text("Giriş yapmış bir eğitim koçu bulunamadı."));
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        // Veritabanından sadece bu koça atanmış öğrencileri çek
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'Ogrenci')
            .where('coachUid', isEqualTo: coachId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Size atanmış bir öğrenci bulunmuyor.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Öğrenciler yüklenirken bir hata oluştu.'));
          }

          final students = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final studentDoc = students[index];
              final studentData = studentDoc.data() as Map<String, dynamic>;
              final studentId = studentDoc.id;

              // Mentor panelinde de kullandığımız hazır öğrenci kartını kullanıyoruz
              return StudentStatusTile(
                studentId: studentId,
                studentData: studentData,
              );
            },
          );
        },
      ),
    );
  }
}