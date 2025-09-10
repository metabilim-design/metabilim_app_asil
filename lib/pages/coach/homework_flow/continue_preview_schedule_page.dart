// lib/pages/coach/homework_flow/continue_preview_schedule_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:metabilim/models/user_model.dart';
import 'package:metabilim/pages/coach/homework_flow/preview_schedule_page.dart';
import 'package:metabilim/pages/coach/homework_flow/continue_select_materials_page.dart';
import 'package:metabilim/pages/coach/homework_flow/continue_direct_topic_page.dart';
import 'dart:math';

class ContinuePreviewSchedulePage extends StatefulWidget {
  final AppUser student;
  final DocumentSnapshot previousScheduleDoc;

  const ContinuePreviewSchedulePage({
    Key? key,
    required this.student,
    required this.previousScheduleDoc,
  }) : super(key: key);

  @override
  _ContinuePreviewSchedulePageState createState() => _ContinuePreviewSchedulePageState();
}

class _ContinuePreviewSchedulePageState extends State<ContinuePreviewSchedulePage> {
  bool _isLoading = true;
  String? _infoMessage;
  Map<DateTime, List<EtudSlot>> _schedule = {};
  final PageController _pageController = PageController();
  int _currentPage = 0;
  EtudSlot? _selectedForSwap;

  late DateTime _newStartDate;
  late DateTime _newEndDate;

  @override
  void initState() {
    super.initState();
    _generateScheduleFromPrevious();
  }

