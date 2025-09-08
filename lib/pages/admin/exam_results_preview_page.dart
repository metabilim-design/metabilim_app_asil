// lib/pages/admin/exam_results_preview_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/models/exam_result.dart';
import 'package:metabilim/services/firestore_service.dart';
import 'package:metabilim/pages/admin/admin_exam_detail_page.dart';

class ExamResultsPreviewPage extends StatefulWidget {
  final List<StudentExamResult> results;
  final String examName;

  const ExamResultsPreviewPage({
    super.key,
    required this.results,
    required this.examName,
  });

  @override
  State<ExamResultsPreviewPage> createState() => _ExamResultsPreviewPageState();
}

class _ExamResultsPreviewPageState extends State<ExamResultsPreviewPage> {
  bool _isSaving = false;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _saveResults() async {
    setState(() => _isSaving = true);
    try {
      await _firestoreService.saveExamResults(widget.results, widget.examName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.results.length} öğrenci sonucu başarıyla kaydedildi.'), backgroundColor: Colors.green));
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kayıt sırasında hata oluştu: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examName, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(child: Text("${widget.results.length} Öğrenci", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold))),
          ),
          if (!_isSaving) IconButton(icon: const Icon(Icons.save_alt), tooltip: 'Sonuçları Kaydet', onPressed: _saveResults),
          if (_isSaving) const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white)))
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: widget.results.length,
        itemBuilder: (context, index) {
          final studentResult = widget.results[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
            child: ListTile(
              leading: CircleAvatar(child: Text((index + 1).toString())),
              title: Text(studentResult.fullName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              subtitle: Text('${studentResult.className} - Puan: ${studentResult.score.toStringAsFixed(2)} - Net: ${studentResult.totalNet}', style: GoogleFonts.poppins()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => AdminExamDetailPage(result: studentResult),
                ));
              },
            ),
          );
        },
      ),
    );
  }
}