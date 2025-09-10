// lib/pages/coach/homework_flow/finalize_schedule_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:metabilim/models/user_model.dart';
import 'package:metabilim/pages/coach/homework_flow/preview_schedule_page.dart';
import 'package:metabilim/pages/coach/homework_flow/select_topic_page.dart';

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

  @override
  void initState() {
    super.initState();
    _finalSchedule = _distributeTopics();
  }

  Map<DateTime, List<EtudSlot>> _distributeTopics() {
    final newSchedule = Map<DateTime, List<EtudSlot>>.from(widget.initialSchedule.map(
          (key, value) => MapEntry(key, value.map((e) => EtudSlot(dateTime: e.dateTime, isDigital: e.isDigital, lessonName: e.lessonName, lessonType: e.lessonType)).toList()),
    ));

    final tasksToAssign = List<Topic>.from(widget.selectedTopics);
    final emptySlots = <EtudSlot>[];
    newSchedule.values.forEach((daySlots) {
      emptySlots.addAll(daySlots.where((slot) => !slot.isDigital && (widget.lessonEtuds.containsKey(slot.fullLessonName))));
    });

    tasksToAssign.shuffle();

    int taskIndex = 0;
    for (var slot in emptySlots) {
      if (taskIndex < tasksToAssign.length) {
        final topic = tasksToAssign[taskIndex];
        // ÖNEMLİ: Etüdün orijinal ders adını değil, sadece gösterilecek konu adını değiştiriyoruz.
        // Bu yüzden slot.lessonName'e değil, slot'un içindeki başka bir alana atama yapmak daha doğru
        // ama mevcut yapıda direkt atama yapıyoruz ve kaydederken orijinalini kullanıyoruz.
        slot.lessonName = topic.konu;
        slot.lessonType = topic.bookPublisher;
        taskIndex++;
      } else {
        slot.lessonName = 'Boş Etüt';
      }
    }
    return newSchedule;
  }

  Future<void> _saveScheduleToFirebase() async {
    setState(() => _isSaving = true);
    try {
      final dailySlotsForDB = <String, dynamic>{};

      _finalSchedule.forEach((date, slots) {
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        // Orijinal, bozulmamış ders bilgilerini içeren slot listesini alıyoruz.
        final originalSlotsForDate = widget.initialSchedule[date]!;

        dailySlotsForDB[dateKey] = slots.map((slot) {
          // Konu atanmış güncel slot ile orijinal slotu eşleştiriyoruz.
          final originalSlot = originalSlotsForDate.firstWhere((s) => s.dateTime == slot.dateTime);

          Map<String, dynamic> taskData = {};
          if (slot.isDigital) {
            taskData = {'type': 'digital', 'task': 'Dijital Etüt', 'status': 'assigned'};
          } else if (slot.lessonName != 'Boş Etüt' && slot.lessonName != null) {
            final assignedTopic = widget.selectedTopics.firstWhere(
                  (t) => t.konu == slot.lessonName && t.bookPublisher == slot.lessonType,
              orElse: () => Topic(konu: slot.lessonName!, startPage: 0, endPage: 0, bookPublisher: slot.lessonType ?? 'Bilinmiyor', bookId: ''),
            );
            taskData = {
              'type': 'topic',
              // ### ANA DÜZELTME BURADA ###
              // 'subject' alanına, konuyla bozulmuş slot'un adını değil,
              // her zaman orijinal etüdün adını ("TYT Fizik" gibi) kaydediyoruz.
              'subject': originalSlot.fullLessonName,
              'publisher': assignedTopic.bookPublisher,
              'bookId': assignedTopic.bookId,
              'konu': assignedTopic.konu,
              'sayfa': '${assignedTopic.startPage}-${assignedTopic.endPage}',
              'status': 'assigned',
            };
          } else {
            taskData = {'type': 'empty', 'status': 'assigned'};
          }
          final timeString = "${DateFormat('HH:mm').format(slot.dateTime)} - ${DateFormat('HH:mm').format(slot.dateTime.add(const Duration(minutes: 40)))}";
          return {'time': timeString, 'task': taskData};
        }).toList();
      });

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
    // ... (UI kodunda değişiklik yok)
    final scheduleDays = _finalSchedule.keys.toList()..sort();
    final PageController _pageController = PageController();

    return Scaffold(
      appBar: AppBar(title: Text('Program Önizleme', style: GoogleFonts.poppins())),
      body: PageView.builder(
        controller: _pageController,
        itemCount: scheduleDays.length,
        itemBuilder: (context, index) {
          final day = scheduleDays[index];
          final slots = _finalSchedule[day]!;
          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    DateFormat.yMMMEd('tr_TR').format(day),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                ...slots.map((slot) {
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    color: slot.isDigital ? Colors.teal.shade100 : (slot.lessonName == 'Boş Etüt' ? null : Colors.blue.shade100),
                    child: ListTile(
                      leading: Text(DateFormat.Hm().format(slot.dateTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                      title: Text(slot.lessonName ?? 'Hata'),
                      subtitle: (slot.isDigital || slot.lessonName == 'Boş Etüt') ? null : Text(slot.lessonType ?? ''),
                      trailing: slot.isDigital ? const Icon(Icons.computer, color: Colors.teal) : null,
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveScheduleToFirebase,
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