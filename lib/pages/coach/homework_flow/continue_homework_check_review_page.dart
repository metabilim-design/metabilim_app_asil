import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:metabilim/models/user_model.dart';
import 'package:metabilim/pages/coach/homework_flow/preview_schedule_page.dart'; // EtudSlot için
import 'package:metabilim/pages/student/dashboard_page.dart'; // Event modeli için
import 'package:metabilim/pages/coach/homework_flow/continue_select_topic_page.dart'; // Bir sonraki adım

class ContinueHomeworkCheckReviewPage extends StatefulWidget {
  final AppUser student;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, int> lessonEtuds;
  final List<String> selectedMaterials;
  final Map<DateTime, List<EtudSlot>> schedule;
  final int effortRating;
  final DocumentSnapshot previousScheduleDoc;

  const ContinueHomeworkCheckReviewPage({
    Key? key,
    required this.student,
    required this.startDate,
    required this.endDate,
    required this.lessonEtuds,
    required this.selectedMaterials,
    required this.schedule,
    required this.effortRating,
    required this.previousScheduleDoc,
  }) : super(key: key);

  @override
  _ContinueHomeworkCheckReviewPageState createState() => _ContinueHomeworkCheckReviewPageState();
}

class _ContinueHomeworkCheckReviewPageState extends State<ContinueHomeworkCheckReviewPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Event _createEventFromTask(Map<String, dynamic> taskData, String time) {
    final type = taskData['type'] as String?;
    if (type == 'digital') {
      return Event(title: 'Dijital Etüt', subtitle: taskData['task'] as String? ?? 'Çevrimiçi çalışma', time: time, icon: Icons.laptop_chromebook_outlined, iconColor: Colors.teal);
    } else if (type == 'topic') {
      final subject = (taskData['subject'] as String?)?.split('-').last.trim() ?? 'Ders';
      final publisher = taskData['bookPublisher'] as String? ?? '';
      final topic = taskData['konu'] as String? ?? 'Konu';
      final pageRange = taskData['chunkPageRange'] as String? ?? taskData['sayfa'] as String? ?? '';
      return Event(title: '$subject: $publisher', subtitle: '$topic ($pageRange)', time: time, icon: Icons.book_outlined, iconColor: Colors.blueGrey);
    } else if (type == 'empty') {
      return Event(title: 'Boş Etüt', subtitle: 'Bu saatte bir görevin yok.', time: time, icon: Icons.hourglass_empty, iconColor: Colors.grey.shade400);
    } else {
      return Event(title: 'Bilinmeyen Görev', subtitle: 'Programda tanımlanmamış görev.', time: time, icon: Icons.help_outline, iconColor: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previousData = widget.previousScheduleDoc.data() as Map<String, dynamic>;
    final dailySlots = previousData['dailySlots'] as Map<String, dynamic>;
    final scheduleDays = dailySlots.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.name} - Önceki Program Durumu'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Konu seçmeden önce öğrencinin bir önceki programdaki performansını gözden geçirin.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: _currentPage > 0 ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease) : null),
                Text(
                  scheduleDays.isNotEmpty
                      ? DateFormat.yMMMEd('tr_TR').format(DateTime.parse(scheduleDays[_currentPage]))
                      : 'Program Boş',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
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
                final dateKey = scheduleDays[index];
                final slots = dailySlots[dateKey] as List<dynamic>? ?? [];

                if (slots.isEmpty) {
                  return Center(child: Text('Bu gün için görev yok.', style: GoogleFonts.poppins()));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: slots.length,
                  itemBuilder: (context, slotIndex) {
                    final slot = slots[slotIndex] as Map<String, dynamic>;
                    final task = (slot['task'] as Map<String, dynamic>?) ?? {'type': 'empty'};
                    final event = _createEventFromTask(task, slot['time'] ?? '00:00');

                    if (event.icon == Icons.hourglass_empty) return const SizedBox.shrink();

                    final timeKey = event.time.replaceAll(RegExp(r'[^0-9]'), '');
                    final noteId = '${widget.student.uid}_${dateKey}_$timeKey';
                    final checkStream = FirebaseFirestore.instance.collection('homework_checks').doc(noteId).snapshots();

                    return StreamBuilder<DocumentSnapshot>(
                      stream: checkStream,
                      builder: (context, checkSnapshot) {
                        Widget checkStatusWidget = const SizedBox.shrink();
                        String? note;

                        if (checkSnapshot.hasData && checkSnapshot.data!.exists) {
                          final data = checkSnapshot.data!.data() as Map<String, dynamic>?;
                          final status = data?['status'];
                          note = data?['note'];

                          if (status == 'done') {
                            checkStatusWidget = const Icon(Icons.check_circle, color: Colors.green, size: 28);
                          } else if (status == 'not_done') {
                            checkStatusWidget = const Icon(Icons.cancel, color: Colors.red, size: 28);
                          }
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(event.icon, color: event.iconColor),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(event.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                          Text(event.subtitle, style: GoogleFonts.poppins(), maxLines: 2, overflow: TextOverflow.ellipsis,),
                                        ],
                                      ),
                                    ),
                                    checkStatusWidget,
                                  ],
                                ),
                                if (note != null && note.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(top: 10),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(note, style: GoogleFonts.poppins(fontStyle: FontStyle.italic)),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ContinueSelectTopicPage(
                  student: widget.student,
                  startDate: widget.startDate,
                  endDate: widget.endDate,
                  lessonEtuds: widget.lessonEtuds,
                  // --- HATA BURADAYDI, ŞİMDİ KESİN DÜZELDİ ---
                  selectedMaterials: widget.selectedMaterials,
                  // --- BİTTİ ---
                  effortRating: widget.effortRating,
                  schedule: widget.schedule,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Konu Seçimine Devam Et', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}