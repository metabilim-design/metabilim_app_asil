// lib/pages/coach/homework_flow/finalize_schedule_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:metabilim/models/user_model.dart';
import 'package:metabilim/pages/coach/homework_flow/preview_schedule_page.dart';
// Merkezi ve doğru Topic modelini buradan alıyoruz.
import 'package:metabilim/pages/coach/homework_flow/select_topic_page.dart';
import 'dart:math';

// Her bir etüde atanacak görevin parçalarını ve sayfa aralığını tutan yardımcı sınıf.
class TaskChunk {
  final Topic originalTopic;
  final int startPage;
  final int endPage;

  TaskChunk({
    required this.originalTopic,
    required this.startPage,
    required this.endPage,
  });

  String get konu => originalTopic.konu;
  String get bookPublisher => originalTopic.bookPublisher;
  String get bookId => originalTopic.bookId;
  // Önizlemede gösterilecek net sayfa aralığı (örn: "Sayfa 50 - 59")
  String get chunkPageRange => 'Sayfa $startPage - ${endPage - 1}';
}


class FinalizeSchedulePage extends StatefulWidget {
  final AppUser student;
  final DateTime startDate;
  final DateTime endDate;
  final Map<DateTime, List<EtudSlot>> initialSchedule;
  final List<Topic> selectedTopics;
  final List<String> allSelectedMaterialIds;
  final Map<String, int> lessonEtuds;
  final int effortRating;

  const FinalizeSchedulePage({
    super.key,
    required this.student,
    required this.startDate,
    required this.endDate,
    required this.initialSchedule,
    required this.selectedTopics,
    required this.allSelectedMaterialIds,
    required this.lessonEtuds,
    required this.effortRating,
  });

  @override
  State<FinalizeSchedulePage> createState() => _FinalizeSchedulePageState();
}

class _FinalizeSchedulePageState extends State<FinalizeSchedulePage> {
  bool _isSaving = false;
  late Map<DateTime, List<EtudSlot>> _finalSchedule;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _finalSchedule = _distributeAndSplitTopics();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- İSTEDİĞİN ESNEK DAĞITIM MANTIĞI BURADA ---
  Map<DateTime, List<EtudSlot>> _distributeAndSplitTopics() {
    // 1. Adım: Konuları ve etütleri derslere göre grupla.
    final Map<String, List<Topic>> topicsByLesson = {};
    for (var topic in widget.selectedTopics) {
      topicsByLesson.putIfAbsent(topic.lesson, () => []).add(topic);
    }

    final Map<String, List<EtudSlot>> slotsByLesson = {};
    final sortedDates = widget.initialSchedule.keys.toList()..sort();
    for (var date in sortedDates) {
      for (var slot in widget.initialSchedule[date]!) {
        if (!slot.isDigital && widget.lessonEtuds.containsKey(slot.fullLessonName)) {
          slotsByLesson.putIfAbsent(slot.fullLessonName, () => []).add(slot);
        }
      }
    }

    // 2. Adım: Her ders için dağıtımı kendi içinde, esnek bir şekilde yap.
    slotsByLesson.forEach((lessonName, lessonSlots) {
      final lessonTopics = topicsByLesson[lessonName] ?? [];
      // Eğer bu ders için hiç konu seçilmemişse, etütleri "Boş Etüt" olarak bırak.
      if (lessonTopics.isEmpty) {
        for (var slot in lessonSlots) {
          slot.assignedTask = null;
        }
        return; // Sonraki derse geç.
      }

      // 3. Adım: Bu derse ait tüm seçili sayfaları tek bir listeye topla.
      final List<MapEntry<Topic, int>> allPages = [];
      for (var topic in lessonTopics) {
        for (int i = topic.startPage; i < topic.endPage; i++) {
          allPages.add(MapEntry(topic, i));
        }
      }

      final totalPages = allPages.length;
      final totalSlots = lessonSlots.length;

      if (totalPages == 0) return; // Çözülecek sayfa yoksa bu dersi atla.

      // 4. Adım: Akıllı ve Esnek Dağıtım
      // Her etüde en az kaç sayfa düşeceğini ve kaç etüde +1 sayfa ekleneceğini hesapla.
      int pagesPerSlot = totalPages ~/ totalSlots;
      int extraPages = totalPages % totalSlots;
      int currentPageIndex = 0;

      // 5. Adım: Sayfaları etütlere bölüştür.
      for (int i = 0; i < totalSlots; i++) {
        final slot = lessonSlots[i];
        // Eğer dağıtılacak sayfa kalmadıysa (çok fazla etüt, çok az sayfa durumu), etüdü boş bırak.
        if (currentPageIndex >= totalPages) {
          slot.assignedTask = null;
          continue;
        }

        // Bu etüde düşen sayfa sayısını belirle.
        int pagesForThisSlot = pagesPerSlot + (i < extraPages ? 1 : 0);

        // Görevin başlangıç ve bitiş sayfalarını belirle.
        final startEntry = allPages[currentPageIndex];
        final endEntryIndex = min(currentPageIndex + pagesForThisSlot, allPages.length);
        final endEntry = allPages[endEntryIndex - 1];

        // Bu etüt için görev parçasını (TaskChunk) oluştur ve ata.
        slot.assignedTask = TaskChunk(
          originalTopic: startEntry.key,
          startPage: startEntry.value,
          endPage: endEntry.value + 1, // Bitiş sayfası dahil edilmeyeceği için +1
        );
        currentPageIndex = endEntryIndex;
      }
    });

    return widget.initialSchedule;
  }


