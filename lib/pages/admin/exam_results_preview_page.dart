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

  // YENİ: Sıralanmış listeyi tutmak için bir state değişkeni
  late List<StudentExamResult> sortedResults;

  @override
  void initState() {
    super.initState();
    // Sayfa ilk açıldığında, gelen sonuç listesini netlere göre büyükten küçüğe sıralıyoruz.
    // Önce widget.results'ten bir kopya oluşturuyoruz ki orijinal listeyi bozmayalım.
    sortedResults = List<StudentExamResult>.from(widget.results);
    // Dart'ın sort fonksiyonu ile sıralama yapıyoruz. b.totalNet, a.totalNet'ten önce gelirse, b daha büyük demektir.
    sortedResults.sort((a, b) => b.totalNet.compareTo(a.totalNet));
  }

  Future<void> _saveResults() async {
    setState(() => _isSaving = true);
    try {
      // Kaydederken orijinal sıranın bir önemi olmadığı için sıralanmış listeyi de kullanabiliriz.
      await _firestoreService.saveExamResults(sortedResults, widget.examName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${sortedResults.length} öğrenci sonucu başarıyla kaydedildi.'), backgroundColor: Colors.green));
        Navigator.of(context).popUntil((route) => route.isFirst); // Kayıttan sonra en başa dön
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
            child: Center(child: Text("${sortedResults.length} Öğrenci", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold))),
          ),
          if (!_isSaving) IconButton(icon: const Icon(Icons.save_alt), tooltip: 'Sonuçları Kaydet', onPressed: _saveResults),
          if (_isSaving) const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white)))
        ],
      ),
      // ListView.builder artık sıralanmış olan 'sortedResults' listesini kullanıyor.
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: sortedResults.length,
        itemBuilder: (context, index) {
          final studentResult = sortedResults[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
            child: ListTile(
              // Sıralamadaki yerini göstermek için index + 1 kullanıyoruz.
              leading: CircleAvatar(child: Text((index + 1).toString())),
              title: Text(studentResult.fullName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${studentResult.className} - Puan: ${studentResult.score.toStringAsFixed(2)} - Net: ${studentResult.totalNet.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins()
              ),
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