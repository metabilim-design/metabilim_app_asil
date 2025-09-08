// lib/pages/student/exams_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/models/exam_result.dart';
import 'package:metabilim/services/firestore_service.dart';
import 'package:metabilim/pages/student/exam_detail_page.dart';

class ExamsPage extends StatefulWidget {
  const ExamsPage({super.key});

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<StudentExamResult>> _examResultsFuture;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _examResultsFuture = _firestoreService.getStudentExams(user.uid);
    } else {
      _examResultsFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sınav Sonuçlarım", style: GoogleFonts.poppins()),
      ),
      body: FutureBuilder<List<StudentExamResult>>(
        future: _examResultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Sonuçlar yüklenirken bir hata oluştu.', style: GoogleFonts.poppins()));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Henüz görüntüleyecek bir sınav sonucunuz yok.', style: GoogleFonts.poppins()));
          }

          final results = snapshot.data!;

          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(result.examName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Puan: ${result.score.toStringAsFixed(2)} - Genel Sıralama: ${result.overallRank}',
                    style: GoogleFonts.poppins(),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExamDetailPage(result: result),
                      ),
                    );
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