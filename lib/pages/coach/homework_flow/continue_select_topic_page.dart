// lib/pages/coach/homework_flow/continue_select_topic_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/models/user_model.dart';
import 'package:metabilim/pages/coach/homework_flow/finalize_schedule_page.dart';
// HATA DÜZELTMESİ: EtudSlot'un tanımını içeren dosyayı import ediyoruz.
import 'package:metabilim/pages/coach/homework_flow/preview_schedule_page.dart';
import 'package:metabilim/pages/coach/homework_flow/select_topic_page.dart';

class ContinueSelectTopicPage extends StatefulWidget {
  final AppUser student;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, int> lessonEtuds;
  final List<String> selectedMaterials;
  final int effortRating;
  final Map<DateTime, List<EtudSlot>> schedule; // Bu satır artık hata vermeyecek

  const ContinueSelectTopicPage({
    Key? key,
    required this.student,
    required this.startDate,
    required this.endDate,
    required this.lessonEtuds,
    required this.selectedMaterials,
    required this.effortRating,
    required this.schedule,
  }) : super(key: key);

  @override
  _ContinueSelectTopicPageState createState() => _ContinueSelectTopicPageState();
}

class _ContinueSelectTopicPageState extends State<ContinueSelectTopicPage> {
  // ... Geri kalan kodun tamamı aynı, hiçbir değişiklik yok ...
  bool _isLoading = true;
  final Map<String, int> _totalPageQuotas = {};
  final Map<String, int> _solvedPageQuotas = {};
  final Map<String, List<Book>> _booksByLesson = {};

  @override
  void initState() {
    super.initState();
    _initializePageData();
  }

  Future<void> _initializePageData() async {
    await _fetchBooksAndCalculateQuotas();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchBooksAndCalculateQuotas() async {
    if (widget.selectedMaterials.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final booksSnapshot = await FirebaseFirestore.instance.collection('books').where(FieldPath.documentId, whereIn: widget.selectedMaterials).get();
    final List<Book> allBooks = [];
    for (var doc in booksSnapshot.docs) {
      final data = doc.data();
      final bookPublisher = data['publisher'] ?? 'Bilinmeyen Yayınevi';
      final lessonName = '${data['level']} ${data['subject']}';
      allBooks.add(Book(
        id: doc.id,
        name: data['bookType'] ?? 'İsimsiz Kitap',
        lesson: lessonName,
        difficulty: data['difficulty'] ?? 3,
        topics: List<Map<String, dynamic>>.from(data['topics'] ?? []).map((topicMap) => Topic.fromMap(topicMap, bookPublisher, doc.id, lessonName)).toList(),
      ));
    }

    for (var book in allBooks) {
      _booksByLesson.putIfAbsent(book.lesson, () => []).add(book);
    }

    for (String lessonName in widget.lessonEtuds.keys) {
      final etudCount = widget.lessonEtuds[lessonName]!;
      final booksForLesson = _booksByLesson[lessonName] ?? [];
      if (booksForLesson.isEmpty) {
        _totalPageQuotas[lessonName] = 0;
        _solvedPageQuotas[lessonName] = 0;
        continue;
      }
      final avgDifficulty = booksForLesson.map((b) => b.difficulty).reduce((a, b) => a + b) / booksForLesson.length;
      final quota = _calculatePageQuota(etudCount, lessonName, avgDifficulty, widget.effortRating);
      _totalPageQuotas[lessonName] = quota;
      _solvedPageQuotas[lessonName] = 0;
    }
  }

  int _calculatePageQuota(int etudCount, String lessonName, double avgBookDifficulty, int effort) {
    const double basePagesPerEtud = 10.0;
    double lessonMultiplier = 1.0;
    if (lessonName.contains('Fizik') || lessonName.contains('Kimya') || lessonName.contains('Türkçe')) {
      lessonMultiplier = 0.5;
    } else if (!lessonName.contains('Matematik')) {
      lessonMultiplier = 0.4;
    }
    final bookDifficultyMultipliers = {1: 5/3, 2: 4/3, 3: 1.0, 4: 2/3, 5: 1/3};
    final bookMultiplier = bookDifficultyMultipliers[avgBookDifficulty.round()] ?? 1.0;
    final effortMultipliers = {1: 1/3, 2: 2/3, 3: 1.0, 4: 4/3, 5: 5/3};
    final effortMultiplier = effortMultipliers[effort] ?? 1.0;
    final totalPages = etudCount * basePagesPerEtud * lessonMultiplier * bookMultiplier * effortMultiplier;
    return totalPages.round();
  }

  void _onTopicSelected(Topic topic, String lessonName, bool isSelected) {
    setState(() {
      topic.isSelected = isSelected;
      int currentPageCount = _solvedPageQuotas[lessonName] ?? 0;
      _solvedPageQuotas[lessonName] = isSelected ? currentPageCount + topic.pageCount : currentPageCount - topic.pageCount;
    });
  }

  void _finalizeAndProceed() {
    final List<Topic> allSelectedTopics = [];
    _booksByLesson.forEach((lesson, books) {
      for (var book in books) {
        allSelectedTopics.addAll(book.topics.where((topic) => topic.isSelected));
      }
    });

    if (allSelectedTopics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen devam etmek için en az bir konu seçin.')));
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => FinalizeSchedulePage(
      student: widget.student,
      startDate: widget.startDate,
      endDate: widget.endDate,
      initialSchedule: widget.schedule,
      selectedTopics: allSelectedTopics,
      allSelectedMaterialIds: widget.selectedMaterials,
      lessonEtuds: widget.lessonEtuds,
      effortRating: widget.effortRating,
    )));
  }

  @override
  Widget build(BuildContext context) {
    final lessonKeys = _totalPageQuotas.keys.where((k) => _booksByLesson.containsKey(k)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Konu Seçimi', style: GoogleFonts.poppins()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _booksByLesson.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Seçilen materyaller arasında konu içeren bir kitap bulunamadı. Lütfen materyal seçiminizi kontrol edin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: lessonKeys.length,
        itemBuilder: (context, index) {
          final lessonName = lessonKeys[index];
          return _buildLessonCard(lessonName);
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _finalizeAndProceed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Programı Dağıt ve Önizle', style: GoogleFonts.poppins(fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildLessonCard(String lessonName) {
    final totalPages = _totalPageQuotas[lessonName]!;
    final solvedPages = _solvedPageQuotas[lessonName]!;
    final progress = totalPages > 0 ? (solvedPages / totalPages).clamp(0.0, 1.0) : 0.0;
    final books = _booksByLesson[lessonName] ?? [];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lessonName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hedef: $solvedPages / $totalPages sayfa', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                Text('${(progress * 100).toStringAsFixed(0)}%', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(solvedPages > totalPages ? Colors.orangeAccent : Colors.lightBlueAccent),
              ),
            ),
            const Divider(height: 20, thickness: 1),
            ...books.map((book) => _buildBookTile(book, lessonName)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookTile(Book book, String lessonName) {
    if (book.topics.isEmpty) return const SizedBox.shrink();

    return ExpansionTile(
      title: Text(book.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      subtitle: Text('Zorluk: ${book.difficulty} / 5'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: 16),
      initiallyExpanded: true,
      children: book.topics.map((topic) {
        return CheckboxListTile(
          title: Text(topic.konu),
          subtitle: Text('Sayfa ${topic.startPage} - ${topic.endPage} (${topic.pageCount} sayfa)'),
          value: topic.isSelected,
          onChanged: (bool? value) {
            _onTopicSelected(topic, lessonName, value ?? false);
          },
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        );
      }).toList(),
    );
  }
}