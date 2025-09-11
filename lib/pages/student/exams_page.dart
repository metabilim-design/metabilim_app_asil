import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/models/exam_result.dart';
import 'package:metabilim/services/firestore_service.dart';
import 'package:metabilim/pages/student/exam_detail_page.dart';
import 'package:metabilim/pages/student/exam_statistics_page.dart';

class ExamsPage extends StatefulWidget {
  final String? studentId;
  const ExamsPage({super.key, this.studentId});

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<StudentExamResult>> _examResultsFuture;
  late TabController _tabController;
  late String _targetStudentId;

  List<StudentExamResult> _tytExams = [];
  List<StudentExamResult> _aytExams = [];
  List<StudentExamResult> _branchExams = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _targetStudentId = widget.studentId ?? FirebaseAuth.instance.currentUser!.uid;
    _loadExams();
  }

  void _loadExams() {
    _examResultsFuture = _firestoreService.getStudentExams(_targetStudentId);
    _examResultsFuture.then((allExams) {
      if(mounted) {
        setState(() {
          _tytExams = allExams.where((exam) => exam.examType == 'TYT').toList();
          _aytExams = allExams.where((exam) => exam.examType == 'AYT').toList();
          _branchExams = allExams.where((exam) => exam.examType == 'BRANŞ').toList();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sınav Sonuçları", style: GoogleFonts.poppins()),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'TYT'),
            Tab(text: 'AYT'),
            Tab(text: 'BRANŞ'),
          ],
        ),
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
            return Center(child: Text('Henüz görüntülenecek bir sınav sonucu yok.', style: GoogleFonts.poppins()));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildExamList(_tytExams, 'TYT'),
              _buildExamList(_aytExams, 'AYT'),
              _buildExamList(_branchExams, 'BRANŞ'),
            ],
          );
        },
      ),
    );
  }

  // --- DEĞİŞİKLİK BURADA: İSTATİSTİK BUTONU GERİ GELDİ ---
  Widget _buildExamList(List<StudentExamResult> exams, String examType) {
    if (exams.isEmpty) {
      return Center(child: Text('Bu kategoride sınav bulunmamaktadır.', style: GoogleFonts.poppins()));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(Icons.bar_chart, color: Theme.of(context).primaryColor),
              onPressed: () {
                if (exams.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Grafik oluşturmak için en az 2 sınav sonucu gereklidir."),
                  ));
                  return;
                }
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ExamStatisticsPage(examResults: exams, title: '$examType Net Grafiği'),
                ));
              },
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final result = exams[index];
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
          ),
        ),
      ],
    );
  }
// --- BİTTİ ---
}