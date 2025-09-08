import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/admin/coach_detail_page.dart'; // Yeni oluşturacağımız sayfa

class CoachManagementPage extends StatefulWidget {
  const CoachManagementPage({super.key});

  @override
  State<CoachManagementPage> createState() => _CoachManagementPageState();
}

class _CoachManagementPageState extends State<CoachManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        // Sadece 'Eğitim Koçu' rolündeki kullanıcıları çek
        stream: _firestore.collection('users').where('role', isEqualTo: 'Eğitim Koçu').snapshots(),
        builder: (context, coachSnapshot) {
          if (coachSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!coachSnapshot.hasData || coachSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Sistemde kayıtlı eğitim koçu bulunmuyor.'));
          }
          if (coachSnapshot.hasError) {
            return const Center(child: Text('Eğitim koçları yüklenemedi.'));
          }

          final coaches = coachSnapshot.data!.docs;

          // Her koçun öğrenci sayısını bulmak için ikinci bir StreamBuilder
          return StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').where('role', isEqualTo: 'Ogrenci').snapshots(),
            builder: (context, studentSnapshot) {

              Map<String, int> studentCounts = {};
              if (studentSnapshot.hasData) {
                for (var student in studentSnapshot.data!.docs) {
                  final coachId = (student.data() as Map<String, dynamic>)['coachUid'];
                  if (coachId != null) {
                    studentCounts[coachId] = (studentCounts[coachId] ?? 0) + 1;
                  }
                }
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: coaches.length,
                itemBuilder: (context, index) {
                  final coachDoc = coaches[index];
                  final coachData = coachDoc.data() as Map<String, dynamic>;
                  final studentCount = studentCounts[coachDoc.id] ?? 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.school_outlined),
                      ),
                      title: Text('${coachData['name']} ${coachData['surname']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      subtitle: Text('$studentCount öğrenci atanmış'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CoachDetailPage(coachId: coachDoc.id, coachName: '${coachData['name']} ${coachData['surname']}'),
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