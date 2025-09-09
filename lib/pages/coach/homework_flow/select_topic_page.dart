import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// ----- MODELLER: Veritabanından gelen verileri bu sağlam yapılarda tutacağız -----

class Topic {
  final String konu;
  final int startPage;
  final int endPage;
  bool isSelected;

  Topic({
    required this.konu,
    required this.startPage,
    required this.endPage,
    this.isSelected = false,
  });

  int get pageCount => endPage - startPage > 0 ? endPage - startPage : 0;

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      konu: map['konu'] ?? 'İsimsiz Konu',
      startPage: map['start_page'] ?? 0, // Yeni formata uygun
      endPage: map['end_page'] ?? 0,     // Yeni formata uygun
    );
  }
}

class Book {
  final String id;
  final String name;
  final String lesson;
  final int difficulty; // 1-5 arası zorluk
  final List<Topic> topics;

  Book({
    required this.id,
    required this.name,
    required this.lesson,
    required this.difficulty,
    required this.topics,
  });
}

// ----- ANA SAYFA WIDGET'I -----

class SelectTopicPage extends StatefulWidget {
  final String studentId;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, int> lessonEtuds; // Örn: {'TYT Matematik': 8}
  final List<String> selectedMaterials; // Seçilen kitapların ID'leri
  final int effortRating; // 1-5 arası efor

  const SelectTopicPage({
    Key? key,
    required this.studentId,
    required this.startDate,
    required this.endDate,
    required this.lessonEtuds,
    required this.selectedMaterials,
    required this.effortRating,
  }) : super(key: key);

  @override
  _SelectTopicPageState createState() => _SelectTopicPageState();
}

class _SelectTopicPageState extends State<SelectTopicPage> {
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
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ----- MATEMATİK VE VERİ ÇEKME İŞLEMLERİ -----

  Future<void> _fetchBooksAndCalculateQuotas() async {
    if (widget.selectedMaterials.isEmpty) return;

    final booksSnapshot = await FirebaseFirestore.instance
        .collection('books')
        .where(FieldPath.documentId, whereIn: widget.selectedMaterials)
        .get();

    final List<Book> allBooks = [];
    for (var doc in booksSnapshot.docs) {
      final data = doc.data();
      final List<dynamic> topicsData = data['topics'] ?? [];

      allBooks.add(Book(
        id: doc.id,
        name: data['bookType'] ?? 'İsimsiz Kitap',
        lesson: '${data['level']} ${data['subject']}',
        difficulty: data['difficulty'] ?? 3,
        topics: topicsData.map((topicMap) => Topic.fromMap(topicMap)).toList(),
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
      if (isSelected) {
        _solvedPageQuotas[lessonName] = currentPageCount + topic.pageCount;
      } else {
        _solvedPageQuotas[lessonName] = currentPageCount - topic.pageCount;
      }
    });
  }

  // ----- ARAYÜZ KODLARI -----

  @override
  Widget build(BuildContext context) {
    final lessonKeys = _totalPageQuotas.keys.where((k) => _booksByLesson.containsKey(k)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Konu Seçimi', style: GoogleFonts.poppins()),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
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
          onPressed: _isLoading ? null : () { /* TODO: Önizleme sayfasına git */ },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Programı Önizle ve Bitir', style: GoogleFonts.poppins(fontSize: 16)),
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
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hedef: $solvedPages / $totalPages sayfa', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                Text('${(progress * 100).toStringAsFixed(0)}%', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(solvedPages > totalPages ? Colors.orangeAccent : Colors.lightBlueAccent),
              ),
            ),
            Divider(height: 20, thickness: 1),
            ...books.map((book) => _buildBookTile(book, lessonName)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookTile(Book book, String lessonName) {
    if(book.topics.isEmpty) return SizedBox.shrink();

    return ExpansionTile(
      title: Text(book.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      subtitle: Text('Zorluk: ${book.difficulty} / 5'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.only(left: 16),
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