// lib/pages/coach/homework_flow/continue_select_topic_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/models/user_model.dart';
import 'package:metabilim/pages/coach/homework_flow/finalize_schedule_page.dart';
import 'package:metabilim/pages/coach/homework_flow/preview_schedule_page.dart';
// Artık deneme modelini de içeren bu sayfayı kullanacağız
import 'package:metabilim/pages/coach/homework_flow/select_topic_page.dart';

class ContinueSelectTopicPage extends StatefulWidget {
  final AppUser student;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, int> lessonEtuds;
  final List<String> selectedMaterials;
  final int effortRating;
  final Map<DateTime, List<EtudSlot>> schedule;

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
  bool _isLoading = true;
  // ### DEĞİŞİKLİK: Denemeler ve kitaplar için ayrı haritalar ###
  final Map<String, int> _solvedPageQuotas = {};
  final Map<String, List<Book>> _booksByLesson = {};
  final Map<String, List<Practice>> _practicesByLesson = {};

  @override
  void initState() {
    super.initState();
    _initializePageData();
  }

  Future<void> _initializePageData() async {
    await _fetchMaterials();
    // Çözülen sayfaları sıfırla
    _booksByLesson.keys.forEach((lessonName) {
      _solvedPageQuotas[lessonName] = 0;
    });
    if (mounted) setState(() => _isLoading = false);
  }

  // ### DEĞİŞİKLİK: Artık hem kitapları hem denemeleri çekiyor ###
  Future<void> _fetchMaterials() async {
    if (widget.selectedMaterials.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final booksSnapshot = await FirebaseFirestore.instance.collection('books').where(FieldPath.documentId, whereIn: widget.selectedMaterials).get();
    for (var doc in booksSnapshot.docs) {
      final data = doc.data();
      final bookPublisher = data['publisher'] ?? 'Bilinmeyen Yayınevi';
      final lessonName = '${data['level']} ${data['subject']}';
      final book = Book(
        id: doc.id,
        name: data['bookType'] ?? 'İsimsiz Kitap',
        lesson: lessonName,
        difficulty: data['difficulty'] ?? 3,
        topics: List<Map<String, dynamic>>.from(data['topics'] ?? []).map((topicMap) => Topic.fromMap(topicMap, bookPublisher, doc.id, lessonName)).toList(),
      );
      _booksByLesson.putIfAbsent(book.lesson, () => []).add(book);
    }

    final practicesSnapshot = await FirebaseFirestore.instance.collection('practices').where(FieldPath.documentId, whereIn: widget.selectedMaterials).get();
    for (var doc in practicesSnapshot.docs) {
      final data = doc.data();
      final lessonName = '${data['level']} ${data['subject']}';
      final practice = Practice(
        id: doc.id,
        name: data['practiceName'] ?? 'İsimsiz Deneme',
        lesson: lessonName,
        publisher: data['publisher'] ?? 'Bilinmeyen Yayınevi',
        totalCount: data['count'] ?? 0,
      );
      _practicesByLesson.putIfAbsent(practice.lesson, () => []).add(practice);
    }
  }

  int _calculatePageQuota(int bookEtudCount, String lessonName, double avgBookDifficulty, int effort) {
    if (bookEtudCount <= 0) return 0;
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
    final totalPages = bookEtudCount * basePagesPerEtud * lessonMultiplier * bookMultiplier * effortMultiplier;
    return totalPages.round();
  }

  void _onTopicSelected(Topic topic, String lessonName, bool isSelected) {
    setState(() {
      topic.isSelected = isSelected;
      int currentPageCount = _solvedPageQuotas[lessonName] ?? 0;
      _solvedPageQuotas[lessonName] = isSelected ? currentPageCount + topic.pageCount : currentPageCount - topic.pageCount;
    });
  }

  // ### DEĞİŞİKLİK: Artık denemeleri de topluyor ###
  void _finalizeAndProceed() {
    final List<Topic> allSelectedTopics = [];
    _booksByLesson.forEach((lesson, books) {
      for (var book in books) {
        allSelectedTopics.addAll(book.topics.where((topic) => topic.isSelected));
      }
    });

    final List<Practice> allSelectedPractices = [];
    _practicesByLesson.forEach((lesson, practices) {
      for (var practice in practices) {
        if (practice.selectedCount > 0) {
          allSelectedPractices.add(practice);
        }
      }
    });

    if (allSelectedTopics.isEmpty && allSelectedPractices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen devam etmek için en az bir konu veya deneme seçin.')));
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => FinalizeSchedulePage(
      student: widget.student,
      startDate: widget.startDate,
      endDate: widget.endDate,
      initialSchedule: widget.schedule,
      selectedTopics: allSelectedTopics,
      selectedPractices: allSelectedPractices,
      allSelectedMaterialIds: widget.selectedMaterials,
      lessonEtuds: widget.lessonEtuds,
      effortRating: widget.effortRating,
    )));
  }