  Future<void> _generateScheduleFromPrevious() async {
    setState(() { _isLoading = true; _infoMessage = null; });
    try {
      final firestore = FirebaseFirestore.instance;
      final previousData = widget.previousScheduleDoc.data() as Map<String, dynamic>;

      final previousStartDate = (previousData['startDate'] as Timestamp).toDate();
      final previousEndDate = (previousData['endDate'] as Timestamp).toDate();
      final duration = previousEndDate.difference(previousStartDate);

      _newStartDate = previousEndDate.add(const Duration(days: 1));
      _newEndDate = _newStartDate.add(duration);

      // ### ANA DÜZELTME BURADA: Daha güvenilir ders okuma mantığı ###
      final List<EtudSlot> lessonSequence = [];
      if (previousData.containsKey('lessonEtuds')) {
        // En güvenilir yöntem: Kayıtlı ders-etüt sayısını kullan
        final lessonEtuds = previousData['lessonEtuds'] as Map<String, dynamic>;
        lessonEtuds.forEach((fullLessonName, count) {
          if (fullLessonName == 'Boş Etüt') return;
          final parts = fullLessonName.split(' ');
          if (parts.length >= 2) {
            final lessonType = parts[0];
            final lessonName = parts.sublist(1).join(' ');
            for (int i = 0; i < count; i++) {
              lessonSequence.add(EtudSlot(dateTime: DateTime.now(), lessonType: lessonType, lessonName: lessonName));
            }
          }
        });
      } else {
        // Eski yöntem: Eğer 'lessonEtuds' yoksa, eski programları okumak için yedek mantık
        final previousDailySlots = previousData['dailySlots'] as Map<String, dynamic>;
        previousDailySlots.values.forEach((slots) {
          for (var slotData in (slots as List)) {
            final task = slotData['task'] as Map<String, dynamic>?;
            if (task != null && task['type'] == 'topic') {
              final String subject = task['subject'] as String? ?? '';
              final parts = subject.split(' ');
              if (parts.length >= 2) {
                lessonSequence.add(EtudSlot(dateTime: DateTime.now(), lessonType: parts[0], lessonName: parts.sublist(1).join(' ')));
              }
            }
          }
        });
      }

      if (lessonSequence.isEmpty) {
        throw Exception('Önceki programdan kopyalanacak ders bulunamadı. Lütfen yeni bir program oluşturun.');
      }
      lessonSequence.shuffle(Random());

      if (widget.student.classId == null || widget.student.classId!.isEmpty) {
        throw Exception('Bu öğrenci herhangi bir sınıfa atanmamış.');
      }
      final classDoc = await firestore.collection('classes').doc(widget.student.classId).get();
      if (!classDoc.exists) throw Exception('Öğrencinin sınıfı bulunamadı.');
      final activeTimetableId = classDoc.data()?['activeTimetableId'] as String?;
      if (activeTimetableId == null || activeTimetableId.isEmpty) {
        throw Exception('Bu sınıfa bir etüt programı atanmamış.');
      }
      final templateDoc = await firestore.collection('schedule_templates').doc(activeTimetableId).get();
      final timetable = templateDoc.data()?['timetable'] as Map<String, dynamic>? ?? {};

      List<EtudSlot> allNewSlots = [];
      for (var day = _newStartDate; day.isBefore(_newEndDate.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
        String dayName = _getDayNameInTurkish(day.weekday);
        final slotsForDay = timetable[dayName] as List<dynamic>? ?? [];
        for (var timeEntry in slotsForDay) {
          String startTime = timeEntry.toString().split('-')[0].trim();
          final parts = startTime.split(':');
          allNewSlots.add(EtudSlot(dateTime: DateTime(day.year, day.month, day.day, int.parse(parts[0]), int.parse(parts[1]))));
        }
      }

      final Map<String, List<String>> studentWeeklyDigitalSchedule = {};
      final digitalSchedulesSnapshot = await firestore.collection('digital_schedules').get();
      for (var computerDoc in digitalSchedulesSnapshot.docs) {
        final scheduleMap = computerDoc.data()['schedule'] as Map<String, dynamic>? ?? {};
        scheduleMap.forEach((dayName, timeSlots) {
          (timeSlots as Map<String, dynamic>).forEach((timeSlot, studentId) {
            if (studentId == widget.student.uid) {
              studentWeeklyDigitalSchedule.putIfAbsent(dayName, () => []).add(timeSlot);
            }
          });
        });
      }

      List<EtudSlot> finalNewSlots = [];
      for (var slot in allNewSlots) {
        String dayName = _getDayNameInTurkish(slot.dateTime.weekday);
        String time = DateFormat('HH:mm').format(slot.dateTime);
        final digitalSlotsForDay = studentWeeklyDigitalSchedule[dayName] ?? [];
        final isDigitalMatch = digitalSlotsForDay.any((digitalTimeSlot) => digitalTimeSlot.startsWith(time));
        if (isDigitalMatch) {
          finalNewSlots.add(EtudSlot(dateTime: slot.dateTime, isDigital: true, lessonName: 'Dijital Etüt'));
        } else {
          finalNewSlots.add(slot);
        }
      }
      finalNewSlots.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      int lessonIndex = 0;
      for (var slot in finalNewSlots) {
        if (!slot.isDigital) {
          if (lessonIndex < lessonSequence.length) {
            slot.lessonType = lessonSequence[lessonIndex].lessonType;
            slot.lessonName = lessonSequence[lessonIndex].lessonName;
            lessonIndex++;
          } else {
            slot.lessonName = 'Boş Etüt';
          }
        }
      }

      Map<DateTime, List<EtudSlot>> groupedSchedule = {};
      for (var slot in finalNewSlots) {
        final dateOnly = DateTime(slot.dateTime.year, slot.dateTime.month, slot.dateTime.day);
        groupedSchedule.putIfAbsent(dateOnly, () => []).add(slot);
      }
      groupedSchedule.forEach((key, value) => value.sort((a,b) => a.dateTime.compareTo(b.dateTime)));
      if(mounted) setState(() => _schedule = groupedSchedule);

    } catch (e) {
      if(mounted) _infoMessage = 'Program oluşturulamadı: ${e.toString().replaceFirst("Exception: ", "")}';
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // ... (UI kodunda ve diğer fonksiyonlarda değişiklik yok)
  void _handleSwap(EtudSlot clickedSlot) {
    if (clickedSlot.isDigital || clickedSlot.lessonName == null || clickedSlot.lessonName == 'Boş Etüt') return;
    if (_selectedForSwap == null) {
      setState(() => _selectedForSwap = clickedSlot);
    } else {
      if (_selectedForSwap != clickedSlot && !_selectedForSwap!.isDigital) {
        final tempLessonName = _selectedForSwap!.lessonName;
        final tempLessonType = _selectedForSwap!.lessonType;
        setState(() {
          _selectedForSwap!.lessonName = clickedSlot.lessonName;
          _selectedForSwap!.lessonType = clickedSlot.lessonType;
          clickedSlot.lessonName = tempLessonName;
          clickedSlot.lessonType = tempLessonType;
        });
      }
      setState(() => _selectedForSwap = null);
    }
  }

  String _getDayNameInTurkish(int weekday) {
    const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    return days[weekday - 1];
  }

  void _showMaterialChoiceDialog() {
    final previousData = widget.previousScheduleDoc.data() as Map<String, dynamic>?;
    final List<String> previousMaterials = List<String>.from(previousData?['materials'] ?? []);
    final bool canContinueWithSame = previousMaterials.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Materyal Seçimi", style: GoogleFonts.poppins()),
          content: Text("Bu program için materyalleri değiştirmek mi istersiniz, yoksa önceki programdaki materyallerle mi devam edeceksiniz?", style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              child: const Text("Materyalleri Değiştir"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ContinueSelectMaterialsPage(
                    student: widget.student,
                    startDate: _newStartDate,
                    endDate: _newEndDate,
                    schedule: _schedule,
                    previousScheduleDoc: widget.previousScheduleDoc,
                  ),
                ));
              },
            ),
            ElevatedButton(
              onPressed: canContinueWithSame ? () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ContinueDirectTopicPage(
                    student: widget.student,
                    startDate: _newStartDate,
                    endDate: _newEndDate,
                    schedule: _schedule,
                    previousScheduleDoc: widget.previousScheduleDoc,
                  ),
                ));
              } : null,
              child: const Text("Aynılarıyla Devam Et"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleDays = _schedule.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Program Önizleme')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _infoMessage != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24.0), child: Text(_infoMessage!, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.error))))
          : Column(
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
                final slots = _schedule[day]!;
                return ListView.builder(
                  itemCount: slots.length,
                  itemBuilder: (context, slotIndex) {
                    final slot = slots[slotIndex];
                    final isSelectedForSwap = _selectedForSwap == slot;
                    final Color? lessonColor = slot.isDigital ? Colors.teal.shade100 : (slot.lessonType == 'TYT' ? Colors.blue.shade100 : slot.lessonType == 'AYT' ? Colors.orange.shade100 : Colors.grey.shade200);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      color: isSelectedForSwap ? Colors.amber.withOpacity(0.3) : lessonColor,
                      child: ListTile(
                        leading: Text(DateFormat.Hm().format(slot.dateTime), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                        title: Text(slot.fullLessonName),
                        trailing: slot.isDigital ? Icon(Icons.computer, color: Colors.teal) : (slot.lessonName == 'Boş Etüt' ? null : IconButton(
                          icon: Icon(Icons.swap_horiz, color: isSelectedForSwap ? Colors.amber.shade900 : null),
                          onPressed: () => _handleSwap(slot),
                        )),
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
        child: ElevatedButton(
          onPressed: (_isLoading || _infoMessage != null) ? null : _showMaterialChoiceDialog,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Devam Et', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}