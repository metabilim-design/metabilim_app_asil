import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/models/user_model.dart';
import 'package:metabilim/pages/mentor/student_detail_page.dart';

class StudentsByClassPage extends StatefulWidget {
  final String classId;
  final String className;

  const StudentsByClassPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<StudentsByClassPage> createState() => _StudentsByClassPageState();
}

class _StudentsByClassPageState extends State<StudentsByClassPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // YENİ MANTIK: Önce sınıfın belgesini çekip öğrenci ID'lerini alacak bir Future
  Future<List<String>> _getStudentUids() async {
    final classDoc = await _firestore.collection('classes').doc(widget.classId).get();
    if (classDoc.exists && classDoc.data()!.containsKey('students')) {
      // 'students' alanını bir string listesine çeviriyoruz.
      return List<String>.from(classDoc.data()!['students']);
    }
    return []; // Eğer 'students' alanı yoksa veya boşsa, boş liste döndür.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} Sınıfı', style: GoogleFonts.poppins()),
      ),
      // FutureBuilder ile önce öğrenci ID'lerini çekiyoruz
      body: FutureBuilder<List<String>>(
        future: _getStudentUids(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Öğrenci listesi alınırken bir hata oluştu: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Bu sınıfa kayıtlı öğrenci bulunamadı.'));
          }

          final studentUids = snapshot.data!;

          // Şimdi o ID'lere sahip öğrencileri çekmek için StreamBuilder kullanıyoruz
          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .where(FieldPath.documentId, whereIn: studentUids)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (userSnapshot.hasError) {
                return Center(child: Text('Öğrenci detayları çekilirken hata: ${userSnapshot.error}'));
              }
              if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Öğrenci bilgileri bulunamadı.'));
              }

              final students = userSnapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final studentDoc = students[index];
                  final student = AppUser.fromMap(studentDoc.data() as Map<String, dynamic>, studentDoc.id);

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(student.name.isNotEmpty ? student.name[0].toUpperCase() : 'O', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      title: Text('${student.name} ${student.surname}', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      subtitle: Text(student.email),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentDetailPage(
                              studentId: student.uid,
                              studentName: '${student.name} ${student.surname}',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}