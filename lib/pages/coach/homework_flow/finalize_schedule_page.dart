// lib/pages/coach/homework_flow/finalize_schedule_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:metabilim/models/user_model.dart';
import 'package:metabilim/pages/coach/homework_flow/preview_schedule_page.dart';
import 'package:metabilim/pages/coach/homework_flow/select_topic_page.dart';
import 'dart:math';

// Kitap görevleri için model
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
  String get chunkPageRange => 'Sayfa $startPage - ${endPage - 1}';
}

// Deneme görevleri için model
class PracticeTask {
  final Practice originalPractice;
  PracticeTask({required this.originalPractice});

  String get name => originalPractice.name;
  String get publisher => originalPractice.publisher;
  String get id => originalPractice.id;
  String get lesson => originalPractice.lesson;
}

class FinalizeSchedulePage extends StatefulWidget {
  final AppUser student;
  final DateTime startDate;
  final DateTime endDate;
  final Map<DateTime, List<EtudSlot>> initialSchedule;
  final List<Topic> selectedTopics;
  final List<Practice> selectedPractices;
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
    required this.selectedPractices,
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
    _finalSchedule = _distributeTasks();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ### SON İSTEK BURADA DÜZELTİLDİ: GÖREVLER ARTIK KARIŞTIRILIYOR ###
  Map<DateTime, List<EtudSlot>> _distributeTasks() {
    // 1. Adım: Tüm etütleri derslere göre grupla
    final Map<String, List<EtudSlot>> slotsByLesson = {};
    final sortedDates = widget.initialSchedule.keys.toList()..sort();
    for (var date in sortedDates) {
      for (var slot in widget.initialSchedule[date]!) {
        if (!slot.isDigital) {
          slotsByLesson.putIfAbsent(slot.fullLessonName, () => []).add(slot);
        }
      }
    }

    // 2. Adım: Her ders için görevleri oluştur ve karıştır
    slotsByLesson.forEach((lessonName, lessonSlots) {
      // O derse ait tüm görevleri (deneme + kitap) tek bir listede topla
      final List<dynamic> allTasksForLesson = [];

      // a) Seçilen denemeleri ekle
      final lessonPractices = widget.selectedPractices.where((p) => p.lesson == lessonName);
      for (var practice in lessonPractices) {
        for (int i = 0; i < practice.selectedCount; i++) {
          allTasksForLesson.add(PracticeTask(originalPractice: practice));
        }
      }

      // b) Kitap konularını sayfalara bölerek ekle
      final lessonTopics = widget.selectedTopics.where((t) => t.lesson == lessonName).toList();
      final bookSlotsCount = lessonSlots.length - allTasksForLesson.length;

      if (bookSlotsCount > 0 && lessonTopics.isNotEmpty) {
        final List<MapEntry<Topic, int>> allPages = [];
        for (var topic in lessonTopics) {
          for (int i = topic.startPage; i < topic.endPage; i++) {
            allPages.add(MapEntry(topic, i));
          }
        }

        final totalPages = allPages.length;
        if(totalPages > 0) {
          int pagesPerSlot = totalPages ~/ bookSlotsCount;
          int extraPages = totalPages % bookSlotsCount;
          int currentPageIndex = 0;

          for (int i = 0; i < bookSlotsCount; i++) {
            if (currentPageIndex >= totalPages) break;
            int pagesForThisSlot = pagesPerSlot + (i < extraPages ? 1 : 0);
            final startEntry = allPages[currentPageIndex];
            final endEntryIndex = min(currentPageIndex + pagesForThisSlot, allPages.length);
            final endEntry = allPages[endEntryIndex - 1];

            allTasksForLesson.add(TaskChunk(
              originalTopic: startEntry.key,
              startPage: startEntry.value,
              endPage: endEntry.value + 1,
            ));
            currentPageIndex = endEntryIndex;
          }
        }
      }

      // 3. Adım: Oluşturulan tüm görevleri güzelce karıştır
      allTasksForLesson.shuffle(Random());

      // 4. Adım: Karıştırılmış görevleri etütlere sırayla ata
      for (int i = 0; i < lessonSlots.length; i++) {
        if (i < allTasksForLesson.length) {
          final task = allTasksForLesson[i];
          if (task is PracticeTask) {
            lessonSlots[i].assignedPractice = task;
          } else if (task is TaskChunk) {
            lessonSlots[i].assignedTask = task;
          }
        } else {
          // Eğer görev kalmadıysa boş etüt olarak bırak
          lessonSlots[i].assignedTask = null;
          lessonSlots[i].assignedPractice = null;
        }
      }
    });

    return widget.initialSchedule;
  }


  Future<void> _saveScheduleToFirebase() async {
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
          final assignedPractice = slot.assignedPractice;

          if (slot.isDigital) {
            taskData = {'type': 'digital', 'task': 'Dijital Etüt', 'status': 'assigned'};
          } else if (assignedPractice != null) {
            taskData = {
              'type': 'practice',
              'subject': slot.fullLessonName,
              'publisher': assignedPractice.publisher,
              'practiceId': assignedPractice.id,
              'status': 'assigned',
            };
          } else if (assignedTask != null) {
            taskData = {
              'type': 'topic',
              'subject': slot.fullLessonName,
              'publisher': assignedTask.bookPublisher,
              'bookId': assignedTask.bookId,
              'konu': assignedTask.konu,
              'sayfa': '${assignedTask.startPage}-${assignedTask.endPage-1}',
              'chunkPageRange': assignedTask.chunkPageRange,
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
                  onPressed: _currentPage > 0 ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease) : null,
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
                  onPressed: _currentPage < scheduleDays.length - 1 ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease) : null,
                ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: slots.length,
                  itemBuilder: (context, slotIndex) {
                    final slot = slots[slotIndex];
                    final task = slot.assignedTask;
                    final practice = slot.assignedPractice;
                    final lessonColor = slot.isDigital ? Colors.teal.shade100 : (task != null || practice != null ? Colors.blue.shade100 : Colors.grey.shade200);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: lessonColor,
                      child: ListTile(
                        leading: Text(DateFormat.Hm().format(slot.dateTime), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                        title: Text(
                            practice?.name ?? task?.konu ?? slot.fullLessonName,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)
                        ),
                        subtitle: Text(
                          practice != null ? '${practice.publisher} Denemesi' : (task != null ? '${task.bookPublisher} - ${task.chunkPageRange}' : (slot.isDigital ? 'Çevrimiçi Etüt' : 'Boş Etüt')),
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        trailing: practice != null ? Icon(Icons.assignment_outlined, color: Colors.purple) : (slot.isDigital ? const Icon(Icons.computer, color: Colors.teal) : null),
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

extension EtudSlotExtension on EtudSlot {
  static final Map<EtudSlot, dynamic> _assignedTasks = {};

  dynamic get _assignedGenericTask => _assignedTasks[this];
  set _assignedGenericTask(dynamic task) {
    _assignedTasks[this] = task;
  }

  TaskChunk? get assignedTask => _assignedGenericTask is TaskChunk ? _assignedGenericTask : null;
  set assignedTask(TaskChunk? task) => _assignedGenericTask = task;

  PracticeTask? get assignedPractice => _assignedGenericTask is PracticeTask ? _assignedGenericTask : null;
  set assignedPractice(PracticeTask? task) => _assignedGenericTask = task;
}