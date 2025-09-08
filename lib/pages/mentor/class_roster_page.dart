import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/mentor/student_status_tile.dart';

class ClassRosterPage extends StatelessWidget {
  final String className;

  const ClassRosterPage({super.key, required this.className});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$className Öğrencileri', style: GoogleFonts.poppins()),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'Ogrenci')
            .where('class', isEqualTo: className)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Bu sınıfta kayıtlı öğrenci bulunmuyor.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Bir hata oluştu.'));
          }

          final students = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0), // Padding eklendi
            itemCount: students.length,
            itemBuilder: (context, index) {
              final studentDoc = students[index]; // DocumentSnapshot'ı al
              final studentData = studentDoc.data() as Map<String, dynamic>;
              final studentId = studentDoc.id;

              // DÜZELTİLDİ: StudentStatusTile'a doğru parametreleri veriyoruz
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