  Future<void> _saveScheduleToFirebase() async {
    // ... (Kaydetme fonksiyonunda değişiklik yok, doğru çalışıyor)
    setState(() => _isSaving = true);
    try {
      final dailySlotsForDB = <String, dynamic>{};
      final sortedDays = widget.initialSchedule.keys.toList()..sort();

      for(var date in sortedDays) {
        final slots = widget.initialSchedule[date]!;
        final dateKey = DateFormat('yyyy-MM-dd').format(date);

        dailySlotsForDB[dateKey] = slots.map((slot) {
          Map<String, dynamic> taskData = {};
          final assignedTask = slot.assignedTask;

          if (slot.isDigital) {
            taskData = {'type': 'digital', 'task': 'Dijital Etüt', 'status': 'assigned'};
          } else if (assignedTask != null) {
            taskData = {
              'type': 'topic',
              'subject': slot.fullLessonName, // Orijinal ders adını koruyoruz
              'publisher': assignedTask.bookPublisher,
              'bookId': assignedTask.bookId,
              'konu': assignedTask.konu,
              'sayfa': '${assignedTask.startPage}-${assignedTask.endPage-1}',
              'chunkPageRange': assignedTask.chunkPageRange, // "Sayfa 50-59" metnini de kaydediyoruz
              'status': 'assigned',
            };
          } else {
            taskData = {'type': 'empty', 'status': 'assigned'};
          }
          final timeString = "${DateFormat('HH:mm').format(slot.dateTime)} - ${DateFormat('HH:mm').format(slot.dateTime.add(const Duration(minutes: 40)))}";
          return {'time': timeString, 'task': taskData};
        }).toList();
      }

      await FirebaseFirestore.instance.collection('schedules').add({
        'studentUid': widget.student.uid,
        'startDate': widget.startDate,
        'endDate': widget.endDate,
        'createdAt': FieldValue.serverTimestamp(),
        'materials': widget.allSelectedMaterialIds,
        'lessonEtuds': widget.lessonEtuds,
        'effortRating': widget.effortRating,
        'dailySlots': dailySlotsForDB,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Program başarıyla oluşturuldu!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydederken bir hata oluştu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- ÖNİZLEME EKRANI GÜNCELLEMESİ BURADA ---
    final scheduleDays = _finalSchedule.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text('Final Önizleme ve Onay', style: GoogleFonts.poppins())),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: _currentPage > 0
                      ? () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300), curve: Curves.ease)
                      : null,
                ),
                Expanded(
                  child: Text(
                    scheduleDays.isNotEmpty ? DateFormat.yMMMEd('tr_TR').format(scheduleDays[_currentPage]) : 'Program Boş',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: _currentPage < scheduleDays.length - 1
                      ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300), curve: Curves.ease)
                      : null,
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: scheduleDays.length,
              itemBuilder: (context, index) {
                final day = scheduleDays[index];
                final slots = _finalSchedule[day]!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: slots.length,
                  itemBuilder: (context, slotIndex) {
                    final slot = slots[slotIndex];
                    final task = slot.assignedTask;
                    final lessonColor = slot.isDigital ? Colors.teal.shade100 : (task != null ? Colors.blue.shade100 : Colors.grey.shade200);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: lessonColor,
                      child: ListTile(
                        leading: Text(DateFormat.Hm().format(slot.dateTime),
                            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                        title: Text(
                          // Eğer görev varsa konunun adını, yoksa orijinal ders adını göster
                            task?.konu ?? slot.fullLessonName,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)
                        ),
                        subtitle: Text(
                          // Alt başlıkta yayıncı ve net sayfa aralığını göster
                          task != null ? '${task.bookPublisher} - ${task.chunkPageRange}' : (slot.isDigital ? 'Çevrimiçi Etüt' : 'Boş Etüt'),
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        trailing: slot.isDigital ? const Icon(Icons.computer, color: Colors.teal) : null,
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
          onPressed: _isSaving ? null : _saveScheduleToFirebase,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
              : const Icon(Icons.check_circle_outline),
          label: Text(_isSaving ? 'Kaydediliyor...' : 'Onayla ve Kaydet',
              style: GoogleFonts.poppins(fontSize: 16)),
        ),
      ),
    );
  }
}

// EtudSlot'a atanmış görevi (TaskChunk) eklemek için bir extension.
// Bu, orijinal EtudSlot sınıfını değiştirmeden ona yeni bir özellik eklememizi sağlar.
extension EtudSlotExtension on EtudSlot {
  static final Map<EtudSlot, TaskChunk?> _assignedTasks = {};

  TaskChunk? get assignedTask => _assignedTasks[this];
  set assignedTask(TaskChunk? task) {
    _assignedTasks[this] = task;
  }
}