  @override
  Widget build(BuildContext context) {
    final lessonKeys = {..._booksByLesson.keys, ..._practicesByLesson.keys}.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Konu & Deneme Seçimi', style: GoogleFonts.poppins()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _booksByLesson.isEmpty && _practicesByLesson.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Seçilen materyaller arasında konu veya deneme bulunamadı. Lütfen materyal seçiminizi kontrol edin.',
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

  // ### DEĞİŞİKLİK: Bu widget artık `select_topic_page` içindekiyle aynı mantıkta çalışıyor ###
  Widget _buildLessonCard(String lessonName) {
    final books = _booksByLesson[lessonName] ?? [];
    final practices = _practicesByLesson[lessonName] ?? [];

    final totalEtudCount = widget.lessonEtuds[lessonName] ?? 0;
    final selectedPracticeCount = practices.fold<int>(0, (sum, p) => sum + p.selectedCount);
    final bookEtudCount = totalEtudCount - selectedPracticeCount;

    final avgDifficulty = books.isEmpty ? 3.0 : books.map((b) => b.difficulty).reduce((a, b) => a + b) / books.length;
    final totalPages = _calculatePageQuota(bookEtudCount, lessonName, avgDifficulty, widget.effortRating);
    final solvedPages = _solvedPageQuotas[lessonName] ?? 0;
    final progress = totalPages > 0 ? (solvedPages / totalPages).clamp(0.0, 1.0) : 0.0;

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
            if (practices.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text("Deneme Hedefi", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Hedef: $selectedPracticeCount / $totalEtudCount etüt', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  Text('${(totalEtudCount > 0 ? (selectedPracticeCount/totalEtudCount) * 100 : 0).toStringAsFixed(0)}%', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: totalEtudCount > 0 ? (selectedPracticeCount / totalEtudCount) : 0.0,
                  minHeight: 10,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
                ),
              ),
              const Divider(height: 20, thickness: 1),
              ...practices.map((practice) => _buildPracticeTile(practice, lessonName, totalEtudCount > selectedPracticeCount)).toList(),
            ],
            if (books.isNotEmpty) ...[
              const Divider(height: 20, thickness: 1),
              Text("Kitap Hedefi (Kalan Etüt: $bookEtudCount)", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 4),
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
          onChanged: (bool? value) => _onTopicSelected(topic, lessonName, value ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        );
      }).toList(),
    );
  }

  Widget _buildPracticeTile(Practice practice, String lessonName, bool hasRemainingSlots) {
    return ListTile(
      title: Text(practice.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      subtitle: Text(practice.publisher),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: practice.selectedCount > 0 ? () => setState(() => practice.selectedCount--) : null,
          ),
          Text(practice.selectedCount.toString(), style: const TextStyle(fontSize: 18)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: (practice.selectedCount < practice.totalCount && hasRemainingSlots)
                ? () => setState(() => practice.selectedCount++)
                : null,
          ),
        ],
      ),
    );
  }
}