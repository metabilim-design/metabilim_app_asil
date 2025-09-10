import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:metabilim/models/user_model.dart';
import 'package:metabilim/pages/coach/homework_flow/preview_schedule_page.dart'; // EtudSlot için
import 'package:metabilim/pages/coach/homework_flow/select_topic_page.dart'; // Book ve Topic modelleri için

// Her bir etüte atanacak olan son, detaylı görevi temsil eden model
class HomeworkTask {
  final String bookName;
  final String topicName;
  final int startPage;
  final int endPage;

  HomeworkTask({
    required this.bookName,
    required this.topicName,
    required this.startPage,
    required this.endPage,
  });

  @override
  String toString() {
    return '$bookName - $topicName (Sayfa $startPage-$endPage)';
  }
}

class FinalizeSchedulePage extends StatefulWidget {
  final AppUser student;
  final DateTime startDate;
  final DateTime endDate;
  final Map<DateTime, List<EtudSlot>> initialSchedule;
  final Map<String, List<Book>> selectedTopicsByLesson;

  const FinalizeSchedulePage({
    super.key,
    required this.student,
    required this.startDate,
    required this.endDate,
    required this.initialSchedule,
    required this.selectedTopicsByLesson,
  });

  @override
  State<FinalizeSchedulePage> createState() => _FinalizeSchedulePageState();
}

class _FinalizeSchedulePageState extends State<FinalizeSchedulePage> {
  bool _isSaving = false;
  // Son, dağıtılmış programı bu map'te tutacağız
  final Map<DateTime, List<EtudSlot>> _finalSchedule = {};
  // Etütlere atanan görevleri ayrıca tutalım
  final Map<EtudSlot, HomeworkTask> _assignedTasks = {};

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _distributeTopicsToSchedule();
  }

  // ##### AKILLI DAĞITIM ALGORİTMASI #####
  void _distributeTopicsToSchedule() {
    // 1. Gelen ham programı kopyala
    _finalSchedule.addAll(widget.initialSchedule);

    // 2. Her ders için dağıtım yap
    widget.selectedTopicsByLesson.forEach((lessonName, books) {
      // O derse ait tüm etütleri bul (dijital olanlar hariç)
      List<EtudSlot> availableSlots = [];
      _finalSchedule.values.forEach((daySlots) {
        availableSlots.addAll(daySlots.where((slot) => slot.fullLessonName == lessonName && !slot.isDigital));
      });
      availableSlots.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      // O derse ait tüm seçili konuları tek bir listede topla
      List<Topic> allTopicsForLesson = [];
      Map<Topic, String> topicToBookNameMap = {}; // Hangi konunun hangi kitaba ait olduğunu bilmek için
      for (var book in books) {
        allTopicsForLesson.addAll(book.topics);
        for (var topic in book.topics) {
          topicToBookNameMap[topic] = book.name;
        }
      }
      allTopicsForLesson.sort((a,b) => a.startPage.compareTo(b.startPage));

      if (availableSlots.isEmpty || allTopicsForLesson.isEmpty) return;

      // 3. Sayfa sayısını ve etüt başına düşen ortalama sayfayı hesapla
      final totalPages = allTopicsForLesson.fold<int>(0, (sum, t) => sum + t.pageCount);
      final pagesPerSlot = (totalPages / availableSlots.length).ceil();

      // 4. Dağıtım döngüsü
      int currentTopicIndex = 0;
      int currentPageInTopic = allTopicsForLesson[0].startPage;

      for (var slot in availableSlots) {
        if (currentTopicIndex >= allTopicsForLesson.length) break;

        final currentTopic = allTopicsForLesson[currentTopicIndex];
        final bookName = topicToBookNameMap[currentTopic]!;

        int taskStartPage = currentPageInTopic;
        int taskEndPage = currentPageInTopic + pagesPerSlot - 1;

        // Eğer bu görev, mevcut konunun sonunu aşıyorsa
        if (taskEndPage >= currentTopic.endPage) {
          taskEndPage = currentTopic.endPage;
          currentTopicIndex++; // Bir sonraki konuya geç
          if (currentTopicIndex < allTopicsForLesson.length) {
            currentPageInTopic = allTopicsForLesson[currentTopicIndex].startPage;
          }
        } else {
          currentPageInTopic = taskEndPage + 1; // Konuda kaldığımız yerden devam et
        }

        // Bu etüt için görevi oluştur ve map'e ekle
        if (taskStartPage <= taskEndPage) {
          _assignedTasks[slot] = HomeworkTask(
            bookName: bookName,
            topicName: currentTopic.konu,
            startPage: taskStartPage,
            endPage: taskEndPage,
          );
        }
      }
    });
  }

  Future<void> _saveFinalSchedule() async {
    setState(() => _isSaving = true);
    try {
      // TODO: Burada, _finalSchedule ve _assignedTasks map'lerini kullanarak
      // öğrencinin veritabanına kaydetme işlemi yapılacak.
      // Örnek: `schedules` koleksiyonuna yeni bir belge olarak eklenebilir.

      // Şimdilik sadece başarılı mesajı gösterelim
      await Future.delayed(const Duration(seconds: 1)); // Sahte bir bekleme

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Program başarıyla kaydedildi!'), backgroundColor: Colors.green));
        // Program kaydedildikten sonra en başa dön.
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kaydederken hata oluştu: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final scheduleDays = _finalSchedule.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: Text('Program Önizleme', style: GoogleFonts.poppins())),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: _currentPage > 0 ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease) : null),
                Text(scheduleDays.isNotEmpty ? DateFormat.yMMMEd('tr_TR').format(scheduleDays[_currentPage]) : 'Program Boş', style: Theme.of(context).textTheme.headlineSmall),
                IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: _currentPage < scheduleDays.length - 1 ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease) : null),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: scheduleDays.length,
              itemBuilder: (context, index) {
                final day = scheduleDays[index];
                final slots = _finalSchedule[day]!;
                return ListView.builder(
                  itemCount: slots.length,
                  itemBuilder: (context, slotIndex) {
                    final slot = slots[slotIndex];
                    final task = _assignedTasks[slot]; // Bu etüte atanmış görevi al

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: Text(DateFormat.Hm().format(slot.dateTime), style: TextStyle(fontWeight: FontWeight.bold)),
                        // Eğer görev varsa onu göster, yoksa etütün normal adını göster
                        title: Text(task?.toString() ?? slot.fullLessonName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        subtitle: task == null ? null : Text(slot.fullLessonName), // Alt başlık olarak dersin adını yaz
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveFinalSchedule,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: _isSaving ? const SizedBox(width:20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.check_circle_outline),
          label: Text(_isSaving ? 'Kaydediliyor...' : 'Onayla ve Kaydet', style: GoogleFonts.poppins(fontSize: 16)),
        ),
      ),
    );
  }
}